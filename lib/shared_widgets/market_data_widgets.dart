import 'package:flutter/material.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';
import 'package:tradingpro/models/coin_model.dart';

// ─── Market Status Badge ─────────────────────────────────────────────────────

/// A small pill badge that shows the current market data status of a coin.
///
/// Appearance:
///   ● LIVE    → green dot + green text
///   ● STALE   → amber dot + amber text
///   ● OFFLINE → red dot + red text
///   ● DISABLED → grey dot + grey text
class MarketStatusBadge extends StatelessWidget {
  final MarketDataStatus status;
  final bool compact;

  const MarketStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label) = _resolve(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 5 : 6,
            height: compact ? 5 : 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, String) _resolve(MarketDataStatus status) {
    switch (status) {
      case MarketDataStatus.live:
        return (const Color(0xFF16A34A), 'LIVE');
      case MarketDataStatus.stale:
        return (const Color(0xFFD97706), 'STALE');
      case MarketDataStatus.offline:
        return (const Color(0xFFDC2626), 'OFFLINE');
      case MarketDataStatus.disabled:
        return (const Color(0xFF6B7280), 'DISABLED');
    }
  }
}

// ─── Market Data Info Row ────────────────────────────────────────────────────

/// Shows the market status badge + a "last updated" timestamp in one row.
/// Used in the admin coin list and admin coin dialog.
class MarketDataInfoRow extends StatelessWidget {
  final CoinModel coin;

  const MarketDataInfoRow({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    final isLive = coin.marketDataMode == MarketDataMode.live;
    return Row(
      children: [
        if (isLive) ...[
          MarketStatusBadge(status: coin.marketDataStatus, compact: true),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              AppFormatters.marketDataAge(coin.lastMarketUpdate),
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF6B7280),
                fontFamily: 'Inter',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF6B7280).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'MANUAL',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
                fontFamily: 'Inter',
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Stale Data Indicator ────────────────────────────────────────────────────

/// A subtle inline indicator shown on coin rows when data is not live-fresh.
/// Shows nothing when data is live or coin is in manual mode.
class StaleDataIndicator extends StatelessWidget {
  final CoinModel coin;

  const StaleDataIndicator({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    // Manual mode coins intentionally don't show a stale indicator.
    if (coin.marketDataMode == MarketDataMode.manual) return const SizedBox.shrink();
    if (coin.marketDataStatus == MarketDataStatus.live) return const SizedBox.shrink();

    final (color, label) = switch (coin.marketDataStatus) {
      MarketDataStatus.stale => (const Color(0xFFD97706), 'Data delayed'),
      MarketDataStatus.offline => (const Color(0xFFDC2626), 'Offline'),
      MarketDataStatus.disabled => (const Color(0xFF9CA3AF), 'Disabled'),
      _ => (const Color(0xFF9CA3AF), ''),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning_amber_rounded, size: 10, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Market Data Mode Selector ───────────────────────────────────────────────

/// Toggle row for LIVE / MANUAL mode used in the admin coin dialog.
class MarketDataModeSelector extends StatelessWidget {
  final MarketDataMode value;
  final ValueChanged<MarketDataMode> onChanged;

  const MarketDataModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ModeOption(
          label: 'LIVE (Binance)',
          icon: Icons.bolt_rounded,
          selected: value == MarketDataMode.live,
          color: const Color(0xFF16A34A),
          onTap: () => onChanged(MarketDataMode.live),
        ),
        const SizedBox(width: 10),
        _ModeOption(
          label: 'MANUAL',
          icon: Icons.edit_rounded,
          selected: value == MarketDataMode.manual,
          color: const Color(0xFF6B7280),
          onTap: () => onChanged(MarketDataMode.manual),
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? color : const Color(0xFF6B7280)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : const Color(0xFF374151),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
