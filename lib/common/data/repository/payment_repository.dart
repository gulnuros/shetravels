// lib/repositories/payment_repository.dart
import 'dart:convert';
import 'dart:html' as html; // For web redirection
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

// final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
//   return PaymentRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
// });

// class PaymentRepository {
//   final FirebaseAuth _auth;
//   final FirebaseFirestore _firestore;

//   PaymentRepository(this._auth, this._firestore);

//   Future<void> handlePayment({
//     required int amount,
//     required String eventName,
//   }) async {
//     final user = _auth.currentUser;

//     if (user == null) {
//       throw Exception('User not logged in');
//     }

//     final userId = user.uid;
//     final userEmail = user.email ?? 'unknown';

//     if (kIsWeb) {
//       // 🔁 Web checkout flow
//       final url = Uri.parse(
//         'https://us-central1-shetravels-ac34a.cloudfunctions.net/createCheckoutSession',
//       );

//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({'amount': amount, 'currency': 'usd'}),
//       );

//       if (response.statusCode != 200) {
//         throw Exception('Failed to create checkout session');
//       }

//       final jsonResponse = json.decode(response.body);
//       final checkoutUrl = jsonResponse['checkoutUrl'];

//       if (checkoutUrl != null) {
//         await _firestore.collection('bookings').add({
//           'userId': userId,
//           'userEmail': userEmail,
//           'eventName': eventName,
//           'amount': amount,
//           'timestamp': FieldValue.serverTimestamp(),
//           'status': 'pending',
//           'platform': 'web',
//         });

//         // Redirect user to Stripe checkout page
//         html.window.location.href = checkoutUrl;
//       }
//     } else {
//       // 📱 Mobile (Payment Sheet)
//       final url = Uri.parse(
//         'https://us-central1-shetravels-ac34a.cloudfunctions.net/createPaymentIntent',
//       );

//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({'amount': amount, 'currency': 'usd'}),
//       );

//       if (response.statusCode != 200) {
//         throw Exception('Failed to create payment intent');
//       }

//       final jsonResponse = json.decode(response.body);
//       final clientSecret = jsonResponse['clientSecret'];

//       await Stripe.instance.initPaymentSheet(
//         paymentSheetParameters: SetupPaymentSheetParameters(
//           paymentIntentClientSecret: clientSecret,
//           merchantDisplayName: eventName,
//         ),
//       );

//       await Stripe.instance.presentPaymentSheet();

//       await _firestore.collection('bookings').add({
//         'userId': userId,
//         'userEmail': userEmail,
//         'eventName': eventName,
//         'amount': amount,
//         'timestamp': FieldValue.serverTimestamp(),
//         'status': 'paid',
//         'platform': 'mobile',
//       });
//     }
//   }

//   Future<bool> hasUserBookedEvent(String userId, String eventName) async {
//     try {
//       final bookings =
//           await _firestore
//               .collection('bookings')
//               .where('userId', isEqualTo: userId)
//               .where('eventName', isEqualTo: eventName)
//               .where('status', whereIn: ['paid', 'pending'])
//               .get();
//       return bookings.docs.isNotEmpty;
//     } catch (e) {
//       debugPrint('Error checking booking status: $e');
//       return false;
//     }
//   }

//   Map<String, int> calculateCountdown(String dateString) {
//     try {
//       final eventDate = DateTime.tryParse(dateString);
//       if (eventDate == null) {
//         return {'days': 0, 'hours': 0, 'minutes': 0};
//       }
//       final now = DateTime.now();
//       final difference = eventDate.difference(now);

//       if (difference.isNegative) {
//         return {'days': 0, 'hours': 0, 'minutes': 0};
//       }

//       return {
//         'days': difference.inDays,
//         'hours': difference.inHours % 24,
//         'minutes': difference.inMinutes % 60,
//       };
//     } catch (_) {
//       return {'days': 0, 'hours': 0, 'minutes': 0};
//     }
//   }

//   Future<int> getBookedCount(String eventName) async {
//   try {
//     final snapshot = await _firestore
//         .collection('bookings')
//         .where('eventName', isEqualTo: eventName)
//         .where('status', isEqualTo: 'paid') 
//         .get();

//     return snapshot.docs.length;
//   } catch (e) {
//     debugPrint('Error getting booked count: $e');
//     return 0;
//   }
// }

// }



// lib/repositories/payment_repository.dart
import 'dart:convert';
import 'dart:html' as html; // For web redirection
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shetravels/web_redirect_web.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

class PaymentRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  PaymentRepository(this._auth, this._firestore);

  Future<void> handlePayment({
    required int amount,
    required String eventName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userId = user.uid;
    final userEmail = user.email ?? 'unknown';
    final platform = kIsWeb ? 'web' : 'mobile';

    // 1) Create booking doc first (status = pending)
    final bookingRef = _firestore.collection('bookings').doc();
    await bookingRef.set({
      'userId': userId,
      'userEmail': userEmail,
      'eventName': eventName,
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'platform': platform,
    });

    try {
      if (kIsWeb) {
        // 2A) Web: create Stripe Checkout session (pass bookingId)
        final url = Uri.parse(
          'https://us-central1-shetravels-ac34a.cloudfunctions.net/createCheckoutSession',
        );

        final payload = json.encode({
          'amount': amount,
          'currency': 'usd',
          'bookingId': bookingRef.id,
          'userId': userId,
          'userEmail': userEmail,
          'eventName': eventName,
        });

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );

        if (response.statusCode != 200) {
          // mark booking failed or delete it
          await bookingRef.update({
            'status': 'failed',
            'error': 'createCheckoutSession_failed',
            'errorBody': response.body,
          });
          throw Exception(
            'Failed to create checkout session: ${response.body}',
          );
        }

        final jsonResponse = json.decode(response.body);
        final checkoutUrl = jsonResponse['checkoutUrl'] as String?;

        if (checkoutUrl == null || checkoutUrl.isEmpty) {
          await bookingRef.update({
            'status': 'failed',
            'error': 'no_checkout_url_returned',
          });
          throw Exception('No checkoutUrl returned from server.');
        }

        // Redirect user to Stripe Checkout
        openCheckoutUrl(
          checkoutUrl,
        ); // conditional helper: only does something on web
      } else {
        // 2B) Mobile: create PaymentIntent (pass bookingId)
        final url = Uri.parse(
          'https://us-central1-shetravels-ac34a.cloudfunctions.net/createPaymentIntent',
        );

        final payload = json.encode({
          'amount': amount,
          'currency': 'usd',
          'bookingId': bookingRef.id,
          'userId': userId,
          'userEmail': userEmail,
          'eventName': eventName,
        });

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );

        if (response.statusCode != 200) {
          await bookingRef.update({
            'status': 'failed',
            'error': 'createPaymentIntent_failed',
            'errorBody': response.body,
          });
          throw Exception('Failed to create payment intent: ${response.body}');
        }

        final jsonResponse = json.decode(response.body);
        final clientSecret = jsonResponse['clientSecret'] as String?;

        if (clientSecret == null) {
          await bookingRef.update({
            'status': 'failed',
            'error': 'no_client_secret_returned',
          });
          throw Exception('No clientSecret returned from server.');
        }

        // Initialize and present Payment Sheet
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: eventName,
          ),
        );

        await Stripe.instance.presentPaymentSheet();

        // NOTE:
        // Do NOT mark the booking "paid" here as the source-of-truth — the webhook will
        // confirm payment. If you want immediate UX feedback you can optimistically
        // update to 'processing' or 'paid' and then let webhook ensure canonical state.
      }
    } catch (e) {
      // Keep pending/failed info in Firestore, rethrow so UI can show error
      debugPrint('Payment flow error: $e');
      rethrow;
    }
  }

  // Future<void> handlePayment({
  //   required int amount,
  //   required String eventName,
  // }) async {
  //   final user = _auth.currentUser;

  //   if (user == null) {
  //     throw Exception('User not logged in');
  //   }

  //   final userId = user.uid;
  //   final userEmail = user.email ?? 'unknown';

  //   if (kIsWeb) {
  //     // 🔁 Web checkout flow
  //     final url = Uri.parse(
  //       'https://us-central1-shetravels-ac34a.cloudfunctions.net/createCheckoutSession',
  //     );

  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({'amount': amount, 'currency': 'usd'}),
  //     );

  //     if (response.statusCode != 200) {
  //       throw Exception('Failed to create checkout session');
  //     }

  //     final jsonResponse = json.decode(response.body);
  //     final checkoutUrl = jsonResponse['checkoutUrl'];

  //     if (checkoutUrl != null) {
  //       await _firestore.collection('bookings').add({
  //         'userId': userId,
  //         'userEmail': userEmail,
  //         'eventName': eventName,
  //         'amount': amount,
  //         'timestamp': FieldValue.serverTimestamp(),
  //         'status': 'pending',
  //         'platform': 'web',
  //       });

  //       // Redirect user to Stripe checkout page
  //       html.window.location.href = checkoutUrl;
  //     }
  //   } else {
  //     // 📱 Mobile (Payment Sheet)
  //     final url = Uri.parse(
  //       'https://us-central1-shetravels-ac34a.cloudfunctions.net/createPaymentIntent',
  //     );

  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({'amount': amount, 'currency': 'usd'}),
  //     );

  //     if (response.statusCode != 200) {
  //       throw Exception('Failed to create payment intent');
  //     }

  //     final jsonResponse = json.decode(response.body);
  //     final clientSecret = jsonResponse['clientSecret'];

  //     await Stripe.instance.initPaymentSheet(
  //       paymentSheetParameters: SetupPaymentSheetParameters(
  //         paymentIntentClientSecret: clientSecret,
  //         merchantDisplayName: eventName,
  //       ),
  //     );

  //     await Stripe.instance.presentPaymentSheet();

  //     await _firestore.collection('bookings').add({
  //       'userId': userId,
  //       'userEmail': userEmail,
  //       'eventName': eventName,
  //       'amount': amount,
  //       'timestamp': FieldValue.serverTimestamp(),
  //       'status': 'paid',
  //       'platform': 'mobile',
  //     });
  //   }
  // }

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
}
