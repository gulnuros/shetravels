import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stp;
import 'package:shetravels/utils/route.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get config from window object (set by config.js)
  final firebaseConfig = _getFirebaseConfig();
  final stripeKey = _getStripeKey();
  
  stp.Stripe.publishableKey = stripeKey; 
  await stp.Stripe.instance.applySettings();
  
  await Firebase.initializeApp(options: firebaseConfig);
  
  runApp(const ProviderScope(child: SheTravelApp()));
}

FirebaseOptions _getFirebaseConfig() {
  final config = html.window as dynamic;
  final fbConfig = config.firebaseConfig;
  
  return FirebaseOptions(
    apiKey: fbConfig['apiKey'] ?? '',
    authDomain: fbConfig['authDomain'] ?? '',
    projectId: fbConfig['projectId'] ?? '',
    storageBucket: fbConfig['storageBucket'] ?? '',
    messagingSenderId: fbConfig['messagingSenderId'] ?? '',
    appId: fbConfig['appId'] ?? '',
    measurementId: fbConfig['measurementId'],
  );
}

String _getStripeKey() {
  final config = html.window as dynamic;
  return config.stripePublishableKey ?? '';
}

class SheTravelApp extends StatefulWidget {
  const SheTravelApp({super.key});

  @override
  State<SheTravelApp> createState() => _SheTravelAppState();
}

class _SheTravelAppState extends State<SheTravelApp> {
  final appRouter = AppRouter();
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveApp(
      builder: (context) => MaterialApp.router(
        title: 'SheTravels',
        routerConfig: appRouter.config(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}