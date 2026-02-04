import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stp;
import 'package:shetravels/utils/route.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get config from environment variables or other secure storage
  final firebaseConfig = _getFirebaseConfig();
  final stripeKey = _getStripeKey();
  
  stp.Stripe.publishableKey = stripeKey; 
  await stp.Stripe.instance.applySettings();
  
  await Firebase.initializeApp(options: firebaseConfig);
  
  runApp(const ProviderScope(child: SheTravelApp()));
}

FirebaseOptions _getFirebaseConfig() {
  // Replace with a method to fetch Firebase config without using dart:html
  return FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
    authDomain: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: ''),
    projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
    storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: ''),
    messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: ''),
    appId: const String.fromEnvironment('FIREBASE_APP_ID', defaultValue: ''),
    measurementId: const String.fromEnvironment('FIREBASE_MEASUREMENT_ID', defaultValue: ''),
  );
}

String _getStripeKey() {
  // Replace with a method to fetch Stripe key without using dart:html
  return const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');
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