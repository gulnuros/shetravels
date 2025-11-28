import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stp;
import 'package:shetravels/utils/route.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  stp.Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  await stp.Stripe.instance.applySettings();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "",
      appId: "",
      messagingSenderId: "",
      projectId: "",
      storageBucket: "",
    ),
  );
  runApp(const ProviderScope(child: SheTravelApp()));
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
      builder:
          (context) => MaterialApp.router(
            title: 'SheTravels',
            routerConfig: appRouter.config(),
            debugShowCheckedModeBanner: false,
          ),
    );
  }
}

