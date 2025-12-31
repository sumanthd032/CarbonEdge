import 'package:carbonedge/auth_screens/login_screen.dart';
import 'package:carbonedge/main_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print("AuthWrapper: ConnectionState=${snapshot.connectionState}, HasData=${snapshot.hasData}");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const MainHomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
