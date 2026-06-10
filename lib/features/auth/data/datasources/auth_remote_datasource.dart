import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shmuki_talk/core/constants/firestore_constants.dart';
import 'package:shmuki_talk/core/errors/app_exception.dart';
import 'package:shmuki_talk/core/utils/logger.dart';
import 'package:shmuki_talk/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<User?> get firebaseAuthStateChanges;
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<UserModel?> getUserProfile(String uid);
  Future<void> createOrUpdateUserProfile(UserModel user);
  Future<void> updateLastSeen(String uid);
  Future<void> addFcmToken(String uid, String token);
  Future<void> removeFcmToken(String uid, String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  @override
  Stream<User?> get firebaseAuthStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException(message: 'כניסה בוטלה', code: 'sign_in_cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw const AuthException(message: 'כניסה נכשלה', code: 'sign_in_failed');
      }

      // Check if user profile exists
      final existingProfile = await getUserProfile(firebaseUser.uid);

      if (existingProfile != null) {
        // Update last seen
        await updateLastSeen(firebaseUser.uid);
        return UserModel(
          uid: existingProfile.uid,
          displayName: existingProfile.displayName,
          email: existingProfile.email,
          photoURL: existingProfile.photoURL,
          createdAt: existingProfile.createdAt,
          lastSeen: DateTime.now(),
          rooms: existingProfile.rooms,
          fcmTokens: existingProfile.fcmTokens,
          status: 'online',
          currentRoomId: existingProfile.currentRoomId,
          isListenerOnly: existingProfile.isListenerOnly,
        );
      }

      // Create new user profile
      final newUser = UserModel(
        uid: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? googleUser.displayName ?? '',
        email: firebaseUser.email ?? googleUser.email,
        photoURL: firebaseUser.photoURL ?? googleUser.photoURL,
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
      );

      await createOrUpdateUserProfile(newUser);
      AppLogger.auth('New user profile created: ${newUser.uid}');
      return newUser;
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.e('Auth', 'Sign in with Google failed', e);
      throw AuthException(message: 'כניסה נכשלה: ${e.toString()}', original: e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final uid = _firebaseAuth.currentUser?.uid;
      if (uid != null) {
        await _firestore
            .collection(FirestoreConstants.usersCollection)
            .doc(uid)
            .update({'status': 'offline', 'currentRoomId': null});
      }
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      AppLogger.e('Auth', 'Sign out failed', e);
    }
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<void> createOrUpdateUserProfile(UserModel user) async {
    final docRef = _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(user.uid);

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.update({
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastSeen': FieldValue.serverTimestamp(),
        'status': 'online',
      });
    } else {
      await docRef.set(user.toFirestoreCreate());
    }
  }

  @override
  Future<void> updateLastSeen(String uid) async {
    await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(uid)
        .update({
      'lastSeen': FieldValue.serverTimestamp(),
      'status': 'online',
    });
  }

  @override
  Future<void> addFcmToken(String uid, String token) async {
    await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(uid)
        .update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  @override
  Future<void> removeFcmToken(String uid, String token) async {
    await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(uid)
        .update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }
}

// Providers
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    googleSignIn: GoogleSignIn(
      scopes: ['email', 'profile'],
    ),
  );
});
