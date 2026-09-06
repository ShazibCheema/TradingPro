/**
 * TradingPro: I&T — Firestore Demo Data & Initial Configuration Seeder
 *
 * Usage:
 * 1. Place serviceAccountKey.json in the scripts/ folder
 * 2. Run: node scripts/seed_demo_data.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('Error: scripts/serviceAccountKey.json not found.');
  console.error('Please download your service account key from the Firebase Console.');
  process.exit(1);
}

try {
  const serviceAccount = require(serviceAccountPath);
  initializeApp({
    credential: cert(serviceAccount),
  });
} catch (e) {
  console.error('Initialization Error:', e.message);
  process.exit(1);
}

const db = getFirestore();

async function seedData() {
  console.log('🚀 Starting TradingPro: I&T initial database seeding...\n');

  // 1. Seed Coins / Markets
  console.log('📦 Seeding Market Coins...');
  const coins = [
    {
      coinId: 'btc',
      name: 'Bitcoin',
      symbol: 'BTC',
      latestPrice: 77420.50,
      percentageChange: 2.45,
      isPositive: true,
      displayOrder: 1,
      isFeatured: true,
      isActive: true,
      logoUrl: 'https://cryptologos.cc/logos/bitcoin-btc-logo.png',
    },
    {
      coinId: 'eth',
      name: 'Ethereum',
      symbol: 'ETH',
      latestPrice: 3120.80,
      percentageChange: 1.85,
      isPositive: true,
      displayOrder: 2,
      isFeatured: true,
      isActive: true,
      logoUrl: 'https://cryptologos.cc/logos/ethereum-eth-logo.png',
    },
    {
      coinId: 'sol',
      name: 'Solana',
      symbol: 'SOL',
      latestPrice: 195.40,
      percentageChange: 4.12,
      isPositive: true,
      displayOrder: 3,
      isFeatured: true,
      isActive: true,
      logoUrl: 'https://cryptologos.cc/logos/solana-sol-logo.png',
    },
    {
      coinId: 'xrp',
      name: 'XRP',
      symbol: 'XRP',
      latestPrice: 1.4850,
      percentageChange: -1.25,
      isPositive: false,
      displayOrder: 4,
      isFeatured: false,
      isActive: true,
      logoUrl: 'https://cryptologos.cc/logos/xrp-xrp-logo.png',
    },
    {
      coinId: 'bnb',
      name: 'BNB',
      symbol: 'BNB',
      latestPrice: 652.10,
      percentageChange: 0.95,
      isPositive: true,
      displayOrder: 5,
      isFeatured: false,
      isActive: true,
      logoUrl: 'https://cryptologos.cc/logos/bnb-bnb-logo.png',
    },
    {
      coinId: 'ada',
      name: 'Cardano',
      symbol: 'ADA',
      latestPrice: 0.7240,
      percentageChange: -0.85,
      isPositive: false,
      displayOrder: 6,
      isFeatured: false,
      isActive: true,
      logoUrl: 'https://cryptologos.cc/logos/cardano-ada-logo.png',
    },
    {
      coinId: 'doge',
      name: 'Dogecoin',
      symbol: 'DOGE',
      latestPrice: 0.2840,
      percentageChange: 5.60,
      isPositive: true,
      displayOrder: 7,
      isFeatured: false,
      isActive: true,
      logoUrl: 'https://cryptologos.cc/logos/dogecoin-doge-logo.png',
    },
    {
      coinId: 'avax',
      name: 'Avalanche',
      symbol: 'AVAX',
      latestPrice: 34.80,
      percentageChange: 2.10,
      isPositive: true,
      displayOrder: 8,
      isFeatured: false,
      isActive: true,
      logoUrl: 'https://cryptologos.cc/logos/avalanche-avax-logo.png',
    },
    {
      coinId: 'link',
      name: 'Chainlink',
      symbol: 'LINK',
      latestPrice: 18.25,
      percentageChange: -2.30,
      isPositive: false,
      displayOrder: 9,
      isFeatured: false,
      isActive: true,
      logoUrl: 'https://cryptologos.cc/logos/chainlink-link-logo.png',
    },
    {
      coinId: 'sui',
      name: 'Sui',
      symbol: 'SUI',
      latestPrice: 3.42,
      percentageChange: 6.80,
      isPositive: true,
      displayOrder: 10,
      isFeatured: false,
      isActive: true,
      logoUrl: 'https://cryptologos.cc/logos/sui-sui-logo.png',
    },
  ];

  for (const coin of coins) {
    await db.collection('coins').doc(coin.coinId).set({
      ...coin,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log(`  ✓ Coin: ${coin.name} (${coin.symbol}) - $${coin.latestPrice}`);
  }

  // 2. Seed Default App & Financial Settings
  console.log('\n⚙️ Seeding Platform Settings...');
  await db.collection('settings').doc('appSettings').set({
    appName: 'TradingPro: I&T',
    displayCurrency: 'USD',
    currencySymbol: '$',
    minWithdrawalAmount: 50.0,
    maxWithdrawalAmount: 100000.0,
    withdrawalFeePercent: 0.0,
    supportAutoCloseMinutes: 30,
    supportAutoCloseMessage: 'This support inquiry was automatically resolved due to 30 minutes of inactivity. Send a message anytime to reopen.',
    allowNewRegistrations: true,
    maintenanceMode: false,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  console.log('  ✓ System & Withdrawal Limits Configured');

  // 3. Seed Receiving Deposit Channels
  console.log('\n💳 Seeding Crypto Deposit Receiving Channels...');
  const depositChannels = [
    {
      methodId: 'usdt_trc20',
      asset: 'USDT',
      network: 'TRC20 (Tron)',
      walletAddress: 'TYDzsXDvG5W3z2L4i5S7o9K1mV8n3p2q1r',
      qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=TYDzsXDvG5W3z2L4i5S7o9K1mV8n3p2q1r',
      instructions: 'Send only USDT via the TRC20 network. Minimum deposit is $20. Funds will be credited after admin verification.',
      minDeposit: 20.0,
      isActive: true,
    },
    {
      methodId: 'usdt_erc20',
      asset: 'USDT',
      network: 'ERC20 (Ethereum)',
      walletAddress: '0x71C8360d8C4D4A9e9b0bB22e0C98d672E9c1D9f8',
      qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=0x71C8360d8C4D4A9e9b0bB22e0C98d672E9c1D9f8',
      instructions: 'Send only USDT via Ethereum (ERC20). Ensure sufficient gas fees.',
      minDeposit: 50.0,
      isActive: true,
    },
    {
      methodId: 'btc_native',
      asset: 'BTC',
      network: 'Bitcoin Native',
      walletAddress: 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
      qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
      instructions: 'Send only Native BTC to this Bitcoin address. Requires 2 network confirmations.',
      minDeposit: 50.0,
      isActive: true,
    },
    {
      methodId: 'eth_native',
      asset: 'ETH',
      network: 'Ethereum (ERC20)',
      walletAddress: '0x71C8360d8C4D4A9e9b0bB22e0C98d672E9c1D9f8',
      qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=0x71C8360d8C4D4A9e9b0bB22e0C98d672E9c1D9f8',
      instructions: 'Send only ETH via Ethereum network.',
      minDeposit: 50.0,
      isActive: true,
    },
    {
      methodId: 'sol_native',
      asset: 'SOL',
      network: 'Solana (SPL)',
      walletAddress: '7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU',
      qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU',
      instructions: 'Send only SOL via Solana network.',
      minDeposit: 20.0,
      isActive: true,
    },
  ];

  for (const method of depositChannels) {
    await db.collection('depositMethods').doc(method.methodId).set({
      ...method,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log(`  ✓ Channel: ${method.asset} (${method.network})`);
  }

  console.log('\n🎉 Seeding completed successfully! TradingPro: I&T is ready for production.\n');
  process.exit(0);
}

seedData().catch((err) => {
  console.error('Seeding error:', err);
  process.exit(1);
});
