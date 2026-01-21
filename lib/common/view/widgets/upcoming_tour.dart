import 'package:flutter/material.dart';
import 'package:shetravels/admin/data/controller/event_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
                "Discover breathtaking destinations and create unforgettable memories.",
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
        Consumer(
          builder: (context, ref, child) {
            final eventsAsync = ref.watch(upcomingEventsProvider);

            return eventsAsync.when(
              loading: () => _buildToursLoadingState(),
              error:
                  (error, stackTrace) =>
                      _buildToursErrorState(error.toString()),
              data:
                  (events) =>
                      events.isEmpty
                          ? _buildToursEmptyState()
                          : _buildToursContent(context, events),
            );
          },
        ),
      ],
    ),
  );
}

Widget _buildToursLoadingState() {
  return SizedBox(
    height: 460,
    child: Center(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (context, index) => const SizedBox(width: 16),
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

Widget _buildToursContent(BuildContext context, List<dynamic> events) {
  return SizedBox(
    height: 460,
    child: Center(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final tour = events[index];
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

Widget buildUpcomingTourCard(BuildContext context, dynamic tour) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TourDetailsPage(tour: tour)),
      );
    },
    child: Container(
      height: 420,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: _buildTourImage(tour)),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            if (_isPopularTour(tour))
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
                    color: Colors.orange.withOpacity(0.9),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "Popular",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTourMetadata(tour),
                        const SizedBox(height: 12),
                        Text(
                          _getTourTitle(tour),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getTourDescription(tour),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        _buildTourActions(context, tour),
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
}

Widget _buildTourImage(dynamic tour) {
  final imageUrl = _getTourImageUrl(tour);

  if (imageUrl != null && imageUrl.isNotEmpty) {
    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultTourBackground();
      },
    );
  } else {
    return _buildDefaultTourBackground();
  }
}

Widget _buildDefaultTourBackground() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blue.shade300, Colors.purple.shade300],
      ),
    ),
    child: Center(
      child: Icon(
        Icons.landscape_outlined,
        size: 64,
        color: Colors.white.withOpacity(0.7),
      ),
    ),
  );
}

Widget _buildTourMetadata(dynamic tour) {
  final duration = _getTourDuration(tour);
  final location = _getTourLocation(tour);

  return Row(
    children: [
      if (duration != null) ...[
        Icon(Icons.schedule, size: 16, color: Colors.white.withOpacity(0.8)),
        const SizedBox(width: 4),
        Text(
          duration,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
      if (duration != null && location != null)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        ),
      if (location != null) ...[
        Icon(Icons.location_on, size: 16, color: Colors.white.withOpacity(0.8)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            location,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ],
  );
}

Widget _buildTourActions(BuildContext context, dynamic tour) {
  final price = _getTourPrice(tour);

  return Row(
    children: [
      if (price != null)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "From",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                "\$$price",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: Colors.grey.shade800,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
        onPressed: () {
          _handleTourBooking(context, tour);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              "Book Tour",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

String? _getTourImageUrl(dynamic tour) {
  if (tour == null) return null;
  return tour.imageUrl?.toString() ?? tour.image?.toString();
}

String _getTourTitle(dynamic tour) {
  if (tour == null) return "Amazing Tour";
  return tour.title?.toString() ?? tour.name?.toString() ?? "Amazing Tour";
}

String _getTourDescription(dynamic tour) {
  if (tour == null) {
    return "Discover amazing places and create unforgettable memories.";
  }
  return tour.description?.toString() ??
      tour.summary?.toString() ??
      "Discover amazing places and create unforgettable memories.";
}

String? _getTourDuration(dynamic tour) {
  if (tour == null) return null;
  return tour.duration?.toString();
}

String? _getTourLocation(dynamic tour) {
  if (tour == null) return null;
  return tour.location?.toString() ?? tour.destination?.toString();
}

String? _getTourPrice(dynamic tour) {
  if (tour == null) return null;
  return tour.price?.toString();
}

bool _isPopularTour(dynamic tour) {
  if (tour == null) return false;
  return tour.featured == true ||
      tour.isPopular == true ||
      tour.popular == true;
}

void _handleTourBooking(BuildContext context, dynamic tour) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(
            "Book Tour",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Would you like to book '${_getTourTitle(tour)}'?",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Booking initiated for ${_getTourTitle(tour)}",
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text("Book Now", style: GoogleFonts.poppins()),
            ),
          ],
        ),
  );
}

class TourDetailsPage extends StatelessWidget {
  final dynamic tour;

  const TourDetailsPage({super.key, required this.tour});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTourTitle(tour), style: GoogleFonts.poppins()),
      ),
      body: Center(
        child: Text(
          "Tour Details Page",
          style: GoogleFonts.poppins(fontSize: 24),
        ),
      ),
    );
  }
}
