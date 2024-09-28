/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// functions/index.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.joinGroup = functions.https.onCall(async (data, context) => {
    // Check if the user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated to join a group.'
        );
    }

    const userId = context.auth.uid;
    const groupId = data.groupId;

    if (!groupId) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'The function must be called with a groupId.'
        );
    }

    const groupRef = admin.firestore().collection('groups').doc(groupId);

    try {
        const groupDoc = await groupRef.get();

        if (!groupDoc.exists) {
            throw new functions.https.HttpsError(
                'not-found',
                'Group does not exist.'
            );
        }

        const groupData = groupDoc.data();
        const members = groupData.members || {};

        if (members[userId]) {
            throw new functions.https.HttpsError(
                'already-exists',
                'User is already a member of this group.'
            );
        }

        // Add the user to the members map
        await groupRef.update({
            [`members.${userId}`]: true
        });

        return { success: true, message: 'Successfully joined the group.' };
    } catch (error) {
        if (error instanceof functions.https.HttpsError) {
            throw error; // Re-throw known HttpsErrors
        } else {
            console.error('Error joining group:', error);
            throw new functions.https.HttpsError(
                'internal',
                'An unexpected error occurred.'
            );
        }
    }
});

