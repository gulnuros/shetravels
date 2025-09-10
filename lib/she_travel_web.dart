import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shetravels/admin/data/controller/event_controller.dart';
import 'package:shetravels/admin/data/event_model.dart';
import 'package:shetravels/common/data/models/upcoming_tour_2.dart';
import 'package:shetravels/testimonial/data/model/testimonial.dart';
import 'package:shimmer/shimmer.dart';

import 'testimonial/data/testimonial_repository.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

class TripGalleryPage extends StatelessWidget {
  final PastTrip trip;

  const TripGalleryPage({Key? key, required this.trip}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${trip.title} Memories')),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: trip.galleryImages.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(trip.galleryImages[index], fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}

class PastTrip {
  final String title;
  final String date;
  final String description;
  final String coverImage;
  final List<String> galleryImages;

  PastTrip({
    required this.title,
    required this.date,
    required this.description,
    required this.coverImage,
    required this.galleryImages,
  });
}

final List<PastTrip> pastTrips = [
  PastTrip(
    title: "Bali Escape",
    date: "July 2025",
    description:
        "A rejuvenating getaway to Bali with serene beaches and vibrant culture.",
    coverImage: 'assets/home_image.webp',
    galleryImages: ['assets/bali.webp', 'assets/bali.webp', 'assets/bali.webp'],
  ),
  PastTrip(
    title: "Maldives Magic",
    date: "May 2025",
    description:
        "Crystal clear waters and luxurious island vibes in the Maldives.",
    coverImage: 'assets/past3.webp',
    galleryImages: ['assets/bali.webp', 'assets/bali.webp', 'assets/bali.webp'],
  ),
  PastTrip(
    title: "Maldives Magic",
    date: "May 2025",
    description:
        "Crystal clear waters and luxurious island vibes in the Maldives.",
    coverImage: 'assets/past3.webp',
    galleryImages: ['assets/bali.webp', 'assets/bali.webp', 'assets/bali.webp'],
  ),

  PastTrip(
    title: "Maldives Magic",
    date: "May 2025",
    description:
        "Crystal clear waters and luxurious island vibes in the Maldives.",
    coverImage: 'assets/past3.webp',
    galleryImages: ['assets/bali.webp', 'assets/bali.webp', 'assets/bali.webp'],
  ),

  PastTrip(
    title: "Maldives Magic",
    date: "May 2025",
    description:
        "Crystal clear waters and luxurious island vibes in the Maldives.",
    coverImage: 'assets/past3.webp',
    galleryImages: ['assets/bali.webp', 'assets/bali.webp', 'assets/bali.webp'],
  ),
];

Widget pastTripCard(BuildContext context, PastTrip trip) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TripGalleryPage(trip: trip)),
      );
    },
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.asset(
              trip.coverImage,
              fit: BoxFit.cover,
              width: 300,
              height: 400,
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: 300,
                padding: EdgeInsets.all(12),
                color: Colors.black.withOpacity(0.6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      trip.date,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      trip.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildUpcomingTourCard(BuildContext context, Event event) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 5,
    margin: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: Image.asset(
            event.imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(event.date, style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: 8),
              Text(
                event.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Container(),
                      //TourDetailPage(tour: tour),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade100,
                ),
                child: Text("Read More"),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class TourDetailPage extends StatelessWidget {
  final Event event;

  const TourDetailPage({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              event.imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(event.date, style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 16),
                  Text(
                    event.description,
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildUpcomingToursSection(BuildContext context, WidgetRef ref) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.blue.shade50,
          Colors.indigo.shade50,
          Colors.purple.shade50,
        ],
      ),
    ),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
                "Upcoming Tours",
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
                "Discover breathtaking destinations and create unforgettable memories with our curated travel experiences.",
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

        // Tours list with proper state handling
        Consumer(
          builder: (context, ref, child) {
            final toursAsync = ref.watch(upcomingEventsProvider);

            return toursAsync.when(
              loading: () => _buildToursShimmerLoading(),
              error:
                  (error, stackTrace) =>
                      _buildToursErrorState(error.toString()),
              data:
                  (tours) =>
                      tours.isEmpty
                          ? _buildToursEmptyState()
                          : _buildToursList(context, tours),
            );
          },
        ),
      ],
    ),
  );
}

// Shimmer loading effect for tours
Widget _buildToursShimmerLoading() {
  return SizedBox(
    height: 460,
    child: Center(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 320,
              child: Container(
                height: 420,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withOpacity(0.3),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Image placeholder
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        color: Colors.grey.shade300,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue.shade300,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    // Content placeholder
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 24,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 16,
                              width: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade300,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              height: 48,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.grey.shade300,
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
          );
        },
      ),
    ),
  );
}

// Error state for tours
Widget _buildToursErrorState(String error) {
  return Container(
    height: 300,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      color: Colors.red.shade50.withOpacity(0.8),
      border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.travel_explore_outlined,
          size: 64,
          color: Colors.red.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          "Unable to Load Tours",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "We couldn't fetch the latest tour information. Please check your connection and try again.",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.red.shade600,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// Empty state for tours
Widget _buildToursEmptyState() {
  return Container(
    height: 300,
    margin: const EdgeInsets.symmetric(horizontal: 20),
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
        Icon(Icons.explore_outlined, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(
          "No Tours Available",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "We're currently planning exciting new tour destinations. Check back soon for amazing travel opportunities!",
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

// Tours list
Widget _buildToursList(BuildContext context, List<dynamic> tours) {
  return SizedBox(
    height: 460,
    child: Center(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tours.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final tour = tours[index];
          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 320,
              child: buildUpcomingTourCard(context, tour),
            ),
          );
        },
      ),
    ),
  );
}

Widget buildTestimonialCard(Testimonial t) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 3,
    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    child: Container(
      width: 300,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.comment,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 12),
          Text(
            "- ${t.name}, ${t.region}",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            children:
                List.generate(
                  t.rating.floor(),
                  (index) => Icon(Icons.star, color: Colors.amber, size: 18),
                ) +
                List.generate(
                  5 - t.rating.floor(),
                  (index) =>
                      Icon(Icons.star_border, color: Colors.grey, size: 18),
                ),
          ),
        ],
      ),
    ),
  );
}
Widget buildTestimonialSection(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  
  // Card width adapts to screen size
  double cardWidth = screenWidth * 0.8; // Increased for better mobile experience
  if (screenWidth > 1200) {
    cardWidth = 400; // fixed max width for desktop
  } else if (screenWidth > 800) {
    cardWidth = 320; // medium size for tablets
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          "What Travellers Say",
          style: TextStyle(
            fontSize: screenWidth > 600 ? 28 : 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      SizedBox(
        height: 280, // Increased height slightly
        child: StreamBuilder<List<Testimonial>>(
          stream: TestimonialRepository.getTestimonialsStream(),
          builder: (context, snapshot) {
            // Debug information
            print('Connection State: ${snapshot.connectionState}');
            print('Has Data: ${snapshot.hasData}');
            print('Has Error: ${snapshot.hasError}');
            if (snapshot.hasData) {
              print('Data Length: ${snapshot.data!.length}');
            }
            if (snapshot.hasError) {
              print('Error: ${snapshot.error}');
            }

            // Handle error state
            if (snapshot.hasError) {
              return _buildErrorWidget(context, cardWidth, snapshot.error.toString());
            }

            // Key fix: Only show shimmer if we're waiting AND don't have data yet
            // Firestore streams often stay in 'active' state, not 'done'
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return _buildShimmerLoading(cardWidth);
            }

            // Show empty state if no data
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // If we're still connecting for the first time, show shimmer briefly
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerLoading(cardWidth);
              }
              return _buildEmptyState(context, cardWidth);
            }

            // Show actual data
            final testimonials = snapshot.data!;
            return _buildTestimonialsList(testimonials, cardWidth);
          },
        ),
      ),
    ],
  );
}

// Extracted shimmer loading widget
Widget _buildShimmerLoading(double cardWidth) {
  return ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: 3,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: cardWidth,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    },
  );
}

// Enhanced empty state
Widget _buildEmptyState(BuildContext context, double cardWidth) {
  return Center(
    child: Container(
      width: cardWidth,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No testimonials yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Be the first to share your experience!",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// Enhanced error state
Widget _buildErrorWidget(BuildContext context, double cardWidth, String error) {
  return Center(
    child: Container(
      width: cardWidth,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            "Failed to load testimonials",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Please check your connection",
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Force rebuild to retry
              if (context.mounted) {
                (context as Element).markNeedsBuild();
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

// Extracted testimonials list
Widget _buildTestimonialsList(List<Testimonial> testimonials, double cardWidth) {
  return ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: testimonials.length,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    physics: const BouncingScrollPhysics(), // Better scrolling on mobile
    itemBuilder: (context, index) {
      return Padding(
        padding: EdgeInsets.only(
          right: index == testimonials.length - 1 ? 16 : 20,
        ),
        child: SizedBox(
          width: cardWidth,
          child: buildTestimonialCard(testimonials[index]),
        ),
      );
    },
  );
}