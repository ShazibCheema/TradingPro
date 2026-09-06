import 'package:cloud_firestore/cloud_firestore.dart';

enum ConversationStatus { open, closed }
enum MessageSenderRole { user, admin, system }

class SupportConversationModel {
  final String conversationId;
  final String userId;
  final String userId7;
  final String userFullName;
  final String userEmail;
  final ConversationStatus status;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? lastUserMessageAt;
  final int unreadByAdmin;
  final int unreadByUser;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportConversationModel({
    required this.conversationId,
    required this.userId,
    required this.userId7,
    required this.userFullName,
    required this.userEmail,
    required this.status,
    this.lastMessage,
    this.lastMessageAt,
    this.lastUserMessageAt,
    required this.unreadByAdmin,
    required this.unreadByUser,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOpen => status == ConversationStatus.open;

  factory SupportConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportConversationModel(
      conversationId: doc.id,
      userId: data['userId'] as String? ?? '',
      userId7: data['userId7'] as String? ?? '',
      userFullName: data['userFullName'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      status: ConversationStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'open'),
        orElse: () => ConversationStatus.open,
      ),
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastUserMessageAt: (data['lastUserMessageAt'] as Timestamp?)?.toDate(),
      unreadByAdmin: data['unreadByAdmin'] as int? ?? 0,
      unreadByUser: data['unreadByUser'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class SupportMessageModel {
  final String messageId;
  final String conversationId;
  final String senderId;
  final MessageSenderRole senderRole;
  final String senderName;
  final String content;
  final DateTime createdAt;

  const SupportMessageModel({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  bool get isUser => senderRole == MessageSenderRole.user;
  bool get isAdmin => senderRole == MessageSenderRole.admin;
  bool get isSystem => senderRole == MessageSenderRole.system;

  factory SupportMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportMessageModel(
      messageId: doc.id,
      conversationId: data['conversationId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderRole: MessageSenderRole.values.firstWhere(
        (e) => e.name == (data['senderRole'] as String? ?? 'user'),
        orElse: () => MessageSenderRole.user,
      ),
      senderName: data['senderName'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderRole': senderRole.name,
      'senderName': senderName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
