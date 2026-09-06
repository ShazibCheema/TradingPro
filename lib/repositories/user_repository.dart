import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tradingpro/models/user_model.dart';
import 'package:tradingpro/core/constants/app_constants.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _users =>
      _db.collection(AppConstants.usersCollection);

  DocumentReference _userDoc(String uid) => _users.doc(uid);

  /// Stream the current user's document
  Stream<UserModel?> streamUser(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromFirestore(snap);
    });
  }

  /// Get user once
  Future<UserModel?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Get user by userId7 (admin search)
  Future<UserModel?> getUserByUserId7(String userId7) async {
    final query = await _users
        .where('userId7', isEqualTo: userId7)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return UserModel.fromFirestore(query.docs.first);
  }

  /// Search users (admin)
  Future<List<UserModel>> searchUsers(String query) async {
    final results = <UserModel>[];
    final snapByName = await _users
        .orderBy('fullName')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();
    results.addAll(snapByName.docs.map(UserModel.fromFirestore));

    // Search by email
    final snapByEmail = await _users
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();
    for (final doc in snapByEmail.docs) {
      if (!results.any((u) => u.uid == doc.id)) {
        results.add(UserModel.fromFirestore(doc));
      }
    }
    return results;
  }

  /// Stream all users (admin)
  Stream<List<UserModel>> streamAllUsers({int limit = 50}) {
    return _users
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }

  /// Update profile (name, photo only — no financial fields)
  Future<void> updateProfile(String uid, {String? fullName, String? photoUrl}) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (fullName != null) updates['fullName'] = fullName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    await _userDoc(uid).update(updates);
  }

  /// Update account status (admin only — through Cloud Function in prod)
  Future<void> updateAccountStatus(String uid, AccountStatus status) async {
    await _userDoc(uid).update({
      'accountStatus': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Register FCM token
  Future<void> registerFcmToken(String uid, String token, String platform) async {
    await _userDoc(uid)
        .collection(AppConstants.devicesSubCollection)
        .doc(token)
        .set({
      'token': token,
      'platform': platform,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get total user count (admin dashboard)
  Future<int> getTotalUserCount() async {
    final agg = await _users.count().get();
    return agg.count ?? 0;
  }

  /// Get active user count (admin dashboard)
  Future<int> getActiveUserCount() async {
    final agg = await _users
        .where('accountStatus', isEqualTo: 'active')
        .count()
        .get();
    return agg.count ?? 0;
  }
}
