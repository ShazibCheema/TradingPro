import WebSocket from 'ws';
import { logger } from './logger.js';
import { validateAndParseTicker, ValidatedTickerData } from './data-validator.js';

export type TickerCallback = (data: ValidatedTickerData) => void;
export type StatusCallback = (connected: boolean) => void;

export class BinanceWebSocketClient {
  private wsBaseUrl: string;
  private maxReconnectDelayMs: number;
  private ws: WebSocket | null = null;
  private activeStreams: Set<string> = new Set(); // e.g. "btcusdt@ticker"

  private isClosedIntentionally = false;
  private isConnecting = false;
  private currentReconnectDelayMs = 1000;
  private reconnectTimer: NodeJS.Timeout | null = null;

  private pingTimer: NodeJS.Timeout | null = null;
  private requestCounter = 1;

  private onTickerReceived: TickerCallback;
  private onStatusChange?: StatusCallback;

  constructor(
    wsBaseUrl: string,
    onTickerReceived: TickerCallback,
    maxReconnectDelaySeconds = 30,
    onStatusChange?: StatusCallback
  ) {
    this.wsBaseUrl = wsBaseUrl;
    this.onTickerReceived = onTickerReceived;
    this.maxReconnectDelayMs = maxReconnectDelaySeconds * 1000;
    this.onStatusChange = onStatusChange;
  }

  /**
   * Sets or updates the active Binance stream list.
   * Format of streams parameter: lowercase Binance symbols, e.g. ["btcusdt", "ethusdt"]
   */
  public updateSubscriptions(binanceSymbols: string[]): void {
    const newStreams = new Set(binanceSymbols.map((s) => `${s.toLowerCase()}@ticker`));

    // Determine streams to add and remove
    const toAdd: string[] = [];
    const toRemove: string[] = [];

    for (const stream of newStreams) {
      if (!this.activeStreams.has(stream)) {
        toAdd.push(stream);
      }
    }

    for (const stream of this.activeStreams) {
      if (!newStreams.has(stream)) {
        toRemove.push(stream);
      }
    }

    this.activeStreams = newStreams;

    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      if (toRemove.length > 0) {
        this.sendFrame('UNSUBSCRIBE', toRemove);
        logger.info(`[MARKET] Unsubscribed: ${toRemove.join(', ')}`);
      }
      if (toAdd.length > 0) {
        this.sendFrame('SUBSCRIBE', toAdd);
        logger.info(`[MARKET] Subscribed: ${toAdd.join(', ')}`);
      }
    } else if (!this.ws && this.activeStreams.size > 0 && !this.isConnecting) {
      this.connect();
    }
  }

  /**
   * Initiates outbound WebSocket connection to Binance.
   */
  public connect(): void {
    if (this.isClosedIntentionally || this.isConnecting) return;
    if (this.activeStreams.size === 0) {
      logger.info('No active symbols to subscribe to. Waiting for subscription configuration.');
      return;
    }

    this.isConnecting = true;
    this.cleanupSocket();

    const streamList = Array.from(this.activeStreams).join('/');
    const url = `${this.wsBaseUrl}?streams=${streamList}`;

    logger.info(`Connecting to Binance WebSocket streams (${this.activeStreams.size} symbols)...`);

    try {
      this.ws = new WebSocket(url);

      this.ws.on('open', () => {
        this.isConnecting = false;
        this.currentReconnectDelayMs = 1000; // Reset exponential backoff delay on successful connect
        logger.info('Binance connection established');
        if (this.onStatusChange) this.onStatusChange(true);
        this.startPingLoop();
      });

      this.ws.on('message', (rawMsg: WebSocket.Data) => {
        try {
          const str = rawMsg.toString();
          const parsed = JSON.parse(str);

          // Handle Binance ticker event
          const validated = validateAndParseTicker(parsed);
          if (validated) {
            logger.debug(`Received ticker: ${validated.symbol}`);
            this.onTickerReceived(validated);
          }
        } catch (err) {
          logger.warn('Failed to parse Binance WebSocket message:', err);
        }
      });

      this.ws.on('ping', (data: Buffer) => {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
          this.ws.pong(data);
        }
      });

      this.ws.on('error', (err: Error) => {
        logger.error('Binance WebSocket error:', err.message);
      });

      this.ws.on('close', (code: number, reason: Buffer) => {
        this.isConnecting = false;
        logger.warn(`Binance disconnected (code: ${code}, reason: ${reason.toString() || 'none'})`);
        if (this.onStatusChange) this.onStatusChange(false);
        this.stopPingLoop();
        this.scheduleReconnect();
      });
    } catch (err) {
      this.isConnecting = false;
      logger.error('Exception creating Binance WebSocket:', err);
      this.scheduleReconnect();
    }
  }

  /**
   * Schedules reconnection using exponential backoff with max cap.
   */
  private scheduleReconnect(): void {
    if (this.isClosedIntentionally) return;
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);

    const delaySeconds = Math.round(this.currentReconnectDelayMs / 1000);
    logger.info(`Reconnecting in ${delaySeconds} seconds...`);

    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.connect();
    }, this.currentReconnectDelayMs);

    // Exponential backoff capped at maxReconnectDelayMs
    this.currentReconnectDelayMs = Math.min(this.currentReconnectDelayMs * 2, this.maxReconnectDelayMs);
  }

  /**
   * Sends SUBSCRIBE or UNSUBSCRIBE frame to Binance.
   */
  private sendFrame(method: 'SUBSCRIBE' | 'UNSUBSCRIBE', params: string[]): void {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return;
    const payload = {
      method,
      params,
      id: this.requestCounter++,
    };
    this.ws.send(JSON.stringify(payload));
  }

  private startPingLoop(): void {
    this.stopPingLoop();
    this.pingTimer = setInterval(() => {
      if (this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.ws.ping();
      }
    }, 180000); // 3 minutes heartbeat ping
  }

  private stopPingLoop(): void {
    if (this.pingTimer) {
      clearInterval(this.pingTimer);
      this.pingTimer = null;
    }
  }

  private cleanupSocket(): void {
    this.stopPingLoop();
    if (this.ws) {
      try {
        this.ws.removeAllListeners();
        this.ws.close();
      } catch (_) {
        // ignore cleanup errors
      }
      this.ws = null;
    }
  }

  /**
   * Graceful shutdown of WebSocket connection.
   */
  public close(): void {
    this.isClosedIntentionally = true;
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    this.cleanupSocket();
    logger.info('Binance WebSocket connection closed by application shutdown.');
  }
}
