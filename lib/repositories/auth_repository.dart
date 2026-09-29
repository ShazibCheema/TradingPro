import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  AuthRepository() {
    // Attempt automatic user index sync if current user is logged in
    if (_auth.currentUser != null) {
      syncUserIndex();
    }
  }


  /// Syncs all userId7 mappings to appSettings/userIndex for fast public invitation validation
  Future<void> syncUserIndex() async {
    try {
      final snap = await _db.collection('users').get();
      final Map<String, dynamic> map = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final userId7 = data['userId7']?.toString();
        final refCode = data['referralCode']?.toString();
        if (userId7 != null && userId7.isNotEmpty) {
          map[userId7] = doc.id;
        }
        if (refCode != null && refCode.isNotEmpty) {
          map[refCode] = doc.id;
        }
      }
      if (map.isNotEmpty) {
        await _db
            .collection('appSettings')
            .doc('userIndex')
            .set(map, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  /// Validates an invitation code (7-digit userId7 or referral code) against Firestore.
  /// Returns the matching uid if valid, or throws a descriptive Exception.
  /// [currentEmail] is used to prevent self-referral.
  Future<String?> validateInvitationCode({
    required String code,
    String? currentEmail,
  }) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null; // optional field – no code entered is fine

    // Must be exactly 7 digits
    if (!RegExp(r'^\d{7}$').hasMatch(trimmed)) {
      throw Exception('Invitation code must be a 7-digit numeric ID.');
    }

    final intCode = int.tryParse(trimmed);

    // If logged in as Admin, sync user index on the fly
    if (await isAdmin()) {
      syncUserIndex();
    }

    // 1. Direct Firestore Lookup
    try {
      var snap = await _db
          .collection('users')
          .where('userId7', isEqualTo: trimmed)
          .limit(1)
          .get();

      if (snap.docs.isEmpty && intCode != null) {
        snap = await _db
            .collection('users')
            .where('userId7', isEqualTo: intCode)
            .limit(1)
            .get();
      }

      if (snap.docs.isEmpty) {
        snap = await _db
            .collection('users')
            .where('referralCode', isEqualTo: trimmed)
            .limit(1)
            .get();
      }

      if (snap.docs.isNotEmpty) {
        final inviterDoc = snap.docs.first;
        if (currentEmail != null &&
            currentEmail.trim().isNotEmpty &&
            (inviterDoc.data()['email'] as String?)?.toLowerCase() ==
                currentEmail.trim().toLowerCase()) {
          throw Exception('You cannot use your own ID as an invitation code.');
        }
        return inviterDoc.id;
      }
    } on FirebaseException catch (fe) {
      if (fe.code != 'permission-denied') rethrow;
    } catch (e) {
      if (e is Exception && e.toString().contains('You cannot use your own ID')) {
        rethrow;
      }
    }

    // 2. Check public userIndex document under /appSettings (allowed by rules)
    try {
      final indexDoc = await _db.collection('appSettings').doc('userIndex').get();
      if (indexDoc.exists && indexDoc.data() != null) {
        final map = indexDoc.data()!;
        if (map.containsKey(trimmed)) {
          final inviterUid = map[trimmed] as String?;
          if (inviterUid != null && inviterUid.isNotEmpty) {
            if (currentEmail != null && currentEmail.trim().isNotEmpty) {
              try {
                final userDoc = await _db.collection('users').doc(inviterUid).get();
                if (userDoc.exists &&
                    (userDoc.data()?['email'] as String?)?.toLowerCase() ==
                        currentEmail.trim().toLowerCase()) {
                  throw Exception('You cannot use your own ID as an invitation code.');
                }
              } catch (e) {
                if (e is Exception && e.toString().contains('You cannot use your own ID')) {
                  rethrow;
                }
              }
            }
            return inviterUid;
          }
        }
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('You cannot use your own ID')) {
        rethrow;
      }
    }

    // 3. Fallback to Cloud Function validateInvitationCode
    try {
      final callable = _functions.httpsCallable('validateInvitationCode');
      final result = await callable.call({
        'code': trimmed,
        if (currentEmail != null && currentEmail.trim().isNotEmpty)
          'email': currentEmail.trim(),
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['valid'] == true) {
        return data['inviterUid'] as String?;
      }
    } catch (_) {}

    // If code is not found anywhere in database -> strictly fail!
    throw Exception('Invalid invitation code. No user found with this ID.');
  }







  /// Register user — creates Firebase Auth account then calls Cloud Function
  /// to create Firestore document and generate userId7.
  /// [invitedByUserId] is the Firestore uid of the referrer (optional).
  Future<User> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? invitedByUserId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;

      // Call Cloud Function to create Firestore profile + userId7
      try {
        await _functions.httpsCallable('createUserProfile').call({
          'fullName': fullName.trim(),
          'email': email.trim(),
          if (invitedByUserId != null) 'invitedByUserId': invitedByUserId,
        });
      } catch (e) {
        debugPrint('⚠️ [createUserProfile function notice]: $e');
      }

      // Guarantee invitedByUserId is saved directly into the user document
      if (invitedByUserId != null && invitedByUserId.trim().isNotEmpty) {
        try {
          await _db.collection('users').doc(user.uid).set({
            'invitedByUserId': invitedByUserId.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('⚠️ [Set invitedByUserId notice]: $e');
        }
      }

      return user;

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

  /// Update temporary password (enforces new != temp and clears mustChangePassword)
  Future<void> updateTemporaryPassword({
    required String temporaryPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      if (temporaryPassword.trim() == newPassword.trim()) {
        throw Exception(
            'New password cannot be the same as your temporary password. Please choose a new password.');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: temporaryPassword.trim(),
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword.trim());

      // Clear flags in Firestore
      await _db.collection('users').doc(user.uid).update({
        'mustChangePassword': false,
        'isTemporaryPassword': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
