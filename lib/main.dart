import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stp;
import 'package:shetravels/utils/route.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  stp.Stripe.publishableKey =
      'pk_test_51Ro4rt4PEU7g7vAIEniFRppWPZVviCtkyRqWpmzCuQKk3aHgFmvLzAWEU27pTPDkj2gCX0UPLVqwEcUBiEVGqZ1r00XHc6VPoN';
  await stp.Stripe.instance.applySettings();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDB1oaqJLqOQniQJdXDZ_9Nnv-2rwCrUMw",
      appId: "1:954659216726:web:8d0f2d910d445134840af7",
      messagingSenderId: "954659216726",
      projectId: "shetravels-ac34a",
      storageBucket: "shetravels-ac34a.firebasestorage.app",
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
