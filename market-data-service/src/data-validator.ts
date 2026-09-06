import { logger } from './logger.js';

export interface BinanceRawTicker {
  e?: string; // Event type ("24hrTicker")
  E?: number; // Event time (timestamp ms)
  s?: string; // Symbol (e.g. "BTCUSDT")
  c?: string; // Close price (latest price)
  P?: string; // Price change percent 24h
  v?: string; // Total traded base asset volume
}

export interface ValidatedTickerData {
  symbol: string; // Uppercase (e.g. "BTCUSDT")
  latestPrice: number; // e.g. 77424.05
  priceChangePercent24h: number; // e.g. -1.24
  eventTimestamp: Date;
}

/**
 * Validates raw Binance WebSocket ticker payload.
 * Returns ValidatedTickerData if valid, or null if rejected.
 */
export function validateAndParseTicker(rawPayload: unknown): ValidatedTickerData | null {
  if (!rawPayload || typeof rawPayload !== 'object') {
    logger.warn('Malformed ticker data: payload is not an object');
    return null;
  }

  // Binance stream wrapper format: { stream: "btcusdt@ticker", data: { ... } }
  const obj = rawPayload as Record<string, unknown>;
  const ticker: BinanceRawTicker = (obj.data && typeof obj.data === 'object' ? obj.data : obj) as BinanceRawTicker;

  // 1. Symbol validation
  if (!ticker.s || typeof ticker.s !== 'string' || ticker.s.trim().length === 0) {
    logger.warn('Malformed ticker data: missing or invalid symbol');
    return null;
  }
  const symbol = ticker.s.trim().toUpperCase();

  // 2. Price validation
  if (ticker.c === undefined || ticker.c === null || typeof ticker.c !== 'string') {
    logger.warn(`Malformed ticker data for ${symbol}: missing latest price ('c')`);
    return null;
  }
  const price = parseFloat(ticker.c);
  if (isNaN(price) || !isFinite(price) || price <= 0) {
    logger.warn(`Malformed ticker data for ${symbol}: invalid price value '${ticker.c}'`);
    return null;
  }

  // 3. 24h Percentage validation
  if (ticker.P === undefined || ticker.P === null || typeof ticker.P !== 'string') {
    logger.warn(`Malformed ticker data for ${symbol}: missing 24h percentage ('P')`);
    return null;
  }
  const percent = parseFloat(ticker.P);
  if (isNaN(percent) || !isFinite(percent)) {
    logger.warn(`Malformed ticker data for ${symbol}: invalid percentage value '${ticker.P}'`);
    return null;
  }

  // 4. Timestamp validation
  let eventTimestamp = new Date();
  if (typeof ticker.E === 'number' && ticker.E > 0 && isFinite(ticker.E)) {
    eventTimestamp = new Date(ticker.E);
  }

  return {
    symbol,
    latestPrice: price,
    priceChangePercent24h: percent,
    eventTimestamp,
  };
}
