import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:tradingpro/models/support_models.dart';
import 'package:tradingpro/core/constants/app_constants.dart';

class SupportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _conversations =>
      _db.collection(AppConstants.supportConversationsCollection);

  CollectionReference _messages(String conversationId) =>
      _conversations.doc(conversationId).collection(AppConstants.messagesSubCollection);

  /// Get or create the user's conversation
  Future<SupportConversationModel> getOrCreateConversation(
    String uid,
    String userId7,
    String userFullName,
    String userEmail,
  ) async {
    try {
      // Look for any existing conversation for this user
      final existing = await _conversations
          .where('userId', isEqualTo: uid)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return SupportConversationModel.fromFirestore(existing.docs.first);
      }
    } catch (e) {
      print('SupportRepository: Query failed (possible missing index): $e');
      
      // Fallback: search without ordering if index is not ready
      final fallback = await _conversations
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();
          
      if (fallback.docs.isNotEmpty) {
        return SupportConversationModel.fromFirestore(fallback.docs.first);
      }
    }

    // Create new if none found or if ordering query failed and fallback also found nothing
    final ref = await _conversations.add({
      'userId': uid,
      'userId7': userId7,
      'userFullName': userFullName,
      'userEmail': userEmail,
      'isGuest': uid.startsWith('guest_'),
      'status': 'open',
      'lastMessage': null,
      'lastMessageAt': null,
      'lastUserMessageAt': null,
      'unreadByAdmin': 0,
      'unreadByUser': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final doc = await ref.get();
    return SupportConversationModel.fromFirestore(doc);
  }

  /// Stream a conversation
  Stream<SupportConversationModel?> streamConversation(String conversationId) {
    return _conversations.doc(conversationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SupportConversationModel.fromFirestore(doc);
    });
  }

  /// Stream messages for a conversation
  Stream<List<SupportMessageModel>> streamMessages(String conversationId) {
    return _messages(conversationId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map(SupportMessageModel.fromFirestore).toList());
  }

  /// Upload support attachment securely to Firebase Storage (cross-platform web/mobile)
  Future<String> uploadSupportAttachment({
    required String conversationId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final cleanExt = fileName.split('.').last.replaceAll('.', '').toLowerCase();
    final uniqueName = '${const Uuid().v4()}.$cleanExt';
    String contentType = 'image/jpeg';
    if (cleanExt == 'png') {
      contentType = 'image/png';
    } else if (cleanExt == 'webp') {
      contentType = 'image/webp';
    } else if (cleanExt == 'gif') {
      contentType = 'image/gif';
    } else if (cleanExt == 'pdf') {
      contentType = 'application/pdf';
    }

    final storageRef = _storage
        .ref()
        .child('support-attachments')
        .child(conversationId)
        .child(uniqueName);

    final uploadTask = await storageRef.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  /// Send a message (text or attachment)
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required MessageSenderRole senderRole,
    required String senderName,
    required String content,
    required String userId,
    String? attachmentUrl,
    String? messageType,
  }) async {
    final batch = _db.batch();

    // Add message
    final msgRef = _messages(conversationId).doc();
    final hasAttachment = attachmentUrl != null && attachmentUrl.isNotEmpty;
    final finalType = messageType ?? (hasAttachment ? 'image' : 'text');
    final msgData = <String, dynamic>{
      'conversationId': conversationId,
      'senderId': senderId,
      'senderRole': senderRole.name,
      'senderName': senderName,
      'content': content.trim(),
      'messageType': finalType,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (hasAttachment) {
      msgData['attachmentUrl'] = attachmentUrl;
    }
    batch.set(msgRef, msgData);

    // Update conversation metadata
    final previewText = hasAttachment
        ? (content.trim().isNotEmpty ? content.trim() : '📷 Image attachment')
        : (content.trim().isNotEmpty ? content.trim() : 'New message');

    final convRef = _conversations.doc(conversationId);
    final updates = <String, dynamic>{
      'lastMessage': previewText,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'open', // Reopen if closed when user sends
    };

    if (senderRole == MessageSenderRole.user) {
      updates['lastUserMessageAt'] = FieldValue.serverTimestamp();
      updates['unreadByAdmin'] = FieldValue.increment(1);
    } else if (senderRole == MessageSenderRole.admin) {
      updates['unreadByUser'] = FieldValue.increment(1);
    }

    batch.update(convRef, updates);
    await batch.commit();
  }

  /// Mark user messages as read by user
  Future<void> markReadByUser(String conversationId) async {
    await _conversations.doc(conversationId).update({'unreadByUser': 0});
  }

  /// Mark admin messages as read by admin
  Future<void> markReadByAdmin(String conversationId) async {
    await _conversations.doc(conversationId).update({'unreadByAdmin': 0});
  }

  // ─── Admin Streams ────────────────────────────────────────────────────────

  /// Stream all open conversations (admin)
  Stream<List<SupportConversationModel>> streamOpenConversations() {
    return _conversations
        .where('status', isEqualTo: 'open')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(SupportConversationModel.fromFirestore).toList());
  }

  /// Stream all conversations (admin)
  Stream<List<SupportConversationModel>> streamAllConversations() {
    return _conversations
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) =>
            snap.docs.map(SupportConversationModel.fromFirestore).toList());
  }

  /// Admin: Close conversation manually
  Future<void> closeConversation(String conversationId, {String? systemMessage}) async {
    final batch = _db.batch();
    final convRef = _conversations.doc(conversationId);

    batch.update(convRef, {
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (systemMessage != null && systemMessage.isNotEmpty) {
      final msgRef = _messages(conversationId).doc();
      batch.set(msgRef, {
        'conversationId': conversationId,
        'senderId': 'system',
        'senderRole': MessageSenderRole.system.name,
        'senderName': 'System',
        'content': systemMessage.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
