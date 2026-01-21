import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:shetravels/payment/success.dart';
import 'package:shetravels/utils/route.gr.dart';

class PaymentNavigationHelper {
  static void navigateToSuccessFromWeb(
    BuildContext context,
    String eventName, {
    String? bookingId,
    String? sessionId,
  }) {
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
  static void navigateToSuccessGeneric(BuildContext context, String eventName) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(eventName: eventName),
      ),
    );
  }
}
