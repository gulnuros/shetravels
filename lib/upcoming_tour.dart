import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shetravels/admin/data/controller/event_controller.dart';
import 'package:shetravels/admin/data/event_model.dart';
import 'package:shetravels/auth/views/screens/login_screen.dart';
import 'package:shetravels/common/data/provider/payment_provider.dart';

class UpcomingTours extends StatefulHookConsumerWidget {
  const UpcomingTours({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UpcomingToursState();
}

class _UpcomingToursState extends ConsumerState<UpcomingTours> {
  Widget _buildActionButton({
    required BuildContext context,
    required String userId,
    required Event event,
  }) {
    final paymentProvider = ref.watch(paymentNotifierProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        paymentProvider.hasBooked(userId, event.title),
        paymentProvider.getBookedCount(event.title),
      ]).then((results) => {
        'hasBooked': results[0] as bool,
        'bookedCount': results[1] as int,
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 40,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final data = snapshot.data ?? {'hasBooked': false, 'bookedCount': 0};
        final hasBooked = data['hasBooked'] as bool;
        final bookedCount = data['bookedCount'] as int;
        
        // Calculate remaining slots using bookedCount
        final remainingSlots = event.availableSlots - bookedCount;
        final isSoldOut = remainingSlots <= 0;

        // Check if user is already subscribed (fallback check)
        final isUserSubscribed = event.subscribedUsers?.contains(userId) ?? false;

        if (hasBooked || isUserSubscribed) {
          // Show countdown if user has booked
          final countdown = paymentProvider.countdown(event.date);
          final days = countdown['days'] ?? 0;
          final hours = countdown['hours'] ?? 0;
          final minutes = countdown['minutes'] ?? 0;

          if (days <= 0 && hours <= 0 && minutes <= 0) {
            // Event has passed or is happening now
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Event Completed",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "You're Going!",
                      style: GoogleFonts.poppins(
                        color: Colors.green.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${days}d ${hours}h ${minutes}m until event",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Show sold out or book button
        if (isSoldOut) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Sold Out",
                  style: GoogleFonts.poppins(
                    color: Colors.red.shade600,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        // Show book button if not booked and slots available
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.shade600, Colors.pink.shade700],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  event.price == 0
                      ? "Join Free Event"
                      : "Book Now",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            onPressed: () async {
      await paymentProvider.pay(
  context: context,
  amount: event.price,
  eventName: event.title,
);
ref.refresh(upcomingEventsProvider);

            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final paymentProvider = ref.watch(paymentNotifierProvider);

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Upcoming Events",
            style: GoogleFonts.poppins(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Curated faith-friendly adventures & soulful hikes.",
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          eventsAsync.when(
            loading:
                () => CircularProgressIndicator(color: Colors.pink.shade300),
            error:
                (e, _) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    "Error loading events: $e",
                    style: GoogleFonts.poppins(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
            data:
                (events) =>
                    events.isEmpty
                        ? Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy,
                                color: Colors.white60,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No upcoming events.",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                        : Column(
                          children:
                              events.map((event) {
                                return FutureBuilder<int>(
                                  future: paymentProvider.getBookedCount(event.title),
                                  builder: (context, snapshot) {
                                    final bookedCount = snapshot.data ?? 0;
                                    
                                    // Calculate remaining slots using getBookedCount
                                    final remainingSlots = event.availableSlots - bookedCount;
                                    final isSoldOut = remainingSlots <= 0;
                                    final isLowStock = remainingSlots <= 5 && remainingSlots > 0;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 30),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Image with overlay badges
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(16),
                                                child: Image.network(
                                                  event.imageUrl,
                                                  width: double.infinity,
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (_, __, ___) => Container(
                                                        color: Colors.grey.shade200,
                                                        height: 200,
                                                        alignment: Alignment.center,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons.broken_image,
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade400,
                                                              size: 48,
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              "Image not available",
                                                              style:
                                                                  GoogleFonts.poppins(
                                                                    color:
                                                                        Colors
                                                                            .grey
                                                                            .shade500,
                                                                    fontSize: 14,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                ),
                                              ),

                                              // Price badge
                                              Positioned(
                                                top: 12,
                                                right: 12,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        event.price == 0
                                                            ? Colors.green.shade600
                                                            : Colors.pink.shade600,
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        event.price == 0
                                                            ? Icons.free_breakfast
                                                            : Icons.attach_money,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        event.price == 0
                                                            ? "Free"
                                                            : "\$${(event.price / 100).toStringAsFixed(2)}",
                                                        style: GoogleFonts.poppins(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              // Slots badge
                                              Positioned(
                                                top: 12,
                                                left: 12,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isSoldOut
                                                            ? Colors.red.shade600
                                                            : isLowStock
                                                            ? Colors.orange.shade600
                                                            : Colors.green.shade600,
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
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
                                                            ? Icons.block
                                                            : Icons.people_outline,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isSoldOut
                                                            ? "Sold Out"
                                                            : "$remainingSlots left",
                                                        style: GoogleFonts.poppins(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 20),

                                          // Event title
                                          Text(
                                            event.title,
                                            style: GoogleFonts.poppins(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // Date and location row
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                color: Colors.pink.shade600,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                event.date,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.pink.shade600,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              Icon(
                                                Icons.location_on,
                                                color: Colors.orange.shade600,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  event.location,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.orange.shade600,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Slots info row
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.people,
                                                  color: Colors.grey.shade600,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "Total Capacity: ${event.availableSlots} slots",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isSoldOut
                                                            ? Colors.red.shade100
                                                            : isLowStock
                                                            ? Colors.orange.shade100
                                                            : Colors.green.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    isSoldOut
                                                        ? "Full"
                                                        : isLowStock
                                                        ? "Almost Full"
                                                        : "Available",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color:
                                                          isSoldOut
                                                              ? Colors.red.shade700
                                                              : isLowStock
                                                              ? Colors
                                                                  .orange
                                                                  .shade700
                                                              : Colors
                                                                  .green
                                                                  .shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Description
                                          Text(
                                            event.description,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              color: Colors.grey.shade700,
                                              height: 1.5,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 20),

                                          // Dynamic action button based on user authentication and booking status
                                          Consumer(
                                            builder: (context, ref, child) {
                                              final user = FirebaseAuth.instance.currentUser;

                                              if (user == null) {
                                                // User not logged in - show login button
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.teal.shade500,
                                                        Colors.teal.shade600,
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.teal
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      shadowColor:
                                                          Colors.transparent,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 14,
                                                            horizontal: 20,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.login,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          "Login to Book",
                                                          style:
                                                              GoogleFonts.poppins(
                                                                color: Colors.white,
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight.w600,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    onPressed: () async {
                                                      final shouldContinue =
                                                          await Navigator.push<bool>(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (_) =>
                                                                      const LoginScreen(),
                                                            ),
                                                          );

                                                      if (shouldContinue == true &&
                                                          FirebaseAuth
                                                                  .instance
                                                                  .currentUser !=
                                                              null) {
                                                        // Trigger a rebuild to show the correct button state
                                                        // The Consumer will automatically rebuild when auth state changes
                                                      }
                                                    },
                                                  ),
                                                );
                                              }

                                              // User is logged in - show appropriate button
                                              return _buildActionButton(
                                                context: context,
                                                userId: user.uid,
                                                event: event,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                        ),
          ),
        ],
      ),
    );
  }
}