import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:shetravels/booking/views/payment_success.dart';
import 'package:shetravels/payment/success.dart';
import 'package:shetravels/utils/route.gr.dart';

class PaymentNavigationHelper {
  /// Navigate to success screen from web redirect
  static void navigateToSuccessFromWeb(
    BuildContext context,
    String eventName, {
    String? bookingId,
    String? sessionId,
  }) {
    // Extract parameters from URL if available
    final uri = Uri.base;
    final extractedBookingId = bookingId ?? uri.queryParameters['booking_id'];
    final extractedSessionId = sessionId ?? uri.queryParameters['session_id'];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentSuccessScreen(
              eventName: eventName,
              bookingId: extractedBookingId,
              sessionId: extractedSessionId,
            ),
      ),
    );
  }

  /// Navigate to success screen from mobile payment
  static void navigateToSuccessFromMobile(
    BuildContext context,
    String eventName, {
    String? bookingId,
    String? paymentIntentId,
  }) {
    context.router.push(PaymentSuccessRoute(
              eventName: eventName,
              bookingId: bookingId,
              paymentIntentId: paymentIntentId,
            ),);
  }

  /// Navigate to success screen with minimal info (will auto-find booking)
  static void navigateToSuccessGeneric(BuildContext context, String eventName) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(eventName: eventName),
      ),
    );
  }
}
