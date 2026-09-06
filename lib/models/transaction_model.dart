import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  deposit,
  withdrawal,
  profit,
  trade,
  tradeProfit,
  tradeLoss,
  adjustment,
}

enum TransactionDirection { credit, debit }

class TransactionModel {
  final String transactionId;
  final String userId;
  final TransactionType type;
  final double amount;
  final String asset;
  final TransactionDirection direction;
  final double balanceBefore;
  final double balanceAfter;
  final String? referenceId;
  final String description;
  final String? createdBy;
  final DateTime createdAt;

  const TransactionModel({
    required this.transactionId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.asset,
    required this.direction,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceId,
    required this.description,
    this.createdBy,
    required this.createdAt,
  });

  bool get isCredit => direction == TransactionDirection.credit;
  bool get isDebit => direction == TransactionDirection.debit;

  String get typeDisplayName {
    switch (type) {
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.profit:
        return 'Profit';
      case TransactionType.trade:
        return 'Trade';
      case TransactionType.tradeProfit:
        return 'Trade Profit';
      case TransactionType.tradeLoss:
        return 'Trade Loss';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      transactionId: doc.id,
      userId: data['userId'] as String? ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'deposit'),
        orElse: () => TransactionType.deposit,
      ),
      amount: (data['amount'] as num? ?? 0).toDouble(),
      asset: data['asset'] as String? ?? 'USD',
      direction: TransactionDirection.values.firstWhere(
        (e) => e.name == (data['direction'] as String? ?? 'credit'),
        orElse: () => TransactionDirection.credit,
      ),
      balanceBefore: (data['balanceBefore'] as num? ?? 0).toDouble(),
      balanceAfter: (data['balanceAfter'] as num? ?? 0).toDouble(),
      referenceId: data['referenceId'] as String?,
      description: data['description'] as String? ?? '',
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'asset': asset,
      'direction': direction.name,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'referenceId': referenceId,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
