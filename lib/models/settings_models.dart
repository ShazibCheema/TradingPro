import 'package:cloud_firestore/cloud_firestore.dart';

class DepositMethodModel {
  final String methodId;
  final String asset;
  final String network;
  final String walletAddress;
  final String? qrCodeUrl;
  final double minimumDeposit;
  final String? instructions;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DepositMethodModel({
    required this.methodId,
    required this.asset,
    required this.network,
    required this.walletAddress,
    this.qrCodeUrl,
    required this.minimumDeposit,
    this.instructions,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DepositMethodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DepositMethodModel(
      methodId: doc.id,
      asset: data['asset'] as String? ?? '',
      network: data['network'] as String? ?? '',
      walletAddress: data['walletAddress'] as String? ?? '',
      qrCodeUrl: data['qrCodeUrl'] as String?,
      minimumDeposit: (data['minimumDeposit'] as num? ?? 0).toDouble(),
      instructions: data['instructions'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      displayOrder: data['displayOrder'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'asset': asset,
      'network': network,
      'walletAddress': walletAddress,
      'qrCodeUrl': qrCodeUrl,
      'minimumDeposit': minimumDeposit,
      'instructions': instructions,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class AppSettingsModel {
  final double minimumWithdrawal;
  final double? maximumWithdrawal;
  final int supportAutoCloseMinutes;
  final String supportAutoCloseMessage;
  final String depositProcessingMessage;
  final bool appEnabled;

  const AppSettingsModel({
    required this.minimumWithdrawal,
    this.maximumWithdrawal,
    required this.supportAutoCloseMinutes,
    required this.supportAutoCloseMessage,
    required this.depositProcessingMessage,
    required this.appEnabled,
  });

  factory AppSettingsModel.defaults() {
    return const AppSettingsModel(
      minimumWithdrawal: 50.0,
      supportAutoCloseMinutes: 30,
      supportAutoCloseMessage:
          'Admin chat has been closed. Hope you liked our service.',
      depositProcessingMessage:
          'Your deposit is being reviewed and will be confirmed within 30 minutes to 24 hours.',
      appEnabled: true,
    );
  }

  factory AppSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppSettingsModel(
      minimumWithdrawal: (data['minimumWithdrawal'] as num? ?? 50).toDouble(),
      maximumWithdrawal: (data['maximumWithdrawal'] as num?)?.toDouble(),
      supportAutoCloseMinutes: data['supportAutoCloseMinutes'] as int? ?? 30,
      supportAutoCloseMessage: data['supportAutoCloseMessage'] as String? ??
          'Admin chat has been closed. Hope you liked our service.',
      depositProcessingMessage: data['depositProcessingMessage'] as String? ??
          'Your deposit is being reviewed.',
      appEnabled: data['appEnabled'] as bool? ?? true,
    );
  }
}

class NotificationPrefsModel {
  final bool transactions;
  final bool deposits;
  final bool withdrawals;
  final bool profit;
  final bool trading;
  final bool customerSupport;

  const NotificationPrefsModel({
    required this.transactions,
    required this.deposits,
    required this.withdrawals,
    required this.profit,
    required this.trading,
    required this.customerSupport,
  });

  factory NotificationPrefsModel.defaults() {
    return const NotificationPrefsModel(
      transactions: true,
      deposits: true,
      withdrawals: true,
      profit: true,
      trading: true,
      customerSupport: true,
    );
  }

  factory NotificationPrefsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationPrefsModel(
      transactions: data['transactions'] as bool? ?? true,
      deposits: data['deposits'] as bool? ?? true,
      withdrawals: data['withdrawals'] as bool? ?? true,
      profit: data['profit'] as bool? ?? true,
      trading: data['trading'] as bool? ?? true,
      customerSupport: data['customerSupport'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'transactions': transactions,
      'deposits': deposits,
      'withdrawals': withdrawals,
      'profit': profit,
      'trading': trading,
      'customerSupport': customerSupport,
    };
  }

  NotificationPrefsModel copyWith({
    bool? transactions,
    bool? deposits,
    bool? withdrawals,
    bool? profit,
    bool? trading,
    bool? customerSupport,
  }) {
    return NotificationPrefsModel(
      transactions: transactions ?? this.transactions,
      deposits: deposits ?? this.deposits,
      withdrawals: withdrawals ?? this.withdrawals,
      profit: profit ?? this.profit,
      trading: trading ?? this.trading,
      customerSupport: customerSupport ?? this.customerSupport,
    );
  }
}
