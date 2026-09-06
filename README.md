# TradingPro: I&T — Investing & Trading Platform

[![Flutter CI](https://github.com/tradingpro/tradingpro-it/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/tradingpro/tradingpro-it/actions)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Functions%20%7C%20Firestore%20%7C%20Auth-FFCA28?logo=firebase)](https://firebase.google.com)
[![Currency](https://img.shields.io/badge/Currency-USD%20%28%24%29-16A34A)](#)

**TradingPro: I&T (Investing & Trading)** is an admin-managed, enterprise-grade investment and cryptocurrency trading platform built with a **single Flutter codebase** targeting **Android, iOS, Web, and Tablet/Desktop**, powered by an atomic **Firebase Cloud Functions backend**.

---

## 🌟 Core Architecture Highlights

* **Zero-Trust Client Security**: All account balances, ledger mutations, profit awards, deposit approvals, withdrawal settlements, and trade results are processed exclusively on the server via Firebase Cloud Functions with atomic Firestore transactions.
* **Denominated in USD**: All calculations, displays, fees, minimum limits, and ledger balances are strictly denominated in USD (`$`).
* **Atomic 7-Digit User IDs**: Automatically generated sequentially (e.g. `5832147`) on user registration with collision-free transactions.
* **Role-Based Admin Access**: Admin portal access is guarded by Firebase Auth Custom Claims (`superAdmin`, `admin`, `supportAdmin`, `financeAdmin`).
* **Interactive Financial Charts**: Cubic spline charts with gradient fills, min/max scaling, and touch tooltips powered by `fl_chart`.
* **Automated Support Auto-Close**: Scheduled 30-minute inactivity timer that closes stale chats and allows seamless reopening upon user message.
* **Offline Connectivity Guard**: Real-time network watcher with animated offline banner across both mobile and web.
* **Financial CSV Statement Exporter**: One-tap statement generator with preview and clipboard copy.

---

## 📁 Repository Directory Map

```text
TradingPro/
├── lib/
│   ├── core/
│   │   ├── constants/           # AppConstants & collection identifiers
│   │   ├── theme/               # Material 3 Theme, AppColors (Purple #6C3FE0), AppTextStyles
│   │   └── utils/               # AppFormatters ($ USD, Crypto pricing, PnL), AppValidators
│   ├── models/                  # Freezed & Firestore models:
│   │                            # UserModel, CoinModel, DepositModel, WithdrawalModel,
│   │                            # TradeModel, TransactionModel, NotificationModel,
│   │                            # SupportModels, SettingsModels, AuditLogModel, AdminNotificationModel
│   ├── repositories/            # Data layer (Auth, User, Coin, Deposit, Withdrawal, Trade,
│   │                            # Notification, Support, Settings, Admin)
│   ├── providers/               # Centralized Riverpod State Management Providers
│   ├── router/
│   │   ├── user_router.dart     # GoRouter configuration for User App with Auth Guards
│   │   └── admin_router.dart    # GoRouter configuration for 10-destination Admin Portal
│   ├── services/
│   │   ├── notification_service.dart # FCM push notification handler, local alerts, token sync
│   │   ├── connectivity_service.dart # Real-time online/offline detector & Animated Offline Banner
│   │   ├── analytics_service.dart    # Event tracking & Crashlytics exception pipeline
│   │   ├── app_check_service.dart    # Play Integrity, DeviceCheck & ReCaptcha v3 attestation
│   │   ├── export_service.dart       # CSV financial account statement & ledger generator
│   │   └── session_lock_service.dart # Inactivity security auto-lock manager
│   ├── shared_widgets/          # UI Components (Buttons, Badges, Skeleton loaders, Dialogs, Shells)
│   │   ├── price_chart.dart     # Interactive LineChart with touch tooltips & MiniSparklines
│   │   └── skeleton_widgets.dart# Shimmer skeleton loading cards & lists
│   ├── features/
│   │   ├── auth/                # User Login, Registration (Atomic 7-Digit ID), Forgot Password
│   │   ├── home/                # Top 3 Featured Coins with Sparklines, Balance Card, Quick Actions, Live Market
│   │   ├── account/             # Balance Header, Transaction Ledger Filter Tabs, CSV Statement Export
│   │   ├── inbox/               # Real-time notifications with unread states & mark-all-read
│   │   ├── profile/             # Profile overview, Settings, Change Password, Saved Wallet Addresses
│   │   ├── deposit/             # Crypto asset/network selector, QR code, Screenshot proof upload
│   │   ├── withdrawal/          # Balance reservation, Dynamic minimum limit check, Payout request
│   │   ├── trading/             # Interactive Price Chart, Order placement, Active position tracking, Settlement
│   │   ├── market/              # Searchable market list with rise/fall indicators
│   │   ├── support/             # Live Customer Support chat with 30-min auto-close banner & auto-reopen
│   │   └── admin/               # Full Flutter Admin Portal:
│   │       ├── auth/            # Admin login with custom claim verification
│   │       ├── dashboard/       # 8-metric overview + Live Recent Activity Feed (Deposits & Withdrawals)
│   │       ├── users/           # 7-digit ID search, profile view, Profit Award, Financial Adjustment
│   │       ├── coins/           # Coin CRUD, price update, Top 3 featured coin selection
│   │       ├── deposits/        # Queue reviews, Screenshot preview modal, Account credit
│   │       ├── withdrawals/     # Payout verification, Destination inspection, Settlement
│   │       ├── trades/          # Order approval, Exit price & PnL assignment, Ledger settlement
│   │       ├── support/         # Customer support chat desk with ticket archiving
│   │       ├── notifications/   # Push/Inbox notification dispatcher (Broadcast & 7-Digit ID target)
│   │       ├── audit_logs/      # Immutable audit trail explorer with JSON payload inspector
│   │       └── settings/        # Dynamic limits, 30-min auto-close duration/message, Deposit channels
│   ├── main.dart                # User App Entry Point
│   └── main_admin.dart          # Admin App Entry Point
├── functions/                   # Firebase Cloud Functions (TypeScript)
│   ├── src/index.ts             # 11 secure financial mutations + 30-min auto-close scheduler
│   └── package.json
├── market-data-service/         # Cloud Run Binance Spot WebSocket Market Data Worker
│   ├── src/
│   │   ├── binance-client.ts    # Spot WebSocket combined stream listener & backoff reconnect
│   │   ├── firestore-writer.ts  # In-memory ticker buffer & 1000ms throttled Firestore sync
│   │   ├── subscription-manager.ts # Active coin reconciliation from Firestore
│   │   └── data-validator.ts    # Ticker validation (rejects NaN/Infinity/negative price)
│   ├── Dockerfile               # Google Cloud Run deployment image
│   └── MARKET_DATA_SETUP.md     # Deployment & operational guide
├── scripts/
│   ├── set_admin_claim.js       # Node.js tool to assign superAdmin custom claims
│   ├── seed_demo_data.js        # Node.js script to seed top coins, deposit methods, & limits
│   └── fix_imports.js           # Monorepo import normalizer
├── firestore.rules              # Least-privilege Firestore rules protecting financial ledger
├── storage.rules                # Private screenshot storage security rules
└── firebase.json                # Local Emulator Suite configuration
```

---

## 🎨 App Logo Asset Placement

Place your application logo in:
📂 `assets/images/logo.png` (or `assets/images/logo.svg`)

---

## 🚀 Running the Applications

### 1. User Application (Android / iOS / Web)
```bash
flutter run -t lib/main.dart
```

### 2. Admin Portal (Web / Tablet / Desktop)
```bash
# Run Admin Web on Chrome
flutter run -d chrome -t lib/main_admin.dart

# Run Admin on connected Android / Desktop
flutter run -t lib/main_admin.dart
```

---

## 🛠 Database Seeding & Admin Setup

### 1. Seed Initial Markets & Settings
```bash
# Place your Firebase serviceAccountKey.json in the scripts/ directory
node scripts/seed_demo_data.js
```

### 2. Assign SuperAdmin Role
```bash
node scripts/set_admin_claim.js your_admin_email@example.com
```

---

## ☁️ Firebase Cloud Functions & Rules Deployment

```bash
# Deploy Firestore & Storage Security Rules
firebase deploy --only firestore:rules,storage:rules

# Deploy TypeScript Cloud Functions
cd functions
npm install
npm run build
firebase deploy --only functions
```

---

## 🧪 Running Automated Tests

```bash
# Run all unit, widget, chart, and export tests
flutter test

# Run static analysis
flutter analyze
```

---

## 📈 Real-Time Binance Market Data Architecture

The market data architecture uses **one single backend market-data worker service** on Google Cloud Run to stream live public Binance Spot prices into Firestore.

```
Binance Spot WebSocket -> Cloud Run Market Worker -> Firestore -> Admin & User Apps
```

- **No Client WebSocket:** Flutter clients listen to Firestore streams for low-latency updates.
- **Throttled Firestore Writes:** Raw Binance ticks are buffered in memory and throttled (`MARKET_DATA_FIRESTORE_UPDATE_INTERVAL_MS = 1000`).
- **Live / Manual Modes:** Admin can set coins to LIVE (Binance) or MANUAL mode. Manual mode values are never overwritten by the worker.
- **Health Indicators:** Automatic detection of LIVE, STALE (>30s), OFFLINE, and DISABLED feeds.

For step-by-step Google Cloud Run deployment commands, see [MARKET_DATA_SETUP.md](file:///d:/Work_Hub/Flutter/TradingPro/MARKET_DATA_SETUP.md).

