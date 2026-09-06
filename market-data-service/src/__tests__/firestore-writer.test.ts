import { describe, test, expect, beforeEach, jest } from '@jest/globals';
import { FirestoreWriter, CoinDocInfo } from '../firestore-writer.js';
import { ValidatedTickerData } from '../data-validator.js';

describe('Firestore Writer Unit Tests', () => {
  let mockUpdate: any;
  let mockDoc: any;
  let mockCollection: any;
  let mockDb: any;

  beforeEach(() => {
    mockUpdate = jest.fn().mockImplementation(() => Promise.resolve());
    mockDoc = jest.fn().mockReturnValue({ update: mockUpdate });
    mockCollection = jest.fn().mockReturnValue({ doc: mockDoc });
    mockDb = { collection: mockCollection };
  });

  test('Writes live coin ticker data to Firestore', async () => {
    const writer = new FirestoreWriter(mockDb, 1000);

    const coins: CoinDocInfo[] = [
      {
        id: 'btc_doc_id',
        symbol: 'BTC/USDT',
        binanceSymbol: 'BTCUSDT',
        marketDataMode: 'live',
        isActive: true,
      },
    ];

    writer.updateCoinMap(coins);

    const ticker: ValidatedTickerData = {
      symbol: 'BTCUSDT',
      latestPrice: 77424.05,
      priceChangePercent24h: -1.24,
      eventTimestamp: new Date(),
    };

    writer.handleTickerUpdate(ticker);

    expect(mockCollection).toHaveBeenCalledWith('coins');
    expect(mockDoc).toHaveBeenCalledWith('btc_doc_id');
    expect(mockUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        latestPrice: 77424.05,
        priceChangePercent24h: -1.24,
        marketDataStatus: 'live',
      })
    );
  });

  test('Does NOT write updates for coins in manual mode', async () => {
    const writer = new FirestoreWriter(mockDb, 1000);

    const coins: CoinDocInfo[] = [
      {
        id: 'manual_coin_id',
        symbol: 'DOGE/USDT',
        binanceSymbol: 'DOGEUSDT',
        marketDataMode: 'manual',
        isActive: true,
      },
    ];

    writer.updateCoinMap(coins);

    const ticker: ValidatedTickerData = {
      symbol: 'DOGEUSDT',
      latestPrice: 0.09115,
      priceChangePercent24h: 5.2,
      eventTimestamp: new Date(),
    };

    writer.handleTickerUpdate(ticker);

    expect(mockUpdate).not.toHaveBeenCalled();
  });

  test('Throttles rapid consecutive updates for the same coin', async () => {
    const writer = new FirestoreWriter(mockDb, 1000);

    const coins: CoinDocInfo[] = [
      {
        id: 'btc_doc_id',
        symbol: 'BTC/USDT',
        binanceSymbol: 'BTCUSDT',
        marketDataMode: 'live',
        isActive: true,
      },
    ];

    writer.updateCoinMap(coins);

    const ticker1: ValidatedTickerData = {
      symbol: 'BTCUSDT',
      latestPrice: 77424.05,
      priceChangePercent24h: -1.24,
      eventTimestamp: new Date(),
    };

    const ticker2: ValidatedTickerData = {
      symbol: 'BTCUSDT',
      latestPrice: 77425.10,
      priceChangePercent24h: -1.23,
      eventTimestamp: new Date(),
    };

    writer.handleTickerUpdate(ticker1);
    writer.handleTickerUpdate(ticker2); // Fired immediately within 1000ms

    // Should only have been written once immediately; 2nd tick is buffered
    expect(mockUpdate).toHaveBeenCalledTimes(1);
    expect(mockUpdate).toHaveBeenLastCalledWith(
      expect.objectContaining({
        latestPrice: 77424.05,
      })
    );
  });
});
