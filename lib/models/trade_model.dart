import 'package:cloud_firestore/cloud_firestore.dart';

enum TradeStatus { pending, open, closed, cancelled }

class TradeModel {
  final String tradeId;
  final String userId;
  final String userId7;
  final String userFullName;
  final String coinId;
  final String coinSymbol;
  final String coinName;
  final double investmentAmount;
  final double entryPrice;
  final double? closingPrice;
  final double? profitAmount;
  final double? lossAmount;
  final TradeStatus status;
  final String? adminNote;
  final String? adminUid;
  final DateTime createdAt;
  final DateTime? openedAt;
  final DateTime? closedAt;

  const TradeModel({
    required this.tradeId,
    required this.userId,
    required this.userId7,
    required this.userFullName,
    required this.coinId,
    required this.coinSymbol,
    required this.coinName,
    required this.investmentAmount,
    required this.entryPrice,
    this.closingPrice,
    this.profitAmount,
    this.lossAmount,
    required this.status,
    this.adminNote,
    this.adminUid,
    required this.createdAt,
    this.openedAt,
    this.closedAt,
  });

  bool get isPending => status == TradeStatus.pending;
  bool get isOpen => status == TradeStatus.open;
  bool get isClosed => status == TradeStatus.closed;
  bool get isCancelled => status == TradeStatus.cancelled;
  bool get hasProfit => profitAmount != null && profitAmount! > 0;
  bool get hasLoss => lossAmount != null && lossAmount! > 0;

  factory TradeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TradeModel(
      tradeId: doc.id,
      userId: data['userId'] as String? ?? '',
      userId7: data['userId7'] as String? ?? '',
      userFullName: data['userFullName'] as String? ?? '',
      coinId: data['coinId'] as String? ?? '',
      coinSymbol: data['coinSymbol'] as String? ?? '',
      coinName: data['coinName'] as String? ?? '',
      investmentAmount: (data['investmentAmount'] as num? ?? 0).toDouble(),
      entryPrice: (data['entryPrice'] as num? ?? 0).toDouble(),
      closingPrice: (data['closingPrice'] as num?)?.toDouble(),
      profitAmount: (data['profitAmount'] as num?)?.toDouble(),
      lossAmount: (data['lossAmount'] as num?)?.toDouble(),
      status: TradeStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => TradeStatus.pending,
      ),
      adminNote: data['adminNote'] as String?,
      adminUid: data['adminUid'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      openedAt: (data['openedAt'] as Timestamp?)?.toDate(),
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userId7': userId7,
      'userFullName': userFullName,
      'coinId': coinId,
      'coinSymbol': coinSymbol,
      'coinName': coinName,
      'investmentAmount': investmentAmount,
      'entryPrice': entryPrice,
      'closingPrice': closingPrice,
      'profitAmount': profitAmount,
      'lossAmount': lossAmount,
      'status': status.name,
      'adminNote': adminNote,
      'adminUid': adminUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'openedAt': openedAt != null ? Timestamp.fromDate(openedAt!) : null,
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
    };
  }
}
