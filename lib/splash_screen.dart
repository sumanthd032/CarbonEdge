import 'dart:async';
import 'package:carbonedge/auth_wrapper.dart';
import 'package:carbonedge/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Assuming logo needs to be visible on dark background, 
            // if it's black text it might be invisible. 
            // I'll assume it's fine or wrap it in a container if needed.
            // For now, I'll keep it as is.
            Image.asset('assets/logo.png', width: 180, height: 180),
            const SizedBox(height: 30),
            Text(
              "CarbonEdge",
              style: TextStyle( // Removed GoogleFonts for debugging
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.neonCyan,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Industrial Energy Optimization",
              style: TextStyle( // Removed GoogleFonts for debugging
                fontSize: 16,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
            ),
          ],
        ),
      ),
    );
  }
}
