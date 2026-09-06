import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:tradingpro/models/coin_model.dart';
import 'package:tradingpro/core/constants/app_constants.dart';

class CoinRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _coins =>
      _db.collection(AppConstants.coinsCollection);

  /// Upload coin logo image bytes to Firebase Storage and get download URL
  Future<String> uploadCoinLogo(Uint8List bytes, [String fileExtension = 'png']) async {
    final cleanExt = fileExtension.replaceAll('.', '').toLowerCase();
    final fileName = '${const Uuid().v4()}.$cleanExt';
    final ref = _storage.ref().child('coin-logos').child(fileName);
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/$cleanExt'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  /// Stream all active coins ordered by displayOrder
  Stream<List<CoinModel>> streamActiveCoins() {
    return _coins
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder')
        .snapshots()
        .map((snap) => snap.docs.map(CoinModel.fromFirestore).toList());
  }

  /// Stream featured coins (Top 3)
  Stream<List<CoinModel>> streamFeaturedCoins() {
    return _coins
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('displayOrder')
        .limit(AppConstants.maxFeaturedCoins)
        .snapshots()
        .map((snap) => snap.docs.map(CoinModel.fromFirestore).toList());
  }

  /// Stream all coins (admin)
  Stream<List<CoinModel>> streamAllCoins() {
    return _coins
        .orderBy('displayOrder')
        .snapshots()
        .map((snap) => snap.docs.map(CoinModel.fromFirestore).toList());
  }

  /// Get coin by id
  Future<CoinModel?> getCoin(String coinId) async {
    final doc = await _coins.doc(coinId).get();
    if (!doc.exists) return null;
    return CoinModel.fromFirestore(doc);
  }

  /// Admin: Add coin
  Future<String> addCoin(CoinModel coin) async {
    final ref = await _coins.add(coin.toFirestore());
    return ref.id;
  }

  /// Admin: Update coin
  Future<void> updateCoin(String coinId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _coins.doc(coinId).update(data);
  }

  /// Admin: Toggle active status
  Future<void> toggleCoinActive(String coinId, bool isActive) async {
    await _coins.doc(coinId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: Toggle featured (with max 3 enforcement)
  Future<void> toggleCoinFeatured(String coinId, bool isFeatured) async {
    if (isFeatured) {
      // Check current featured count
      final featured = await _coins
          .where('isFeatured', isEqualTo: true)
          .count()
          .get();
      if ((featured.count ?? 0) >= AppConstants.maxFeaturedCoins) {
        throw Exception(
            'Maximum ${AppConstants.maxFeaturedCoins} featured coins allowed. Unfeature another coin first.');
      }
    }
    await _coins.doc(coinId).update({
      'isFeatured': isFeatured,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: Delete coin (soft delete by deactivating)
  Future<void> deleteCoin(String coinId) async {
    await _coins.doc(coinId).update({
      'isActive': false,
      'isFeatured': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream coins that are active AND in live market-data mode.
  /// Used by the admin dashboard to show which coins have live feeds.
  Stream<List<CoinModel>> streamLiveActiveCoins() {
    return _coins
        .where('isActive', isEqualTo: true)
        .where('marketDataMode', isEqualTo: 'live')
        .orderBy('displayOrder')
        .snapshots()
        .map((snap) => snap.docs.map(CoinModel.fromFirestore).toList());
  }

  /// Update market data mode for a coin.
  /// When switching to manual the backend will stop overwriting this coin.
  Future<void> updateMarketDataMode(
    String coinId,
    String mode, {
    String? binanceSymbol,
  }) async {
    await _coins.doc(coinId).update({
      'marketDataMode': mode,
      if (binanceSymbol != null) 'binanceSymbol': binanceSymbol,
      // When switching to live, reset status so backend can update it.
      if (mode == 'live') 'marketDataStatus': 'offline',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
