import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shetravels/admin/data/controller/event_controller.dart';
import 'package:shetravels/admin/data/event_model.dart';
import 'package:shetravels/common/data/provider/payment_provider.dart';

import 'dart:ui';
Widget buildUpcomingEventsSection(WidgetRef ref) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.pink.shade50,
          Colors.purple.shade50,
          Colors.blue.shade50,
        ],
      ),
    ),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
    child: Column(
      children: [
        // Title with glassmorphism effect
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                "Upcoming Events",
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Join us for soul-nourishing retreats, reflective walks, and in-person sisterhood experiences.",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Events list with proper state handling
        Consumer(
          builder: (context, ref, child) {
            final eventsAsync = ref.watch(upcomingEventsProvider);

            return eventsAsync.when(
              loading: () => _buildShimmerLoading(),
              error: (error, stackTrace) => _buildErrorState(error.toString()),
              data:
                  (events) =>
                      events.isEmpty
                          ? _buildEmptyState()
                          : _buildEventsList(events, ref),
            );
          },
        ),
      ],
    ),
  );
}

// Shimmer loading effect
Widget _buildShimmerLoading() {
  return SizedBox(
    height: 400,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        return Container(
          width: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.3),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
          ),
          child: Column(
            children: [
              // Image placeholder
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  color: Colors.grey.shade300,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.pink.shade200,
                    strokeWidth: 2,
                  ),
                ),
              ),
              // Content placeholder
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 20,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

// Error state
Widget _buildErrorState(String error) {
  return Container(
    height: 300,
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      color: Colors.red.shade50.withOpacity(0.8),
      border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
        const SizedBox(height: 16),
        Text(
          "Oops! Something went wrong",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "We couldn't load the events. Please try again later.",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.red.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// Empty state
Widget _buildEmptyState() {
  return Container(
    height: 300,
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      color: Colors.white.withOpacity(0.4),
      border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.event_note_outlined, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(
          "No Upcoming Events",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Stay tuned! We're planning amazing experiences for you.",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade500,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// Events list
Widget _buildEventsList(List<Event> events, WidgetRef ref) {
  return SizedBox(
    height: 420,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(width: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        return _buildEventCard(events[index], ref, context);
      },
    ),
  );
}

Widget _buildEventCard(Event event, WidgetRef ref, BuildContext context) {
  final paymentProvider = ref.watch(paymentNotifierProvider);

  return FutureBuilder<int>(
    future: paymentProvider.getBookedCount(event.title),
    builder: (context, snapshot) {
      final bookedCount = snapshot.data ?? 0;
      
      // Calculate remaining slots using getBookedCount
      final remainingSlots = event.availableSlots - bookedCount;
      final isSoldOut = remainingSlots <= 0;
      final isLowStock = remainingSlots <= 5 && remainingSlots > 0;

      return GestureDetector(
        onTap: () {
          // Navigate to details or booking page
          // You can add your navigation logic here
        },
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 64,
                          color: Colors.grey.shade500,
                        ),
                      );
                    },
                  ),
                ),

                // Price tag in top-right corner
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: event.price == 0
                          ? Colors.green.withOpacity(0.9)
                          : Colors.pink.withOpacity(0.9),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          event.price == 0 ? Icons.free_breakfast : Icons.attach_money,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.price == 0 
                              ? 'Free' 
                              : '\$${(event.price / 100).toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Slots indicator in top-left corner
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isSoldOut
                          ? Colors.red.withOpacity(0.9)
                          : isLowStock
                              ? Colors.orange.withOpacity(0.9)
                              : Colors.green.withOpacity(0.9),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSoldOut 
                              ? Icons.close 
                              : Icons.people_outline,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSoldOut 
                              ? 'Sold Out' 
                              : '$remainingSlots left',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Glassmorphism overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Content
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                event.date,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Title
                            Text(
                              event.title,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Description
                            Text(
                              event.description,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),

                            // Event details row (Location & Slots info)
                            Row(
                              children: [
                                // Location
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          event.location,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(0.8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Slots info
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white.withOpacity(0.15),
                                  ),
                                  child: Text(
                                    '${event.availableSlots} slots',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Book button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSoldOut
                                      ? Colors.grey.withOpacity(0.6)
                                      : Colors.white.withOpacity(0.9),
                                  foregroundColor: isSoldOut
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 20,
                                  ),
                                ),
                                onPressed: isSoldOut
                                    ? null
                                    : () async {
                                        try {
                                          await paymentProvider.pay(
                                            context: context,
                                            amount: event.price,
                                            eventName: event.title,
                                          );
                                        } catch (e) {
                                          // Handle payment error
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Payment failed. Please try again.',
                                                style: GoogleFonts.poppins(),
                                              ),
                                              backgroundColor: Colors.red.shade400,
                                            ),
                                          );
                                        }
                                      },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isSoldOut
                                          ? Icons.block
                                          : Icons.event_available,
                                      size: 18,
                                      color: isSoldOut
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isSoldOut
                                          ? "Sold Out"
                                          : event.price == 0
                                              ? "Join Free Event"
                                              : "Book Now",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}