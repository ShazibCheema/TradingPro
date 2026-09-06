import dotenv from 'dotenv';

dotenv.config();

export interface Config {
  firebaseProjectId: string;
  binanceMarketDataEnabled: boolean;
  binanceWsBaseUrl: string;
  firestoreUpdateIntervalMs: number;
  marketDataStaleAfterSeconds: number;
  marketDataReconnectionMaxDelaySeconds: number;
  subscriptionRefreshIntervalSeconds: number;
  port: number;
}

export const config: Config = {
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID || 'tradingpro-6c1ac',
  binanceMarketDataEnabled: process.env.BINANCE_MARKET_DATA_ENABLED !== 'false',
  binanceWsBaseUrl: process.env.BINANCE_WS_BASE_URL || 'wss://stream.binance.com:9443/stream',
  firestoreUpdateIntervalMs: parseInt(process.env.FIRESTORE_UPDATE_INTERVAL_MS || '1000', 10),
  marketDataStaleAfterSeconds: parseInt(process.env.MARKET_DATA_STALE_AFTER_SECONDS || '30', 10),
  marketDataReconnectionMaxDelaySeconds: parseInt(
    process.env.MARKET_DATA_RECONNECTION_MAX_DELAY_SECONDS || '30',
    10
  ),
  subscriptionRefreshIntervalSeconds: parseInt(
    process.env.SUBSCRIPTION_REFRESH_INTERVAL_SECONDS || '30',
    10
  ),
  port: parseInt(process.env.PORT || '8080', 10),
};
