import 'dart:ui';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shetravels/admin/data/controller/event_controller.dart';
import 'package:shetravels/admin/data/event_model.dart';
import 'package:shetravels/common/view/widgets/hero_video.dart';
import 'package:shetravels/explore_tour/explore_tour_screen.dart';
import 'package:shetravels/landing_page/widgets/auth_login_button.dart';
import 'package:shetravels/news_letter/views/widgets/news_letter_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  
  


  Event? getNextUpcomingEvent(List<Event> events) {
    final now = DateTime.now();
    
    // Filter events that haven't happened yet
    final upcomingEvents = events.where((event) {
      final eventDate = _parseEventDate(event.date);
      return eventDate != null && eventDate.isAfter(now);
    }).toList();

    if (upcomingEvents.isEmpty) return null;

    // Sort by date (earliest first) and return the next upcoming event
    upcomingEvents.sort((a, b) {
      final dateA = _parseEventDate(a.date);
      final dateB = _parseEventDate(b.date);
      if (dateA == null || dateB == null) return 0;
      return dateA.compareTo(dateB);
    });

    return upcomingEvents.first;
  }

  /// Parse event date string to DateTime
  DateTime? _parseEventDate(String dateString) {
    try {
      // Handle different date formats
      if (dateString.contains('T')) {
        // ISO format: 2024-03-15T10:00:00Z
        return DateTime.parse(dateString);
      } else if (dateString.contains('/')) {
        // Format: MM/DD/YYYY or DD/MM/YYYY
        final parts = dateString.split('/');
        if (parts.length >= 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } else if (dateString.contains('-')) {
        // Format: YYYY-MM-DD
        final parts = dateString.split('-');
        if (parts.length >= 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
      
      // Try to parse as timestamp
      final timestamp = int.tryParse(dateString);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error parsing date: $dateString - $e');
      return null;
    }
  }

  void showUpcomingEventsPopup(Event event, {required BuildContext context, required bool mounted, required Map<String, GlobalKey> sectionKeys}) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: _buildPopupContent(event, context: context, mounted: mounted, sectionKeys: sectionKeys),
        );
      },
    );
  }

  Widget _buildPopupContent(Event event, {required BuildContext context, required bool mounted, required Map<String, GlobalKey> sectionKeys}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: const BoxConstraints(maxWidth: 500),
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                _buildPopupHeader(  context: context, mounted: mounted),
                const SizedBox(height: 16),

                // Description
                _buildPopupDescription(),
                const SizedBox(height: 20),

                _buildEventPreview(event),
                const SizedBox(height: 24),

                _buildPopupActions(event, context: context, mounted: mounted, scrollToSection: (String key) {
                  final sectionKey = sectionKeys[key];
                  if (sectionKey != null) {
                    Scrollable.ensureVisible(
                      sectionKey.currentContext!,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                    );
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupHeader({ required BuildContext context, required bool mounted}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.event_available,
            color: Colors.pink.shade400,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Upcoming Event',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.close, color: Colors.grey.shade600, size: 20),
          ),
        ),
      ],
    );
  }





  Widget _buildPopupDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1), width: 1),
      ),
      child: Text(
        'Don\'t miss out! Here\'s the next transformative experience designed to nourish your soul, build sisterhood, and inspire personal growth.',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade700,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEventPreview(Event event) {
    final eventDate = _parseEventDate(event.date);
    final timeUntilEvent = eventDate != null 
        ? _getTimeUntilEvent(eventDate) 
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.pink.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Event image
              _buildEventImage(event),
              const SizedBox(width: 16),

              // Event details
              Expanded(child: _buildEventDetails(event)),
            ],
          ),
          
          // Time countdown if available
          if (timeUntilEvent != null) ...[
            const SizedBox(height: 12),
            _buildTimeCountdown(timeUntilEvent),
          ],
          
          // Event status indicators
          const SizedBox(height: 12),
          _buildEventStatus(event),
        ],
      ),
    );
  }

  Widget _buildTimeCountdown(String timeUntilEvent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Text(
            timeUntilEvent,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventStatus(Event event) {
    return Row(
      children: [
        // Slots indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: event.isLowStock 
                ? Colors.red.shade100 
                : Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${event.remainingSlots} slots left',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: event.isLowStock 
                  ? Colors.red.shade700 
                  : Colors.green.shade700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Price indicator
        if (event.price > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '\$${(event.price / 100).toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.purple.shade700,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'FREE',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ),
      ],
    );
  }

  String? _getTimeUntilEvent(DateTime eventDate) {
    final now = DateTime.now();
    final difference = eventDate.difference(now);

    if (difference.isNegative) return null;

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} to go';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} to go';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} to go';
    } else {
      return 'Starting soon!';
    }
  }

  Widget _buildEventImage(Event event) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: event.imageUrl.isNotEmpty
            ? Image.network(
                event.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultEventImage();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.pink.shade300,
                        ),
                      ),
                    ),
                  );
                },
              )
            : _buildDefaultEventImage(),
      ),
    );
  }

  Widget _buildDefaultEventImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.pink.shade300, Colors.purple.shade300],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.event, color: Colors.white, size: 24),
    );
  }

  Widget _buildEventDetails(Event event) {
    final eventDate = _parseEventDate(event.date);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey.shade800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _formatEventDate(eventDate),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (event.location.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.location,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatEventDate(DateTime? eventDate) {
    if (eventDate == null) return "Date TBA";
    
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    if (eventDate.day == now.day && 
        eventDate.month == now.month && 
        eventDate.year == now.year) {
      return "Today";
    } else if (eventDate.day == tomorrow.day && 
               eventDate.month == tomorrow.month && 
               eventDate.year == tomorrow.year) {
      return "Tomorrow";
    } else {
      // Format: Mar 15, 2024
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return "${months[eventDate.month - 1]} ${eventDate.day}, ${eventDate.year}";
    }
  }

  Widget _buildPopupActions(Event event,    {required BuildContext context, required bool mounted, required Function scrollToSection}) {
    return Row(
      children: [
        // Dismiss button
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              'Maybe Later',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // View details button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade400,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              if (mounted) {
              Navigator.of(context).pop();
              scrollToSection('tours');
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.explore, size: 18),
                const SizedBox(width: 8),
                Text(
                  event.isSoldOut ? 'VIEW DETAILS' : 'JOIN EVENT',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }






  Widget buildHeader( Function scrollToSection, BuildContext context) {
    const String assetName = 'assets/she_travel.svg';
    final Widget svg = SvgPicture.asset(assetName, semanticsLabel: 'App Logo');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          svg,
          Spacer(),
          _navItem("Home", 'home'),
          SizedBox(width: 20),
          _navItem("Tours", 'tours'),
          SizedBox(width: 20),
          _navItem("Past Trips", 'past'),
          SizedBox(width: 20),
          _navItem("Apply", 'apply'),
          SizedBox(width: 20),
          _navItem("Connect", 'connect'),
       AuthAwareLoginButton(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExploreToursScreen()),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              margin: EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pink.shade100, width: 2),
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),

              child: Center(
                child: Text(
                  "Explore Trips",
                  style: GoogleFonts.poppins(
                    color: Colors.pink.shade100,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(String label, String key,   {Function? scrollToSection}) {
    return InkWell(
      onTap: () => scrollToSection!(key),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: Colors.black.withOpacity(0.8),
        ),
      ),
    );
  }



  Widget buildHeroSection(BuildContext context, Function scrollToSection) {
    return Container(
      height: 700,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          HeroVideoBackground(),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedTextKit(
                    isRepeatingAnimation: false,
                    totalRepeatCount: 1,
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'SheTravels',
                        textStyle: GoogleFonts.poppins(
                          color: Colors.pink.shade100,
                          fontSize: 55,
                          fontWeight: FontWeight.bold,
                        ),
                        speed: Duration(milliseconds: 100),
                      ),
                    ],
                  ),
                  Text(
                    "Where Sisterhood Meets the Road",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 55,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: 500,
                    child: Text(
                      "Welcome to SheTravels, your ultimate resource for Curated travel experiences and nature retreats for women who seek connection, renewal, and adventure",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap:
                            () => launchUrl(
                              Uri.parse("https://shetravel.com/apply"),
                            ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          margin: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "Hike schedule",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          print('This is the dialog');
                          showDialog(
                          context: context,
                          builder: (context) => NewsletterSubscriptionDialog(),
                          );
                              print('This is the dialog2');
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          margin: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.pink.shade100,
                              width: 2,
                            ),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "Join Our Sisterhood",
                              style: GoogleFonts.poppins(
                                color: Colors.pink.shade100,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMission() {
    return Padding(
      padding: const EdgeInsets.all(50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Mission & Values',
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 30),

                Text(
                  softWrap: true,
                  "SheTravels is more than travel — it’s a journey back to yourself. Founded and guided by Aleksa, our trips blend nature, faith-friendly spaces, reflection, and real connection between women. Whether it’s a quiet hike or a soulful retreat, you’re never alone.",

                  style: GoogleFonts.poppins(fontSize: 17),
                ),
              ],
            ),
          ),
          SizedBox(width: 30),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/past2.jpeg'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSafety(  BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50, bottom: 50, left: 30, right: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Safety and Convenience are Our Top Priorities',
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 30),

                Text(
                  softWrap: true,
                  'At SheTravels, we understand the unique concerns of women travelers. That’s why we’ve built our platform with a strong emphasis on safety and convenience, ensuring every journey is enjoyable and worry-free.',
                  style: GoogleFonts.poppins(fontSize: 17),
                ),

                SizedBox(height: 30),

                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '98 %',
                      style: GoogleFonts.poppins(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      softWrap: true,
                      'Of our users report feeling safer using SheTravels',
                      style: GoogleFonts.poppins(fontSize: 17),
                    ),
                  ],
                ),

                SizedBox(height: 13),

                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '24/7',
                      style: GoogleFonts.poppins(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      softWrap: true,
                      'Customer support available to assist you anytime.',
                      style: GoogleFonts.poppins(fontSize: 17),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 2.5,
            child: Image.asset('assets/safety_group.webp'),
          ),
        ],
      ),
    );
  }

  Widget buildFooter() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: Colors.pink.shade100.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'GET IN TOUCH',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.pink.shade300,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Contact SheTravels',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: 600,
            child: Text(
              'Reach out to us for inquiries, feedback, or support. We’re here to help you explore the world with safety, sisterhood, and confidence.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 30),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mail, size: 20),
                  SizedBox(width: 8),
                  Text("contact@shetravels.com"),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, size: 20),
                  SizedBox(width: 8),
                  Text("+234 800 000 0000"),
                ],
              ),
            ],
          ),
          SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.facebook),
                onPressed:
                    () =>
                        launchUrl(Uri.parse("https://facebook.com/shetravel")),
                tooltip: "Facebook",
              ),
              IconButton(
                icon: Icon(Icons.camera_alt),
                onPressed:
                    () =>
                        launchUrl(Uri.parse("https://instagram.com/shetravel")),
                tooltip: "Instagram",
              ),
              IconButton(
                icon: Icon(Icons.message),
                onPressed:
                    () => launchUrl(Uri.parse("https://wa.me/2348000000000")),
                tooltip: "WhatsApp",
              ),
            ],
          ),
          SizedBox(height: 30),
          Text(
            "© 2025 SheTravels. All rights reserved.",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }



