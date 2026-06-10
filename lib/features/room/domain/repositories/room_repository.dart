import 'package:dartz/dartz.dart';
import 'package:shmuki_talk/core/errors/failures.dart';
import 'package:shmuki_talk/features/room/domain/entities/queue_entry.dart';
import 'package:shmuki_talk/features/room/domain/entities/room.dart';
import 'package:shmuki_talk/features/room/domain/entities/room_member.dart';

abstract class RoomRepository {
  // Room CRUD
  Future<Either<Failure, Room>> createRoom({
    required String name,
    required String emoji,
    required String ownerId,
    String? imageURL,
  });

  Future<Either<Failure, Room>> getRoomById(String roomId);
  Future<Either<Failure, Room?>> getRoomByInviteCode(String inviteCode);
  Stream<Room> watchRoom(String roomId);
  Future<Either<Failure, void>> updateRoom(Room room);
  Future<Either<Failure, void>> deleteRoom(String roomId);

  // Membership
  Future<Either<Failure, void>> joinRoom(String roomId, String userId);
  Future<Either<Failure, void>> leaveRoom(String roomId, String userId);
  Stream<List<RoomMember>> watchRoomMembers(String roomId);
  Future<Either<Failure, RoomMember?>> getMember(String roomId, String userId);

  // Member management
  Future<Either<Failure, void>> updateMemberRole(
    String roomId,
    String userId,
    MemberRole role,
  );
  Future<Either<Failure, void>> muteMember(String roomId, String userId, bool mute);
  Future<Either<Failure, void>> removeMember(String roomId, String userId);
  Future<Either<Failure, void>> updateMemberStatus(
    String roomId,
    String userId,
    MemberStatus status,
  );
  Future<Either<Failure, void>> setListenerOnly(
    String roomId,
    String userId,
    bool isListenerOnly,
  );

  // Room controls
  Future<Either<Failure, void>> lockRoom(String roomId, bool locked);
  Future<Either<Failure, void>> transferOwnership(
    String roomId,
    String newOwnerId,
  );

  // Speaker management
  Future<Either<Failure, bool>> tryClaimSpeaker(
    String roomId,
    String userId,
    String displayName,
    String? photoURL,
  );
  Future<Either<Failure, void>> releaseSpeaker(String roomId, String userId);

  // Queue
  Stream<List<QueueEntry>> watchQueue(String roomId);
  Future<Either<Failure, void>> joinQueue(
    String roomId,
    String userId,
    String displayName,
    String? photoURL, {
    bool isAdmin = false,
  });
  Future<Either<Failure, void>> leaveQueue(String roomId, String userId);
  Future<Either<Failure, void>> promoteToTopOfQueue(
    String roomId,
    String userId,
  );

  // User rooms
  Stream<List<Room>> watchUserRooms(String userId);
  Future<Either<Failure, List<Room>>> getUserRooms(String userId);
}
