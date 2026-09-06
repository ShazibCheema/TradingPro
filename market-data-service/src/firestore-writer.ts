import { Firestore, FieldValue } from 'firebase-admin/firestore';
import { ValidatedTickerData } from './data-validator.js';
import { logger } from './logger.js';

export interface CoinDocInfo {
  id: string;
  symbol: string;
  binanceSymbol: string;
  marketDataMode: 'live' | 'manual';
  isActive: boolean;
}

export class FirestoreWriter {
  private db: Firestore;
  private updateIntervalMs: number;

  // In-memory cache of last processed data per binanceSymbol (UPPERCASE)
  private latestBuffer: Map<string, ValidatedTickerData> = new Map();

  // Map of binanceSymbol -> last Firestore write timestamp (ms)
  private lastWriteTimestamp: Map<string, number> = new Map();

  // Active coin document mappings (binanceSymbol -> CoinDocInfo)
  private coinDocMap: Map<string, CoinDocInfo> = new Map();

  // Periodic flush timer handle
  private flushTimer: NodeJS.Timeout | null = null;

  constructor(db: Firestore, updateIntervalMs = 1000) {
    this.db = db;
    this.updateIntervalMs = updateIntervalMs;
  }

  /**
   * Updates the in-memory active coin document map.
   */
  public updateCoinMap(coins: CoinDocInfo[]): void {
    const newMap = new Map<string, CoinDocInfo>();
    for (const coin of coins) {
      if (coin.binanceSymbol) {
        newMap.set(coin.binanceSymbol.toUpperCase(), coin);
      }
    }
    this.coinDocMap = newMap;
  }

  /**
   * Enqueues a validated ticker tick into memory and triggers throttled write if interval has passed.
   */
  public handleTickerUpdate(ticker: ValidatedTickerData): void {
    const symbolKey = ticker.symbol.toUpperCase();
    const docInfo = this.coinDocMap.get(symbolKey);

    if (!docInfo) {
      // Symbol not active or not configured in Firestore
      return;
    }

    // Spec Requirement 7 & 29: NEVER overwrite coins in manual mode.
    if (docInfo.marketDataMode !== 'live') {
      return;
    }

    // Buffer latest ticker in memory
    this.latestBuffer.set(symbolKey, ticker);

    // Check throttle interval
    const now = Date.now();
    const lastWrite = this.lastWriteTimestamp.get(symbolKey) || 0;

    if (now - lastWrite >= this.updateIntervalMs) {
      this.writeCoinToFirestore(symbolKey);
    }
  }

  /**
   * Starts periodic timer to flush any buffered ticks that haven't been written yet.
   */
  public startPeriodicFlush(): void {
    if (this.flushTimer) return;
    this.flushTimer = setInterval(() => {
      this.flushAllBuffered();
    }, this.updateIntervalMs);
  }

  /**
   * Stops periodic flush timer.
   */
  public stopPeriodicFlush(): void {
    if (this.flushTimer) {
      clearInterval(this.flushTimer);
      this.flushTimer = null;
    }
  }

  /**
   * Flushes all buffered symbols to Firestore.
   */
  public async flushAllBuffered(): Promise<void> {
    const now = Date.now();
    for (const [symbolKey, lastWrite] of this.lastWriteTimestamp.entries()) {
      if (now - lastWrite >= this.updateIntervalMs && this.latestBuffer.has(symbolKey)) {
        await this.writeCoinToFirestore(symbolKey);
      }
    }
  }

  /**
   * Writes the buffered value for a single coin to Firestore.
   */
  private async writeCoinToFirestore(symbolKey: string): Promise<void> {
    const ticker = this.latestBuffer.get(symbolKey);
    const docInfo = this.coinDocMap.get(symbolKey);

    if (!ticker || !docInfo) return;

    // Double check mode requirement
    if (docInfo.marketDataMode !== 'live') {
      this.latestBuffer.delete(symbolKey);
      return;
    }

    // Mark write timestamp immediately to enforce interval throttle
    this.lastWriteTimestamp.set(symbolKey, Date.now());
    this.latestBuffer.delete(symbolKey);

    try {
      await this.db.collection('coins').doc(docInfo.id).update({
        latestPrice: ticker.latestPrice,
        priceChangePercent24h: ticker.priceChangePercent24h,
        marketDataStatus: 'live',
        lastMarketUpdate: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      logger.debug(`Firestore update: ${symbolKey} -> $${ticker.latestPrice} (${ticker.priceChangePercent24h}%)`);
    } catch (err) {
      logger.error(`Failed to update Firestore for ${symbolKey} (doc ${docInfo.id}):`, err);
    }
  }
}
