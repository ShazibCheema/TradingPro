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
  const rawInvitedByUserId = (data.invitedByUserId || "").trim();

  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  if (userSnap.exists) {
    return { success: true, userId7: userSnap.data()?.userId7 };
  }

  // ── Validate invitation code server-side ────────────────────────────────
  let invitedByUserId: string | null = null;
  if (rawInvitedByUserId) {
    let inviterUid: string | null = null;

    // Check by doc ID first
    const inviterDocDirect = await db.collection("users").doc(rawInvitedByUserId).get();
    if (inviterDocDirect.exists) {
      inviterUid = inviterDocDirect.id;
    } else {
      // Check by 7-digit userId7 (string or number)
      const intCode = parseInt(rawInvitedByUserId, 10);
      let inviterQuery = await db.collection("users").where("userId7", "==", rawInvitedByUserId).limit(1).get();
      if (inviterQuery.empty && !isNaN(intCode)) {
        inviterQuery = await db.collection("users").where("userId7", "==", intCode).limit(1).get();
      }
      if (inviterQuery.empty) {
        inviterQuery = await db.collection("users").where("referralCode", "==", rawInvitedByUserId).limit(1).get();
      }
      if (!inviterQuery.empty) {
        inviterUid = inviterQuery.docs[0].id;
      }
    }

    if (!inviterUid) {
      throw new functions.https.HttpsError("not-found", "Inviter user not found. Please check the invitation code.");
    }
    if (inviterUid === uid) {
      throw new functions.https.HttpsError("invalid-argument", "Self-referral is not allowed.");
    }
    invitedByUserId = inviterUid;
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
    ...(invitedByUserId ? { invitedByUserId } : {}),
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

  // Update public userIndex mapping for fast invitation code lookup
  try {
    await db.collection("appSettings").doc("userIndex").set(
      { [userId7]: uid },
      { merge: true }
    );
  } catch (e) {
    console.error("Failed to update userIndex map:", e);
  }

  return { success: true, userId7 };
});

// ─── 1b. Validate Invitation Code ───────────────────────────────────────────

export const validateInvitationCode = functions.https.onCall(async (data, _context) => {
  const code = (data.code || "").trim();
  if (!code) {
    return { valid: false, message: "Code cannot be empty." };
  }
  if (!/^\d{7}$/.test(code)) {
    throw new functions.https.HttpsError("invalid-argument", "Invitation code must be a 7-digit numeric ID.");
  }

  const snap = await db.collection("users").where("userId7", "==", code).limit(1).get();
  if (snap.empty) {
    throw new functions.https.HttpsError("not-found", "Invalid invitation code. No user found with this ID.");
  }

  const inviterDoc = snap.docs[0];
  const inviterData = inviterDoc.data();

  const currentEmail = (data.email || "").trim().toLowerCase();
  if (currentEmail && inviterData.email?.toLowerCase() === currentEmail) {
    throw new functions.https.HttpsError("invalid-argument", "You cannot use your own ID as an invitation code.");
  }

  return {
    valid: true,
    inviterUid: inviterDoc.id,
    inviterName: inviterData.fullName || "User",
  };
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

// ─── 17. Fetch Binance Market Prices (Scheduled every 1 minute) ───────────────
//
// This function:
//   1. Reads all active coins from Firestore that have marketDataMode = "live"
//   2. Calls Binance REST API to get current ticker prices
//   3. Updates each coin document with latestPrice, priceChangePercent24h,
//      high24h, low24h, volume24h, and sets marketDataStatus = "online"
//   4. If a coin symbol is not found on Binance, it marks it "offline"

async function fetchBinancePrices(symbols: string[]): Promise<Map<string, {
  price: number;
  priceChangePercent: number;
  high24h: number;
  low24h: number;
  volume24h: number;
  quoteVolume24h: number;
}>> {
  const result = new Map();

  if (symbols.length === 0) return result;

  try {
    // Binance REST API: Get 24hr ticker for multiple symbols at once
    const url = `https://api.binance.com/api/v3/ticker/24hr?symbols=[${symbols.map(s => `"${s}"`).join(",")}]`;

    const response = await fetch(url, {
      method: "GET",
      headers: { "Content-Type": "application/json" },
    });

    if (!response.ok) {
      console.error(`Binance API error: ${response.status} ${response.statusText}`);
      // Try one by one as fallback
      for (const sym of symbols) {
        try {
          const singleUrl = `https://api.binance.com/api/v3/ticker/24hr?symbol=${sym}`;
          const singleResp = await fetch(singleUrl);
          if (singleResp.ok) {
            const ticker: any = await singleResp.json();
            result.set(sym, {
              price: parseFloat(ticker.lastPrice || "0"),
              priceChangePercent: parseFloat(ticker.priceChangePercent || "0"),
              high24h: parseFloat(ticker.highPrice || "0"),
              low24h: parseFloat(ticker.lowPrice || "0"),
              volume24h: parseFloat(ticker.volume || "0"),
              quoteVolume24h: parseFloat(ticker.quoteVolume || "0"),
            });
          }
        } catch (e) {
          console.error(`Failed to fetch price for ${sym}:`, e);
        }
      }
      return result;
    }

    const tickers: any[] = await response.json();
    for (const ticker of tickers) {
      result.set(ticker.symbol, {
        price: parseFloat(ticker.lastPrice || "0"),
        priceChangePercent: parseFloat(ticker.priceChangePercent || "0"),
        high24h: parseFloat(ticker.highPrice || "0"),
        low24h: parseFloat(ticker.lowPrice || "0"),
        volume24h: parseFloat(ticker.volume || "0"),
        quoteVolume24h: parseFloat(ticker.quoteVolume || "0"),
      });
    }
  } catch (error) {
    console.error("Failed to fetch Binance prices:", error);
  }

  return result;
}

async function runMarketPriceFetch(): Promise<{ updated: number; failed: number }> {
  // 1. Get all active live-mode coins
  const coinsSnap = await db.collection("coins")
    .where("isActive", "==", true)
    .where("marketDataMode", "==", "live")
    .get();

  if (coinsSnap.empty) {
    console.log("No active live-mode coins found.");
    return { updated: 0, failed: 0 };
  }

  // 2. Collect unique binance symbols
  const coinDocs = coinsSnap.docs.map(doc => ({
    id: doc.id,
    data: doc.data(),
    binanceSymbol: (doc.data().binanceSymbol || doc.data().symbol || "").toUpperCase().trim(),
  })).filter(c => c.binanceSymbol.length > 0);

  const uniqueSymbols = [...new Set(coinDocs.map(c => c.binanceSymbol))];
  console.log(`Fetching prices for ${uniqueSymbols.length} symbol(s): ${uniqueSymbols.join(", ")}`);

  // 3. Fetch from Binance
  const priceMap = await fetchBinancePrices(uniqueSymbols);

  // 4. Update Firestore
  const batch = db.batch();
  let updated = 0;
  let failed = 0;

  for (const coin of coinDocs) {
    const ticker = priceMap.get(coin.binanceSymbol);
    const ref = db.collection("coins").doc(coin.id);

    if (ticker && ticker.price > 0) {
      batch.update(ref, {
        latestPrice: ticker.price,
        priceChangePercent24h: ticker.priceChangePercent,
        high24h: ticker.high24h,
        low24h: ticker.low24h,
        volume24h: ticker.volume24h,
        quoteVolume24h: ticker.quoteVolume24h,
        marketDataStatus: "online",
        lastPriceFetchedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      updated++;
      console.log(`✅ ${coin.binanceSymbol}: $${ticker.price} (${ticker.priceChangePercent >= 0 ? "+" : ""}${ticker.priceChangePercent.toFixed(2)}%)`);
    } else {
      // Symbol not found on Binance or price is 0
      batch.update(ref, {
        marketDataStatus: "offline",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      failed++;
      console.warn(`⚠️  ${coin.binanceSymbol}: not found on Binance or price is 0`);
    }
  }

  await batch.commit();
  console.log(`Market price update complete. Updated: ${updated}, Failed: ${failed}`);
  return { updated, failed };
}

// Scheduled: runs every minute automatically
export const fetchMarketPrices = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async (_context) => {
    console.log("⏰ fetchMarketPrices scheduled run started...");
    try {
      const result = await runMarketPriceFetch();
      console.log(`fetchMarketPrices done: ${JSON.stringify(result)}`);
    } catch (error) {
      console.error("fetchMarketPrices FAILED:", error);
    }
    return null;
  });

// On-demand: admin can trigger manually for testing
export const fetchMarketPricesNow = functions.https.onCall(async (_data, context) => {
  verifyAdmin(context);
  try {
    const result = await runMarketPriceFetch();
    return { success: true, ...result };
  } catch (error: any) {
    throw new functions.https.HttpsError("internal", error.message || "Price fetch failed");
  }
});

// ─── Set Temporary Password (Admin Only) ───────────────────────────────────────
// Admin sets a temporary password for a user who has lost access to their account.
// The user will be forced to change this password upon next login.
export const setTemporaryPassword = functions.https.onCall(async (data, context) => {
  const adminUid = verifyAdmin(context);
  const { userId, temporaryPassword } = data;

  if (!userId || typeof userId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "A valid userId is required.");
  }
  if (!temporaryPassword || typeof temporaryPassword !== "string" || temporaryPassword.length < 6) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Temporary password must be at least 6 characters."
    );
  }

  // Verify the target user exists in Firestore
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) {
    throw new functions.https.HttpsError("not-found", "User not found.");
  }

  try {
    // Update the user's Firebase Auth password
    await admin.auth().updateUser(userId, { password: temporaryPassword });

    // Set flags in Firestore so the client forces a password change
    await db.collection("users").doc(userId).update({
      mustChangePassword: true,
      isTemporaryPassword: true,
      temporaryPasswordSetAt: admin.firestore.FieldValue.serverTimestamp(),
      temporaryPasswordSetBy: adminUid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Log the action in the audit trail
    await db.collection("auditLogs").add({
      action: "setTemporaryPassword",
      targetType: "user",
      targetId: userId,
      performedBy: adminUid,
      details: {
        userEmail: userDoc.data()?.email || "unknown",
        userName: userDoc.data()?.fullName || "unknown",
        userId7: userDoc.data()?.userId7 || "unknown",
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Admin ${adminUid} set temporary password for user ${userId}`);
    return { success: true, message: "Temporary password set successfully." };
  } catch (error: any) {
    console.error(`❌ Failed to set temporary password for ${userId}:`, error);
    throw new functions.https.HttpsError(
      "internal",
      error.message || "Failed to set temporary password."
    );
  }
});

// ─── Auto Delete Guest Support Chats (> 48 Hours) ─────────────────────────────
// Automatically cleans up guest support conversations and messages older than 48 hours
export const autoDeleteGuestSupportChats = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async (_context) => {
    console.log("⏰ autoDeleteGuestSupportChats scheduled run started...");
    const fortyEightHoursAgo = new Date(Date.now() - 48 * 60 * 60 * 1000);
    try {
      const snap = await db
        .collection("supportConversations")
        .where("isGuest", "==", true)
        .where("createdAt", "<=", fortyEightHoursAgo)
        .get();

      if (snap.empty) {
        console.log("No expired guest support chats found.");
        return null;
      }

      let deletedCount = 0;
      for (const doc of snap.docs) {
        const messagesSnap = await doc.ref.collection("messages").get();
        const batch = db.batch();
        messagesSnap.docs.forEach((msgDoc) => batch.delete(msgDoc.ref));
        batch.delete(doc.ref);
        await batch.commit();
        deletedCount++;
      }

      console.log(`✅ Deleted ${deletedCount} guest support chats older than 48 hours.`);
    } catch (error) {
      console.error("autoDeleteGuestSupportChats FAILED:", error);
    }
    return null;
  });
