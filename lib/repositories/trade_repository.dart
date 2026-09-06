import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:tradingpro/models/trade_model.dart';
import 'package:tradingpro/core/constants/app_constants.dart';

class TradeRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference _userTrades(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.tradesSubCollection);

  /// Stream user trades
  Stream<List<TradeModel>> streamUserTrades(String uid) {
    return _userTrades(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TradeModel.fromFirestore).toList());
  }

  /// Submit a trade via Cloud Functions
  Future<void> createTrade({required double investmentAmount}) async {
    try {
      final callable = _functions.httpsCallable('createTrade');
      await callable.call({
        'investmentAmount': investmentAmount,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to submit trade.');
    }
  }

  // ─── Admin Methods ────────────────────────────────────────────────────────

  /// Stream all trades for admin (collectionGroup)
  Stream<List<TradeModel>> streamAdminTrades({TradeStatus? status}) {
    Query query = _db
        .collectionGroup(AppConstants.tradesSubCollection)
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map(TradeModel.fromFirestore).toList(),
        );
  }

  /// Admin approve/open trade
  Future<void> openTrade({
    required String tradeId,
    required String userId,
    String? adminNote,
  }) async {
    try {
      final callable = _functions.httpsCallable('manageTrade');
      await callable.call({
        'tradeId': tradeId,
        'userId': userId,
        'action': 'open',
        'adminNote': adminNote,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to open trade.');
    }
  }

  /// Admin close trade with profit/loss
  Future<void> closeTrade({
    required String tradeId,
    required String userId,
    required double closingPrice,
    double? profitAmount,
    double? lossAmount,
    String? adminNote,
  }) async {
    try {
      final callable = _functions.httpsCallable('closeTrade');
      await callable.call({
        'tradeId': tradeId,
        'userId': userId,
        'closingPrice': closingPrice,
        'profitAmount': profitAmount ?? 0.0,
        'lossAmount': lossAmount ?? 0.0,
        'adminNote': adminNote,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to close trade.');
    }
  }

  /// Admin cancel trade
  Future<void> cancelTrade({
    required String tradeId,
    required String userId,
    String? adminNote,
  }) async {
    try {
      final callable = _functions.httpsCallable('manageTrade');
      await callable.call({
        'tradeId': tradeId,
        'userId': userId,
        'action': 'cancel',
        'adminNote': adminNote,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to cancel trade.');
    }
  }
}
