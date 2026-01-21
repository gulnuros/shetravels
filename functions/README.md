# SheTravels Firebase Cloud Functions

This directory contains Firebase Cloud Functions for handling Stripe payments.

## Functions

### 1. `createCheckoutSession`
- **URL:** `https://us-central1-she-travels-5578a.cloudfunctions.net/createCheckoutSession`
- **Method:** POST
- **Purpose:** Creates a Stripe Checkout Session for web payments
- **Request Body:**
  ```json
  {
    "amount": 35000,
    "currency": "cad",
    "bookingId": "booking_id_here",
    "userId": "user_id_here",
    "userEmail": "user@example.com",
    "eventName": "Summer Mountain Retreat",
    "metadata": {}
  }
  ```
- **Response:**
  ```json
  {
    "checkoutUrl": "https://checkout.stripe.com/...",
    "sessionId": "cs_..."
  }
  ```

### 2. `createPaymentIntent`
- **URL:** `https://us-central1-she-travels-5578a.cloudfunctions.net/createPaymentIntent`
- **Method:** POST
- **Purpose:** Creates a Stripe Payment Intent for mobile payments
- **Request Body:**
  ```json
  {
    "amount": 35000,
    "currency": "cad",
    "bookingId": "booking_id_here",
    "userId": "user_id_here",
    "userEmail": "user@example.com",
    "eventName": "Summer Mountain Retreat",
    "metadata": {}
  }
  ```
- **Response:**
  ```json
  {
    "clientSecret": "pi_..._secret_...",
    "paymentIntentId": "pi_..."
  }
  ```

### 3. `stripeWebhook`
- **URL:** `https://us-central1-she-travels-5578a.cloudfunctions.net/stripeWebhook`
- **Method:** POST
- **Purpose:** Receives Stripe webhook events
- **Events Handled:**
  - `checkout.session.completed` - Payment successful (web)
  - `payment_intent.succeeded` - Payment successful (mobile)
  - `payment_intent.payment_failed` - Payment failed
  - `charge.refunded` - Refund processed

## Setup Instructions

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure Stripe Keys

Set your Stripe secret key and webhook secret as Firebase config:

```bash
# Set Stripe secret key
firebase functions:config:set stripe.secret_key="sk_test_YOUR_KEY_HERE"

# Set Stripe webhook secret (after creating webhook in Stripe Dashboard)
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"
```

**For production:**
```bash
firebase functions:config:set stripe.secret_key="sk_live_YOUR_LIVE_KEY_HERE"
```

### 3. Deploy Functions

```bash
# From project root
firebase deploy --only functions

# Or deploy individual functions
firebase deploy --only functions:createCheckoutSession
firebase deploy --only functions:createPaymentIntent
firebase deploy --only functions:stripeWebhook
```

### 4. Configure Stripe Webhook

After deploying, configure the webhook in Stripe Dashboard:

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/) → Developers → Webhooks
2. Click "Add endpoint"
3. Enter URL: `https://us-central1-she-travels-5578a.cloudfunctions.net/stripeWebhook`
4. Select events:
   - `checkout.session.completed`
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `charge.refunded`
5. Copy the webhook signing secret
6. Set it in Firebase config:
   ```bash
   firebase functions:config:set stripe.webhook_secret="whsec_..."
   ```

### 5. Update Flutter App

Update the base URL in `lib/common/data/repository/payment_repository.dart`:

```dart
const String _baseUrl = 'https://us-central1-she-travels-5578a.cloudfunctions.net';
```

## Local Development

### Run Functions Locally

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Download config to local
firebase functions:config:get > functions/.runtimeconfig.json

# Start emulator
firebase emulators:start --only functions
```

Functions will be available at:
- `http://localhost:5001/she-travels-5578a/us-central1/createCheckoutSession`
- `http://localhost:5001/she-travels-5578a/us-central1/createPaymentIntent`
- `http://localhost:5001/she-travels-5578a/us-central1/stripeWebhook`

### Test with curl

```bash
# Test createCheckoutSession
curl -X POST \
  http://localhost:5001/she-travels-5578a/us-central1/createCheckoutSession \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 35000,
    "currency": "cad",
    "bookingId": "test123",
    "userId": "user123",
    "userEmail": "test@example.com",
    "eventName": "Test Event"
  }'
```

## Monitoring

### View Logs

```bash
# View all function logs
firebase functions:log

# View specific function logs
firebase functions:log --only createCheckoutSession

# Stream logs in real-time
firebase functions:log --follow
```

### Firebase Console

View logs in Firebase Console:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `she-travels-5578a`
3. Go to Functions → Logs

## Security

- ✅ Stripe secret key is stored securely in Firebase config (not in code)
- ✅ CORS enabled to allow requests from your domain
- ✅ Webhook signature verification prevents unauthorized requests
- ✅ All sensitive operations happen on the backend

## Troubleshooting

### "stripe.secret_key is not set"

Run:
```bash
firebase functions:config:set stripe.secret_key="sk_test_..."
firebase deploy --only functions
```

### "Webhook signature verification failed"

Make sure:
1. Webhook secret is set: `firebase functions:config:set stripe.webhook_secret="whsec_..."`
2. You're using the correct webhook URL in Stripe Dashboard
3. Redeploy functions after setting the secret

### CORS errors

Functions already have CORS enabled for all origins. If issues persist, check:
- Request includes `Content-Type: application/json` header
- Using POST method (not GET)

### Function timeout

Current timeout is default (60s). To increase:
```javascript
exports.createCheckoutSession = functions
  .runWith({timeoutSeconds: 300})
  .https.onRequest(...);
```

## Cost Estimation

Firebase Cloud Functions pricing (Blaze plan):
- First 2M invocations/month: FREE
- After that: $0.40 per million invocations
- Typical cost for small business: $0-5/month

## Next Steps

1. Deploy functions: `firebase deploy --only functions`
2. Configure Stripe webhook
3. Update Flutter app with function URLs
4. Test with Stripe test card: 4242 4242 4242 4242
5. Monitor logs for first few transactions
