/**
 * Structured Logger for TradingPro Market Data Service.
 * Prefix: [MARKET]
 * Controls debug vs info vs error levels.
 */

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

const currentLogLevel = process.env.LOG_LEVEL === 'debug' ? LogLevel.DEBUG : LogLevel.INFO;

export const logger = {
  debug: (message: string, ...args: unknown[]) => {
    if (currentLogLevel <= LogLevel.DEBUG) {
      console.log(`[MARKET] [DEBUG] ${message}`, ...args);
    }
  },

  info: (message: string, ...args: unknown[]) => {
    if (currentLogLevel <= LogLevel.INFO) {
      console.log(`[MARKET] ${message}`, ...args);
    }
  },

  warn: (message: string, ...args: unknown[]) => {
    if (currentLogLevel <= LogLevel.WARN) {
      console.warn(`[MARKET] [WARN] ${message}`, ...args);
    }
  },

  error: (message: string, ...args: unknown[]) => {
    if (currentLogLevel <= LogLevel.ERROR) {
      console.error(`[MARKET] [ERROR] ${message}`, ...args);
    }
  },
};
