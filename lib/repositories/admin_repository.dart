import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:tradingpro/core/constants/app_constants.dart';
import 'package:tradingpro/models/audit_log_model.dart';
import 'package:tradingpro/models/admin_notification_model.dart';
import 'package:tradingpro/models/deposit_model.dart';
import 'package:tradingpro/models/withdrawal_model.dart';
import 'package:tradingpro/models/trade_model.dart';
import 'package:tradingpro/models/support_models.dart';

class AdminDashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int pendingDeposits;
  final int pendingWithdrawals;
  final int openTrades;
  final int openSupportChats;
  final int newMessages;
  final double totalPlatformBalance;
  final double totalProfitAwarded;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.pendingDeposits,
    required this.pendingWithdrawals,
    required this.openTrades,
    required this.openSupportChats,
    required this.newMessages,
    required this.totalPlatformBalance,
    required this.totalProfitAwarded,
  });

  factory AdminDashboardStats.empty() {
    return const AdminDashboardStats(
      totalUsers: 0,
      activeUsers: 0,
      pendingDeposits: 0,
      pendingWithdrawals: 0,
      openTrades: 0,
      openSupportChats: 0,
      newMessages: 0,
      totalPlatformBalance: 0.0,
      totalProfitAwarded: 0.0,
    );
  }
}

class AdminRecentActivity {
  final List<DepositModel> recentDeposits;
  final List<WithdrawalModel> recentWithdrawals;
  final List<TradeModel> recentTrades;
  final List<SupportConversationModel> recentSupport;

  const AdminRecentActivity({
    required this.recentDeposits,
    required this.recentWithdrawals,
    required this.recentTrades,
    required this.recentSupport,
  });

  factory AdminRecentActivity.empty() {
    return const AdminRecentActivity(
      recentDeposits: [],
      recentWithdrawals: [],
      recentTrades: [],
      recentSupport: [],
    );
  }
}

class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _auditLogs =>
      _db.collection(AppConstants.auditLogsCollection);

  CollectionReference get _adminNotifications =>
      _db.collection(AppConstants.adminNotificationsCollection);

  /// Fetch dashboard metrics
  Future<AdminDashboardStats> getDashboardStats() async {
    try {
      final usersSnap = await _db.collection(AppConstants.usersCollection).get();
      final totalUsers = usersSnap.docs.length;
      int activeUsers = 0;
      double totalBalance = 0.0;
      double totalProfit = 0.0;

      for (final doc in usersSnap.docs) {
        final data = doc.data();
        if (data['accountStatus'] == 'active') {
          activeUsers++;
        }
        totalBalance += (data['balance'] as num? ?? 0).toDouble();
        totalProfit += (data['profit'] as num? ?? 0).toDouble();
      }
      final pendingDepositsSnap = await _db
          .collectionGroup(AppConstants.depositsSubCollection)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final pendingWithdrawalsSnap = await _db
          .collectionGroup(AppConstants.withdrawalsSubCollection)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final openTradesSnap = await _db
          .collectionGroup(AppConstants.tradesSubCollection)
          .where('status', isEqualTo: 'open')
          .count()
          .get();

      final openSupportSnap = await _db
          .collection(AppConstants.supportConversationsCollection)
          .where('status', isEqualTo: 'open')
          .count()
          .get();

      final newMessagesSnap = await _db
          .collectionGroup('messages')
          .where('senderRole', isEqualTo: 'user')
          .where('isReadByAdmin', isEqualTo: false)
          .count()
          .get();

      return AdminDashboardStats(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        pendingDeposits: pendingDepositsSnap.count ?? 0,
        pendingWithdrawals: pendingWithdrawalsSnap.count ?? 0,
        openTrades: openTradesSnap.count ?? 0,
        openSupportChats: openSupportSnap.count ?? 0,
        newMessages: newMessagesSnap.count ?? 0,
        totalPlatformBalance: totalBalance,
        totalProfitAwarded: totalProfit,
      );
    } catch (e, stack) {
      debugPrint('🚨 [Admin Stats Error]: $e');
      debugPrint('📍 [StackTrace]: $stack');
      rethrow;
    }
  }

  /// Fetch recent activities across deposits, withdrawals, trades, and support
  Stream<AdminRecentActivity> streamRecentActivity({int limit = 5}) {
    return _db
        .collectionGroup(AppConstants.depositsSubCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((depSnap) async {
      final deposits =
          depSnap.docs.map(DepositModel.fromFirestore).toList();

      final withSnap = await _db
          .collectionGroup(AppConstants.withdrawalsSubCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final withdrawals =
          withSnap.docs.map(WithdrawalModel.fromFirestore).toList();

      final tradesSnap = await _db
          .collectionGroup(AppConstants.tradesSubCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final trades = tradesSnap.docs.map(TradeModel.fromFirestore).toList();

      final suppSnap = await _db
          .collection(AppConstants.supportConversationsCollection)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();
      final support =
          suppSnap.docs.map(SupportConversationModel.fromFirestore).toList();

      return AdminRecentActivity(
        recentDeposits: deposits,
        recentWithdrawals: withdrawals,
        recentTrades: trades,
        recentSupport: support,
      );
    });
  }

  /// Stream audit logs with optional filters
  Stream<List<AuditLogModel>> streamAuditLogs({
    String? targetType,
    String? action,
    int limit = 100,
  }) {
    Query query = _auditLogs.orderBy('createdAt', descending: true).limit(limit);

    if (targetType != null && targetType.isNotEmpty) {
      query = query.where('targetType', isEqualTo: targetType);
    }
    if (action != null && action.isNotEmpty) {
      query = query.where('action', isEqualTo: action);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map(AuditLogModel.fromFirestore).toList(),
        );
  }

  /// Stream broadcast notification history
  Stream<List<AdminNotificationModel>> streamBroadcastNotifications({
    int limit = 50,
  }) {
    return _adminNotifications
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map(AdminNotificationModel.fromFirestore).toList());
  }

  /// Award manual profit via Cloud Function (creates ledger transaction & notification)
  Future<void> awardProfit({
    required String userId,
    required double amount,
    required String reason,
  }) async {
    try {
      final callable = _functions.httpsCallable('awardProfit');
      await callable.call({
        'userId': userId,
        'amount': amount,
        'reason': reason,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to award profit.');
    }
  }

  /// Manual financial adjustment with immutable audit log
  Future<void> makeAdjustment({
    required String userId,
    required double amount,
    required String reason,
    required bool isCredit,
  }) async {
    try {
      final callable = _functions.httpsCallable('makeAdjustment');
      await callable.call({
        'userId': userId,
        'amount': amount,
        'reason': reason,
        'isCredit': isCredit,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to make adjustment.');
    }
  }

  /// Send push notification / manual inbox message to a user or broadcast to all
  Future<void> sendNotification({
    String? targetUserId,
    String? targetUserId7,
    required String title,
    required String body,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendNotification');
      await callable.call({
        'targetUserId': targetUserId,
        'targetUserId7': targetUserId7,
        'title': title,
        'body': body,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to send notification.');
    }
  }

  /// Upload coin logo to Firebase Storage
  Future<String> uploadCoinLogo(String coinId, File file) async {
    final ext = file.path.split('.').last;
    final ref = _storage.ref().child('coin-logos').child('${coinId}_${const Uuid().v4()}.$ext');
    final task = await ref.putFile(file, SettableMetadata(contentType: 'image/$ext'));
    return await task.ref.getDownloadURL();
  }

  /// Upload deposit method QR Code to Firebase Storage
  Future<String> uploadQrCode(String methodId, File file) async {
    final ext = file.path.split('.').last;
    final ref = _storage.ref().child('qr-codes').child('${methodId}_${const Uuid().v4()}.$ext');
    final task = await ref.putFile(file, SettableMetadata(contentType: 'image/$ext'));
    return await task.ref.getDownloadURL();
  }
}
