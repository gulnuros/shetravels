import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/booking/views/payment_success.dart';
import 'package:shetravels/common/data/repository/payment_repository.dart';
import 'package:shetravels/payment/success.dart';
import 'package:shetravels/web_redirect_web.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Add this to your main app widget or home screen
class AppWithPaymentCheck extends ConsumerStatefulWidget {
  final Widget child;
  
  const AppWithPaymentCheck({super.key, required this.child});

  @override
  ConsumerState<AppWithPaymentCheck> createState() => _AppWithPaymentCheckState();
}

class _AppWithPaymentCheckState extends ConsumerState<AppWithPaymentCheck> {
  @override
  void initState() {
    super.initState();
    
    // Check for payment success on web
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForPaymentSuccess();
      });
    }
  }

  void _checkForPaymentSuccess() {
    try {
      // Handle success redirect first
      handleSuccessRedirect();
      
      // Get success parameters
      final params = getSuccessParameters();
      final isSuccess = params['isSuccess'] == 'true';
      
      if (isSuccess) {
        final bookingId = params['bookingId'];
        final sessionId = params['sessionId'];
        
        // Clear the parameters
        clearSuccessParameters();
        
        // Navigate to success screen
        // You'll need to determine the event name somehow
        // You can either:
        // 1. Store it in localStorage during payment initiation
        // 2. Fetch it from Firebase using the bookingId
        // 3. Pass it as a URL parameter
        
        if (bookingId != null) {
          _navigateToSuccessWithBookingId(bookingId, sessionId);
        } else {
          // Fallback: show a generic success message
          _showGenericSuccessMessage();
        }
      } else if (isPaymentCancelled()) {
        _showCancellationMessage();
      }
    } catch (e) {
      debugPrint('Error checking payment success: $e');
    }
  }

  void _navigateToSuccessWithBookingId(String bookingId, String? sessionId) async {
    try {
      // First check if we have the event name in localStorage
      final params = getSuccessParameters();
      final eventName = params['eventName'];
      
      if (eventName != null && mounted) {
        // We have the event name, navigate directly
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              eventName: eventName,
              bookingId: bookingId,
              sessionId: sessionId,
            ),
          ),
        );
        return;
      }
      
      // Fallback: Fetch booking details to get event name
      final paymentRepo = ref.read(paymentRepositoryProvider);
      final booking = await paymentRepo.getBookingById(bookingId);
      
      if (booking != null && mounted) {
        final fetchedEventName = booking['eventName'] as String? ?? 'Event';
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              eventName: fetchedEventName,
              bookingId: bookingId,
              sessionId: sessionId,
            ),
          ),
        );
      } else {
        _showGenericSuccessMessage();
      }
    } catch (e) {
      debugPrint('Error fetching booking details: $e');
      _showGenericSuccessMessage();
    }
  }

  void _showGenericSuccessMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment completed successfully!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'View Bookings',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to bookings page or profile
              // Navigator.pushNamed(context, '/bookings');
            },
          ),
        ),
      );
    }
  }

  void _showCancellationMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment was cancelled'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Usage in your main.dart or app.dart:
// 
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Consumer(
//         builder: (context, ref, child) {
//           return AppWithPaymentCheck(
//             child: YourHomeScreen(), // Your actual home screen
//           );
//         },
//       ),
//     );
//   }
// }