import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shmuki_talk/core/errors/failures.dart';
import 'package:shmuki_talk/core/utils/logger.dart';
import 'package:shmuki_talk/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:shmuki_talk/features/auth/data/models/user_model.dart';
import 'package:shmuki_talk/features/auth/domain/entities/app_user.dart';
import 'package:shmuki_talk/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  const AuthRepositoryImpl(this._dataSource);

  @override
  Stream<AppUser?> get authStateChanges {
    return _dataSource.firebaseAuthStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _dataSource.getUserProfile(firebaseUser.uid);
    });
  }

  @override
  Future<AppUser?> get currentUser async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;
    return _dataSource.getUserProfile(firebaseUser.uid);
  }

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      return Right(user);
    } catch (e) {
      AppLogger.e('AuthRepository', 'Sign in failed', e);
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } catch (e) {
      AppLogger.e('AuthRepository', 'Sign out failed', e);
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserProfile(AppUser user) async {
    try {
      final model = UserModel.fromEntity(user);
      await _dataSource.createOrUpdateUserProfile(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFcmToken(String userId, String token) async {
    try {
      await _dataSource.addFcmToken(userId, token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFcmToken(String userId, String token) async {
    try {
      await _dataSource.removeFcmToken(userId, token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
});
