import 'package:dartz/dartz.dart';
import 'package:shmuki_talk/core/errors/failures.dart';
import 'package:shmuki_talk/features/auth/domain/entities/app_user.dart';
import 'package:shmuki_talk/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository _repository;

  const SignInWithGoogle(this._repository);

  Future<Either<Failure, AppUser>> call() {
    return _repository.signInWithGoogle();
  }
}
