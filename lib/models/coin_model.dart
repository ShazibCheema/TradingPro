import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Market Data Enums ────────────────────────────────────────────────────────

/// Controls how market data is sourced for this coin.
enum MarketDataMode {
  /// Binance backend worker controls price updates automatically.
  live,

  /// Admin enters price and percentage manually.
  manual,
}

/// Current health of the live market data feed for this coin.
enum MarketDataStatus {
  /// Recent successful update received from Binance (within stale threshold).
  live,

  /// No successful update received for a configurable period (default 30s).
  stale,

  /// Market data service or Binance is unavailable.
  offline,

  /// Coin is inactive or live market data is explicitly disabled.
  disabled,
}

/// Legacy enum kept for backward compatibility with existing UI code
/// that checks coin.changeDirection / coin.isPositive.
enum ChangeDirection { up, down }

// ─── CoinModel ────────────────────────────────────────────────────────────────

class CoinModel {
  final String coinId;
  final String name;
  final String symbol;
  final String? logoUrl;

  // ── Market data ──
  /// Raw price from Binance (or manually entered). Stored as numeric, never
  /// formatted. Display formatting is done in the UI layer.
  final double latestPrice;

  /// Signed 24-hour percentage change from Binance (e.g. -1.24 or +3.08).
  /// Stored as numeric. UI adds the % sign and +/- styling.
  /// In manual mode this may be positive or negative as entered by Admin.
  final double priceChangePercent24h;

  // ── Binance integration ──
  /// Binance symbol in UPPERCASE (e.g. BTCUSDT). Empty for manual-only coins.
  final String binanceSymbol;

  /// Whether this coin's price is controlled by the backend worker (live)
  /// or set manually by Admin (manual).
  final MarketDataMode marketDataMode;

  /// Current health status of the live market data feed.
  final MarketDataStatus marketDataStatus;

  /// Last time the backend worker successfully updated market data.
  /// null if no update has ever been received.
  final DateTime? lastMarketUpdate;

  // ── Admin configuration ──
  final bool isActive;
  final bool isFeatured;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CoinModel({
    required this.coinId,
    required this.name,
    required this.symbol,
    this.logoUrl,
    required this.latestPrice,
    required this.priceChangePercent24h,
    this.binanceSymbol = '',
    this.marketDataMode = MarketDataMode.manual,
    this.marketDataStatus = MarketDataStatus.disabled,
    this.lastMarketUpdate,
    required this.isActive,
    required this.isFeatured,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Convenience getters ────────────────────────────────────────────────────

  /// True when the 24h price movement is positive (green).
  bool get isPositive => priceChangePercent24h >= 0;

  /// Absolute percentage value — use isPositive to determine sign for display.
  double get percentageChange => priceChangePercent24h.abs();

  /// Legacy ChangeDirection enum derived from priceChangePercent24h.
  /// Kept for backward compatibility with existing UI widgets.
  ChangeDirection get changeDirection =>
      isPositive ? ChangeDirection.up : ChangeDirection.down;

  /// True when market data is current and from a live Binance feed.
  bool get isLiveDataFresh => marketDataStatus == MarketDataStatus.live;

  /// True when this coin has a valid price (not zero / unset).
  bool get hasPrice => latestPrice > 0;

  // ── Firestore deserialization ─────────────────────────────────────────────

  factory CoinModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoinModel(
      coinId: doc.id,
      name: data['name'] as String? ?? '',
      symbol: data['symbol'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      latestPrice: (data['latestPrice'] as num? ?? 0).toDouble(),

      // priceChangePercent24h is the canonical field (signed, numeric).
      // Fall back to legacy percentageChange + changeDirection for old docs.
      priceChangePercent24h: _resolvePercentage(data),

      binanceSymbol: data['binanceSymbol'] as String? ?? '',
      marketDataMode: _parseMode(data['marketDataMode'] as String?),
      marketDataStatus: _parseStatus(data['marketDataStatus'] as String?),
      lastMarketUpdate:
          (data['lastMarketUpdate'] as Timestamp?)?.toDate(),

      isActive: data['isActive'] as bool? ?? true,
      isFeatured: data['isFeatured'] as bool? ?? false,
      displayOrder: (data['displayOrder'] as num? ?? 0).toInt(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── Firestore serialization ───────────────────────────────────────────────

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'symbol': symbol,
      'logoUrl': logoUrl,
      'latestPrice': latestPrice,
      'priceChangePercent24h': priceChangePercent24h,
      'binanceSymbol': binanceSymbol,
      'marketDataMode': marketDataMode.name,
      'marketDataStatus': marketDataStatus.name,
      if (lastMarketUpdate != null)
        'lastMarketUpdate': Timestamp.fromDate(lastMarketUpdate!),
      'isActive': isActive,
      'isFeatured': isFeatured,
      'displayOrder': displayOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Resolves the percentage value from Firestore data.
  /// Prefers the new signed `priceChangePercent24h` field.
  /// Falls back to the legacy `percentageChange` + `changeDirection` pair
  /// so that existing Firestore documents are parsed correctly.
  static double _resolvePercentage(Map<String, dynamic> data) {
    if (data.containsKey('priceChangePercent24h') &&
        data['priceChangePercent24h'] != null) {
      return (data['priceChangePercent24h'] as num).toDouble();
    }
    // Legacy fallback
    final pct = (data['percentageChange'] as num? ?? 0).toDouble();
    final dir = data['changeDirection'] as String? ?? 'up';
    return dir == 'up' ? pct.abs() : -pct.abs();
  }

  static MarketDataMode _parseMode(String? value) {
    return MarketDataMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MarketDataMode.manual,
    );
  }

  static MarketDataStatus _parseStatus(String? value) {
    return MarketDataStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MarketDataStatus.disabled,
    );
  }

  // ── copyWith ─────────────────────────────────────────────────────────────

  CoinModel copyWith({
    String? coinId,
    String? name,
    String? symbol,
    String? logoUrl,
    double? latestPrice,
    double? priceChangePercent24h,
    String? binanceSymbol,
    MarketDataMode? marketDataMode,
    MarketDataStatus? marketDataStatus,
    DateTime? lastMarketUpdate,
    bool? isActive,
    bool? isFeatured,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoinModel(
      coinId: coinId ?? this.coinId,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      logoUrl: logoUrl ?? this.logoUrl,
      latestPrice: latestPrice ?? this.latestPrice,
      priceChangePercent24h:
          priceChangePercent24h ?? this.priceChangePercent24h,
      binanceSymbol: binanceSymbol ?? this.binanceSymbol,
      marketDataMode: marketDataMode ?? this.marketDataMode,
      marketDataStatus: marketDataStatus ?? this.marketDataStatus,
      lastMarketUpdate: lastMarketUpdate ?? this.lastMarketUpdate,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
