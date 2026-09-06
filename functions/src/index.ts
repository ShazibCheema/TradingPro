import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// ─── Helpers ─────────────────────────────────────────────────────────────────

async function generateUnique7DigitId(): Promise<string> {
  const counterRef = db.collection("systemCounters").doc("userIdCounter");
  return db.runTransaction(async (transaction) => {
    const doc = await transaction.get(counterRef);
    let nextId = 1000000;
    if (doc.exists) {
      nextId = (doc.data()?.lastId || 1000000) + 1;
    }
    transaction.set(counterRef, { lastId: nextId, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    return nextId.toString();
  });
}

function verifyAuth(context: functions.https.CallableContext): string {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }
  return context.auth.uid;
}

function verifyAdmin(context: functions.https.CallableContext): string {
  const uid = verifyAuth(context);
  const role = context.auth?.token?.role;
  if (role !== "admin" && role !== "superAdmin") {
    throw new functions.https.HttpsError("permission-denied", "Requires administrator authorization.");
  }
  return uid;
}

/**
 * Fetch all registered device tokens for a specific user
 */
async function getUserTokens(userId: string): Promise<string[]> {
  const devicesSnap = await db.collection("users").doc(userId).collection("devices").get();
  return devicesSnap.docs.map(doc => doc.data().token).filter(t => !!t);
}

/**
 * Fetch all tokens for users with "admin" or "superAdmin" role
 */
async function getAdminTokens(): Promise<string[]> {
  const adminsSnap = await db.collection("users").where("role", "in", ["admin", "superAdmin"]).get();
  const allTokens: string[] = [];
  for (const doc of adminsSnap.docs) {
    const tokens = await getUserTokens(doc.id);
    allTokens.push(...tokens);
  }
  return allTokens;
}

/**
 * Send FCM push notification to target users
 */
async function sendPushToUsers(userIds: string[], title: string, body: string, route: string = "/inbox") {
  const allTokens: string[] = [];
  for (const uid of userIds) {
    const tokens = await getUserTokens(uid);
    allTokens.push(...tokens);
  }

  if (allTokens.length === 0) return;

  // Split into chunks of 500 (FCM limit)
  for (let i = 0; i < allTokens.length; i += 500) {
    const chunk = allTokens.slice(i, i + 500);
    await admin.messaging().sendEachForMulticast({
      tokens: chunk,
      notification: { title, body },
      data: { route },
      android: {
        priority: "high",
        notification: {
          channelId: "tradingpro_high_importance",
          priority: "high",
          defaultSound: true,
          defaultVibrateTimings: true,
        }
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          }
        }
      }
    });
  }
}

/**
 * Send FCM push notification to all admins
 */
async function sendPushToAdmins(title: string, body: string, route: string = "/admin/dashboard") {
  const tokens = await getAdminTokens();
  if (tokens.length === 0) return;

  for (let i = 0; i < tokens.length; i += 500) {
    const chunk = tokens.slice(i, i + 500);
    await admin.messaging().sendEachForMulticast({
      tokens: chunk,
      notification: { title, body },
      data: { route },
      android: { priority: "high" },
    });
  }
}

// ─── 1. Create User Profile ──────────────────────────────────────────────────

export const createUserProfile = functions.https.onCall(async (data, context) => {
  const uid = verifyAuth(context);
  const fullName = (data.fullName || "").trim();
  const email = (data.email || "").trim();

  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  if (userSnap.exists) {
    return { success: true, userId7: userSnap.data()?.userId7 };
  }

  const userId7 = await generateUnique7DigitId();

  const batch = db.batch();
  batch.set(userRef, {
    uid,
    userId7,
    fullName,
    email,
    photoUrl: null,
    accountStatus: "active",
    balance: 0.0,
    profit: 0.0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const prefsRef = userRef.collection("notificationPrefs").doc("prefs");
  batch.set(prefsRef, {
    transactions: true,
    deposits: true,
    withdrawals: true,
    profit: true,
    trading: true,
    customerSupport: true,
  });

  await batch.commit();
  return { success: true, userId7 };
});

// ─── 2. Submit Deposit ───────────────────────────────────────────────────────

export const submitDeposit = functions.https.onCall(async (data, context) => {
  const uid = verifyAuth(context);
  const { asset, network, walletAddress, amount, screenshotUrl } = data;

  if (!asset || !network || !amount || amount <= 0 || !screenshotUrl) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid deposit parameters.");
  }

  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) throw new functions.https.HttpsError("not-found", "User not found.");
  const userData = userDoc.data();

  if (userData?.accountStatus !== "active") {
    throw new functions.https.HttpsError("permission-denied", "Account restricted.");
  }

  const depositRef = db.collection("users").doc(uid).collection("deposits").doc();
  const depositData = {
    depositId: depositRef.id,
    userId: uid,
    userId7: userData?.userId7 || "",
    userFullName: userData?.fullName || "",
    userEmail: userData?.email || "",
    asset,
    network,
    walletAddress,
    amount: Number(amount),
    screenshotUrl,
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    reviewedAt: null,
  };

  await depositRef.set(depositData);

  // Notify user (in-app)
  const notifRef = db.collection("users").doc(uid).collection("notifications").doc();
  await notifRef.set({
    notificationId: notifRef.id,
    userId: uid,
    title: "Deposit Submitted",
    body: `Your deposit of $${Number(amount).toFixed(2)} ${asset} has been received and is pending review.`,
    type: "depositSubmitted",
    isRead: false,
    referenceId: depositRef.id,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // PUSH: Notify Admin
  await sendPushToAdmins(
    "New Deposit Request",
    `User ${userData?.fullName} submitted a deposit of $${Number(amount).toFixed(2)} ${asset}.`,
    "/admin/deposits"
  );

  return { success: true, depositId: depositRef.id };
});

// ─── 3. Approve Deposit ──────────────────────────────────────────────────────

export const approveDeposit = functions.https.onCall(async (data, context) => {
  const adminUid = verifyAdmin(context);
  const { depositId, userId, creditedAmount, adminNote } = data;

  if (!depositId || !userId || !creditedAmount || creditedAmount <= 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid parameters.");
  }

  const depositRef = db.collection("users").doc(userId).collection("deposits").doc(depositId);
  const userRef = db.collection("users").doc(userId);

  const result = await db.runTransaction(async (transaction) => {
    const depositSnap = await transaction.get(depositRef);
    if (!depositSnap.exists) throw new functions.https.HttpsError("not-found", "Deposit not found.");
    const depositData = depositSnap.data();

    if (depositData?.status !== "pending") {
      throw new functions.https.HttpsError("failed-precondition", "Deposit is no longer pending.");
    }

    const userSnap = await transaction.get(userRef);
    if (!userSnap.exists) throw new functions.https.HttpsError("not-found", "User not found.");
    const userData = userSnap.data();

    const balanceBefore = Number(userData?.balance || 0);
    const balanceAfter = balanceBefore + Number(creditedAmount);

    transaction.update(depositRef, {
      status: "approved",
      creditedAmount: Number(creditedAmount),
      adminNote: adminNote || null,
      adminUid,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.update(userRef, {
      balance: balanceAfter,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const txRef = db.collection("users").doc(userId).collection("transactions").doc();
    transaction.set(txRef, {
      transactionId: txRef.id,
      userId,
      type: "deposit",
      amount: Number(creditedAmount),
      asset: "USD",
      direction: "credit",
      balanceBefore,
      balanceAfter,
      referenceId: depositId,
      description: `Deposit Approved (${depositData?.asset} ${depositData?.network})`,
      createdBy: adminUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const notifRef = db.collection("users").doc(userId).collection("notifications").doc();
    transaction.set(notifRef, {
      notificationId: notifRef.id,
      userId,
      title: "Deposit Confirmed",
      body: `Your deposit of $${Number(creditedAmount).toFixed(2)} has been successfully credited to your account.`,
      type: "depositApproved",
      isRead: false,
      referenceId: depositId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const auditRef = db.collection("auditLogs").doc();
    transaction.set(auditRef, {
      auditId: auditRef.id,
      adminUid,
      action: "APPROVE_DEPOSIT",
      targetType: "deposit",
      targetId: depositId,
      userId,
      metadata: { creditedAmount, balanceBefore, balanceAfter },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { balanceAfter };
  });

  // PUSH: Notify User
  await sendPushToUsers(
    [userId],
    "Deposit Confirmed ✅",
    `$${Number(creditedAmount).toFixed(2)} has been credited to your balance.`
  );

  return { success: true, ...result };
});

// ─── 4. Reject Deposit ───────────────────────────────────────────────────────

export const rejectDeposit = functions.https.onCall(async (data, context) => {
  const adminUid = verifyAdmin(context);
  const { depositId, userId, adminNote } = data;

  const depositRef = db.collection("users").doc(userId).collection("deposits").doc(depositId);
  const depositSnap = await depositRef.get();
  if (!depositSnap.exists) throw new functions.https.HttpsError("not-found", "Deposit not found.");

  await depositRef.update({
    status: "rejected",
    adminNote: adminNote || "Payment could not be verified.",
    adminUid,
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const notifRef = db.collection("users").doc(userId).collection("notifications").doc();
  await notifRef.set({
    notificationId: notifRef.id,
    userId: userId,
    title: "Deposit Rejected",
    body: adminNote || "Your deposit could not be confirmed. Please check transfer details.",
    type: "depositRejected",
    isRead: false,
    referenceId: depositId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // PUSH: Notify User
  await sendPushToUsers(
    [userId],
    "Deposit Rejected ❌",
    adminNote || "Your deposit could not be verified."
  );

  return { success: true };
});

// ─── 5. Submit Withdrawal ───────────────────────────────────────────────────

export const submitWithdrawal = functions.https.onCall(async (data, context) => {
  const uid = verifyAuth(context);
  const { amount, asset, network, walletAddress } = data;

  const amountNum = Number(amount);
  if (!amountNum || amountNum <= 0 || !walletAddress || !asset || !network) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid withdrawal arguments.");
  }

  const settingsDoc = await db.collection("appSettings").doc("global").get();
  const minWithdrawal = settingsDoc.data()?.minimumWithdrawal || 50.0;

  if (amountNum < minWithdrawal) {
    throw new functions.https.HttpsError("invalid-argument", `Minimum withdrawal is $${minWithdrawal.toFixed(2)}.`);
  }

  const userRef = db.collection("users").doc(uid);

  const result = await db.runTransaction(async (transaction) => {
    const userSnap = await transaction.get(userRef);
    if (!userSnap.exists) throw new functions.https.HttpsError("not-found", "User not found.");
    const userData = userSnap.data();

    if (userData?.accountStatus !== "active") {
      throw new functions.https.HttpsError("permission-denied", "Account restricted.");
    }

    const currentBalance = Number(userData?.balance || 0);
    if (currentBalance < amountNum) {
      throw new functions.https.HttpsError("failed-precondition", "Insufficient balance.");
    }

    const withdrawalRef = db.collection("users").doc(uid).collection("withdrawals").doc();
    transaction.set(withdrawalRef, {
      withdrawalId: withdrawalRef.id,
      userId: uid,
      userId7: userData?.userId7 || "",
      userFullName: userData?.fullName || "",
      userEmail: userData?.email || "",
      amount: amountNum,
      asset,
      network,
      walletAddress,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewedAt: null,
    });

    return { fullName: userData?.fullName, withdrawalId: withdrawalRef.id };
  });

  // PUSH: Notify Admin
  await sendPushToAdmins(
    "New Withdrawal Request",
    `User ${result.fullName} requested a withdrawal of $${amountNum.toFixed(2)} ${asset}.`,
    "/admin/withdrawals"
  );

  return { success: true, withdrawalId: result.withdrawalId };
});

// ─── 6. Approve Withdrawal ───────────────────────────────────────────────────

export const approveWithdrawal = functions.https.onCall(async (data, context) => {
  const adminUid = verifyAdmin(context);
  const { withdrawalId, userId, adminNote } = data;

  const withdrawalRef = db.collection("users").doc(userId).collection("withdrawals").doc(withdrawalId);
  const userRef = db.collection("users").doc(userId);

  const result = await db.runTransaction(async (transaction) => {
    const wSnap = await transaction.get(withdrawalRef);
    if (!wSnap.exists) throw new functions.https.HttpsError("not-found", "Withdrawal not found.");
    const wData = wSnap.data();

    if (wData?.status !== "pending") {
      throw new functions.https.HttpsError("failed-precondition", "Withdrawal is no longer pending.");
    }

    const userSnap = await transaction.get(userRef);
    if (!userSnap.exists) throw new functions.https.HttpsError("not-found", "User not found.");
    const userData = userSnap.data();

    const amountNum = Number(wData?.amount || 0);
    const balanceBefore = Number(userData?.balance || 0);
    if (balanceBefore < amountNum) {
      throw new functions.https.HttpsError("failed-precondition", "User balance is less than withdrawal amount.");
    }
    const balanceAfter = balanceBefore - amountNum;

    transaction.update(withdrawalRef, {
      status: "approved",
      adminNote: adminNote || null,
      adminUid,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.update(userRef, {
      balance: balanceAfter,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const txRef = db.collection("users").doc(userId).collection("transactions").doc();
    transaction.set(txRef, {
      transactionId: txRef.id,
      userId,
      type: "withdrawal",
      amount: amountNum,
      asset: "USD",
      direction: "debit",
      balanceBefore,
      balanceAfter,
      referenceId: withdrawalId,
      description: `Withdrawal Approved (${wData?.asset} ${wData?.network})`,
      createdBy: adminUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const notifRef = db.collection("users").doc(userId).collection("notifications").doc();
    transaction.set(notifRef, {
      notificationId: notifRef.id,
      userId,
      title: "Withdrawal Confirmed",
      body: `Your withdrawal of $${amountNum.toFixed(2)} ${wData?.asset} has been approved and paid.`,
      type: "withdrawalApproved",
      isRead: false,
      referenceId: withdrawalId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const auditRef = db.collection("auditLogs").doc();
    transaction.set(auditRef, {
      auditId: auditRef.id,
      adminUid,
      action: "APPROVE_WITHDRAWAL",
      targetType: "withdrawal",
      targetId: withdrawalId,
      userId,
      metadata: { amount: amountNum, balanceBefore, balanceAfter },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { balanceAfter, asset: wData?.asset, amount: amountNum };
  });

  // PUSH: Notify User
  await sendPushToUsers(
    [userId],
    "Withdrawal Paid ✅",
    `Your $${result.amount.toFixed(2)} ${result.asset} withdrawal has been settled.`
  );

  return { success: true, balanceAfter: result.balanceAfter };
});

// ─── 7. Reject Withdrawal ────────────────────────────────────────────────────

export const rejectWithdrawal = functions.https.onCall(async (data, context) => {
  const adminUid = verifyAdmin(context);
  const { withdrawalId, userId, adminNote } = data;

  const withdrawalRef = db.collection("users").doc(userId).collection("withdrawals").doc(withdrawalId);
  await withdrawalRef.update({
    status: "rejected",
    adminNote: adminNote || "Withdrawal request declined.",
    adminUid,
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const notifRef = db.collection("users").doc(userId).collection("notifications").doc();
  await notifRef.set({
    notificationId: notifRef.id,
    userId,
    title: "Withdrawal Rejected",
    body: adminNote || "Your withdrawal request could not be processed.",
    type: "withdrawalRejected",
    isRead: false,
    referenceId: withdrawalId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // PUSH: Notify User
  await sendPushToUsers(
    [userId],
    "Withdrawal Rejected ❌",
    adminNote || "Your withdrawal request was declined."
  );

  return { success: true };
});

// ─── 8. Award Profit ─────────────────────────────────────────────────────────

export const awardProfit = functions.https.onCall(async (data, context) => {
  const adminUid = verifyAdmin(context);
  const { userId, amount, reason } = data;

  const amountNum = Number(amount);
  if (!userId || !amountNum || amountNum <= 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid profit amount or user ID.");
  }

  const userRef = db.collection("users").doc(userId);

  const result = await db.runTransaction(async (transaction) => {
    const userSnap = await transaction.get(userRef);
    if (!userSnap.exists) throw new functions.https.HttpsError("not-found", "User not found.");
    const userData = userSnap.data();

    const balanceBefore = Number(userData?.balance || 0);
    const balanceAfter = balanceBefore + amountNum;
    const profitAfter = Number(userData?.profit || 0) + amountNum;

    transaction.update(userRef, {
      balance: balanceAfter,
      profit: profitAfter,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const txRef = db.collection("users").doc(userId).collection("transactions").doc();
    transaction.set(txRef, {
      transactionId: txRef.id,
      userId,
      type: "profit",
      amount: amountNum,
      asset: "USD",
      direction: "credit",
      balanceBefore,
      balanceAfter,
      referenceId: txRef.id,
      description: reason || "Trading Profit Awarded",
      createdBy: adminUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const notifRef = db.collection("users").doc(userId).collection("notifications").doc();
    transaction.set(notifRef, {
      notificationId: notifRef.id,
      userId,
      title: "Profit Awarded",
      body: `A profit of $${amountNum.toFixed(2)} has been added to your account.`,
      type: "profitAwarded",
      isRead: false,
      referenceId: txRef.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const auditRef = db.collection("auditLogs").doc();
    transaction.set(auditRef, {
      auditId: auditRef.id,
      adminUid,
      action: "AWARD_PROFIT",
      targetType: "user",
      targetId: userId,
      userId,
      metadata: { amount: amountNum, reason, balanceBefore, balanceAfter },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { balanceAfter, profitAfter };
  });

  // PUSH: Notify User
  await sendPushToUsers(
    [userId],
    "Profit Awarded 💰",
    `$${amountNum.toFixed(2)} has been added to your profit ledger.`
  );

  return { success: true, ...result };
});

// ─── 9. Create Trade ─────────────────────────────────────────────────────────

export const createTrade = functions.https.onCall(async (data, context) => {
  const uid = verifyAuth(context);
  const { investmentAmount } = data;

  const amountNum = Number(investmentAmount);
  if (!amountNum || amountNum <= 0) {
    throw new functions.https.HttpsError("invalid-argument", "Enter a valid investment amount.");
  }

  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) throw new functions.https.HttpsError("not-found", "User not found.");
  const userData = userSnap.data();

  if (userData?.accountStatus !== "active") {
    throw new functions.https.HttpsError("permission-denied", "Account restricted.");
  }

  if (Number(userData?.balance || 0) < amountNum) {
    throw new functions.https.HttpsError("failed-precondition", "Insufficient balance for this trade.");
  }

  const tradeRef = db.collection("users").doc(uid).collection("trades").doc();
  await tradeRef.set({
    tradeId: tradeRef.id,
    userId: uid,
    userId7: userData?.userId7 || "",
    userFullName: userData?.fullName || "",
    coinId: "",
    coinSymbol: "",
    coinName: "",
    investmentAmount: amountNum,
    entryPrice: 0,
    closingPrice: null,
    profitAmount: null,
    lossAmount: null,
    status: "pending",
    adminNote: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    openedAt: null,
    closedAt: null,
  });

  // PUSH: Notify Admin
  await sendPushToAdmins(
    "New Trade Order",
    `${userData?.fullName} submitted a trade investment of $${amountNum.toFixed(2)}.`,
    "/admin/trades"
  );

  return { success: true, tradeId: tradeRef.id };
});

// ─── 10. Close Trade ─────────────────────────────────────────────────────────

export const closeTrade = functions.https.onCall(async (data, context) => {
  const adminUid = verifyAdmin(context);
  const { tradeId, userId, closingPrice, profitAmount, lossAmount, adminNote } = data;

  const tradeRef = db.collection("users").doc(userId).collection("trades").doc(tradeId);
  const userRef = db.collection("users").doc(userId);

  const result = await db.runTransaction(async (transaction) => {
    const tradeSnap = await transaction.get(tradeRef);
    if (!tradeSnap.exists) throw new functions.https.HttpsError("not-found", "Trade not found.");
    const tradeData = tradeSnap.data();

    if (tradeData?.status === "closed" || tradeData?.status === "cancelled") {
      throw new functions.https.HttpsError("failed-precondition", "Trade is already settled.");
    }

    const userSnap = await transaction.get(userRef);
    if (!userSnap.exists) throw new functions.https.HttpsError("not-found", "User not found.");
    const userData = userSnap.data();

    const p = Number(profitAmount || 0);
    const l = Number(lossAmount || 0);
    const netChange = p - l;

    const balanceBefore = Number(userData?.balance || 0);
    const balanceAfter = balanceBefore + netChange;
    const profitAfter = Number(userData?.profit || 0) + p;

    transaction.update(tradeRef, {
      status: "closed",
      closingPrice: Number(closingPrice),
      profitAmount: p,
      lossAmount: l,
      adminNote: adminNote || null,
      adminUid,
      closedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.update(userRef, {
      balance: balanceAfter,
      profit: profitAfter,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const txRef = db.collection("users").doc(userId).collection("transactions").doc();
    transaction.set(txRef, {
      transactionId: txRef.id,
      userId,
      type: p > 0 ? "tradeProfit" : "tradeLoss",
      amount: Math.abs(netChange),
      asset: "USD",
      direction: netChange >= 0 ? "credit" : "debit",
      balanceBefore,
      balanceAfter,
      referenceId: tradeId,
      description: `Trade Outcome: ${tradeData?.coinSymbol} (${netChange >= 0 ? "+" : "-"}$${Math.abs(netChange).toFixed(2)})`,
      createdBy: adminUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { balanceAfter, symbol: tradeData?.coinSymbol, netChange };
  });

  // PUSH: Notify User
  const outcome = result.netChange >= 0 ? "Profit" : "Loss";
  await sendPushToUsers(
    [userId],
    "Trade Settled 📊",
    `Your ${result.symbol} trade closed with a ${outcome} of $${Math.abs(result.netChange).toFixed(2)}.`
  );

  return { success: true, balanceAfter: result.balanceAfter };
});

// ─── 11. Manage Trade (Open or Cancel) ───────────────────────────────────────

export const manageTrade = functions.https.onCall(async (data, context) => {
  const adminUid = verifyAdmin(context);
  const { tradeId, userId, action, adminNote } = data;

  if (!tradeId || !userId || !action) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid parameters.");
  }

  const tradeRef = db.collection("users").doc(userId).collection("trades").doc(tradeId);
  const tradeSnap = await tradeRef.get();
  if (!tradeSnap.exists) throw new functions.https.HttpsError("not-found", "Trade not found.");

  if (action === "open") {
    await tradeRef.update({
      status: "open",
      adminNote: adminNote || null,
      adminUid,
      openedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const notifRef = db.collection("users").doc(userId).collection("notifications").doc();
    await notifRef.set({
      notificationId: notifRef.id,
      userId,
      title: "Trade Order Opened",
      body: "Your market position has been successfully opened by the trading floor.",
      type: "tradeOpened",
      isRead: false,
      referenceId: tradeId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // PUSH: Notify User
    await sendPushToUsers([userId], "Trade Opened 🚀", "Your market position is now active.");
  } else if (action === "cancel") {
    await tradeRef.update({
      status: "cancelled",
      adminNote: adminNote || "Order cancelled by administrator.",
      adminUid,
      closedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const notifRef = db.collection("users").doc(userId).collection("notifications").doc();
    await notifRef.set({
      notificationId: notifRef.id,
      userId,
      title: "Trade Order Cancelled",
      body: adminNote || "Your trade order was cancelled. Funds have not been deducted.",
      type: "tradeCancelled",
      isRead: false,
      referenceId: tradeId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // PUSH: Notify User
    await sendPushToUsers([userId], "Trade Order Cancelled ⚠️", adminNote || "Your trade order was cancelled.");
  }

  return { success: true };
});

// ─── 12. Manual Balance Adjustment ───────────────────────────────────────────

export const makeAdjustment = functions.https.onCall(async (data, context) => {
  const adminUid = verifyAdmin(context);
  const { userId, amount, reason, isCredit } = data;

  const amountNum = Number(amount);
  if (!userId || !amountNum || amountNum <= 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid adjustment parameters.");
  }

  const userRef = db.collection("users").doc(userId);

  const result = await db.runTransaction(async (transaction) => {
    const userSnap = await transaction.get(userRef);
    if (!userSnap.exists) throw new functions.https.HttpsError("not-found", "User not found.");
    const userData = userSnap.data();

    const balanceBefore = Number(userData?.balance || 0);
    const balanceAfter = isCredit ? balanceBefore + amountNum : balanceBefore - amountNum;

    if (!isCredit && balanceAfter < 0) {
      throw new functions.https.HttpsError("failed-precondition", "User balance cannot be adjusted below zero.");
    }

    transaction.update(userRef, {
      balance: balanceAfter,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const txRef = db.collection("users").doc(userId).collection("transactions").doc();
    transaction.set(txRef, {
      transactionId: txRef.id,
      userId,
      type: "adjustment",
      amount: amountNum,
      asset: "USD",
      direction: isCredit ? "credit" : "debit",
      balanceBefore,
      balanceAfter,
      referenceId: txRef.id,
      description: reason || "Administrative Balance Adjustment",
      createdBy: adminUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const auditRef = db.collection("auditLogs").doc();
    transaction.set(auditRef, {
      auditId: auditRef.id,
      adminUid,
      action: "MANUAL_ADJUSTMENT",
      targetType: "user",
      targetId: userId,
      userId,
      metadata: { amount: amountNum, isCredit, reason, balanceBefore, balanceAfter },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { balanceAfter };
  });

  // PUSH: Notify User
  const verb = isCredit ? "credited to" : "deducted from";
  await sendPushToUsers(
    [userId],
    "Balance Adjusted ⚖️",
    `$${amountNum.toFixed(2)} has been ${verb} your account balance.`
  );

  return { success: true, ...result };
});

// ─── 13. Send Notification (Broadcast or Direct) ─────────────────────────────

export const sendNotification = functions.https.onCall(async (data, context) => {
  const adminUid = verifyAdmin(context);
  const { targetUserId, targetUserId7, title, body } = data;

  if (!title || !body) {
    throw new functions.https.HttpsError("invalid-argument", "Title and body are required.");
  }

  const createdAt = admin.firestore.FieldValue.serverTimestamp();
  const targetIds: string[] = [];

  if (targetUserId) {
    targetIds.push(targetUserId);
    const notifRef = db.collection("users").doc(targetUserId).collection("notifications").doc();
    await notifRef.set({
      notificationId: notifRef.id,
      userId: targetUserId,
      title,
      body,
      type: "adminMessage",
      isRead: false,
      createdAt,
    });
  } else {
    // BROADCAST: Create notification for every active user
    const usersSnap = await db.collection("users").where("accountStatus", "==", "active").get();
    const batch = db.batch();

    usersSnap.docs.forEach((userDoc) => {
      targetIds.push(userDoc.id);
      const notifRef = userDoc.ref.collection("notifications").doc();
      batch.set(notifRef, {
        notificationId: notifRef.id,
        userId: userDoc.id,
        title,
        body,
        type: "broadcast",
        isRead: false,
        createdAt,
      });
    });

    await batch.commit();
  }

  // PUSH: Notify all targets
  await sendPushToUsers(targetIds, title, body, "/inbox");

  // Log in admin broadcast history
  await db.collection("adminNotifications").add({
    createdBy: adminUid,
    title,
    body,
    isBroadcast: !targetUserId,
    targetUserId: targetUserId || null,
    targetUserId7: targetUserId7 || null,
    createdAt,
  });

  return { success: true };
});

// ─── 14. Support Chat Auto-Close (Scheduled every 5 minutes) ──────────────────

export const autoCloseSupportChat = functions.pubsub.schedule("every 5 minutes").onRun(async (context) => {
  console.log("Running autoCloseSupportChat cycle...");
  try {
    const settingsDoc = await db.collection("appSettings").doc("global").get();
    const autoCloseMinutes = settingsDoc.data()?.supportAutoCloseMinutes || 30;
    const autoCloseMsg = settingsDoc.data()?.supportAutoCloseMessage || "Admin chat has been closed. Hope you liked our service.";

    // Logic: Current Time - Inactivity Limit
    const thresholdMillis = Date.now() - (autoCloseMinutes * 60 * 1000);
    const thresholdTimestamp = admin.firestore.Timestamp.fromMillis(thresholdMillis);

    console.log(`Checking for chats with no activity since: ${thresholdTimestamp.toDate().toISOString()}`);

    const inactiveSnap = await db
      .collection("supportConversations")
      .where("status", "==", "open")
      .where("updatedAt", "<=", thresholdTimestamp)
      .get();

    if (inactiveSnap.empty) {
      console.log("No inactive chats found in this cycle.");
      return null;
    }

    const batch = db.batch();
    for (const doc of inactiveSnap.docs) {
      batch.update(doc.ref, {
        status: "closed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const msgRef = doc.ref.collection("messages").doc();
      batch.set(msgRef, {
        conversationId: doc.id,
        senderId: "system",
        senderRole: "system",
        senderName: "System",
        content: autoCloseMsg,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    console.log(`Successfully closed ${inactiveSnap.size} inactive support chats.`);
    return null;
  } catch (error) {
    console.error("CRITICAL: autoCloseSupportChat failed:", error);
    return null;
  }
});

// ─── 15. Real-time Chat Notifications (Trigger) ──────────────────────────────

export const onChatMessageCreated = functions.firestore
  .document("supportConversations/{convId}/messages/{msgId}")
  .onCreate(async (snap, context) => {
    const msg = snap.data();

    const convRef = db.collection("supportConversations").doc(context.params.convId);
    const convSnap = await convRef.get();
    const convData = convSnap.data();

    if (!convData) return;

    if (msg.senderRole === "user") {
      // Notify Admins
      await sendPushToAdmins(
        `Message from ${msg.senderName}`,
        msg.content,
        `/admin/support/${context.params.convId}`
      );
    } else if (msg.senderRole === "admin") {
      // Notify User
      await sendPushToUsers(
        [convData.userId],
        "Support Representative",
        msg.content,
        "/support"
      );
    } else if (msg.senderRole === "system") {
      // Notify User of system message (e.g. Chat Closed)
      await sendPushToUsers(
        [convData.userId],
        "Support Alert",
        msg.content,
        "/support"
      );
    }
  });

// ─── 16. Delete User Account (App Store & Play Store Compliance) ──────────────

export const deleteUserAccount = functions.https.onCall(async (data, context) => {
  const uid = verifyAuth(context);

  try {
    const userRef = db.collection("users").doc(uid);
    await userRef.set({
      fullName: "Deleted User",
      email: `deleted_${uid}@deleted.invalid`,
      photoUrl: null,
      accountStatus: "deleted",
      isDeleted: true,
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    const devicesSnap = await userRef.collection("devices").get();
    const batch = db.batch();
    devicesSnap.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();

    await admin.auth().deleteUser(uid);

    return { success: true };
  } catch (error: any) {
    console.error(`Failed to delete account for user ${uid}:`, error);
    throw new functions.https.HttpsError("internal", error.message || "Failed to delete account");
  }
});
