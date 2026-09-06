import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:tradingpro/models/deposit_model.dart';
import 'package:tradingpro/models/settings_models.dart';
import 'package:tradingpro/core/constants/app_constants.dart';

class DepositRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference _userDeposits(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.depositsSubCollection);

  CollectionReference get _depositMethods =>
      _db.collection(AppConstants.depositMethodsCollection);

  /// Stream user deposit history
  Stream<List<DepositModel>> streamUserDeposits(String uid) {
    return _userDeposits(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(DepositModel.fromFirestore).toList());
  }

  /// Stream active deposit methods configured by admin
  Stream<List<DepositMethodModel>> streamActiveDepositMethods() {
    return _depositMethods
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder')
        .snapshots()
        .map((snap) =>
            snap.docs.map(DepositMethodModel.fromFirestore).toList());
  }

  /// Stream all deposit methods (admin)
  Stream<List<DepositMethodModel>> streamAllDepositMethods() {
    return _depositMethods
        .orderBy('displayOrder')
        .snapshots()
        .map((snap) =>
            snap.docs.map(DepositMethodModel.fromFirestore).toList());
  }

  /// Upload deposit screenshot securely to Firebase Storage
  Future<String> uploadScreenshot(String uid, File imageFile) async {
    final fileExt = imageFile.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$fileExt';
    final storageRef = _storage
        .ref()
        .child('deposit-screenshots')
        .child(uid)
        .child(fileName);

    final uploadTask = await storageRef.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/$fileExt'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  /// Submit a deposit via Cloud Functions (untrusted client protection)
  Future<void> submitDeposit({
    required String asset,
    required String network,
    required String walletAddress,
    required double amount,
    required String screenshotUrl,
  }) async {
    try {
      final callable = _functions.httpsCallable('submitDeposit');
      await callable.call({
        'asset': asset,
        'network': network,
        'walletAddress': walletAddress,
        'amount': amount,
        'screenshotUrl': screenshotUrl,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to submit deposit.');
    }
  }

  // ─── Admin Methods ────────────────────────────────────────────────────────

  /// Stream deposits by status (admin collectionGroup)
  Stream<List<DepositModel>> streamAdminDeposits({DepositStatus? status}) {
    Query query = _db
        .collectionGroup(AppConstants.depositsSubCollection)
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map(DepositModel.fromFirestore).toList(),
        );
  }

  /// Admin approve deposit via Cloud Function
  Future<void> approveDeposit({
    required String depositId,
    required String userId,
    required double creditedAmount,
    String? adminNote,
  }) async {
    try {
      final callable = _functions.httpsCallable('approveDeposit');
      await callable.call({
        'depositId': depositId,
        'userId': userId,
        'creditedAmount': creditedAmount,
        'adminNote': adminNote,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to approve deposit.');
    }
  }

  /// Admin reject deposit via Cloud Function
  Future<void> rejectDeposit({
    required String depositId,
    required String userId,
    required String reason,
  }) async {
    try {
      final callable = _functions.httpsCallable('rejectDeposit');
      await callable.call({
        'depositId': depositId,
        'userId': userId,
        'adminNote': reason,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to reject deposit.');
    }
  }

  /// Admin: Add or update deposit method
  Future<void> saveDepositMethod(DepositMethodModel method) async {
    if (method.methodId.isEmpty) {
      await _depositMethods.add(method.toFirestore());
    } else {
      await _depositMethods.doc(method.methodId).set(
            method.toFirestore(),
            SetOptions(merge: true),
          );
    }
  }

  /// Admin: Toggle deposit method active status
  Future<void> toggleDepositMethodActive(String methodId, bool isActive) async {
    await _depositMethods.doc(methodId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: Delete deposit method
  Future<void> deleteDepositMethod(String methodId) async {
    await _depositMethods.doc(methodId).delete();
  }
}
