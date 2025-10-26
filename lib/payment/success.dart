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
  ConsumerState<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
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
    _updateBookingStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


Future<void> _updateBookingStatus() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    String? bookingId = widget.bookingId ?? await _findBookingId(user.uid);
    if (bookingId == null) throw Exception('Booking not found');

    // Wait a few seconds to allow webhook to update
    await Future.delayed(const Duration(seconds: 3));

    final docRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);
    final bookingSnap = await docRef.get();

    if (!bookingSnap.exists) throw Exception('Booking record not found');

    final data = bookingSnap.data()!;
    _bookingDetails = data;

    if (data['status'] == 'paid') {
      // Already updated by webhook
      setState(() {
        _isUpdating = false;
        _updateSuccess = true;
      });
      _animationController.forward();
      return;
    }

    // Webhook hasn’t updated yet, so update manually
    final updateData = {
      'status': 'paid',
      'stripeStatus': widget.sessionId != null
          ? 'checkout_session_completed'
          : 'payment_intent_succeeded',
      'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'confirmedBySuccessScreen': true,
    };

    await docRef.update(updateData);

    setState(() {
      _isUpdating = false;
      _updateSuccess = true;
      _bookingDetails = {...data, ...updateData};
    });

    _animationController.forward();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Booking confirmed successfully!'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    }
  } catch (e) {
    setState(() {
      _isUpdating = false;
      _updateSuccess = false;
      _errorMessage = e.toString();
    });
  }
}


  Future<String?> _findBookingId(String userId) async {
    try {
      // Search for recent pending/unpaid bookings for this user and event
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('eventName', isEqualTo: widget.eventName)
          .where('status', whereIn: ['pending', 'processing'])
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }

      // If no pending booking, check for recent bookings (maybe already paid by webhook)
      final recentBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('eventName', isEqualTo: widget.eventName)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (recentBookings.docs.isNotEmpty) {
        final recentBooking = recentBookings.docs.first;
        final data = recentBooking.data();
        
        // Check if booking was created recently (within last 10 minutes)
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final bookingTime = timestamp.toDate();
          final now = DateTime.now();
          final difference = now.difference(bookingTime).inMinutes;
          
          if (difference <= 10) {
            return recentBooking.id;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error finding booking ID: $e');
      return null;
    }
  }

  String _getReadableError(String error) {
    if (error.contains('not authenticated')) {
      return 'Please log in and try again';
    } else if (error.contains('not found')) {
      return 'Booking record not found';
    } else if (error.contains('permission')) {
      return 'Access denied. Please contact support';
    } else {
      return 'Something went wrong. Please contact support';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          "Please wait while we update your booking status",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red.shade100, width: 2),
          ),
          child: Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 80,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "Booking Update Failed",
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
              : "We couldn't confirm your booking automatically",
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
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 24),
              const SizedBox(height: 8),
              Text(
                "Don't worry! Your payment was successful. Please contact support with your booking details.",
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
    );
  }

  Widget _buildBookingDetails() {
    final booking = _bookingDetails!;
    final amount = booking['amount'] as int? ?? 0;
    final currency = booking['currency'] as String? ?? 'CAD';
    
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
          _buildDetailRow("Amount", "\$${(amount / 100).toStringAsFixed(2)} $currency"),
          _buildDetailRow("Status", "Confirmed", isStatus: true),
          if (booking['userEmail'] != null)
            _buildDetailRow("Email", booking['userEmail']),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        if (_isUpdating || _errorMessage != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () {
                      setState(() {
                        _isUpdating = true;
                        _errorMessage = null;
                      });
                      _updateBookingStatus();
                    },
              icon: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                _isUpdating ? "Updating..." : "Retry Update",
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
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            icon: const Icon(Icons.home_outlined),
            label: Text(
              "Back to Home",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _updateSuccess ? Colors.green.shade600 : Colors.grey.shade600,
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