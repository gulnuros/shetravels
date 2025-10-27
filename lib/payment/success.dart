import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
@RoutePage()
class PaymentSuccessScreen extends ConsumerStatefulWidget {
  final String eventName;
  final String? bookingId;
  final String? sessionId; // From Stripe checkout session
  final String? paymentIntentId; // From Stripe payment intent

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
  bool _isUpdating = true;
  bool _updateSuccess = false;
  String? _errorMessage;
  Map<String, dynamic>? _bookingDetails;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  StreamSubscription<DocumentSnapshot>? _bookingListener;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Start the update process
    _verifyAndUpdateBooking();
  }

  @override
  void dispose() {
    _bookingListener?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndUpdateBooking() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Find booking ID
      String? bookingId = widget.bookingId;
      if (bookingId == null || bookingId.isEmpty) {
        bookingId = await _findBookingId(user.uid);
      }

      if (bookingId == null) {
        throw Exception('Booking not found');
      }

      // Listen to booking status changes (webhook might update it)
      _listenToBookingStatus(bookingId);

      // Wait briefly for webhook to update
      await Future.delayed(const Duration(seconds: 2));

      // Check if webhook already updated the status
      final docRef =
          FirebaseFirestore.instance.collection('bookings').doc(bookingId);
      final bookingSnap = await docRef.get();

      if (!bookingSnap.exists) {
        throw Exception('Booking record not found');
      }

      final data = bookingSnap.data()!;

      if (data['status'] == 'paid') {
        // Already paid by webhook
        _handleSuccessfulBooking(data);
        return;
      }

      // Webhook hasn't updated yet, update manually
      await _updateBookingToPaid(docRef, data);
    } catch (e) {
      debugPrint('❌ Error verifying booking: $e');
      setState(() {
        _isUpdating = false;
        _updateSuccess = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _listenToBookingStatus(String bookingId) {
    _bookingListener = FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.data()!;
        if (data['status'] == 'paid' && !_updateSuccess) {
          debugPrint('✅ Booking updated by webhook');
          _handleSuccessfulBooking(data);
        }
      }
    });
  }

  Future<void> _updateBookingToPaid(
    DocumentReference docRef,
    Map<String, dynamic> currentData,
  ) async {
    try {
      final updateData = {
        'status': 'paid',
        'stripeStatus': widget.sessionId != null
            ? 'checkout_session_completed'
            : 'payment_intent_succeeded',
        if (widget.sessionId != null) 'stripeSessionId': widget.sessionId,
        if (widget.paymentIntentId != null)
          'stripePaymentIntentId': widget.paymentIntentId,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'confirmedByClient': true,
      };

      await docRef.update(updateData);

      debugPrint('✅ Booking manually updated to paid');

      _handleSuccessfulBooking({...currentData, ...updateData});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Booking confirmed successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating booking: $e');
      throw Exception('Failed to update booking: $e');
    }
  }

  void _handleSuccessfulBooking(Map<String, dynamic> bookingData) {
    if (!mounted) return;

    setState(() {
      _isUpdating = false;
      _updateSuccess = true;
      _bookingDetails = bookingData;
      _errorMessage = null;
    });

    _animationController.forward();
  }

  Future<String?> _findBookingId(String userId) async {
    try {
      debugPrint('🔍 Searching for booking for user: $userId');

      // First, try to find pending bookings
      final pendingQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('eventName', isEqualTo: widget.eventName)
          .where('status', whereIn: ['pending', 'processing'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (pendingQuery.docs.isNotEmpty) {
        final bookingId = pendingQuery.docs.first.id;
        debugPrint('✅ Found pending booking: $bookingId');
        return bookingId;
      }

      // If no pending, check for recent bookings (within last 10 minutes)
      final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));

      final recentQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('eventName', isEqualTo: widget.eventName)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(tenMinutesAgo))
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (recentQuery.docs.isNotEmpty) {
        final bookingId = recentQuery.docs.first.id;
        debugPrint('✅ Found recent booking: $bookingId');
        return bookingId;
      }

      debugPrint('❌ No booking found');
      return null;
    } catch (e) {
      debugPrint('❌ Error finding booking: $e');
      return null;
    }
  }

  String _getReadableError(String error) {
    if (error.contains('not authenticated')) {
      return 'Please log in and try again';
    } else if (error.contains('not found')) {
      return 'Booking record not found. Your payment was successful, please contact support.';
    } else if (error.contains('permission')) {
      return 'Access denied. Please contact support with your booking details.';
    } else {
      return 'Something went wrong. Your payment was successful, please contact support.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent going back if update is in progress
        if (_isUpdating) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait while we confirm your booking'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            "Payment Status",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.grey.shade800),
          leading: _isUpdating
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: _buildContent(),
                ),
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isUpdating) {
      return _buildLoadingState();
    } else if (_updateSuccess) {
      return _buildSuccessState();
    } else {
      return _buildErrorState();
    }
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade100, width: 2),
          ),
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "Confirming your booking...",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Please wait while we verify your payment",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "This usually takes a few seconds",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade100, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 80,
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Text(
                  "Booking Confirmed!",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "You've successfully booked",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.pink.shade50,
                    border: Border.all(color: Colors.pink.shade100),
                  ),
                  child: Text(
                    widget.eventName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.pink.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_bookingDetails != null) ...[
                  const SizedBox(height: 24),
                  _buildBookingDetails(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade100, width: 2),
            ),
            child: Icon(
              Icons.info_outline,
              color: Colors.orange.shade600,
              size: 80,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Payment Successful",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage != null
                ? _getReadableError(_errorMessage!)
                : "We're still processing your booking",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline,
                    color: Colors.blue.shade600, size: 24),
                const SizedBox(height: 8),
                Text(
                  "Your payment was successful! The booking will be confirmed shortly. You can check your booking status in your account.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails() {
    final booking = _bookingDetails!;
    final amount = booking['amount'] as int? ?? 0;
    final currency = (booking['currency'] as String? ?? 'CAD').toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Booking Details",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow("Event", widget.eventName),
          _buildDetailRow(
              "Amount", "\$${(amount / 100).toStringAsFixed(2)} $currency"),
          _buildDetailRow("Status", "Confirmed", isStatus: true),
          if (booking['userEmail'] != null)
            _buildDetailRow("Email", booking['userEmail']),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: isStatus
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.green.shade100,
                    ),
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Column(
      children: [
        if (_errorMessage != null && !_isUpdating) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isUpdating = true;
                  _errorMessage = null;
                  _updateSuccess = false;
                });
                _verifyAndUpdateBooking();
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                "Try Again",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUpdating
                ? null
                : () => Navigator.popUntil(context, (r) => r.isFirst),
            icon: const Icon(Icons.home_outlined),
            label: Text(
              "Back to Home",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _updateSuccess ? Colors.green.shade600 : Colors.grey.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
















