import 'package:dartz/dartz.dart';
import 'package:shmuki_talk/core/errors/failures.dart';
import 'package:shmuki_talk/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  Future<AppUser?> get currentUser;
  Future<Either<Failure, AppUser>> signInWithGoogle();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> updateUserProfile(AppUser user);
  Future<Either<Failure, void>> updateFcmToken(String userId, String token);
  Future<Either<Failure, void>> removeFcmToken(String userId, String token);
}
