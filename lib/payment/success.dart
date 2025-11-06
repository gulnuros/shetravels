import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@RoutePage()
class PaymentSuccessScreen extends ConsumerStatefulWidget {
  final String eventName;
  final String? bookingId;
  final String? sessionId;
  final String? paymentIntentId;

  const PaymentSuccessScreen({
    super.key,
    required this.eventName,
    this.bookingId,
    this.sessionId,
    this.paymentIntentId,
  });

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  bool _isVerifying = true;
  bool _paymentConfirmed = false;
  String? _errorMessage;
  Map<String, dynamic>? _bookingDetails;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  StreamSubscription<DocumentSnapshot>? _bookingListener;
  Timer? _timeoutTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _webhookWaitTime = Duration(seconds: 3);
  static const Duration _verificationTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startVerificationWithTimeout();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _bookingListener?.cancel();
    _timeoutTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startVerificationWithTimeout() {
    // Set timeout for verification
    _timeoutTimer = Timer(_verificationTimeout, () {
      if (_isVerifying && mounted) {
        debugPrint('⏰ Verification timeout reached');
        _handleVerificationTimeout();
      }
    });

    _verifyPaymentStatus();
  }

  Future<void> _verifyPaymentStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Find or use provided booking ID
      String? bookingId = widget.bookingId;
      if (bookingId == null || bookingId.isEmpty) {
        bookingId = await _findRecentBooking(user.uid);
      }

      if (bookingId == null) {
        throw Exception('Booking not found');
      }

      debugPrint('🔍 Verifying booking: $bookingId');

      // Listen to real-time booking updates (webhook might update it)
      _listenToBookingStatus(bookingId);

      // Wait for webhook to potentially update the status
      await Future.delayed(_webhookWaitTime);

      // Check current booking status
      final bookingRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId);
      
      final bookingSnap = await bookingRef.get();

      if (!bookingSnap.exists) {
        throw Exception('Booking record not found');
      }

      final bookingData = bookingSnap.data()!;
      final currentStatus = bookingData['status'] as String?;

      debugPrint('📊 Current booking status: $currentStatus');

      if (currentStatus == 'paid') {
        // Already paid by webhook - Success!
        debugPrint('✅ Payment already confirmed by webhook');
        _handlePaymentSuccess(bookingData);
      } else if (currentStatus == 'pending' || currentStatus == 'processing') {
        // Webhook hasn't updated yet, update manually
        debugPrint('⚠️ Webhook not updated yet, updating manually...');
        await _updateBookingStatus(bookingRef, bookingData);
      } else {
        // Unexpected status
        debugPrint('❓ Unexpected status: $currentStatus');
        throw Exception('Unexpected booking status: $currentStatus');
      }
    } catch (e) {
      debugPrint('❌ Verification error: $e');
      _handleVerificationError(e.toString());
    }
  }

  void _listenToBookingStatus(String bookingId) {
    _bookingListener = FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted || !_isVerifying) return;

        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data['status'] == 'paid') {
            debugPrint('🎉 Booking status updated to paid (real-time)');
            _handlePaymentSuccess(data);
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Booking listener error: $error');
      },
    );
  }

  Future<String?> _findRecentBooking(String userId) async {
    try {
      debugPrint('🔍 Searching for recent booking for user: $userId');

      // Search for recent bookings (last 15 minutes)
      final fifteenMinutesAgo = DateTime.now()
          .subtract(const Duration(minutes: 15));

      final query = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('eventName', isEqualTo: widget.eventName)
          .where('createdAt', 
              isGreaterThan: Timestamp.fromDate(fifteenMinutesAgo))
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final bookingId = query.docs.first.id;
        debugPrint('✅ Found booking: $bookingId');
        return bookingId;
      }

      debugPrint('❌ No recent booking found');
      return null;
    } catch (e) {
      debugPrint('❌ Error finding booking: $e');
      return null;
    }
  }

  Future<void> _updateBookingStatus(
    DocumentReference bookingRef,
    Map<String, dynamic> currentData,
  ) async {
    try {
      final updateData = <String, dynamic>{
        'status': 'paid',
        'stripeStatus': widget.sessionId != null
            ? 'checkout_session_completed'
            : 'payment_intent_succeeded',
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'confirmedByClient': true,
      };

      if (widget.sessionId != null) {
        updateData['stripeSessionId'] = widget.sessionId;
      }
      if (widget.paymentIntentId != null) {
        updateData['stripePaymentIntentId'] = widget.paymentIntentId;
      }

      await bookingRef.update(updateData);

      debugPrint('✅ Booking manually updated to paid');

      final updatedData = {...currentData, ...updateData};
      _handlePaymentSuccess(updatedData);
    } catch (e) {
      debugPrint('❌ Error updating booking: $e');
      throw Exception('Failed to update booking status: $e');
    }
  }

  void _handlePaymentSuccess(Map<String, dynamic> bookingData) {
    if (!mounted) return;

    _timeoutTimer?.cancel();
    _bookingListener?.cancel();

    setState(() {
      _isVerifying = false;
      _paymentConfirmed = true;
      _bookingDetails = bookingData;
      _errorMessage = null;
    });

    _animationController.forward();

    // Show success message
    _showSnackBar(
      'Booking confirmed successfully! 🎉',
      Colors.green,
      Icons.check_circle,
    );
  }

  void _handleVerificationError(String error) {
    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      _paymentConfirmed = false;
      _errorMessage = error;
    });
  }

  void _handleVerificationTimeout() {
    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      _paymentConfirmed = false;
      _errorMessage = 'Verification timeout. Please check your bookings.';
    });

    _showSnackBar(
      'Verification is taking longer than expected',
      Colors.orange,
      Icons.info_outline,
    );
  }

  Future<void> _retryVerification() async {
    if (_retryCount >= _maxRetries) {
      _showSnackBar(
        'Maximum retry attempts reached. Please contact support.',
        Colors.red,
        Icons.error_outline,
      );
      return;
    }

    _retryCount++;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _paymentConfirmed = false;
    });

    _startVerificationWithTimeout();
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getReadableError(String error) {
    if (error.contains('not authenticated')) {
      return 'Please log in and try again';
    } else if (error.contains('not found')) {
      return 'Booking not found. Your payment was successful, please check your email or contact support.';
    } else if (error.contains('timeout')) {
      return 'Verification is taking longer than expected. Your payment was successful, please check your bookings.';
    } else {
      return 'Unable to verify booking status. Your payment was successful, please check your email confirmation.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isVerifying,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFf8f9fa), Color(0xFFe9ecef)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildContent()),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!_isVerifying)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.router.pop(),
            ),
          const Expanded(
            child: Text(
              'Payment Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (!_isVerifying) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          if (_isVerifying) _buildVerifyingState(),
          if (_paymentConfirmed) _buildSuccessState(),
          if (!_isVerifying && !_paymentConfirmed) _buildPendingState(),
        ],
      ),
    );
  }

  Widget _buildVerifyingState() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667eea).withOpacity(0.2),
                const Color(0xFF764ba2).withOpacity(0.2),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Verifying Payment',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Please wait while we confirm your booking',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'This usually takes a few seconds...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 70,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Booking Confirmed!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You\'ve successfully booked',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              widget.eventName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_bookingDetails != null) ...[
            const SizedBox(height: 32),
            _buildBookingDetailsCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingState() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withOpacity(0.1),
            border: Border.all(color: Colors.orange, width: 3),
          ),
          child: const Icon(
            Icons.schedule,
            color: Colors.orange,
            size: 60,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Payment Successful',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage != null
              ? _getReadableError(_errorMessage!)
              : 'Your booking is being processed',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[700],
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Your payment was successful! You will receive a confirmation email shortly.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetailsCard() {
    final booking = _bookingDetails!;
    final amount = booking['amount'] as int? ?? 0;
    final currency = (booking['currency'] as String? ?? 'CAD').toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            Icons.event,
            'Event',
            widget.eventName,
          ),
          _buildDetailRow(
            Icons.attach_money,
            'Amount',
            '\$${(amount / 100).toStringAsFixed(2)} $currency',
          ),
          _buildDetailRow(
            Icons.check_circle,
            'Status',
            'Confirmed',
            valueColor: Colors.green,
          ),
          if (booking['userEmail'] != null)
            _buildDetailRow(
              Icons.email,
              'Email',
              booking['userEmail'],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF667eea),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF2c3e50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_errorMessage != null && !_isVerifying && _retryCount < _maxRetries) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _retryVerification,
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Retry Verification',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isVerifying
                  ? null
                  : () => context.router.popUntilRoot(),
              icon: const Icon(Icons.home),
              label: const Text(
                'Back to Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _paymentConfirmed
                    ? Colors.green
                    : const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}