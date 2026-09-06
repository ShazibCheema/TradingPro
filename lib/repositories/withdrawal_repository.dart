import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:tradingpro/models/withdrawal_model.dart';
import 'package:tradingpro/core/constants/app_constants.dart';

class WithdrawalRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference _userWithdrawals(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.withdrawalsSubCollection);

  /// Stream user withdrawal history
  Stream<List<WithdrawalModel>> streamUserWithdrawals(String uid) {
    return _userWithdrawals(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(WithdrawalModel.fromFirestore).toList());
  }

  /// Submit withdrawal via Cloud Function (validates server-side balance & min limit)
  Future<void> submitWithdrawal({
    required double amount,
    required String asset,
    required String network,
    required String walletAddress,
  }) async {
    try {
      final callable = _functions.httpsCallable('submitWithdrawal');
      await callable.call({
        'amount': amount,
        'asset': asset,
        'network': network,
        'walletAddress': walletAddress,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to submit withdrawal.');
    }
  }

  // ─── Admin Methods ────────────────────────────────────────────────────────

  /// Stream all withdrawals for admin (collectionGroup)
  Stream<List<WithdrawalModel>> streamAdminWithdrawals({
    WithdrawalStatus? status,
  }) {
    Query query = _db
        .collectionGroup(AppConstants.withdrawalsSubCollection)
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map(WithdrawalModel.fromFirestore).toList(),
        );
  }

  /// Admin approve withdrawal via Cloud Function
  Future<void> approveWithdrawal({
    required String withdrawalId,
    required String userId,
    String? adminNote,
  }) async {
    try {
      final callable = _functions.httpsCallable('approveWithdrawal');
      await callable.call({
        'withdrawalId': withdrawalId,
        'userId': userId,
        'adminNote': adminNote,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to approve withdrawal.');
    }
  }

  /// Admin reject withdrawal via Cloud Function (restores reserved balance)
  Future<void> rejectWithdrawal({
    required String withdrawalId,
    required String userId,
    required String reason,
  }) async {
    try {
      final callable = _functions.httpsCallable('rejectWithdrawal');
      await callable.call({
        'withdrawalId': withdrawalId,
        'userId': userId,
        'adminNote': reason,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to reject withdrawal.');
    }
  }
}
