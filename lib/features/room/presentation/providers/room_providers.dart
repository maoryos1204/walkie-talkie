import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shmuki_talk/features/auth/presentation/providers/auth_providers.dart';
import 'package:shmuki_talk/features/room/data/repositories/room_repository_impl.dart';
import 'package:shmuki_talk/features/room/domain/entities/queue_entry.dart';
import 'package:shmuki_talk/features/room/domain/entities/room.dart';
import 'package:shmuki_talk/features/room/domain/entities/room_member.dart';

// User rooms stream
final userRoomsProvider = StreamProvider<List<Room>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(roomRepositoryProvider).watchUserRooms(user.uid);
});

// Single room stream
final roomProvider = StreamProvider.family<Room, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).watchRoom(roomId);
});

// Room members stream
final roomMembersProvider =
    StreamProvider.family<List<RoomMember>, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).watchRoomMembers(roomId);
});

// Queue stream
final roomQueueProvider =
    StreamProvider.family<List<QueueEntry>, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).watchQueue(roomId);
});

// Current user's member data in a room
final myMemberProvider =
    FutureProvider.family<RoomMember?, String>((ref, roomId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final result =
      await ref.read(roomRepositoryProvider).getMember(roomId, user.uid);
  return result.fold((_) => null, (member) => member);
});

// Is current user an admin/owner of the room
final isAdminProvider = Provider.family<bool, String>((ref, roomId) {
  final members = ref.watch(roomMembersProvider(roomId)).valueOrNull ?? [];
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final myMember = members.firstWhere(
    (m) => m.userId == user.uid,
    orElse: () => RoomMember(
      userId: '',
      displayName: '',
      joinedAt: DateTime.now(),
      lastSeen: DateTime.now(),
    ),
  );
  return myMember.isAdmin;
});

// Room creation
class CreateRoomNotifier extends StateNotifier<AsyncValue<Room?>> {
  final Ref _ref;

  CreateRoomNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<Room?> createRoom({
    required String name,
    required String emoji,
    String? imageURL,
  }) async {
    state = const AsyncValue.loading();
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('לא מחובר', StackTrace.current);
      return null;
    }

    final repo = _ref.read(roomRepositoryProvider);
    // Use the extended createRoom that accepts ownerName/photoURL
    final dataSource = _ref.read(
      // ignore: invalid_use_of_internal_member
      roomRemoteDataSourceProvider,
    );

    try {
      final room = await dataSource.createRoom(
        name: name,
        emoji: emoji,
        ownerId: user.uid,
        ownerName: user.displayName,
        ownerPhotoURL: user.photoURL,
        imageURL: imageURL,
      );
      state = AsyncValue.data(room);
      return room;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return null;
    }
  }
}

final createRoomProvider =
    StateNotifierProvider<CreateRoomNotifier, AsyncValue<Room?>>((ref) {
  return CreateRoomNotifier(ref);
});

// Join room
class JoinRoomNotifier extends StateNotifier<AsyncValue<Room?>> {
  final Ref _ref;

  JoinRoomNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<Room?> joinByCode(String inviteCode) async {
    state = const AsyncValue.loading();
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('לא מחובר', StackTrace.current);
      return null;
    }

    final dataSource = _ref.read(roomRemoteDataSourceProvider);

    try {
      final room = await dataSource.getRoomByInviteCode(inviteCode.toUpperCase());
      if (room == null) {
        state = AsyncValue.error('החדר לא נמצא', StackTrace.current);
        return null;
      }

      await dataSource.joinRoom(
        room.id,
        user.uid,
        user.displayName,
        user.photoURL,
      );

      state = AsyncValue.data(room);
      return room;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return null;
    }
  }
}

final joinRoomProvider =
    StateNotifierProvider<JoinRoomNotifier, AsyncValue<Room?>>((ref) {
  return JoinRoomNotifier(ref);
});
