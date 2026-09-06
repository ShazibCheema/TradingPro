import http from 'http';
import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { config } from './config.js';
import { logger } from './logger.js';
import { FirestoreWriter } from './firestore-writer.js';
import { BinanceWebSocketClient } from './binance-client.js';
import { SubscriptionManager } from './subscription-manager.js';

// ─── Firebase Admin SDK Initialization ────────────────────────────────────────

function initFirebase() {
  if (getApps().length === 0) {
    logger.info(`Initializing Firebase Admin SDK for project ${config.firebaseProjectId}...`);
    initializeApp({
      projectId: config.firebaseProjectId,
    });
  }
  return getFirestore();
}

async function bootstrap() {
  logger.info('====================================================');
  logger.info('Starting TradingPro Binance Spot Market Data Service');
  logger.info('====================================================');

  if (!config.binanceMarketDataEnabled) {
    logger.warn('BINANCE_MARKET_DATA_ENABLED is set to false. Worker will run in idle mode.');
  }

  const db = initFirebase();

  // 1. Initialize Firestore Writer (throttled updates)
  const writer = new FirestoreWriter(db, config.firestoreUpdateIntervalMs);
  writer.startPeriodicFlush();

  // 2. Initialize Binance WebSocket Client
  let isBinanceConnected = false;
  const binanceClient = new BinanceWebSocketClient(
    config.binanceWsBaseUrl,
    (ticker) => writer.handleTickerUpdate(ticker),
    config.marketDataReconnectionMaxDelaySeconds,
    (connected) => {
      isBinanceConnected = connected;
    }
  );

  // 3. Initialize Subscription Manager (polls Firestore for active live coins)
  const subscriptionManager = new SubscriptionManager(
    db,
    binanceClient,
    writer,
    config.subscriptionRefreshIntervalSeconds
  );

  await subscriptionManager.start();

  // Start Binance connection if active symbols exist
  if (config.binanceMarketDataEnabled) {
    binanceClient.connect();
  }

  // 4. Lightweight HTTP Server for Cloud Run Port Health Checks
  const server = http.createServer((req, res) => {
    if (req.url === '/health' || req.url === '/') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(
        JSON.stringify({
          status: 'ok',
          service: 'tradingpro-market-data-service',
          binanceConnected: isBinanceConnected,
          updateIntervalMs: config.firestoreUpdateIntervalMs,
          timestamp: new Date().toISOString(),
        })
      );
    } else {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Not Found');
    }
  });

  server.listen(config.port, () => {
    logger.info(`Market Data Service healthcheck server listening on port ${config.port}`);
  });

  // 5. Graceful Shutdown Signal Handlers
  const shutdown = () => {
    logger.info('Shutting down Market Data Service...');
    subscriptionManager.stop();
    writer.stopPeriodicFlush();
    binanceClient.close();
    server.close(() => {
      logger.info('HTTP server closed. Exiting.');
      process.exit(0);
    });
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

bootstrap().catch((err) => {
  logger.error('Fatal error starting Market Data Service:', err);
  process.exit(1);
});
