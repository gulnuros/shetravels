const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(functions.config().stripe.secret_key);
const cors = require("cors")({origin: true});

admin.initializeApp();

/**
 * Create a Stripe Checkout Session for web payments
 * POST /createCheckoutSession
 * Body: { amount, currency, bookingId, userId, userEmail, eventName, metadata }
 */
exports.createCheckoutSession = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    // Only allow POST requests
    if (req.method !== "POST") {
      return res.status(405).json({error: "Method not allowed"});
    }

    try {
      const {
        amount,
        currency = "cad",
        bookingId,
        userId,
        userEmail,
        eventName,
        metadata = {},
      } = req.body;

      // Validate required fields
      if (!amount || !bookingId || !userId || !eventName) {
        return res.status(400).json({
          error: "Missing required fields: amount, bookingId, userId, eventName",
        });
      }

      console.log(`Creating checkout session for booking: ${bookingId}`);

      // Get the base URL for redirects
      const baseUrl = req.headers.origin || "http://localhost:8080";

      // Create Stripe Checkout Session
      const session = await stripe.checkout.sessions.create({
        payment_method_types: ["card"],
        mode: "payment",
        customer_email: userEmail,
        line_items: [
          {
            price_data: {
              currency: currency.toLowerCase(),
              product_data: {
                name: eventName,
                description: `Booking for ${eventName}`,
              },
              unit_amount: amount, // Amount in cents
            },
            quantity: 1,
          },
        ],
        metadata: {
          bookingId: bookingId,
          userId: userId,
          eventName: eventName,
          ...metadata,
        },
        success_url: `${baseUrl}/payment-success?` +
          `session_id={CHECKOUT_SESSION_ID}&` +
          `booking_id=${bookingId}&` +
          `event_name=${encodeURIComponent(eventName)}`,
        cancel_url: `${baseUrl}/?cancelled=true`,
      });

      console.log(`Checkout session created: ${session.id}`);

      // Update booking with session info
      await admin.firestore().collection("bookings").doc(bookingId).update({
        stripeSessionId: session.id,
        status: "processing",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.status(200).json({
        checkoutUrl: session.url,
        sessionId: session.id,
      });
    } catch (error) {
      console.error("Error creating checkout session:", error);
      return res.status(500).json({
        error: error.message || "Failed to create checkout session",
      });
    }
  });
});

/**
 * Create a Stripe Payment Intent for mobile payments
 * POST /createPaymentIntent
 * Body: { amount, currency, bookingId, userId, userEmail, eventName, metadata }
 */
exports.createPaymentIntent = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    // Only allow POST requests
    if (req.method !== "POST") {
      return res.status(405).json({error: "Method not allowed"});
    }

    try {
      const {
        amount,
        currency = "cad",
        bookingId,
        userId,
        userEmail,
        eventName,
        metadata = {},
      } = req.body;

      // Validate required fields
      if (!amount || !bookingId || !userId || !eventName) {
        return res.status(400).json({
          error: "Missing required fields: amount, bookingId, userId, eventName",
        });
      }

      console.log(`Creating payment intent for booking: ${bookingId}`);

      // Create Stripe Payment Intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: amount,
        currency: currency.toLowerCase(),
        receipt_email: userEmail,
        metadata: {
          bookingId: bookingId,
          userId: userId,
          eventName: eventName,
          ...metadata,
        },
        description: `Booking for ${eventName}`,
      });

      console.log(`Payment intent created: ${paymentIntent.id}`);

      // Update booking with payment intent info
      await admin.firestore().collection("bookings").doc(bookingId).update({
        stripePaymentIntentId: paymentIntent.id,
        status: "processing",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.status(200).json({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      });
    } catch (error) {
      console.error("Error creating payment intent:", error);
      return res.status(500).json({
        error: error.message || "Failed to create payment intent",
      });
    }
  });
});

/**
 * Stripe Webhook Handler
 * Listens to Stripe events and updates Firestore accordingly
 * POST /stripeWebhook
 */
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  const webhookSecret = functions.config().stripe.webhook_secret;

  let event;

  try {
    // Verify webhook signature
    event = stripe.webhooks.constructEvent(
        req.rawBody,
        sig,
        webhookSecret,
    );
  } catch (err) {
    console.error("Webhook signature verification failed:", err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  console.log(`Webhook received: ${event.type}`);

  // Handle the event
  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object;
        await handleCheckoutSessionCompleted(session);
        break;
      }

      case "payment_intent.succeeded": {
        const paymentIntent = event.data.object;
        await handlePaymentIntentSucceeded(paymentIntent);
        break;
      }

      case "payment_intent.payment_failed": {
        const paymentIntent = event.data.object;
        await handlePaymentIntentFailed(paymentIntent);
        break;
      }

      case "charge.refunded": {
        const charge = event.data.object;
        await handleChargeRefunded(charge);
        break;
      }

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.status(200).json({received: true});
  } catch (error) {
    console.error("Error handling webhook:", error);
    res.status(500).json({error: error.message});
  }
});

/**
 * Handle successful checkout session
 */
async function handleCheckoutSessionCompleted(session) {
  const bookingId = session.metadata.bookingId;

  if (!bookingId) {
    console.error("No bookingId in session metadata");
    return;
  }

  console.log(`Checkout session completed for booking: ${bookingId}`);

  try {
    await admin.firestore().collection("bookings").doc(bookingId).update({
      status: "paid",
      stripeStatus: "checkout_session_completed",
      stripeSessionId: session.id,
      stripePaymentIntentId: session.payment_intent,
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      amount: session.amount_total,
      currency: session.currency,
    });

    console.log(`Booking ${bookingId} marked as paid`);

    // TODO: Send confirmation email
    // TODO: Update event available slots
  } catch (error) {
    console.error(`Error updating booking ${bookingId}:`, error);
    throw error;
  }
}

/**
 * Handle successful payment intent (mobile payments)
 */
async function handlePaymentIntentSucceeded(paymentIntent) {
  const bookingId = paymentIntent.metadata.bookingId;

  if (!bookingId) {
    console.error("No bookingId in payment intent metadata");
    return;
  }

  console.log(`Payment intent succeeded for booking: ${bookingId}`);

  try {
    await admin.firestore().collection("bookings").doc(bookingId).update({
      status: "paid",
      stripeStatus: "payment_intent_succeeded",
      stripePaymentIntentId: paymentIntent.id,
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
    });

    console.log(`Booking ${bookingId} marked as paid`);
  } catch (error) {
    console.error(`Error updating booking ${bookingId}:`, error);
    throw error;
  }
}

/**
 * Handle failed payment intent
 */
async function handlePaymentIntentFailed(paymentIntent) {
  const bookingId = paymentIntent.metadata.bookingId;

  if (!bookingId) {
    console.error("No bookingId in payment intent metadata");
    return;
  }

  console.log(`Payment intent failed for booking: ${bookingId}`);

  try {
    await admin.firestore().collection("bookings").doc(bookingId).update({
      status: "failed",
      stripeStatus: "payment_intent_failed",
      stripePaymentIntentId: paymentIntent.id,
      error: "payment_failed",
      errorMessage: paymentIntent.last_payment_error?.message ||
        "Payment failed",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Booking ${bookingId} marked as failed`);
  } catch (error) {
    console.error(`Error updating booking ${bookingId}:`, error);
    throw error;
  }
}

/**
 * Handle charge refunded
 */
async function handleChargeRefunded(charge) {
  const paymentIntentId = charge.payment_intent;

  if (!paymentIntentId) {
    console.error("No payment intent ID in charge");
    return;
  }

  console.log(`Charge refunded for payment intent: ${paymentIntentId}`);

  try {
    // Find booking by payment intent ID
    const bookingsSnapshot = await admin.firestore()
        .collection("bookings")
        .where("stripePaymentIntentId", "==", paymentIntentId)
        .limit(1)
        .get();

    if (bookingsSnapshot.empty) {
      console.error(`No booking found for payment intent: ${paymentIntentId}`);
      return;
    }

    const bookingDoc = bookingsSnapshot.docs[0];

    await bookingDoc.ref.update({
      status: "refunded",
      stripeStatus: "charge_refunded",
      refundedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      refundAmount: charge.amount_refunded,
    });

    console.log(`Booking ${bookingDoc.id} marked as refunded`);
  } catch (error) {
    console.error("Error handling refund:", error);
    throw error;
  }
}
