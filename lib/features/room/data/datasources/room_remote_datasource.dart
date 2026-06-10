import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shmuki_talk/core/constants/app_constants.dart';
import 'package:shmuki_talk/core/constants/firestore_constants.dart';
import 'package:shmuki_talk/core/errors/app_exception.dart';
import 'package:shmuki_talk/core/utils/invite_code_generator.dart';
import 'package:shmuki_talk/core/utils/logger.dart';
import 'package:shmuki_talk/features/room/data/models/queue_entry_model.dart';
import 'package:shmuki_talk/features/room/data/models/room_member_model.dart';
import 'package:shmuki_talk/features/room/data/models/room_model.dart';
import 'package:shmuki_talk/features/room/domain/entities/room_member.dart';

abstract class RoomRemoteDataSource {
  Future<RoomModel> createRoom({
    required String name,
    required String emoji,
    required String ownerId,
    required String ownerName,
    required String? ownerPhotoURL,
    String? imageURL,
  });

  Future<RoomModel> getRoomById(String roomId);
  Future<RoomModel?> getRoomByInviteCode(String inviteCode);
  Stream<RoomModel> watchRoom(String roomId);
  Future<void> updateRoom(RoomModel room);
  Future<void> deleteRoom(String roomId);

  Future<void> joinRoom(
    String roomId,
    String userId,
    String displayName,
    String? photoURL,
  );
  Future<void> leaveRoom(String roomId, String userId);
  Stream<List<RoomMemberModel>> watchRoomMembers(String roomId);
  Future<RoomMemberModel?> getMember(String roomId, String userId);

  Future<void> updateMemberRole(String roomId, String userId, MemberRole role);
  Future<void> muteMember(String roomId, String userId, bool mute);
  Future<void> removeMember(String roomId, String userId);
  Future<void> updateMemberStatus(String roomId, String userId, String status);
  Future<void> setListenerOnly(String roomId, String userId, bool isListenerOnly);

  Future<void> lockRoom(String roomId, bool locked);
  Future<void> transferOwnership(String roomId, String newOwnerId);

  Future<bool> tryClaimSpeaker(
    String roomId,
    String userId,
    String displayName,
    String? photoURL,
  );
  Future<void> releaseSpeaker(String roomId, String userId);

  Stream<List<QueueEntryModel>> watchQueue(String roomId);
  Future<void> joinQueue(
    String roomId,
    String userId,
    String displayName,
    String? photoURL, {
    bool isAdmin = false,
  });
  Future<void> leaveQueue(String roomId, String userId);
  Future<void> promoteToTopOfQueue(String roomId, String userId);

  Stream<List<RoomModel>> watchUserRooms(String userId);
  Future<List<RoomModel>> getUserRooms(String userId);
}

class RoomRemoteDataSourceImpl implements RoomRemoteDataSource {
  final FirebaseFirestore _firestore;

  RoomRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _rooms =>
      _firestore.collection(FirestoreConstants.roomsCollection);

  DocumentReference _roomDoc(String roomId) => _rooms.doc(roomId);

  CollectionReference _members(String roomId) =>
      _roomDoc(roomId).collection(FirestoreConstants.membersSubcollection);

  CollectionReference _queue(String roomId) =>
      _roomDoc(roomId).collection(FirestoreConstants.queueSubcollection);

  @override
  Future<RoomModel> createRoom({
    required String name,
    required String emoji,
    required String ownerId,
    required String ownerName,
    required String? ownerPhotoURL,
    String? imageURL,
  }) async {
    final inviteCode = InviteCodeGenerator.generateFromName(name);
    final roomRef = _rooms.doc();

    final now = DateTime.now();
    final roomData = {
      'id': roomRef.id,
      'name': name,
      'emoji': emoji,
      'imageURL': imageURL,
      'inviteCode': inviteCode,
      'ownerId': ownerId,
      'isLocked': false,
      'currentSpeakerId': null,
      'currentSpeakerName': null,
      'currentSpeakerPhotoURL': null,
      'speakerStartedAt': null,
      'participantCount': 1,
      'listenerCount': 0,
      'queueCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.runTransaction((tx) async {
      tx.set(roomRef, roomData);

      final memberRef = _members(roomRef.id).doc(ownerId);
      tx.set(memberRef, {
        'userId': ownerId,
        'displayName': ownerName,
        'photoURL': ownerPhotoURL,
        'role': FirestoreConstants.roleOwner,
        'isMuted': false,
        'isListenerOnly': false,
        'status': FirestoreConstants.statusOnline,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });

      // Add room to user's rooms list
      final userRef = _firestore
          .collection(FirestoreConstants.usersCollection)
          .doc(ownerId);
      tx.update(userRef, {
        'rooms': FieldValue.arrayUnion([roomRef.id]),
      });
    });

    AppLogger.room('Room created: ${roomRef.id}');
    final doc = await roomRef.get();
    return RoomModel.fromFirestore(doc);
  }

  @override
  Future<RoomModel> getRoomById(String roomId) async {
    final doc = await _roomDoc(roomId).get();
    if (!doc.exists) throw const RoomException(message: 'החדר לא נמצא', code: 'not_found');
    return RoomModel.fromFirestore(doc);
  }

  @override
  Future<RoomModel?> getRoomByInviteCode(String inviteCode) async {
    final query = await _rooms
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return RoomModel.fromFirestore(query.docs.first);
  }

  @override
  Stream<RoomModel> watchRoom(String roomId) {
    return _roomDoc(roomId).snapshots().map(RoomModel.fromFirestore);
  }

  @override
  Future<void> updateRoom(RoomModel room) async {
    await _roomDoc(room.id).update({
      'name': room.name,
      'emoji': room.emoji,
      'imageURL': room.imageURL,
      'isLocked': room.isLocked,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await _roomDoc(roomId).delete();
  }

  @override
  Future<void> joinRoom(
    String roomId,
    String userId,
    String displayName,
    String? photoURL,
  ) async {
    final roomDoc = await _roomDoc(roomId).get();
    if (!roomDoc.exists) {
      throw const RoomException(message: 'החדר לא נמצא', code: 'not_found');
    }

    final roomData = roomDoc.data() as Map<String, dynamic>;
    if (roomData['isLocked'] == true) {
      throw const RoomException(message: 'החדר נעול', code: 'locked');
    }

    final currentCount = roomData['participantCount'] as int? ?? 0;
    if (currentCount >= AppConstants.maxRoomParticipants) {
      throw const RoomException(message: 'החדר מלא', code: 'full');
    }

    await _firestore.runTransaction((tx) async {
      final memberRef = _members(roomId).doc(userId);
      tx.set(memberRef, {
        'userId': userId,
        'displayName': displayName,
        'photoURL': photoURL,
        'role': FirestoreConstants.roleMember,
        'isMuted': false,
        'isListenerOnly': false,
        'status': FirestoreConstants.statusOnline,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });

      tx.update(_roomDoc(roomId), {
        'participantCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final userRef = _firestore
          .collection(FirestoreConstants.usersCollection)
          .doc(userId);
      tx.update(userRef, {
        'rooms': FieldValue.arrayUnion([roomId]),
      });
    });
  }

  @override
  Future<void> leaveRoom(String roomId, String userId) async {
    await _firestore.runTransaction((tx) async {
      // Remove from queue if in it
      final queueQuery = await _queue(roomId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      for (final doc in queueQuery.docs) {
        tx.delete(doc.reference);
      }

      // Release speaker if currently speaking
      final roomDoc = await _roomDoc(roomId).get();
      final roomData = roomDoc.data() as Map<String, dynamic>?;
      if (roomData?['currentSpeakerId'] == userId) {
        tx.update(_roomDoc(roomId), {
          'currentSpeakerId': null,
          'currentSpeakerName': null,
          'currentSpeakerPhotoURL': null,
          'speakerStartedAt': null,
        });
      }

      tx.delete(_members(roomId).doc(userId));

      tx.update(_roomDoc(roomId), {
        'participantCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final userRef = _firestore
          .collection(FirestoreConstants.usersCollection)
          .doc(userId);
      tx.update(userRef, {
        'rooms': FieldValue.arrayRemove([roomId]),
        'currentRoomId': null,
      });
    });
  }

  @override
  Stream<List<RoomMemberModel>> watchRoomMembers(String roomId) {
    return _members(roomId)
        .orderBy('displayName')
        .snapshots()
        .map((snap) => snap.docs.map(RoomMemberModel.fromFirestore).toList());
  }

  @override
  Future<RoomMemberModel?> getMember(String roomId, String userId) async {
    final doc = await _members(roomId).doc(userId).get();
    if (!doc.exists) return null;
    return RoomMemberModel.fromFirestore(doc);
  }

  @override
  Future<void> updateMemberRole(
    String roomId,
    String userId,
    MemberRole role,
  ) async {
    final roleString = role == MemberRole.owner
        ? FirestoreConstants.roleOwner
        : role == MemberRole.admin
            ? FirestoreConstants.roleAdmin
            : FirestoreConstants.roleMember;

    await _members(roomId).doc(userId).update({'role': roleString});
  }

  @override
  Future<void> muteMember(String roomId, String userId, bool mute) async {
    await _members(roomId).doc(userId).update({'isMuted': mute});
  }

  @override
  Future<void> removeMember(String roomId, String userId) async {
    await leaveRoom(roomId, userId);
  }

  @override
  Future<void> updateMemberStatus(
    String roomId,
    String userId,
    String status,
  ) async {
    await _members(roomId).doc(userId).update({
      'status': status,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setListenerOnly(
    String roomId,
    String userId,
    bool isListenerOnly,
  ) async {
    await _members(roomId).doc(userId).update({
      'isListenerOnly': isListenerOnly,
    });

    // Update listener count
    if (isListenerOnly) {
      await _roomDoc(roomId).update({
        'listenerCount': FieldValue.increment(1),
      });
    } else {
      await _roomDoc(roomId).update({
        'listenerCount': FieldValue.increment(-1),
      });
    }
  }

  @override
  Future<void> lockRoom(String roomId, bool locked) async {
    await _roomDoc(roomId).update({
      'isLocked': locked,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> transferOwnership(String roomId, String newOwnerId) async {
    await _firestore.runTransaction((tx) async {
      final roomDoc = await _roomDoc(roomId).get();
      final currentOwnerId =
          (roomDoc.data() as Map<String, dynamic>)['ownerId'] as String;

      tx.update(_roomDoc(roomId), {
        'ownerId': newOwnerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(_members(roomId).doc(newOwnerId), {
        'role': FirestoreConstants.roleOwner,
      });

      tx.update(_members(roomId).doc(currentOwnerId), {
        'role': FirestoreConstants.roleAdmin,
      });
    });
  }

  @override
  Future<bool> tryClaimSpeaker(
    String roomId,
    String userId,
    String displayName,
    String? photoURL,
  ) async {
    bool claimed = false;

    await _firestore.runTransaction((tx) async {
      final roomDoc = await tx.get(_roomDoc(roomId));
      final data = roomDoc.data() as Map<String, dynamic>?;

      final currentSpeaker = data?['currentSpeakerId'] as String?;
      if (currentSpeaker == null || currentSpeaker.isEmpty) {
        tx.update(_roomDoc(roomId), {
          'currentSpeakerId': userId,
          'currentSpeakerName': displayName,
          'currentSpeakerPhotoURL': photoURL,
          'speakerStartedAt': FieldValue.serverTimestamp(),
        });
        claimed = true;
      }
    });

    if (claimed) {
      await updateMemberStatus(
          roomId, userId, FirestoreConstants.statusSpeaking);
    }

    return claimed;
  }

  @override
  Future<void> releaseSpeaker(String roomId, String userId) async {
    await _firestore.runTransaction((tx) async {
      final roomDoc = await tx.get(_roomDoc(roomId));
      final data = roomDoc.data() as Map<String, dynamic>?;

      if (data?['currentSpeakerId'] == userId) {
        tx.update(_roomDoc(roomId), {
          'currentSpeakerId': null,
          'currentSpeakerName': null,
          'currentSpeakerPhotoURL': null,
          'speakerStartedAt': null,
        });
      }
    });

    await updateMemberStatus(roomId, userId, FirestoreConstants.statusOnline);

    // Activate next in queue
    await _activateNextInQueue(roomId);
  }

  Future<void> _activateNextInQueue(String roomId) async {
    final queueSnap = await _queue(roomId)
        .orderBy('priority', descending: true)
        .orderBy('joinedAt')
        .limit(1)
        .get();

    if (queueSnap.docs.isEmpty) return;

    final nextEntry = QueueEntryModel.fromFirestore(queueSnap.docs.first);

    // Claim speaker for next in queue
    final memberDoc =
        await _members(roomId).doc(nextEntry.userId).get();
    if (!memberDoc.exists) {
      // User left - delete queue entry and try next
      await queueSnap.docs.first.reference.delete();
      await _activateNextInQueue(roomId);
      return;
    }

    final memberData = memberDoc.data() as Map<String, dynamic>;
    final displayName = memberData['displayName'] as String? ?? '';
    final photoURL = memberData['photoURL'] as String?;

    await _firestore.runTransaction((tx) async {
      tx.update(_roomDoc(roomId), {
        'currentSpeakerId': nextEntry.userId,
        'currentSpeakerName': displayName,
        'currentSpeakerPhotoURL': photoURL,
        'speakerStartedAt': FieldValue.serverTimestamp(),
        'queueCount': FieldValue.increment(-1),
      });

      tx.delete(queueSnap.docs.first.reference);
      tx.update(_members(roomId).doc(nextEntry.userId), {
        'status': FirestoreConstants.statusSpeaking,
      });
    });
  }

  @override
  Stream<List<QueueEntryModel>> watchQueue(String roomId) {
    return _queue(roomId)
        .orderBy('priority', descending: true)
        .orderBy('joinedAt')
        .snapshots()
        .map((snap) {
      final entries = snap.docs.map(QueueEntryModel.fromFirestore).toList();
      // Assign positions
      return entries
          .asMap()
          .entries
          .map((e) => QueueEntryModel(
                id: e.value.id,
                userId: e.value.userId,
                displayName: e.value.displayName,
                photoURL: e.value.photoURL,
                priority: e.value.priority,
                joinedAt: e.value.joinedAt,
                position: e.key + 1,
              ))
          .toList();
    });
  }

  @override
  Future<void> joinQueue(
    String roomId,
    String userId,
    String displayName,
    String? photoURL, {
    bool isAdmin = false,
  }) async {
    // Check if already in queue
    final existingQuery = await _queue(roomId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (existingQuery.docs.isNotEmpty) return;

    final priority = isAdmin
        ? AppConstants.adminQueuePriority
        : AppConstants.normalQueuePriority;

    await _firestore.runTransaction((tx) async {
      final queueRef = _queue(roomId).doc();
      tx.set(queueRef, {
        'userId': userId,
        'displayName': displayName,
        'photoURL': photoURL,
        'priority': priority,
        'joinedAt': FieldValue.serverTimestamp(),
        'position': 99,
      });

      tx.update(_roomDoc(roomId), {
        'queueCount': FieldValue.increment(1),
      });

      tx.update(_members(roomId).doc(userId), {
        'status': FirestoreConstants.statusInQueue,
      });
    });
  }

  @override
  Future<void> leaveQueue(String roomId, String userId) async {
    final queueQuery = await _queue(roomId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (queueQuery.docs.isEmpty) return;

    await _firestore.runTransaction((tx) async {
      tx.delete(queueQuery.docs.first.reference);
      tx.update(_roomDoc(roomId), {
        'queueCount': FieldValue.increment(-1),
      });
      tx.update(_members(roomId).doc(userId), {
        'status': FirestoreConstants.statusOnline,
      });
    });
  }

  @override
  Future<void> promoteToTopOfQueue(String roomId, String userId) async {
    final queueQuery = await _queue(roomId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (queueQuery.docs.isEmpty) return;

    await queueQuery.docs.first.reference.update({
      'priority': AppConstants.adminQueuePriority,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<RoomModel>> watchUserRooms(String userId) {
    return _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return [];
      final data = userDoc.data() as Map<String, dynamic>;
      final roomIds = List<String>.from(data['rooms'] as List? ?? []);
      if (roomIds.isEmpty) return [];

      final futures = roomIds.map((id) => _roomDoc(id).get()).toList();
      final docs = await Future.wait(futures);
      return docs
          .where((d) => d.exists)
          .map(RoomModel.fromFirestore)
          .toList();
    });
  }

  @override
  Future<List<RoomModel>> getUserRooms(String userId) async {
    final userDoc = await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(userId)
        .get();

    if (!userDoc.exists) return [];
    final data = userDoc.data() as Map<String, dynamic>;
    final roomIds = List<String>.from(data['rooms'] as List? ?? []);
    if (roomIds.isEmpty) return [];

    final futures = roomIds.map((id) => _roomDoc(id).get()).toList();
    final docs = await Future.wait(futures);
    return docs
        .where((d) => d.exists)
        .map(RoomModel.fromFirestore)
        .toList();
  }
}

final roomRemoteDataSourceProvider = Provider<RoomRemoteDataSource>((ref) {
  return RoomRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
});
