import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tradingpro/models/notification_model.dart';
import 'package:tradingpro/models/settings_models.dart';
import 'package:tradingpro/core/constants/app_constants.dart';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _notifCollection(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.notificationsSubCollection);

  CollectionReference _prefCollection(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.notificationPrefsSubCollection);

  /// Stream user notifications (newest first)
  Stream<List<NotificationModel>> streamNotifications(String uid) {
    return _notifCollection(uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromFirestore).toList());
  }

  /// Get unread count
  Stream<int> streamUnreadCount(String uid) {
    return _notifCollection(uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Mark single notification as read
  Future<void> markAsRead(String uid, String notificationId) async {
    await _notifCollection(uid).doc(notificationId).update({'isRead': true});
  }

  /// Mark all as read
  Future<void> markAllAsRead(String uid) async {
    final unread = await _notifCollection(uid)
        .where('isRead', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    try {
      await batch.commit();
    } catch (e) {
      print('Error in markAllAsRead batch commit: $e');
      // If batch fails (e.g. too many docs), try individual updates as fallback
      for (final doc in unread.docs) {
        await doc.reference.update({'isRead': true});
      }
    }
  }

  /// Stream notification preferences
  Stream<NotificationPrefsModel> streamPrefs(String uid) {
    return _prefCollection(uid).doc('prefs').snapshots().map((doc) {
      if (!doc.exists) return NotificationPrefsModel.defaults();
      return NotificationPrefsModel.fromFirestore(doc);
    });
  }

  /// Update notification preferences
  Future<void> updatePrefs(String uid, NotificationPrefsModel prefs) async {
    await _prefCollection(uid).doc('prefs').set(
      prefs.toFirestore(),
      SetOptions(merge: true),
    );
  }
}
