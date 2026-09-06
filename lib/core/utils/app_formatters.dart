import 'package:intl/intl.dart';

/// Centralized financial and date formatting utilities
class AppFormatters {
  AppFormatters._();

  static final _currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final _compactFormatter = NumberFormat.compact(locale: 'en_US');

  // ─── Currency ─────────────────────────────────────────────────────────────
  /// Format: $1,250.00
  static String currency(double amount) {
    return _currencyFormatter.format(amount);
  }

  /// Format with sign: +$250.00 or -$50.00
  static String currencyWithSign(double amount) {
    final formatted = _currencyFormatter.format(amount.abs());
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }

  /// Format profit (always with sign)
  static String profit(double amount) => currencyWithSign(amount);

  // ─── Crypto ───────────────────────────────────────────────────────────────
  /// Format crypto price with appropriate decimals
  static String cryptoPrice(double price) {
    if (price >= 1000) {
      return NumberFormat('#,##0.00').format(price);
    } else if (price >= 1) {
      return NumberFormat('#,##0.0000').format(price);
    } else {
      return NumberFormat('#,##0.00000').format(price);
    }
  }

  /// Format percentage change: +1.48% or -3.08%
  static String percentageChange(double pct) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(2)}%';
  }

  // ─── Dates ────────────────────────────────────────────────────────────────
  /// Format: 26 Aug 2026
  static String date(DateTime dt) {
    return DateFormat('d MMM y').format(dt);
  }

  /// Format: 26 Aug 2026, 10:35 AM
  static String dateTime(DateTime dt) {
    return DateFormat('d MMM y, h:mm a').format(dt);
  }

  /// Format: 10:35 AM
  static String time(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  // ─── User ID ──────────────────────────────────────────────────────────────
  /// Display user ID with spacing for readability
  static String userId(String id) => id;

  // ─── Compact ─────────────────────────────────────────────────────────────
  /// Format: 1.2K, 5.4M
  static String compact(double value) => _compactFormatter.format(value);

  // ─── Market Data Age ───────────────────────────────────────────────────
  /// Converts a nullable [lastUpdate] DateTime into a human-readable
  /// relative time string suitable for market data freshness display.
  /// Returns 'Never updated' if null.
  static String marketDataAge(DateTime? lastUpdate) {
    if (lastUpdate == null) return 'Never updated';
    final diff = DateTime.now().difference(lastUpdate);
    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return date(lastUpdate);
  }

  /// Format crypto price with a custom decimal precision.
  /// Use for coins where you want to override the auto-precision logic.
  static String cryptoPriceWithPrecision(double price, int decimals) {
    final pattern = decimals == 0
        ? '#,##0'
        : '#,##0.${'0' * decimals}';
    return NumberFormat(pattern).format(price);
  }
}
