# TradingPro: I&T — Real-Time Binance Market Data Setup Guide

This guide documents the architecture, configuration, local setup, and Google Cloud Run deployment for the TradingPro real-time Binance Spot market data feed.

---

## 1. Architecture Overview

```
                     BINANCE
                        │
                        │ Outbound Spot WebSocket
                        ▼
              ┌──────────────────┐
              │   Cloud Run      │
              │ Market Data      │
              │ Service          │
              └────────┬─────────┘
                       │
                       │ Firebase Admin SDK
                       ▼
                 FIRESTORE
                       │
             ┌─────────┴─────────┐
             │                   │
             ▼                   ▼
       ADMIN FLUTTER         USER FLUTTER
       Coin Management       Coin Listing
       Live Prices           Live Prices
       Featured Top 3        Featured Top 3
```

- **Outbound Connection:** The backend worker connects to Binance Spot WebSocket stream (`wss://stream.binance.com:9443/stream`).
- **No Client WebSocket:** Flutter apps (Admin & User) do NOT connect to Binance directly. Flutter clients listen to Firestore realtime streams.
- **Controlled Writes:** Raw Binance ticks are buffered in memory and throttled before writing to Firestore (`MARKET_DATA_FIRESTORE_UPDATE_INTERVAL_MS = 1000`).

---

## 2. Binance Data Source

- **Endpoint:** `wss://stream.binance.com:9443/stream?streams=btcusdt@ticker/ethusdt@ticker/...`
- **Data:** Public Binance 24hr Ticker Streams (`@ticker`). No API key or authentication required.
- **Stream Format:** Stream names must be **lowercase** (e.g., `btcusdt@ticker`).
- **Extracted Fields:**
  - `s`: Symbol (`BTCUSDT`)
  - `c`: Latest Price (`77424.05`)
  - `P`: 24h Percentage Change (`-1.24`)
  - `E`: Event Timestamp (`1672531199000`)

---

## 3. Firestore Schema

Collection: `coins/{coinId}`

```json
{
  "name": "Bitcoin",
  "symbol": "BTC/USDT",
  "logoUrl": "https://firebasestorage.googleapis.com/...",

  "binanceSymbol": "BTCUSDT",

  "latestPrice": 77424.05,
  "priceChangePercent24h": -1.24,

  "marketDataMode": "live",
  "marketDataStatus": "live",

  "lastMarketUpdate": "<Firestore Timestamp>",

  "isActive": true,
  "isFeatured": true,
  "displayOrder": 1,

  "createdAt": "<Timestamp>",
  "updatedAt": "<Timestamp>"
}
```

---

## 4. Market Data Modes & Health Statuses

### Market Data Modes (`marketDataMode`)
- `"live"`: Updated automatically by the Cloud Run backend from Binance ticks.
- `"manual"`: Admin manually configures `latestPrice` and `priceChangePercent24h`. Backend worker will **never** overwrite coins in manual mode.

### Market Data Statuses (`marketDataStatus`)
- `"live"`: Recent update received from Binance within `marketDataStaleAfterSeconds` (30s).
- `"stale"`: No update received for > 30 seconds.
- `"offline"`: Backend service or Binance connection unavailable.
- `"disabled"`: Coin is inactive or market data is disabled.

---

## 5. Local Development

### Prerequisites
- Node.js 20+ installed
- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase Service Account Key JSON (for local Firestore write access)

### Steps
1. Navigate to `/market-data-service`:
   ```bash
   cd market-data-service
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create `.env` file:
   ```bash
   cp .env.example .env
   ```
4. Set `GOOGLE_APPLICATION_CREDENTIALS` in `.env` pointing to your service account key JSON file:
   ```env
   FIREBASE_PROJECT_ID=tradingpro-6c1ac
   GOOGLE_APPLICATION_CREDENTIALS=./service-account-key.json
   FIRESTORE_UPDATE_INTERVAL_MS=1000
   ```
5. Run the service in development mode:
   ```bash
   npm run dev
   ```
6. Run unit tests:
   ```bash
   npm test
   ```

---

## 6. Google Cloud Run Deployment Setup

### Step 1: Enable Google Cloud APIs
Run using Google Cloud SDK / gcloud CLI:
```bash
gcloud services enable run.googleapis.com \
                       containerregistry.googleapis.com \
                       artifactregistry.googleapis.com \
                       --project tradingpro-6c1ac
```

### Step 2: Create Service Account & Grant Firestore Roles
```bash
# Create dedicated service account for Cloud Run worker
gcloud iam service-accounts create tradingpro-market-worker \
    --description="TradingPro Market Data Worker Identity" \
    --display-name="TradingPro Market Worker" \
    --project tradingpro-6c1ac

# Grant Datastore User (Firestore write access)
gcloud projects add-iam-policy-binding tradingpro-6c1ac \
    --member="serviceAccount:tradingpro-market-worker@tradingpro-6c1ac.iam.gserviceaccount.com" \
    --role="roles/datastore.user"
```

### Step 3: Build & Deploy Container to Cloud Run
From the project root:
```bash
# Build Docker image using Google Cloud Build
gcloud builds submit market-data-service \
    --tag gcr.io/tradingpro-6c1ac/market-data-service:latest \
    --project tradingpro-6c1ac

# Deploy to Cloud Run
gcloud run deploy tradingpro-market-data \
    --image gcr.io/tradingpro-6c1ac/market-data-service:latest \
    --region us-central1 \
    --platform managed \
    --service-account tradingpro-market-worker@tradingpro-6c1ac.iam.gserviceaccount.com \
    --set-env-vars FIREBASE_PROJECT_ID=tradingpro-6c1ac,FIRESTORE_UPDATE_INTERVAL_MS=1000,MARKET_DATA_STALE_AFTER_SECONDS=30 \
    --min-instances 1 \
    --max-instances 2 \
    --cpu 1 \
    --memory 512Mi \
    --allow-unauthenticated \
    --project tradingpro-6c1ac
```

> **Note:** `--min-instances 1` ensures the market worker stays continuously connected to Binance without cold starts.

---

## 7. How-To Operational Guides

### How to Add a Binance Coin
1. Log in to **TradingPro Admin App**.
2. Go to **Coin & Market Management**.
3. Click **Add Coin**.
4. Fill in:
   - **Symbol:** `BTC/USDT`
   - **Full Name:** `Bitcoin`
   - **Binance Symbol:** `BTCUSDT` (uppercase)
   - **Market Data Source:** Select **LIVE (Binance)**
   - **Active:** Switch **ON**
5. Click **Add Coin**.
6. Within ~30 seconds, the Cloud Run worker automatically detects the new live coin and subscribes to `btcusdt@ticker`.

### How to Enable / Disable a Coin
- Toggle **Active for Trading** switch in Admin Coin Management.
- When deactivated, the backend automatically drops the Binance stream subscription during the next subscription refresh cycle.

### How Top 3 Featured Coins Work
- Admin toggles **Featured (Top 3 on Home)** switch on any coin card.
- Enforces maximum 3 featured coins.
- User Home screen subscribes to `featuredCoinsProvider` which streams `isFeatured == true && isActive == true` ordered by `displayOrder`.

### How Manual / Live Mode Switch Works
- **LIVE -> MANUAL:** Switch source to MANUAL in Admin panel. The backend worker immediately stops overwriting this coin. Admin can enter fixed price and percentage.
- **MANUAL -> LIVE:** Switch source to LIVE. The backend worker sets status to `offline` and resumes writing live Binance values on the next tick.

---

## 8. Troubleshooting & Monitoring

### Check Container Health
- Send GET request to `https://<cloud-run-url>/health`
- Expected response:
  ```json
  {
    "status": "ok",
    "service": "tradingpro-market-data-service",
    "binanceConnected": true,
    "updateIntervalMs": 1000,
    "timestamp": "2026-09-02T18:30:00.000Z"
  }
  ```

### Inspect Cloud Run Logs
View structured logs in Google Cloud Logging with filter:
```text
resource.type="cloud_run_revision"
resource.labels.service_name="tradingpro-market-data"
textPayload=~"\[MARKET\]"
```

Look for key events:
- `[MARKET] Binance connection established`
- `[MARKET] Subscribed: BTCUSDT`
- `[MARKET] Subscription refresh`
- `[MARKET] Reconnecting in X seconds`
