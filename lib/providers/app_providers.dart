import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tradingpro/services/notification_service.dart';
import 'package:tradingpro/repositories/auth_repository.dart';
import 'package:tradingpro/repositories/user_repository.dart';
import 'package:tradingpro/repositories/coin_repository.dart';
import 'package:tradingpro/repositories/notification_repository.dart';
import 'package:tradingpro/repositories/transaction_repository.dart';
import 'package:tradingpro/repositories/support_repository.dart';
import 'package:tradingpro/repositories/deposit_repository.dart';
import 'package:tradingpro/repositories/withdrawal_repository.dart';
import 'package:tradingpro/repositories/trade_repository.dart';
import 'package:tradingpro/repositories/settings_repository.dart';
import 'package:tradingpro/repositories/admin_repository.dart';
import 'package:tradingpro/models/user_model.dart';
import 'package:tradingpro/models/coin_model.dart';
import 'package:tradingpro/models/deposit_model.dart';
import 'package:tradingpro/models/withdrawal_model.dart';
import 'package:tradingpro/models/trade_model.dart';
import 'package:tradingpro/models/notification_model.dart';
import 'package:tradingpro/models/transaction_model.dart';
import 'package:tradingpro/models/settings_models.dart';
import 'package:tradingpro/models/support_models.dart';
import 'package:tradingpro/models/audit_log_model.dart';
import 'package:tradingpro/models/admin_notification_model.dart';
import 'package:tradingpro/core/constants/app_constants.dart';

// ─── Flavor ───────────────────────────────────────────────────────────────────

final flavorProvider = Provider<AppFlavor>((ref) => AppFlavor.user);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final coinRepositoryProvider = Provider<CoinRepository>((ref) {
  return CoinRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository();
});

final depositRepositoryProvider = Provider<DepositRepository>((ref) {
  return DepositRepository();
});

final withdrawalRepositoryProvider = Provider<WithdrawalRepository>((ref) {
  return WithdrawalRepository();
});

final tradeRepositoryProvider = Provider<TradeRepository>((ref) {
  return TradeRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  return NotificationService(userRepo: userRepo);
});

// ─── Auth State ────────────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

// ─── User Data ─────────────────────────────────────────────────────────────────

final userProvider = StreamProvider<UserModel?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).streamUser(uid);
});

// ─── Market Data ───────────────────────────────────────────────────────────────

final activeCoinsProvider = StreamProvider<List<CoinModel>>((ref) {
  return ref.watch(coinRepositoryProvider).streamActiveCoins();
});

final featuredCoinsProvider = StreamProvider<List<CoinModel>>((ref) {
  return ref.watch(coinRepositoryProvider).streamFeaturedCoins();
});

final allCoinsProvider = StreamProvider<List<CoinModel>>((ref) {
  return ref.watch(coinRepositoryProvider).streamAllCoins();
});

// ─── Notifications ─────────────────────────────────────────────────────────────

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(notificationRepositoryProvider).streamNotifications(uid);
});

final unreadNotifCountProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(0);
  return ref.watch(notificationRepositoryProvider).streamUnreadCount(uid);
});

// ─── Notification Preferences ──────────────────────────────────────────────────

final notifPrefsProvider = StreamProvider<NotificationPrefsModel>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(NotificationPrefsModel.defaults());
  return ref.watch(notificationRepositoryProvider).streamPrefs(uid);
});

// ─── Transactions ──────────────────────────────────────────────────────────────

final transactionsProvider =
    StreamProvider.family<List<TransactionModel>, TransactionType?>(
  (ref, filterType) {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return Stream.value([]);
    return ref
        .watch(transactionRepositoryProvider)
        .streamTransactions(uid, filterType: filterType);
  },
);

// ─── Deposits & Methods ────────────────────────────────────────────────────────

final activeDepositMethodsProvider =
    StreamProvider<List<DepositMethodModel>>((ref) {
  return ref.watch(depositRepositoryProvider).streamActiveDepositMethods();
});

final allDepositMethodsProvider =
    StreamProvider<List<DepositMethodModel>>((ref) {
  return ref.watch(depositRepositoryProvider).streamAllDepositMethods();
});

final userDepositsProvider = StreamProvider<List<DepositModel>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(depositRepositoryProvider).streamUserDeposits(uid);
});

// ─── Withdrawals ───────────────────────────────────────────────────────────────

final userWithdrawalsProvider = StreamProvider<List<WithdrawalModel>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(withdrawalRepositoryProvider).streamUserWithdrawals(uid);
});

// ─── Trades ────────────────────────────────────────────────────────────────────

final userTradesProvider = StreamProvider<List<TradeModel>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(tradeRepositoryProvider).streamUserTrades(uid);
});

// ─── App Settings ──────────────────────────────────────────────────────────────

final appSettingsProvider = StreamProvider<AppSettingsModel>((ref) {
  return ref.watch(settingsRepositoryProvider).streamAppSettings();
});

// ─── Support ───────────────────────────────────────────────────────────────────

final userConversationProvider =
    StreamProvider<SupportConversationModel?>((ref) async* {
  final user = ref.watch(userProvider).valueOrNull;
  if (user == null) {
    yield null;
    return;
  }
  final repo = ref.watch(supportRepositoryProvider);
  try {
    final conv = await repo.getOrCreateConversation(
      user.uid,
      user.userId7,
      user.fullName,
      user.email,
    );
    yield* repo.streamConversation(conv.conversationId);
  } catch (e) {
    // If it fails (e.g. index building), don't yield anything or yield error
    // StreamProvider will handle the throw and show ErrorStateWidget
    rethrow;
  }
});

final conversationMessagesProvider =
    StreamProvider.family<List<SupportMessageModel>, String>(
  (ref, conversationId) {
    return ref
        .watch(supportRepositoryProvider)
        .streamMessages(conversationId);
  },
);

// ─── Admin Providers ───────────────────────────────────────────────────────────

final isAdminProvider = FutureProvider<bool>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return false;
  return ref.watch(authRepositoryProvider).isAdmin();
});

final adminDashboardStatsProvider =
    FutureProvider<AdminDashboardStats>((ref) async {
  return ref.watch(adminRepositoryProvider).getDashboardStats();
});

final adminAllUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).streamAllUsers();
});

final adminDepositsProvider =
    StreamProvider.family<List<DepositModel>, DepositStatus?>(
  (ref, status) {
    return ref
        .watch(depositRepositoryProvider)
        .streamAdminDeposits(status: status);
  },
);

final adminWithdrawalsProvider =
    StreamProvider.family<List<WithdrawalModel>, WithdrawalStatus?>(
  (ref, status) {
    return ref
        .watch(withdrawalRepositoryProvider)
        .streamAdminWithdrawals(status: status);
  },
);

final adminTradesProvider =
    StreamProvider.family<List<TradeModel>, TradeStatus?>(
  (ref, status) {
    return ref.watch(tradeRepositoryProvider).streamAdminTrades(status: status);
  },
);

final adminOpenSupportProvider =
    StreamProvider<List<SupportConversationModel>>((ref) {
  return ref.watch(supportRepositoryProvider).streamOpenConversations();
});

final adminAllSupportProvider =
    StreamProvider<List<SupportConversationModel>>((ref) {
  return ref.watch(supportRepositoryProvider).streamAllConversations();
});

final adminRecentActivityProvider =
    StreamProvider<AdminRecentActivity>((ref) {
  return ref.watch(adminRepositoryProvider).streamRecentActivity();
});

final adminAuditLogsProvider =
    StreamProvider.family<List<AuditLogModel>, String?>((ref, targetType) {
  return ref
      .watch(adminRepositoryProvider)
      .streamAuditLogs(targetType: targetType);
});

final adminBroadcastNotificationsProvider =
    StreamProvider<List<AdminNotificationModel>>((ref) {
  return ref
      .watch(adminRepositoryProvider)
      .streamBroadcastNotifications();
});
