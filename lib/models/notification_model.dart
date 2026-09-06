import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  depositSubmitted,
  depositApproved,
  depositRejected,
  withdrawalApproved,
  withdrawalRejected,
  profitAwarded,
  tradeOpened,
  tradeCancelled,
  tradeProfit,
  tradeLoss,
  supportMessage,
  adminMessage,
  broadcast,
  system,
}

class NotificationModel {
  final String notificationId;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final String? referenceId;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.referenceId,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      notificationId: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'system'),
        orElse: () => NotificationType.system,
      ),
      isRead: data['isRead'] as bool? ?? false,
      referenceId: data['referenceId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': isRead,
      'referenceId': referenceId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      referenceId: referenceId,
      createdAt: createdAt,
    );
  }
}
