import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shetravels/admin/data/controller/event_controller.dart';
import 'package:shetravels/animation_section.dart';
import 'package:shetravels/common/view/widgets/build_founder_section.dart';
import 'package:shetravels/common/view/widgets/hero_video.dart';
import 'package:shetravels/common/view/widgets/why_she_travel.dart';
import 'package:shetravels/explore_tour/explore_tour_screen.dart';
import 'package:shetravels/gallery/views/gallery.dart';
import 'package:shetravels/memories_section.dart';
import 'package:shetravels/news_letter/views/widgets/news_letter_widgets.dart';
import 'package:shetravels/she_travel_web.dart';
import 'package:shetravels/upcoming_tour.dart';
import 'package:shetravels/utils/route.gr.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:animate_do/animate_do.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:responsive_builder/responsive_builder.dart';

class LandingPage extends StatefulHookConsumerWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  bool _hasShownPopup = false;

  @override
  void initState() {
    super.initState();
    // Delay showing popup to allow widget tree to build completely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      
    });
  }

  void _checkAndShowUpcomingEventsPopup() {
    if (!mounted || _hasShownPopup) return;

    final eventAsync = ref.read(upcomingEventsProvider);

    // Listen to the provider state
    eventAsync.whenOrNull(
      data: (events) {
        if (events != null && events.isNotEmpty && mounted && !_hasShownPopup) {
          _hasShownPopup = true;
          _showUpcomingEventsPopup(events.first);
        }
      },
    );
  }

  void _showUpcomingEventsPopup(dynamic event) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: _buildPopupContent(event),
        );
      },
    );
  }

  Widget _buildPopupContent(dynamic event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
                _buildPopupHeader(),
                const SizedBox(height: 16),

                // Description
                _buildPopupDescription(),
                const SizedBox(height: 20),

                // Event preview
                _buildEventPreview(event),
                const SizedBox(height: 24),

                // Action buttons
                _buildPopupActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupHeader() {
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
            'Upcoming Events',
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
        'Discover transformative experiences designed to nourish your soul, build sisterhood, and inspire personal growth through our carefully curated events.',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade700,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEventPreview(dynamic event) {
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
      child: Row(
        children: [
          // Event image
          _buildEventImage(event),
          const SizedBox(width: 16),

          // Event details
          Expanded(child: _buildEventDetails(event)),
        ],
      ),
    );
  }

  Widget _buildEventImage(dynamic event) {
    final imageUrl = _getEventImageUrl(event);

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
        child:
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                  imageUrl,
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
      child: Icon(Icons.event, color: Colors.white, size: 24),
    );
  }

  Widget _buildEventDetails(dynamic event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getEventTitle(event),
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
                _getEventDate(event),
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
        if (_getEventLocation(event) != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _getEventLocation(event)!,
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

  Widget _buildPopupActions() {
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
               padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            ),
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              'Skip',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // View all button
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
               padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            ),
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              //  _navigateToEvents();
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore, size: 18),
                const SizedBox(width: 8),
                Text(
                  'VIEW ALL',
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

  void _navigateToEvents() {
    try {
Navigator.of(context).pop();
   
  
    } catch (e) {
   Navigator.of(context).pop();
    }
  }
  String? _getEventImageUrl(dynamic event) {
    if (event == null) return null;
    return event.imageUrl?.toString() ?? event.image?.toString();
  }

  String _getEventTitle(dynamic event) {
    if (event == null) return "Upcoming Event";
    return event.title?.toString() ??
        event.name?.toString() ??
        "Upcoming Event";
  }

  String _getEventDate(dynamic event) {
    if (event == null) return "Date TBA";
    return event.date?.toString() ?? event.startDate?.toString() ?? "Date TBA";
  }

  String? _getEventLocation(dynamic event) {
    if (event == null) return null;
    return event.location?.toString() ?? event.venue?.toString();
  }

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {
    'home': GlobalKey(),
    'mission': GlobalKey(),
    'tours': GlobalKey(),
    'safety': GlobalKey(),
    'past': GlobalKey(),
    'getInTouch': GlobalKey(),
  };

  void _scrollToSection(String key) {
    final context = _sectionKeys[key]!.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _drawerItem(String title, String key) {
    return ListTile(
      title: Text(title, style: GoogleFonts.poppins(fontSize: 15)),
      onTap: () {
        Navigator.pop(context);
        _scrollToSection(key);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(upcomingEventsProvider, (previous, next) {
      if (!_hasShownPopup && mounted) {
        next.whenOrNull(
          data: (events) {
            if (events != null && events.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_hasShownPopup) {
                  _hasShownPopup = true;
                  _showUpcomingEventsPopup(events.first);
                }
              });
            }
          },
        );
      }
    });

    const String assetName = 'assets/she_travel.svg';
    final Widget svg = SvgPicture.asset(
      assetName,
      semanticsLabel: 'App Logo',
      color: Colors.black,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.pink.shade100),

        actions: [
          SizedBox(),

          Spacer(),

          SizedBox(
            height: 40,
            child: SvgPicture.asset(
              assetName,
              semanticsLabel: 'App Logo',
              color: Colors.pink.shade100,
            ),
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.pink.shade100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40, child: svg),
                  SizedBox(height: 10),
                ],
              ),
            ),
            _drawerItem('Home', 'home'),
            _drawerItem('Mission', 'mission'),
            _drawerItem('Why SheTravel', 'why'),
            _drawerItem('Tours', 'tours'),
            _drawerItem('Safety', 'safety'),
            _drawerItem('Past Trips', 'past'),
            _drawerItem('Get In Touch', 'getInTouch'),

            SizedBox(height: 20),

            ListTile(
              title: Text(
                'Login',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.pink.shade100,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.router.push(LoginRoute());
              },
            ),
          ],
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _keyedSection('home', _buildHeroSection()),
                _keyedSection('mission', _buildMission()),
                _keyedSection('why', buildWhyChooseSheTravelsSection()),

                _keyedSection('tours', UpcomingTours()),
                SizedBox(height: 40),
                _keyedSection('safety', _buildSafety()),
                SizedBox(height: 40),
                _keyedSection('past', MemoriesSection()),

                _keyedSection('gallery', GallerySection()),

                _keyedSection(
                  'founder',
                  Column(
                    children: [
                      Text(
                        'A Message From Our Founder',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FounderSection(),
                    ],
                  ),
                ),

            
                _keyedSection('getInTouch', buildTestimonialSection(context)),

                SizedBox(height: 50),
                _buildFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  // If you want to show the upcoming events section, add this widget in your build method where appropriate, for example:

  Widget _buildSection({required String key, required Widget child}) {
    return Container(
      key: _sectionKeys[key],
      width: double.infinity,
      child: child,
    );
  }

  Widget _keyedSection(String key, Widget child) {
    return Container(
      key: _sectionKeys[key],
      child: AnimatedSection(keyId: key, child: child),
    );
  }

  Widget _buildHeroSection() {
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
                        textAlign: TextAlign.center,

                        'SheTravels',
                        textStyle: GoogleFonts.poppins(
                          color: Colors.pink.shade100,
                          fontSize: 35,
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
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: 500,
                    child: Text(
                      softWrap: true,
                      "Welcome to SheTravels, your ultimate resource for Curated travel experiences and nature retreats for women who seek connection, renewal, and adventure",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
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
                        color: Colors.pink.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          "Join Our Sisterhood",
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExploreToursScreen(),
                        ),
                      );
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMission() {
    return Padding(
      padding: const EdgeInsets.all(50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                softWrap: true,
                textAlign: TextAlign.center,
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
          SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/mission.webp'),
          ),
        ],
      ),
    );
  }

  Widget _buildSafety() {
    final List<String> safetyImages = [
      'assets/safety.webp',
      'assets/safety2.webp',
      'assets/safety3.webp',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FadeInDown(
            duration: Duration(milliseconds: 800),
            child: Text(
              'Your Safety and Convenience are Our Top Priorities',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: 24),

          // Description
          FadeInUp(
            duration: Duration(milliseconds: 800),
            child: Text(
              'At SheTravels, we understand the unique concerns of women travelers. '
              'That’s why we’ve built our platform with a strong emphasis on safety and convenience, '
              'ensuring every journey is enjoyable and worry-free.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),

          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAnimatedStat(
                label: 'Of our users report feeling safer using SheTravels',
                value: 98,
                suffix: '%',
                delay: 0,
              ),
              _buildAnimatedStat(
                label: 'Customer support available to assist you anytime.',
                value: 24,
                suffix: '/7',
                delay: 300,
              ),
            ],
          ),

          SizedBox(height: 40),
          ZoomIn(
            duration: Duration(milliseconds: 900),
            child: CarouselSlider(
              options: CarouselOptions(
                height: 250,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.9,
                aspectRatio: 16 / 9,
                autoPlayInterval: Duration(seconds: 3),
                autoPlayAnimationDuration: Duration(milliseconds: 800),
              ),
              items:
                  safetyImages.map((imagePath) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStat({
    required String label,
    required int value,
    required String suffix,
    required int delay,
  }) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      duration: Duration(milliseconds: 800),
      child: Column(
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: Duration(seconds: 2),
            builder: (context, val, child) {
              return Text(
                '$val$suffix',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade100,
                ),
              );
            },
          ),
          SizedBox(height: 10),
          SizedBox(
            width: 150,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: Colors.pink.shade100.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'GET IN TOUCH',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.pink.shade300,
            ),
          ),
          SizedBox(height: 10),

          SizedBox(height: 10),
          SizedBox(
            width: 600,
            child: Text(
              'Reach out to us for inquiries, feedback, or support. We’re here to help you explore the world with safety, sisterhood, and confidence.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap:
                    () => launchUrl(
                      Uri.parse("https://facebook.com/invisible_guide"),
                    ),
                child: SvgPicture.asset(
                  width: 30,
                  height: 30,
                  'assets/facebook.svg',
                  semanticsLabel: 'Facebook',
                ),
              ),

              GestureDetector(
                onTap:
                    () => launchUrl(
                      Uri.parse("https://instagram.com/invisible_guide"),
                    ),
                child: SvgPicture.asset(
                  width: 30,
                  height: 30,
                  'assets/ig.svg',
                  semanticsLabel: 'Instagram',
                ),
              ),

              GestureDetector(
                onTap:
                    () => launchUrl(
                      Uri.parse("https://email.com/invisible_guide"),
                    ),
                child: SvgPicture.asset(
                  width: 30,
                  height: 30,
                  'assets/email.svg',
                  semanticsLabel: 'email',
                ),
              ),

              GestureDetector(
                onTap:
                    () => launchUrl(Uri.parse("https://wa.me/2348000000000")),
                child: SvgPicture.asset(
                  width: 30,
                  height: 30,
                  'assets/whatsapp.svg',
                  semanticsLabel: 'Whatsapp',
                ),
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
}
