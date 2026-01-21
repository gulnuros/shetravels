import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shetravels/web_redirect_web.dart';

// TODO: After deploying Cloud Functions, update this with your actual function URL
// Example: 'https://us-central1-she-travels-5578a.cloudfunctions.net'
const String _baseUrl = 'https://us-central1-she-travels-5578a.cloudfunctions.net';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

class PaymentRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  PaymentRepository(this._auth, this._firestore);

  Future<String> handlePayment({
    required int amount,
    required String eventName,
    required String bookingId, 
    Map<String, String>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userId = user.uid;
    final userEmail = user.email ?? 'unknown';

    try {
      if (kIsWeb) {
        await _handleWebPayment(
          bookingId,
          amount,
          userId,
          userEmail,
          eventName,
          metadata: metadata,
        );
        return bookingId;
      } else {
        await _handleMobilePayment(
          bookingId,
          amount,
          userId,
          userEmail,
          eventName,
          metadata: metadata,
        );
        return bookingId;
      }
    } catch (e) {
      debugPrint(' Payment flow error: $e');
      try {
        await _firestore.collection('bookings').doc(bookingId).update({
          'status': 'failed',
          'error': 'payment_flow_error',
          'errorMessage': e.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (updateError) {
        debugPrint('Failed to update booking status: $updateError');
      }

      rethrow;
    }
  }

  Future<String> createBooking({
    required String eventName,
    required int amount,
    required String userId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userEmail = user.email ?? 'unknown';
    final platform = kIsWeb ? 'web' : 'mobile';

    final bookingRef = _firestore.collection('bookings').doc();
    final bookingData = {
      'userId': userId,
      'userEmail': userEmail,
      'eventName': eventName,
      'amount': amount,
      'currency': 'CAD',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'platform': platform,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await bookingRef.set(bookingData);
    debugPrint(' Booking document created: ${bookingRef.id}');

    return bookingRef.id;
  }

  Future<void> _handleWebPayment(
    String bookingId,
    int amount,
    String userId,
    String userEmail,
    String eventName, {
    Map<String, String>? metadata,
  }) async {
    final url = Uri.parse('$_baseUrl/createCheckoutSession');

    final payload = json.encode({
      'amount': amount,
      'currency': 'cad',
      'bookingId': bookingId,
      'userId': userId,
      'userEmail': userEmail,
      'eventName': eventName,
      'metadata': metadata ?? {},
    });

    debugPrint(' Creating checkout session for booking: $bookingId');
    debugPrint(' Request URL: $url'); 
    debugPrint(' Request payload: $payload'); 

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: payload,
    );

    debugPrint(' Response status: ${response.statusCode}'); 
    debugPrint(' Response body: ${response.body}'); 

    if (response.statusCode != 200) {
      debugPrint(' Checkout session creation failed: ${response.body}');
      throw Exception('Failed to create checkout session: ${response.body}');
    }

    final jsonResponse = json.decode(response.body);
    debugPrint(' Parsed response: $jsonResponse'); 

    final checkoutUrl = jsonResponse['checkoutUrl'] as String?;

    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      debugPrint(' Available keys in response: ${jsonResponse.keys}');
      throw Exception(
        'No checkoutUrl returned from server. Response: $jsonResponse',
      );
    }

    debugPrint(' Checkout session created. Redirecting to: $checkoutUrl');

    openCheckoutUrl(checkoutUrl);
  }

  Future<void> _handleMobilePayment(
    String bookingId,
    int amount,
    String userId,
    String userEmail,
    String eventName, {
    Map<String, String>? metadata, 
  }) async {
    final url = Uri.parse('$_baseUrl/createPaymentIntent');

    final payload = json.encode({
      'amount': amount,
      'currency': 'cad',
      'bookingId': bookingId,
      'userId': userId,
      'userEmail': userEmail,
      'eventName': eventName,
      'metadata': metadata ?? {},
    });

    debugPrint('📱 Creating payment intent for booking: $bookingId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: payload,
    );

    if (response.statusCode != 200) {
      debugPrint(' Payment intent creation failed: ${response.body}');
      throw Exception('Failed to create payment intent: ${response.body}');
    }

    final jsonResponse = json.decode(response.body);
    final clientSecret = jsonResponse['clientSecret'] as String?;
    final paymentIntentId =
        jsonResponse['paymentIntentId'] as String?; 

    if (clientSecret == null) {
      throw Exception('No clientSecret returned from server.');
    }

    debugPrint(' Payment intent created. Initializing payment sheet...');

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: eventName,
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: Color(0xFFE91E63)),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      debugPrint(' Payment sheet completed successfully');
      await Future.delayed(
        const Duration(seconds: 1),
      ); 
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'paid',
        'stripePaymentIntentId': paymentIntentId,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(' Booking marked as paid');
    } on StripeException catch (e) {
      debugPrint(' Stripe payment error: ${e.error}');

      if (e.error.type == 'canceled') {
        await _firestore.collection('bookings').doc(bookingId).update({
          'status': 'cancelled',
          'error': 'user_cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        throw Exception('Payment was cancelled by user');
      } else {
        await _firestore.collection('bookings').doc(bookingId).update({
          'status': 'failed',
          'error': 'stripe_error',
          'errorMessage': e.error.message ?? 'Unknown Stripe error',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        throw Exception('Payment failed: ${e.error.message}');
      }
    }
  }

  Future<bool> hasUserBookedEvent(String userId, String eventName) async {
    try {
      final bookings =
          await _firestore
              .collection('bookings')
              .where('userId', isEqualTo: userId)
              .where('eventName', isEqualTo: eventName)
              .where('status', whereIn: ['paid', 'pending'])
              .get();

      return bookings.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking booking status: $e');
      return false;
    }
  }

  Future<int> getBookedCount(String eventName) async {
    try {
      final snapshot =
          await _firestore
              .collection('bookings')
              .where('eventName', isEqualTo: eventName)
              .where('status', isEqualTo: 'paid')
              .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting booked count: $e');
      return 0;
    }
  }

  Map<String, int> calculateCountdown(String dateString) {
    try {
      final eventDate = DateTime.tryParse(dateString);
      if (eventDate == null) {
        return {'days': 0, 'hours': 0, 'minutes': 0};
      }
      final now = DateTime.now();
      final difference = eventDate.difference(now);

      if (difference.isNegative) {
        return {'days': 0, 'hours': 0, 'minutes': 0};
      }

      return {
        'days': difference.inDays,
        'hours': difference.inHours % 24,
        'minutes': difference.inMinutes % 60,
      };
    } catch (_) {
      return {'days': 0, 'hours': 0, 'minutes': 0};
    }
  }

  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Error getting booking: $e');
      return null;
    }
  }

  Stream<DocumentSnapshot> watchBookingStatus(String bookingId) {
    return _firestore.collection('bookings').doc(bookingId).snapshots();
  }

  Future<void> retryPayment(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      if (booking['status'] != 'failed' && booking['status'] != 'cancelled') {
        throw Exception('Booking is not in a retryable state');
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'pending',
        'error': null,
        'errorMessage': null,
        'retryAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await handlePayment(
        amount: booking['amount'],
        eventName: booking['eventName'],
        bookingId: bookingId, 
        metadata: {'bookingId': bookingId, 'eventName': booking['eventName']},
      );
    } catch (e) {
      debugPrint('Error retrying payment: $e');
      rethrow;
    }
  }
}
