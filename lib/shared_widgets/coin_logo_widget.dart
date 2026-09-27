import 'package:flutter/material.dart';
import 'package:tradingpro/core/theme/app_colors.dart';

/// A robust Coin Logo Widget designed for Mobile and Web platforms.
/// Handles CORS policies, empty image URLs, network timeouts, and
/// provides CDN fallbacks and coin-branded badges for top cryptocurrencies.
class CoinLogoWidget extends StatelessWidget {
  final String? logoUrl;
  final String symbol;
  final double size;

  const CoinLogoWidget({
    super.key,
    required this.logoUrl,
    required this.symbol,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final cleanSymbol = symbol
        .trim()
        .toUpperCase()
        .replaceAll('USDT', '')
        .replaceAll('USD', '');
    final activeSymbol =
        cleanSymbol.isEmpty ? symbol.trim().toUpperCase() : cleanSymbol;

    final hasCustomUrl = logoUrl != null && logoUrl!.trim().isNotEmpty;
    final primaryUrl =
        hasCustomUrl ? logoUrl!.trim() : _getFallbackCdnUrl(activeSymbol);

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.gray100,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: primaryUrl.isNotEmpty
            ? Image.network(
                primaryUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  final secondaryCdn = _getFallbackCdnUrl(activeSymbol);
                  if (primaryUrl != secondaryCdn && secondaryCdn.isNotEmpty) {
                    return Image.network(
                      secondaryCdn,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildInitialBadge(activeSymbol, size),
                    );
                  }
                  return _buildInitialBadge(activeSymbol, size);
                },
              )
            : _buildInitialBadge(activeSymbol, size),
      ),
    );
  }

  static String _getFallbackCdnUrl(String symbol) {
    final sym = symbol.toLowerCase();
    if (sym.isEmpty) return '';
    return 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/$sym.png';
  }

  Widget _buildInitialBadge(String symbol, double size) {
    final color = _getCoinColor(symbol);
    final letter = symbol.isNotEmpty ? symbol[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  static Color _getCoinColor(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'BTC':
        return const Color(0xFFF7931A);
      case 'ETH':
        return const Color(0xFF627EEA);
      case 'SOL':
        return const Color(0xFF14F195);
      case 'BNB':
        return const Color(0xFFF3BA2F);
      case 'USDT':
      case 'USDC':
        return const Color(0xFF26A17B);
      case 'XRP':
        return const Color(0xFF23292F);
      case 'ADA':
        return const Color(0xFF0033AD);
      case 'DOGE':
        return const Color(0xFFC2A633);
      case 'TRX':
        return const Color(0xFFEB0029);
      case 'AVAX':
        return const Color(0xFFE84142);
      case 'LINK':
        return const Color(0xFF375BD2);
      case 'DOT':
        return const Color(0xFFE6007A);
      case 'MATIC':
      case 'POL':
        return const Color(0xFF8247E5);
      case 'LTC':
        return const Color(0xFF345D9D);
      case 'SHIB':
        return const Color(0xFFFFA409);
      default:
        return AppColors.primary;
    }
  }
}
