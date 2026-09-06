import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tradingpro/models/transaction_model.dart';
import 'package:tradingpro/core/constants/app_constants.dart';

class TransactionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _txCollection(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.transactionsSubCollection);

  /// Stream all transactions (newest first)
  Stream<List<TransactionModel>> streamTransactions(
    String uid, {
    TransactionType? filterType,
    int limit = 50,
  }) {
    Query query = _txCollection(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType.name);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map(TransactionModel.fromFirestore).toList(),
        );
  }

  /// Get paginated transactions (for infinite scroll)
  Future<List<TransactionModel>> getTransactions(
    String uid, {
    TransactionType? filterType,
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    Query query = _txCollection(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType.name);
    }
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snap = await query.get();
    return snap.docs.map(TransactionModel.fromFirestore).toList();
  }
}
