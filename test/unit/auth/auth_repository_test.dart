import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shmuki_talk/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:shmuki_talk/features/auth/data/models/user_model.dart';
import 'package:shmuki_talk/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shmuki_talk/features/auth/domain/entities/app_user.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockDataSource);
  });

  group('signInWithGoogle', () {
    final tUser = UserModel(
      uid: 'test-uid',
      displayName: 'Test User',
      email: 'test@example.com',
      photoURL: 'https://example.com/photo.jpg',
      createdAt: DateTime(2024),
      lastSeen: DateTime(2024),
    );

    test('should return AppUser when sign in succeeds', () async {
      when(() => mockDataSource.signInWithGoogle())
          .thenAnswer((_) async => tUser);

      final result = await repository.signInWithGoogle();

      expect(result, isA<Right<dynamic, AppUser>>());
      result.fold((_) => fail('Should not be failure'), (user) {
        expect(user.uid, 'test-uid');
        expect(user.displayName, 'Test User');
      });
    });

    test('should return AuthFailure when sign in fails', () async {
      when(() => mockDataSource.signInWithGoogle())
          .thenThrow(Exception('Sign in failed'));

      final result = await repository.signInWithGoogle();

      expect(result.isLeft(), true);
    });
  });

  group('signOut', () {
    test('should return unit on success', () async {
      when(() => mockDataSource.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result, const Right<dynamic, void>(null));
    });
  });
}
