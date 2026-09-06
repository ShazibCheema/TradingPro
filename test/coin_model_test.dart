import 'package:flutter_test/flutter_test.dart';
import 'package:tradingpro/models/coin_model.dart';
import 'package:tradingpro/core/utils/app_formatters.dart';

void main() {
  group('CoinModel Serialization & Market Data Tests', () {
    test('Correctly resolves new live market fields', () {
      final now = DateTime.now();
      final coin = CoinModel(
        coinId: 'btc_id',
        name: 'Bitcoin',
        symbol: 'BTC/USDT',
        logoUrl: 'https://example.com/btc.png',
        latestPrice: 77424.05,
        priceChangePercent24h: -1.24,
        binanceSymbol: 'BTCUSDT',
        marketDataMode: MarketDataMode.live,
        marketDataStatus: MarketDataStatus.live,
        lastMarketUpdate: now,
        isActive: true,
        isFeatured: true,
        displayOrder: 1,
        createdAt: now,
        updatedAt: now,
      );

      expect(coin.isPositive, false);
      expect(coin.percentageChange, 1.24);
      expect(coin.changeDirection, ChangeDirection.down);
      expect(coin.isLiveDataFresh, true);
      expect(coin.hasPrice, true);
      expect(coin.binanceSymbol, 'BTCUSDT');
    });

    test('Derived fields work correctly for positive percentage change', () {
      final coin = CoinModel(
        coinId: 'eth_id',
        name: 'Ethereum',
        symbol: 'ETH/USDT',
        latestPrice: 2438.28,
        priceChangePercent24h: 3.08,
        binanceSymbol: 'ETHUSDT',
        marketDataMode: MarketDataMode.live,
        marketDataStatus: MarketDataStatus.live,
        isActive: true,
        isFeatured: true,
        displayOrder: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(coin.isPositive, true);
      expect(coin.percentageChange, 3.08);
      expect(coin.changeDirection, ChangeDirection.up);
    });

    test('AppFormatters cryptoPrice and percentageChange output format', () {
      expect(AppFormatters.cryptoPrice(77424.05), '77,424.05');
      expect(AppFormatters.cryptoPrice(1.5798), '1.5798');
      expect(AppFormatters.cryptoPrice(0.09115), '0.09115');

      expect(AppFormatters.percentageChange(-1.24), '-1.24%');
      expect(AppFormatters.percentageChange(3.08), '+3.08%');
      expect(AppFormatters.percentageChange(0.00), '+0.00%');
    });

    test('AppFormatters marketDataAge returns expected relative time string', () {
      expect(AppFormatters.marketDataAge(null), 'Never updated');
      expect(
        AppFormatters.marketDataAge(
            DateTime.now().subtract(const Duration(seconds: 2))),
        'Just now',
      );
      expect(
        AppFormatters.marketDataAge(
            DateTime.now().subtract(const Duration(seconds: 25))),
        '25s ago',
      );
      expect(
        AppFormatters.marketDataAge(
            DateTime.now().subtract(const Duration(minutes: 5))),
        '5m ago',
      );
    });
  });
}
