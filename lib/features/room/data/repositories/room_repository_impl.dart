import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shmuki_talk/core/errors/failures.dart';
import 'package:shmuki_talk/core/utils/logger.dart';
import 'package:shmuki_talk/features/room/data/datasources/room_remote_datasource.dart';
import 'package:shmuki_talk/features/room/data/models/room_model.dart';
import 'package:shmuki_talk/features/room/domain/entities/queue_entry.dart';
import 'package:shmuki_talk/features/room/domain/entities/room.dart';
import 'package:shmuki_talk/features/room/domain/entities/room_member.dart';
import 'package:shmuki_talk/features/room/domain/repositories/room_repository.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource _dataSource;

  const RoomRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Room>> createRoom({
    required String name,
    required String emoji,
    required String ownerId,
    String? imageURL,
    String ownerName = '',
    String? ownerPhotoURL,
  }) async {
    try {
      final room = await _dataSource.createRoom(
        name: name,
        emoji: emoji,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerPhotoURL: ownerPhotoURL,
        imageURL: imageURL,
      );
      return Right(room);
    } catch (e) {
      AppLogger.e('RoomRepo', 'Create room failed', e);
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Room>> getRoomById(String roomId) async {
    try {
      final room = await _dataSource.getRoomById(roomId);
      return Right(room);
    } catch (e) {
      return Left(RoomNotFoundFailure());
    }
  }

  @override
  Future<Either<Failure, Room?>> getRoomByInviteCode(String inviteCode) async {
    try {
      final room = await _dataSource.getRoomByInviteCode(inviteCode);
      return Right(room);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Stream<Room> watchRoom(String roomId) {
    return _dataSource.watchRoom(roomId);
  }

  @override
  Future<Either<Failure, void>> updateRoom(Room room) async {
    try {
      final model = RoomModel.fromEntity(room);
      await _dataSource.updateRoom(model);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRoom(String roomId) async {
    try {
      await _dataSource.deleteRoom(roomId);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> joinRoom(String roomId, String userId) async {
    try {
      await _dataSource.joinRoom(roomId, userId, '', null);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> leaveRoom(String roomId, String userId) async {
    try {
      await _dataSource.leaveRoom(roomId, userId);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Stream<List<RoomMember>> watchRoomMembers(String roomId) {
    return _dataSource.watchRoomMembers(roomId).map((models) => models);
  }

  @override
  Future<Either<Failure, RoomMember?>> getMember(
    String roomId,
    String userId,
  ) async {
    try {
      final member = await _dataSource.getMember(roomId, userId);
      return Right(member);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMemberRole(
    String roomId,
    String userId,
    MemberRole role,
  ) async {
    try {
      await _dataSource.updateMemberRole(roomId, userId, role);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> muteMember(
    String roomId,
    String userId,
    bool mute,
  ) async {
    try {
      await _dataSource.muteMember(roomId, userId, mute);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeMember(
    String roomId,
    String userId,
  ) async {
    try {
      await _dataSource.removeMember(roomId, userId);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMemberStatus(
    String roomId,
    String userId,
    MemberStatus status,
  ) async {
    try {
      final statusString = switch (status) {
        MemberStatus.online => 'online',
        MemberStatus.offline => 'offline',
        MemberStatus.busy => 'busy',
        MemberStatus.speaking => 'speaking',
        MemberStatus.inQueue => 'in_queue',
      };
      await _dataSource.updateMemberStatus(roomId, userId, statusString);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setListenerOnly(
    String roomId,
    String userId,
    bool isListenerOnly,
  ) async {
    try {
      await _dataSource.setListenerOnly(roomId, userId, isListenerOnly);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> lockRoom(String roomId, bool locked) async {
    try {
      await _dataSource.lockRoom(roomId, locked);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> transferOwnership(
    String roomId,
    String newOwnerId,
  ) async {
    try {
      await _dataSource.transferOwnership(roomId, newOwnerId);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> tryClaimSpeaker(
    String roomId,
    String userId,
    String displayName,
    String? photoURL,
  ) async {
    try {
      final claimed = await _dataSource.tryClaimSpeaker(
        roomId,
        userId,
        displayName,
        photoURL,
      );
      return Right(claimed);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> releaseSpeaker(
    String roomId,
    String userId,
  ) async {
    try {
      await _dataSource.releaseSpeaker(roomId, userId);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Stream<List<QueueEntry>> watchQueue(String roomId) {
    return _dataSource.watchQueue(roomId).map((models) => models);
  }

  @override
  Future<Either<Failure, void>> joinQueue(
    String roomId,
    String userId,
    String displayName,
    String? photoURL, {
    bool isAdmin = false,
  }) async {
    try {
      await _dataSource.joinQueue(
        roomId,
        userId,
        displayName,
        photoURL,
        isAdmin: isAdmin,
      );
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> leaveQueue(
    String roomId,
    String userId,
  ) async {
    try {
      await _dataSource.leaveQueue(roomId, userId);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> promoteToTopOfQueue(
    String roomId,
    String userId,
  ) async {
    try {
      await _dataSource.promoteToTopOfQueue(roomId, userId);
      return const Right(null);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }

  @override
  Stream<List<Room>> watchUserRooms(String userId) {
    return _dataSource.watchUserRooms(userId).map((models) => models);
  }

  @override
  Future<Either<Failure, List<Room>>> getUserRooms(String userId) async {
    try {
      final rooms = await _dataSource.getUserRooms(userId);
      return Right(rooms);
    } catch (e) {
      return Left(RoomFailure(e.toString()));
    }
  }
}

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepositoryImpl(ref.read(roomRemoteDataSourceProvider));
});
