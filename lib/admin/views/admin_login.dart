import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shetravels/utils/helpers.dart';
import 'package:shetravels/utils/route.gr.dart';

@RoutePage()
class AdminLoginScreen extends StatefulHookConsumerWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (credential.user!.email != "oleksandradzhus@gmail.com") {
        throw FirebaseAuthException(
          code: "unauthorized",
          message: "Not authorized as admin",
        );
      }

      context.router.push(AdminDashboardRoute());
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    }

    setState(() => _isLoading = false);
  }

  Map<String, double> _getResponsiveDimensions(Size size) {
    final bool isMobile = size.width < 600;
    final bool isTablet = size.width >= 600 && size.width < 1200;
    final bool isDesktop = size.width >= 1200;

    return {
      'horizontalPadding': isMobile ? 16.0 : (isTablet ? 32.0 : 48.0),
      'cardMaxWidth': isMobile ? double.infinity : (isTablet ? 500.0 : 450.0),
      'cardPadding': isMobile ? 24.0 : (isTablet ? 32.0 : 40.0),
      'logoSize': isMobile ? 100.0 : (isTablet ? 120.0 : 140.0),
      'titleFontSize': isMobile ? 20.0 : (isTablet ? 24.0 : 28.0),
      'subtitleFontSize': isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
      'buttonHeight': isMobile ? 50.0 : (isTablet ? 56.0 : 60.0),
      'buttonFontSize': isMobile ? 14.0 : (isTablet ? 16.0 : 18.0),
      'spacing': isMobile ? 16.0 : (isTablet ? 20.0 : 24.0),
      'largeSpacing': isMobile ? 24.0 : (isTablet ? 32.0 : 40.0),
      'extraLargeSpacing': isMobile ? 32.0 : (isTablet ? 48.0 : 64.0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dimensions = _getResponsiveDimensions(size);
    final bool isMobile = size.width < 600;
    final bool isTablet = size.width >= 600 && size.width < 1200;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: dimensions['horizontalPadding']!,
                vertical: dimensions['spacing']!,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dimensions['cardMaxWidth']!,
                  minHeight:
                      size.height -
                      (MediaQuery.of(context).padding.top +
                          MediaQuery.of(context).padding.bottom +
                          dimensions['spacing']! * 2),
                ),
                child: IntrinsicHeight(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isMobile) const Spacer(flex: 1),

                          Container(
                            margin: EdgeInsets.only(
                              bottom: dimensions['extraLargeSpacing']!,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: dimensions['logoSize'],
                                  height: dimensions['logoSize'],
                                  padding: EdgeInsets.all(
                                    dimensions['logoSize']! * 0.15,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: FutureBuilder(
                                    future: loadSvgAsset(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data == true) {
                                        return SvgPicture.asset(
                                          'assets/she_travel.svg',
                                          semanticsLabel: 'SheTravels Logo',
                                          colorFilter: const ColorFilter.mode(
                                            Colors.white,
                                            BlendMode.srcIn,
                                          ),
                                        );
                                      } else {
                                        return Icon(
                                          Icons.travel_explore_rounded,
                                          size: dimensions['logoSize']! * 0.5,
                                          color: Colors.white,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(height: dimensions['spacing']! * 0.5),
                                Text(
                                  "Admin Portal",
                                  style: TextStyle(
                                    fontSize: dimensions['subtitleFontSize'],
                                    color: Colors.white.withOpacity(0.8),
                                    letterSpacing: 0.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: EdgeInsets.all(dimensions['cardPadding']!),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(
                                isMobile ? 20 : 24,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    "Welcome Back",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: dimensions['titleFontSize'],
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                  SizedBox(
                                    height: dimensions['spacing']! * 0.4,
                                  ),
                                  Text(
                                    "Sign in to manage your travel community",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: dimensions['subtitleFontSize'],
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: dimensions['largeSpacing']!),

                                  if (_error != null) ...[
                                    Container(
                                      padding: EdgeInsets.all(
                                        dimensions['spacing']! * 0.75,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red[700],
                                            size: isMobile ? 18 : 20,
                                          ),
                                          SizedBox(
                                            width: dimensions['spacing']! * 0.5,
                                          ),
                                          Expanded(
                                            child: Text(
                                              _error!,
                                              style: TextStyle(
                                                color: Colors.red[700],
                                                fontSize:
                                                    dimensions['subtitleFontSize']! -
                                                    1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: dimensions['spacing']!),
                                  ],

                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                      fontSize: dimensions['subtitleFontSize'],
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(
                                        r'^[^@]+@[^@]+\.[^@]+',
                                      ).hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      labelText: "Email Address",
                                      labelStyle: TextStyle(
                                        fontSize:
                                            dimensions['subtitleFontSize'],
                                      ),
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: const Color(0xFF667eea),
                                        size: isMobile ? 20 : 24,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          isMobile ? 12 : 16,
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          isMobile ? 12 : 16,
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          isMobile ? 12 : 16,
                                        ),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF667eea),
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: dimensions['spacing']!,
                                        vertical: isMobile ? 12 : 16,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: dimensions['spacing']!),

                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(
                                      fontSize: dimensions['subtitleFontSize'],
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      labelText: "Password",
                                      labelStyle: TextStyle(
                                        fontSize:
                                            dimensions['subtitleFontSize'],
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: const Color(0xFF667eea),
                                        size: isMobile ? 20 : 24,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.grey[600],
                                          size: isMobile ? 20 : 24,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          isMobile ? 12 : 16,
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          isMobile ? 12 : 16,
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          isMobile ? 12 : 16,
                                        ),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF667eea),
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: dimensions['spacing']!,
                                        vertical: isMobile ? 12 : 16,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: dimensions['largeSpacing']!),

                                  Container(
                                    height: dimensions['buttonHeight'],
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF667eea),
                                          Color(0xFF764ba2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        isMobile ? 12 : 16,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF667eea,
                                          ).withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            isMobile ? 12 : 16,
                                          ),
                                        ),
                                      ),
                                      child:
                                          _isLoading
                                              ? SizedBox(
                                                width: isMobile ? 20 : 24,
                                                height: isMobile ? 20 : 24,
                                                child:
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                              )
                                              : Text(
                                                "Sign In",
                                                style: TextStyle(
                                                  fontSize:
                                                      dimensions['buttonFontSize'],
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: dimensions['largeSpacing']!),

                          Text(
                            "Empowering women to explore the world safely",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: dimensions['subtitleFontSize'],
                            ),
                          ),

                          if (!isMobile) const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
