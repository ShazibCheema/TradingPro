import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tradingpro/models/settings_models.dart';
import 'package:tradingpro/core/constants/app_constants.dart';

class SettingsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference get _globalDoc => _db
      .collection(AppConstants.appSettingsCollection)
      .doc(AppConstants.globalSettingsDoc);

  /// Stream app settings
  Stream<AppSettingsModel> streamAppSettings() {
    return _globalDoc.snapshots().map((doc) {
      if (!doc.exists) return AppSettingsModel.defaults();
      return AppSettingsModel.fromFirestore(doc);
    });
  }

  /// Get app settings once
  Future<AppSettingsModel> getAppSettings() async {
    final doc = await _globalDoc.get();
    if (!doc.exists) return AppSettingsModel.defaults();
    return AppSettingsModel.fromFirestore(doc);
  }

  /// Admin: Update app settings
  Future<void> updateAppSettings({
    double? minimumWithdrawal,
    double? maximumWithdrawal,
    int? supportAutoCloseMinutes,
    String? supportAutoCloseMessage,
    String? depositProcessingMessage,
    bool? appEnabled,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (minimumWithdrawal != null) {
      updates['minimumWithdrawal'] = minimumWithdrawal;
    }
    if (maximumWithdrawal != null) {
      updates['maximumWithdrawal'] = maximumWithdrawal;
    }
    if (supportAutoCloseMinutes != null) {
      updates['supportAutoCloseMinutes'] = supportAutoCloseMinutes;
    }
    if (supportAutoCloseMessage != null) {
      updates['supportAutoCloseMessage'] = supportAutoCloseMessage;
    }
    if (depositProcessingMessage != null) {
      updates['depositProcessingMessage'] = depositProcessingMessage;
    }
    if (appEnabled != null) {
      updates['appEnabled'] = appEnabled;
    }

    await _globalDoc.set(updates, SetOptions(merge: true));
  }
}
