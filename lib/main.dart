import 'dart:async';
import 'package:carbonedge/splash_screen.dart';
import 'package:carbonedge/theme/app_theme.dart';
import 'package:flutter/material.dart';

import 'package:carbonedge/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    print("CarbonEdge: Starting app...");
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      print("CarbonEdge: Firebase initialized successfully");
    } catch (e) {
      print("CarbonEdge: Firebase initialization failed: $e");
    }
    runApp(const CarbonEdgeApp());
  }, (error, stack) {
    print("CarbonEdge: Uncaught error: $error");
    print(stack);
  });
}

class CarbonEdgeApp extends StatelessWidget {
  const CarbonEdgeApp({super.key}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CarbonEdge',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
