import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/common/data/repository/payment_repository.dart';
import 'package:shetravels/payment/success.dart';
import 'package:shetravels/web_redirect_web.dart';


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
    
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForPaymentSuccess();
      });
    }
  }

  void _checkForPaymentSuccess() {
    try {
      handleSuccessRedirect();
      final params = getSuccessParameters();
      final isSuccess = params['isSuccess'] == 'true';
      
      if (isSuccess) {
        final bookingId = params['bookingId'];
        final sessionId = params['sessionId'];
        
        clearSuccessParameters();
     
        
        if (bookingId != null) {
          _navigateToSuccessWithBookingId(bookingId, sessionId);
        } else {
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
      final params = getSuccessParameters();
      final eventName = params['eventName'];
      
      if (eventName != null && mounted) {
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
