import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shmuki_talk/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shmuki_talk/features/auth/domain/entities/app_user.dart';
import 'package:shmuki_talk/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:shmuki_talk/features/auth/domain/usecases/sign_out.dart';

// Auth state stream
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Current user
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

// Sign-in state
enum SignInStatus { idle, loading, success, error }

class SignInNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final SignInWithGoogle _signInWithGoogle;

  SignInNotifier(this._signInWithGoogle) : super(const AsyncValue.data(null));

  Future<void> signIn() async {
    state = const AsyncValue.loading();
    final result = await _signInWithGoogle();
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }
}

final signInNotifierProvider = StateNotifierProvider<SignInNotifier, AsyncValue<AppUser?>>((ref) {
  final useCase = SignInWithGoogle(ref.read(authRepositoryProvider));
  return SignInNotifier(useCase);
});

class SignOutNotifier extends StateNotifier<AsyncValue<void>> {
  final SignOut _signOut;

  SignOutNotifier(this._signOut) : super(const AsyncValue.data(null));

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final result = await _signOut();
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }
}

final signOutNotifierProvider = StateNotifierProvider<SignOutNotifier, AsyncValue<void>>((ref) {
  final useCase = SignOut(ref.read(authRepositoryProvider));
  return SignOutNotifier(useCase);
});
