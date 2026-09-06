import { Firestore } from 'firebase-admin/firestore';
import { BinanceWebSocketClient } from './binance-client.js';
import { FirestoreWriter, CoinDocInfo } from './firestore-writer.js';
import { logger } from './logger.js';

export class SubscriptionManager {
  private db: Firestore;
  private binanceClient: BinanceWebSocketClient;
  private writer: FirestoreWriter;
  private refreshIntervalMs: number;
  private refreshTimer: NodeJS.Timeout | null = null;
  private isRefreshing = false;

  constructor(
    db: Firestore,
    binanceClient: BinanceWebSocketClient,
    writer: FirestoreWriter,
    refreshIntervalSeconds = 30
  ) {
    this.db = db;
    this.binanceClient = binanceClient;
    this.writer = writer;
    this.refreshIntervalMs = refreshIntervalSeconds * 1000;
  }

  /**
   * Performs an initial fetch of active live coins from Firestore and starts periodic reconciliation.
   */
  public async start(): Promise<void> {
    await this.refreshSubscriptions();

    if (!this.refreshTimer) {
      this.refreshTimer = setInterval(() => {
        this.refreshSubscriptions().catch((err) => {
          logger.error('Error during periodic subscription refresh:', err);
        });
      }, this.refreshIntervalMs);
    }
  }

  /**
   * Queries Firestore for all active coins in live market mode, normalizes symbols,
   * updates the FirestoreWriter coin mapping, and updates Binance WebSocket subscriptions.
   */
  public async refreshSubscriptions(): Promise<void> {
    if (this.isRefreshing) return;
    this.isRefreshing = true;

    try {
      logger.info('Subscription refresh');

      const snapshot = await this.db
        .collection('coins')
        .where('isActive', '==', true)
        .get();

      const activeLiveCoins: CoinDocInfo[] = [];
      const binanceSymbols: string[] = [];

      snapshot.forEach((doc) => {
        const data = doc.data();
        const binanceSymbol = (data.binanceSymbol as string | undefined)?.trim().toUpperCase() || '';
        const marketDataMode = (data.marketDataMode as string | undefined) || 'manual';

        const coinDoc: CoinDocInfo = {
          id: doc.id,
          symbol: data.symbol || '',
          binanceSymbol,
          marketDataMode: marketDataMode === 'live' ? 'live' : 'manual',
          isActive: data.isActive === true,
        };

        if (coinDoc.isActive && coinDoc.marketDataMode === 'live' && binanceSymbol) {
          activeLiveCoins.push(coinDoc);
          binanceSymbols.push(binanceSymbol);
        }
      });

      // Update writer symbol map
      this.writer.updateCoinMap(activeLiveCoins);

      // Update WebSocket client subscriptions (converts to lowercase streams internally)
      this.binanceClient.updateSubscriptions(binanceSymbols);
    } catch (err) {
      logger.error('Failed to query coins collection from Firestore:', err);
    } finally {
      this.isRefreshing = false;
    }
  }

  /**
   * Stops periodic subscription refresh timer.
   */
  public stop(): void {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = null;
    }
  }
}
