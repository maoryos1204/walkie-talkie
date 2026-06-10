import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shmuki_talk/features/room/data/datasources/room_remote_datasource.dart';
import 'package:shmuki_talk/features/room/data/models/room_model.dart';
import 'package:shmuki_talk/features/room/data/repositories/room_repository_impl.dart';
import 'package:shmuki_talk/features/room/domain/entities/room.dart';

class MockRoomRemoteDataSource extends Mock implements RoomRemoteDataSource {}

void main() {
  late RoomRepositoryImpl repository;
  late MockRoomRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockRoomRemoteDataSource();
    repository = RoomRepositoryImpl(mockDataSource);
  });

  final tRoom = RoomModel(
    id: 'room-1',
    name: 'משפחה',
    emoji: '👨‍👩‍👧‍👦',
    inviteCode: 'FAMILY7',
    ownerId: 'user-1',
    participantCount: 1,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  group('getRoomById', () {
    test('should return room on success', () async {
      when(() => mockDataSource.getRoomById('room-1'))
          .thenAnswer((_) async => tRoom);

      final result = await repository.getRoomById('room-1');

      expect(result.isRight(), true);
      result.fold((_) => fail('Should not fail'), (room) {
        expect(room.id, 'room-1');
        expect(room.name, 'משפחה');
        expect(room.inviteCode, 'FAMILY7');
      });
    });

    test('should return RoomNotFoundFailure when room does not exist', () async {
      when(() => mockDataSource.getRoomById('nonexistent'))
          .thenThrow(Exception('not found'));

      final result = await repository.getRoomById('nonexistent');

      expect(result.isLeft(), true);
    });
  });

  group('getRoomByInviteCode', () {
    test('should return room when invite code is valid', () async {
      when(() => mockDataSource.getRoomByInviteCode('FAMILY7'))
          .thenAnswer((_) async => tRoom);

      final result = await repository.getRoomByInviteCode('FAMILY7');

      expect(result.isRight(), true);
      result.fold((_) => fail('Should not fail'), (room) {
        expect(room?.inviteCode, 'FAMILY7');
      });
    });

    test('should return null when code is not found', () async {
      when(() => mockDataSource.getRoomByInviteCode('BADCODE'))
          .thenAnswer((_) async => null);

      final result = await repository.getRoomByInviteCode('BADCODE');

      expect(result.isRight(), true);
      result.fold((_) => fail('Should not fail'), (room) {
        expect(room, null);
      });
    });
  });

  group('createRoom', () {
    test('should create a room successfully', () async {
      when(() => mockDataSource.createRoom(
            name: 'Family',
            emoji: '👨‍👩‍👧‍👦',
            ownerId: 'user-1',
            ownerName: 'Test User',
            ownerPhotoURL: null,
            imageURL: null,
          )).thenAnswer((_) async => tRoom);

      final result = await repository.createRoom(
        name: 'Family',
        emoji: '👨‍👩‍👧‍👦',
        ownerId: 'user-1',
      );

      expect(result.isRight(), true);
    });
  });
}
