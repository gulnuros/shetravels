import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/common/data/repository/payment_repository.dart';

final paymentNotifierProvider = ChangeNotifierProvider<PaymentNotifier>((ref) {
  final repo = ref.read(paymentRepositoryProvider);
  return PaymentNotifier(repo);
});

class PaymentNotifier extends ChangeNotifier {
  final PaymentRepository _repository;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PaymentNotifier(this._repository);

  Future<void> pay({
    required BuildContext context,
    required int amount,
    required String eventName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.handlePayment(amount: amount, eventName: eventName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment in progress, You will be navigate to the payment screen',
          ),
        ),
      );
    } catch (e) {
      _errorMessage = e.toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment Error: $_errorMessage')));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> hasBooked(String userId, String eventName) {
    return _repository.hasUserBookedEvent(userId, eventName);
  }

  Map<String, int> countdown(String dateString) {
    return _repository.calculateCountdown(dateString);
  }

  Future<int> getBookedCount(String eventName) {
    return _repository.getBookedCount(eventName);
  }
}
