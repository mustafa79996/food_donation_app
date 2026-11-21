const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const cloudinary = require("cloudinary").v2;

admin.initializeApp();

/**
 * 1. AI Support Assistant (Mia) - Secure Server-Side Execution
 *
 * The Gemini API key is securely retrieved from Cloud Secret Manager
 * or environment variables on Google Cloud. It is NEVER shipped in the APK.
 */
exports.chatWithMia = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated before allowing AI queries
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in to chat with Mia."
    );
  }

  const userMessage = (data && data.message ? String(data.message) : "").trim();
  if (!userMessage) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Message cannot be empty."
    );
  }

  const apiKey = process.env.GEMINI_API_KEY || functions.config().gemini?.key;
  if (!apiKey) {
    return {
      reply:
        "Hi! I'm Mia, FoodLink's live support agent. I'm currently running in standard mode. How can I help you today?",
    };
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: "gemini-1.5-flash",
      systemInstruction:
        "You are Mia, the warm, supportive, and knowledgeable live AI agent for FoodLink. " +
        "FoodLink is a food donation platform connecting surplus meal donors with verified welfare centres. " +
        "Help users with donating surplus food, checking food safety & shelf life, finding welfare centres, " +
        "or registering a welfare centre. Keep answers concise, clear, and encouraging.",
    });

    const result = await model.generateContent(userMessage);
    const responseText = result.response.text();

    return { reply: responseText };
  } catch (error) {
    functions.logger.error("Error communicating with Gemini AI:", error);
    return {
      reply:
        "I'm having a brief issue connecting to my AI core, but I'm here! Please check the Food Safety checklist or your Welfare Dashboard.",
    };
  }
});

/**
 * 2. Secure Cloudinary Signed Upload
 *
 * Keeps CLOUDINARY_API_SECRET strictly on the server.
 * Instead of embedding secret keys in the app, this function returns a signed signature.
 */
exports.getCloudinarySignature = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required to upload assets."
    );
  }

  const cloudName = process.env.CLOUDINARY_CLOUD_NAME || functions.config().cloudinary?.cloud_name;
  const apiSecret = process.env.CLOUDINARY_API_SECRET || functions.config().cloudinary?.api_secret;
  const apiKey = process.env.CLOUDINARY_API_KEY || functions.config().cloudinary?.api_key;

  if (!apiSecret || !cloudName || !apiKey) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Cloudinary credentials are not configured on the server."
    );
  }

  const timestamp = Math.round(new Date().getTime() / 1000);
  const signature = cloudinary.utils.api_sign_request(
    { timestamp, folder: "foodlink_uploads" },
    apiSecret
  );

  return {
    signature,
    timestamp,
    apiKey,
    cloudName,
    folder: "foodlink_uploads",
  };
});

/**
 * 3. Secure Role Management (Admin-only)
 *
 * Grants admin or centre roles and syncs custom claims.
 * Only existing admins can assign roles to other users.
 */
exports.setUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }

  // Caller must have admin claim or role: 'admin' in Firestore
  const callerDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
  const callerRole = callerDoc.data()?.role;
  const isCallerAdmin = context.auth.token.role === "admin" || callerRole === "admin";

  if (!isCallerAdmin) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only administrators can assign user roles."
    );
  }

  const { targetUid, role } = data;
  if (!targetUid || !["admin", "welfare", "donor"].includes(role)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Valid targetUid and role ('admin', 'welfare', 'donor') required."
    );
  }

  // Set Firebase Auth custom claim
  await admin.auth().setCustomUserClaims(targetUid, { role });

  // Update Firestore user document
  await admin.firestore().collection("users").doc(targetUid).set(
    {
      role: role,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { success: true, targetUid, role };
});
