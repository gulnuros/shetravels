import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/common/data/repository/payment_repository.dart';

// final paymentNotifierProvider = ChangeNotifierProvider<PaymentNotifier>((ref) {
//   final repo = ref.read(paymentRepositoryProvider);
//   return PaymentNotifier(repo);
// });

// class PaymentNotifier extends ChangeNotifier {
//   final PaymentRepository _repository;
//   bool _isLoading = false;
//   String? _errorMessage;

//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;

//   PaymentNotifier(this._repository);

//   Future<void> pay({
//     required BuildContext context,
//     required int amount,
//     required String eventName,
//   }) async {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();

//     try {
//       await _repository.handlePayment(amount: amount, eventName: eventName);

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Payment in progress, You will be navigate to the payment screen',
//           ),
//         ),
//       );
//     } catch (e) {
//       _errorMessage = e.toString();
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Payment Error: $_errorMessage')));
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

  // Future<bool> hasBooked(String userId, String eventName) {
  //   return _repository.hasUserBookedEvent(userId, eventName);
  // }

  // Map<String, int> countdown(String dateString) {
  //   return _repository.calculateCountdown(dateString);
  // }

  // Future<int> getBookedCount(String eventName) {
  //   return _repository.getBookedCount(eventName);
  // }
// }


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paymentNotifierProvider = ChangeNotifierProvider<PaymentNotifier>((ref) {
  final repo = ref.read(paymentRepositoryProvider);
  return PaymentNotifier(repo);
});

enum PaymentStatus {
  idle,
  processing,
  success,
  failed,
  cancelled,
}

class PaymentNotifier extends ChangeNotifier {
  final PaymentRepository _repository;
  
  PaymentStatus _status = PaymentStatus.idle;
  String? _errorMessage;
  String? _currentBookingId;
  Map<String, dynamic>? _currentBooking;

  PaymentStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get currentBookingId => _currentBookingId;
  Map<String, dynamic>? get currentBooking => _currentBooking;
  
  bool get isLoading => _status == PaymentStatus.processing;
  bool get isSuccess => _status == PaymentStatus.success;
  bool get isFailed => _status == PaymentStatus.failed;

  PaymentNotifier(this._repository);

  Future<void> pay({
    required BuildContext context,
    required int amount,
    required String eventName,
  }) async {
    try {
      _setStatus(PaymentStatus.processing);
      _errorMessage = null;
      _currentBookingId = null;
      _currentBooking = null;

      // Show initial progress message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Initializing payment...'),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Handle payment and get booking ID
      final bookingId = await _repository.handlePayment(
        amount: amount,
        eventName: eventName,
      );

      _currentBookingId = bookingId;

      // For mobile payments, we need to wait for the webhook
      // For web payments, user will be redirected
      if (!kIsWeb) {
        // Start listening to booking status changes
        _listenToBookingStatus(bookingId);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment completed! Verifying...'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Redirecting to payment page...'),
              backgroundColor: Colors.blue.shade600,
            ),
          );
        }
      }

    } catch (e) {
      _setStatus(PaymentStatus.failed);
      _errorMessage = e.toString();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Error: ${_getReadableError(e.toString())}'),
            backgroundColor: Colors.red.shade600,
            action: _currentBookingId != null
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () => retryPayment(context),
                  )
                : null,
          ),
        );
      }
    }
  }

  void _setStatus(PaymentStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  void _listenToBookingStatus(String bookingId) {
    _repository.watchBookingStatus(bookingId).listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          _currentBooking = data;
          final status = data['status'] as String?;

          switch (status) {
            case 'paid':
              _setStatus(PaymentStatus.success);
              _errorMessage = null;
              break;
            case 'failed':
              _setStatus(PaymentStatus.failed);
              _errorMessage = data['errorMessage'] as String? ?? 'Payment failed';
              break;
            case 'cancelled':
              _setStatus(PaymentStatus.cancelled);
              _errorMessage = 'Payment was cancelled';
              break;
            case 'pending':
              // Keep processing status
              if (_status != PaymentStatus.processing) {
                _setStatus(PaymentStatus.processing);
              }
              break;
          }
        }
      },
      onError: (error) {
        _setStatus(PaymentStatus.failed);
        _errorMessage = 'Error monitoring payment status: $error';
      },
    );
  }

  Future<void> retryPayment(BuildContext context) async {
    if (_currentBookingId == null) return;

    try {
      _setStatus(PaymentStatus.processing);
      await _repository.retryPayment(_currentBookingId!);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Retrying payment...'),
            backgroundColor: Colors.blue.shade600,
          ),
        );
      }
    } catch (e) {
      _setStatus(PaymentStatus.failed);
      _errorMessage = e.toString();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry failed: ${_getReadableError(e.toString())}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

    Future<int> getBookedCount(String eventName) {
    return _repository.getBookedCount(eventName);
  }

    Future<bool> hasBooked(String userId, String eventName) {
    return _repository.hasUserBookedEvent(userId, eventName);
  }

  Map<String, int> countdown(String dateString) {
    return _repository.calculateCountdown(dateString);
  }

  String _getReadableError(String error) {
    if (error.contains('cancelled')) {
      return 'Payment was cancelled';
    }
    return 'An unexpected error occurred';
  }}