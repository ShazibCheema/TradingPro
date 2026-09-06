import { describe, test, expect } from '@jest/globals';
import { validateAndParseTicker } from '../data-validator.js';

describe('Data Validator Unit Tests', () => {
  test('Validates and parses valid Binance ticker payload', () => {
    const rawPayload = {
      stream: 'btcusdt@ticker',
      data: {
        e: '24hrTicker',
        E: 1672531199000,
        s: 'BTCUSDT',
        c: '77424.05',
        P: '-1.24',
      },
    };

    const result = validateAndParseTicker(rawPayload);

    expect(result).not.toBeNull();
    expect(result?.symbol).toBe('BTCUSDT');
    expect(result?.latestPrice).toBe(77424.05);
    expect(result?.priceChangePercent24h).toBe(-1.24);
    expect(result?.eventTimestamp).toEqual(new Date(1672531199000));
  });

  test('Parses raw ticker object without stream wrapper', () => {
    const rawTicker = {
      s: 'ethusdt',
      c: '2438.28',
      P: '3.08',
    };

    const result = validateAndParseTicker(rawTicker);

    expect(result).not.toBeNull();
    expect(result?.symbol).toBe('ETHUSDT');
    expect(result?.latestPrice).toBe(2438.28);
    expect(result?.priceChangePercent24h).toBe(3.08);
  });

  test('Rejects payload with missing or zero price', () => {
    const invalidPricePayload = {
      s: 'XRPUSDT',
      c: '0.00',
      P: '1.20',
    };

    const result = validateAndParseTicker(invalidPricePayload);
    expect(result).toBeNull();
  });

  test('Rejects payload with non-numeric price', () => {
    const invalidPricePayload = {
      s: 'XRPUSDT',
      c: 'invalid_price',
      P: '1.20',
    };

    const result = validateAndParseTicker(invalidPricePayload);
    expect(result).toBeNull();
  });

  test('Rejects payload with missing symbol', () => {
    const missingSymbolPayload = {
      c: '100.00',
      P: '2.5',
    };

    const result = validateAndParseTicker(missingSymbolPayload);
    expect(result).toBeNull();
  });

  test('Rejects null or non-object payloads', () => {
    expect(validateAndParseTicker(null)).toBeNull();
    expect(validateAndParseTicker(undefined)).toBeNull();
    expect(validateAndParseTicker('invalid_string')).toBeNull();
  });
});
