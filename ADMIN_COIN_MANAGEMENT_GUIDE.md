# TradingPro Admin Guide: Adding & Managing Cryptocurrency Coins

Welcome to the **TradingPro Admin Dashboard** guide. This document provides step-by-step instructions on how to add new cryptocurrency coins, configure real-time market feeds, upload coin logos, and manage live vs. manual price modes.

---

## 🌟 Quick Overview: How Market Data Sync Works

The **TradingPro** platform uses an automated background worker powered by **Binance Spot WebSockets**. 

* When you set a coin's mode to **`Live`** and toggle **`Active: ON`**, our background Cloud worker automatically subscribes to Binance market feeds and streams live price changes to all user mobile/web apps every **1 second**.
* When you set a coin's mode to **`Manual`**, the background worker automatically ignores live feed updates for that coin, allowing you to set and control custom prices manually from the admin panel.

---

## 📝 Step-by-Step: How to Add a New Coin

1. **Log in** to your **TradingPro Admin Dashboard**.
2. Navigate to **Coins Management** from the side menu.
3. Click the **`+ Add Coin`** button at the top right.
4. Fill in the required coin parameters (refer to the table below).
5. Upload the **Coin Logo** (PNG or JPEG with transparent background recommended).
6. Click **`Save Coin`**.

---

## 📋 Field Reference Guide

| Field | Description | Example / Best Practice |
| :--- | :--- | :--- |
| **Coin Name** | The full name of the cryptocurrency. | `Cardano` |
| **Symbol** | The standard ticker code shown in the app. | `ADA` |
| **Binance Symbol** | **CRITICAL:** The exact Binance spot trading pair string. **Must be uppercase**. | `ADAUSDT` *(for ADA/USDT)* |
| **Market Data Mode** | Choose between `Live` (Binance Sync) or `Manual` (Admin Control). | Select **`Live`** for auto-sync |
| **Is Active** | Toggles whether the coin is visible to users in the app. | Set to **`ON`** |
| **Is Featured** | Features the coin in the top card list on the user app homepage (Max 3 allowed). | Set to **`ON`** for top coins |
| **Display Order** | Numerical order for list sorting (1 = Top position). | `4` |
| **Initial Price** | Starting price (will be auto-updated if Mode is `Live`). | `0.75` |
| **Coin Logo** | Icon image file for the coin. | Upload `.png` file |

---

## 🔍 Common Cryptocurrency Examples for Copy-Pasting

Use these exact values when adding popular coins:

| Coin Name | Symbol | Binance Symbol | Recommended Display Order |
| :--- | :--- | :--- | :--- |
| **Bitcoin** | `BTC` | `BTCUSDT` | `1` |
| **Ethereum** | `ETH` | `ETHUSDT` | `2` |
| **Solana** | `SOL` | `SOLUSDT` | `3` |
| **Cardano** | `ADA` | `ADAUSDT` | `4` |
| **Ripple** | `XRP` | `XRPUSDT` | `5` |
| **Dogecoin** | `DOGE` | `DOGEUSDT` | `6` |
| **Avalanche** | `AVAX` | `AVAXUSDT` | `7` |
| **Polkadot** | `DOT` | `DOTUSDT` | `8` |

> 💡 **Tip for finding Binance Symbols**: Search for the trading pair on Binance (e.g., `ADA/USDT`). Remove the slash (`/`) and convert to all capital letters: **`ADAUSDT`**.

---

## ⚙️ Switching Between Live & Manual Modes

You can change a coin's pricing mode anytime from the Admin Coins list:

1. Locate the coin in the list and click **Edit**.
2. **Switch to Manual**:
   * Change **Market Data Mode** to **`Manual`**.
   * Enter your custom price in the **Latest Price** field and save.
   * *Result: The background service immediately stops updating this coin from Binance.*
3. **Switch Back to Live**:
   * Change **Market Data Mode** to **`Live`**.
   * *Result: Within 30 seconds, the service auto-resumes streaming live Binance prices.*

---

## ❓ Frequently Asked Questions (FAQ)

#### Q1: Why is a newly added coin not updating prices automatically?
* Ensure **`Is Active`** is set to **`ON`**.
* Ensure **`Market Data Mode`** is set to **`Live`**.
* Check that **`Binance Symbol`** is correctly typed in **ALL CAPS** without spaces (e.g., `BTCUSDT`, not `btc/usdt`).
* Allow up to **30 seconds** for the background Cloud worker to perform its periodic subscription refresh.

#### Q2: What is the maximum number of Featured Coins?
* You can feature up to **3 coins** at a time for the homepage highlight cards. To feature a 4th coin, unfeature one of the existing 3 first.

#### Q3: How do I hide a coin without deleting data?
* Simply edit the coin and toggle **`Is Active`** to **`OFF`**. The coin will immediately be hidden from user apps, and background price updates will pause.

---
*Created for TradingPro Administration.*
