import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationModel {
  final String notificationId;
  final String title;
  final String body;
  final String? targetUserId;
  final String? targetUserId7;
  final bool isBroadcast;
  final String createdBy;
  final DateTime createdAt;

  const AdminNotificationModel({
    required this.notificationId,
    required this.title,
    required this.body,
    this.targetUserId,
    this.targetUserId7,
    required this.isBroadcast,
    required this.createdBy,
    required this.createdAt,
  });

  factory AdminNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminNotificationModel(
      notificationId: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      targetUserId: data['targetUserId'] as String?,
      targetUserId7: data['targetUserId7'] as String?,
      isBroadcast: data['isBroadcast'] as bool? ?? false,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'targetUserId': targetUserId,
      'targetUserId7': targetUserId7,
      'isBroadcast': isBroadcast,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
