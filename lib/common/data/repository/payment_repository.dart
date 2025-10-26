// lib/repositories/payment_repository.dart
import 'dart:convert';
import 'dart:html' as html; // For web redirection
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shetravels/web_redirect_web.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:html' as html show window; // For web localStorage

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

class PaymentRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Cloud Functions URLs
  static const String _baseUrl =
      'https://us-central1-shetravels-ac34a.cloudfunctions.net';

  PaymentRepository(this._auth, this._firestore);

  Future<String> handlePayment({
    required int amount, // amount in cents (e.g. 1000 = CAD $10.00)
    required String eventName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userId = user.uid;
    final userEmail = user.email ?? 'unknown';
    final platform = kIsWeb ? 'web' : 'mobile';

    // 1) Create booking document first (status = pending)
    final bookingRef = _firestore.collection('bookings').doc();
    final bookingData = {
      'userId': userId,
      'userEmail': userEmail,
      'eventName': eventName,
      'amount': amount, // stored in cents
      'currency': 'CAD',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'platform': platform,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await bookingRef.set(bookingData);
      debugPrint('✅ Booking document created: ${bookingRef.id}');

      if (kIsWeb) {
        // 2A) Web: create Stripe Checkout session
        await _handleWebPayment(
          bookingRef.id,
          amount,
          userId,
          userEmail,
          eventName,
        );
        return bookingRef.id;
      } else {
        // 2B) Mobile: create PaymentIntent and show Payment Sheet
        await _handleMobilePayment(
          bookingRef.id,
          amount,
          userId,
          userEmail,
          eventName,
        );
        return bookingRef.id;
      }
    } catch (e) {
      debugPrint('❌ Payment flow error: $e');

      // Update booking status to failed
      try {
        await bookingRef.update({
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

  Future<void> _handleWebPayment(
    String bookingId,
    int amount,
    String userId,
    String userEmail,
    String eventName,
  ) async {
    final url = Uri.parse('$_baseUrl/createCheckoutSession');

    final payload = json.encode({
      'amount': amount,
      'currency': 'cad',
      'bookingId': bookingId,
      'userId': userId,
      'userEmail': userEmail,
      'eventName': eventName,
    });

    debugPrint('🌐 Creating checkout session for booking: $bookingId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: payload,
    );

    if (response.statusCode != 200) {
      debugPrint('❌ Checkout session creation failed: ${response.body}');
      throw Exception('Failed to create checkout session: ${response.body}');
    }

    final jsonResponse = json.decode(response.body);
    final checkoutUrl = jsonResponse['checkoutUrl'] as String?;

    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw Exception('No checkoutUrl returned from server.');
    }

    debugPrint('✅ Checkout session created. Redirecting to: $checkoutUrl');

    // Import and use your web redirect function
    openCheckoutUrl(checkoutUrl);
  }

  Future<void> _handleMobilePayment(
    String bookingId,
    int amount,
    String userId,
    String userEmail,
    String eventName,
  ) async {
    final url = Uri.parse('$_baseUrl/createPaymentIntent');

    final payload = json.encode({
      'amount': amount,
      'currency': 'cad',
      'bookingId': bookingId,
      'userId': userId,
      'userEmail': userEmail,
      'eventName': eventName,
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
      debugPrint('❌ Payment intent creation failed: ${response.body}');
      throw Exception('Failed to create payment intent: ${response.body}');
    }

    final jsonResponse = json.decode(response.body);
    final clientSecret = jsonResponse['clientSecret'] as String?;

    if (clientSecret == null) {
      throw Exception('No clientSecret returned from server.');
    }

    debugPrint('✅ Payment intent created. Initializing payment sheet...');

    try {
      // Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: eventName,
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFFE91E63), // Pink theme
            ),
          ),
        ),
      );

      // Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      debugPrint('✅ Payment sheet completed successfully');

      // Note: Don't mark as paid here - let the webhook handle it
      // The webhook will update the status to 'paid' when payment succeeds
    } on StripeException catch (e) {
      debugPrint('❌ Stripe payment error: ${e.error}');

      if (e.error.type == 'canceled') {
        // User canceled - update booking status
        await _firestore.collection('bookings').doc(bookingId).update({
          'status': 'cancelled',
          'error': 'user_cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        throw Exception('Payment was cancelled by user');
      } else {
        // Payment failed - update booking status
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

  // New method to get booking status by ID
  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Error getting booking: $e');
      return null;
    }
  }

  // New method to listen to booking status changes
  Stream<DocumentSnapshot> watchBookingStatus(String bookingId) {
    return _firestore.collection('bookings').doc(bookingId).snapshots();
  }

  // Method to retry failed payments
  Future<void> retryPayment(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      if (booking['status'] != 'failed' && booking['status'] != 'cancelled') {
        throw Exception('Booking is not in a retryable state');
      }

      // Reset booking status to pending
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'pending',
        'error': null,
        'errorMessage': null,
        'retryAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Retry the payment flow
      await handlePayment(
        amount: booking['amount'],
        eventName: booking['eventName'],
      );
    } catch (e) {
      debugPrint('Error retrying payment: $e');
      rethrow;
    }
  }
}




// https://us-central1-shetravels-ac34a.cloudfunctions.net/handleStripeWebhook