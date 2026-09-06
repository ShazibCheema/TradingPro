/// Application-wide constants for TradingPro: I&T
class AppConstants {
  AppConstants._();

  // ─── App Info ─────────────────────────────────────────────────────────────
  static const String appName = 'TradingPro: I&T';
  static const String appNameShort = 'TradingPro';
  static const String adminAppName = 'TradingPro';
  static const String tagline = 'Investing & Trading';
  static const String packageName = 'com.tradingpro.it';
  static const String adminPackageName = 'com.tradingpro.it.admin';
  static const String appLogo = 'assets/images/TradingPro-logo.png';

  // ─── Firestore Collections ─────────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String devicesSubCollection = 'devices';
  static const String transactionsSubCollection = 'transactions';
  static const String notificationsSubCollection = 'notifications';
  static const String depositsSubCollection = 'deposits';
  static const String withdrawalsSubCollection = 'withdrawals';
  static const String tradesSubCollection = 'trades';
  static const String notificationPrefsSubCollection = 'notificationPrefs';

  static const String coinsCollection = 'coins';
  static const String depositMethodsCollection = 'depositMethods';
  static const String supportConversationsCollection = 'supportConversations';
  static const String messagesSubCollection = 'messages';
  static const String appSettingsCollection = 'appSettings';
  static const String auditLogsCollection = 'auditLogs';
  static const String adminNotificationsCollection = 'adminNotifications';

  // ─── App Settings Docs ─────────────────────────────────────────────────────
  static const String globalSettingsDoc = 'global';
  static const String withdrawalSettingsDoc = 'withdrawal';
  static const String supportSettingsDoc = 'support';

  // ─── Defaults ─────────────────────────────────────────────────────────────
  static const double defaultMinimumWithdrawal = 50.0;
  static const int supportAutoCloseMinutes = 30;
  static const String supportAutoCloseMessage =
      'Admin chat has been closed. Hope you liked our service.';
  static const int userId7Length = 7;
  static const int maxFeaturedCoins = 3;

  // ─── Market Data ──────────────────────────────────────────────────────────
  /// Seconds after lastMarketUpdate before a coin is considered stale.
  static const int marketDataStaleThresholdSeconds = 30;

  /// Seconds after which a stale coin is considered offline.
  static const int marketDataOfflineThresholdSeconds = 120;

  /// Maximum WebSocket reconnection delay (seconds) — exponential backoff cap.
  static const int marketDataMaxReconnectDelaySeconds = 30;

  /// Binance Spot WebSocket base URL.
  static const String binanceWsBaseUrl =
      'wss://stream.binance.com:9443/stream';

  // ─── Validation ───────────────────────────────────────────────────────────
  static const int minPasswordLength = 8;
  static const int maxWalletAddressLength = 128;
  static const double maxDepositScreenshotMB = 10.0;
  static const int maxDepositScreenshotBytes = 10 * 1024 * 1024;

  // ─── UI ───────────────────────────────────────────────────────────────────
  static const double pageHorizontalPadding = 20.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 14.0;
  static const double inputBorderRadius = 12.0;

  // ─── Currency ─────────────────────────────────────────────────────────────
  static const String displayCurrency = 'USD';
  static const String displayCurrencySymbol = '\$';
}

/// Flavor enum for user vs admin app
enum AppFlavor { user, admin }
