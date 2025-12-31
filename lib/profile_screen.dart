import 'package:carbonedge/auth_screens/login_screen.dart';
import 'package:carbonedge/theme/app_theme.dart';
import 'package:carbonedge/widgets/neon_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isDarkMode = true; // Default to dark mode as per new theme

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile & Settings",
          style: GoogleFonts.orbitron(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.neonCyan),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.surfaceLight,
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.displayName ?? "User Name",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    user?.email ?? "user@example.com",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Account Details",
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.neonCyan,
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoTile(
              Icons.person_outline,
              "Name",
              user?.displayName ?? "Not set",
            ),
            _buildInfoTile(
              Icons.email_outlined,
              "Email",
              user?.email ?? "Not set",
            ),
            _buildInfoTile(Icons.phone_outlined, "Phone", "Not set"),

            const SizedBox(height: 30),
            Text(
              "Settings",
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.neonCyan,
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: Text(
                "Dark Mode",
                style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textPrimary),
              ),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
              secondary: const Icon(Icons.dark_mode_outlined, color: AppTheme.neonCyan),
              activeTrackColor: AppTheme.neonCyan,
              tileColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            ListTile(
              leading: const Icon(Icons.settings_input_component_outlined, color: AppTheme.neonCyan),
              title: Text(
                "Connection Settings",
                style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textPrimary),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
              onTap: () {
                // TODO: Navigate to connection settings
              },
              tileColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonRed,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Logout",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return NeonCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.neonCyan),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
