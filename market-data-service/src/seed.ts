import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

initializeApp({ projectId: 'tradingpro-6c1ac' });
const db = getFirestore();

const defaultCoins = [
  {
    docId: 'BTCUSDT',
    data: {
      name: 'Bitcoin',
      symbol: 'BTC',
      binanceSymbol: 'BTCUSDT',
      isActive: true,
      isFeatured: true,
      marketDataMode: 'live',
      displayOrder: 1,
      latestPrice: 96500.0,
      priceChangePercent24h: 1.5,
      marketDataStatus: 'live',
    },
  },
  {
    docId: 'ETHUSDT',
    data: {
      name: 'Ethereum',
      symbol: 'ETH',
      binanceSymbol: 'ETHUSDT',
      isActive: true,
      isFeatured: true,
      marketDataMode: 'live',
      displayOrder: 2,
      latestPrice: 2750.0,
      priceChangePercent24h: 0.8,
      marketDataStatus: 'live',
    },
  },
  {
    docId: 'SOLUSDT',
    data: {
      name: 'Solana',
      symbol: 'SOL',
      binanceSymbol: 'SOLUSDT',
      isActive: true,
      isFeatured: true,
      marketDataMode: 'live',
      displayOrder: 3,
      latestPrice: 195.0,
      priceChangePercent24h: -1.2,
      marketDataStatus: 'live',
    },
  },
];

async function seed() {
  console.log('Seeding coins collection into Firestore project tradingpro-6c1ac...');
  for (const item of defaultCoins) {
    await db.collection('coins').doc(item.docId).set(item.data, { merge: true });
    console.log(`Created/updated coin document: ${item.docId}`);
  }
  console.log('Successfully seeded coins collection!');
}

seed().catch((err) => {
  console.error('Seeding failed:', err);
  process.exit(1);
});
