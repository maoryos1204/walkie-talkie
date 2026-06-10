import 'package:dartz/dartz.dart';
import 'package:shmuki_talk/core/errors/failures.dart';
import 'package:shmuki_talk/features/auth/domain/repositories/auth_repository.dart';

class SignOut {
  final AuthRepository _repository;

  const SignOut(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.signOut();
  }
}
