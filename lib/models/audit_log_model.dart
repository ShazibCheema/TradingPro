import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String auditId;
  final String adminUid;
  final String? adminEmail;
  final String? adminRole;
  final String action;
  final String targetType;
  final String targetId;
  final String? userId;
  final String? description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const AuditLogModel({
    required this.auditId,
    required this.adminUid,
    this.adminEmail,
    this.adminRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.userId,
    this.description,
    required this.metadata,
    required this.createdAt,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AuditLogModel(
      auditId: doc.id,
      adminUid: data['adminUid'] as String? ?? '',
      adminEmail: data['adminEmail'] as String?,
      adminRole: data['adminRole'] as String? ?? 'admin',
      action: data['action'] as String? ?? '',
      targetType: data['targetType'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      userId: data['userId'] as String?,
      description: data['description'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adminUid': adminUid,
      'adminEmail': adminEmail,
      'adminRole': adminRole,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'userId': userId,
      'description': description,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
