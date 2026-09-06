import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  /// Register user — creates Firebase Auth account then calls Cloud Function
  /// to create Firestore document and generate userId7
  Future<User> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Call Cloud Function to create Firestore profile + userId7
      await _functions.httpsCallable('createUserProfile').call({
        'fullName': fullName.trim(),
        'email': email.trim(),
      });

      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Change password (requires re-authentication)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get user custom claims (for admin role check)
  Future<Map<String, dynamic>?> getUserClaims() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final idTokenResult = await user.getIdTokenResult(true);
      return idTokenResult.claims;
    } catch (_) {
      return null;
    }
  }

  /// Check if current user has admin role
  Future<bool> isAdmin() async {
    final claims = await getUserClaims();
    if (claims == null) return false;
    final role = claims['role'] as String?;
    return role == 'admin' || role == 'superAdmin';
  }

  /// Re-authenticate user (for sensitive operations)
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Delete user account (App Store Guideline 5.1.1(v) & Play Store compliance)
  Future<void> deleteAccount({required String password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await reauthenticate(password);
      await _functions.httpsCallable('deleteUserAccount').call();

      try {
        await user.delete();
      } catch (_) {}

      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception('An account with this email already exists.');
      case 'invalid-email':
        return Exception('The email address is invalid.');
      case 'weak-password':
        return Exception('Password must be at least 8 characters.');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return Exception('Incorrect email or password.');
      case 'user-disabled':
        return Exception('This account has been suspended.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      default:
        return Exception('Authentication failed. Please try again.');
    }
  }
}
