/**
 * TradingPro: I&T — One-Time SuperAdmin Setup Script
 *
 * Usage:
 * 1. Place your Firebase Service Account JSON in this directory as `serviceAccountKey.json`.
 * 2. Run: node scripts/set_admin_claim.js <admin_email>
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('Error: scripts/serviceAccountKey.json not found.');
  console.error('Please ensure you have placed the service account key in the scripts/ folder.');
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

async function setAdminClaim(email) {
  if (!email) {
    console.error('Usage: node scripts/set_admin_claim.js <admin_email>');
    process.exit(1);
  }

  try {
    const auth = getAuth();
    const user = await auth.getUserByEmail(email);
    await auth.setCustomUserClaims(user.uid, {
      role: 'superAdmin',
    });

    console.log(`Success! Custom claim { role: 'superAdmin' } assigned to user: ${email} (${user.uid})`);
    console.log('The user can now sign in to the TradingPro Admin Portal.');
    process.exit(0);
  } catch (error) {
    console.error('Failed to set admin claim:', error.message);
    process.exit(1);
  }
}

const targetEmail = process.argv[2];
setAdminClaim(targetEmail);
