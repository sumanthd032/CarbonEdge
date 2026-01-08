import 'dart:ui';
import 'package:carbonedge/services/simulation_state.dart';
import 'package:carbonedge/bottom_bar/ai_recommendations_screen.dart';
import 'package:carbonedge/bottom_bar/alerts_screen.dart';
import 'package:carbonedge/bottom_bar/connect_scada_screen.dart';
import 'package:carbonedge/bottom_bar/dashboard_screen.dart';
import 'package:carbonedge/bottom_bar/reports_screen.dart';
import 'package:carbonedge/profile_screen.dart';
import 'package:carbonedge/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;
  bool _showSimulationPopup = true;
  bool _isConnecting = false;

  static const List<Widget> _screens = <Widget>[
    DashboardScreen(),
    ConnectScadaScreen(),
    // MachinesScreen(),
    AlertsScreen(),
    AIOptimizationPage(),
    ReportsScreen(),
  ];

  static const List<String> _titles = <String>[
    "Dashboard",
    "Connect SCADA",
    "Alerts",
    "AI Recommendations",
    "Reports",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMainScaffold(context),
        if (_showSimulationPopup) _buildSimulationPopup(),
      ],
    );
  }

  Widget _buildMainScaffold(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 800;

        if (isWeb) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppTheme.surface,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Image.asset('assets/logo.png', height: 32),
                  const SizedBox(width: 12),
                  const Text(
                    "Carbon Edge",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              actions: [
                _buildTopNavItem(0, "Dashboard", Icons.dashboard),
                _buildTopNavItem(1, "Connect SCADA", Icons.link),
                // _buildTopNavItem(2, "Machines", Icons.memory),
                _buildTopNavItem(2, "Alerts", Icons.notifications),
                _buildTopNavItem(3, "AI Recommendations", Icons.lightbulb),
                _buildTopNavItem(4, "Reports", Icons.bar_chart),
                _buildTopNavItem(5, "Profile", Icons.person),
                const SizedBox(width: 16),
              ],
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: [..._screens, const ProfileScreen()],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                color: AppTheme.neonCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person, color: AppTheme.neonCyan),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: IndexedStack(index: _selectedIndex, children: _screens),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: const Border(
                top: BorderSide(color: AppTheme.surfaceLight, width: 1),
              ),
            ),
            child: BottomNavigationBar(
              selectedItemColor: AppTheme.neonCyan,
              unselectedItemColor: AppTheme.textSecondary,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppTheme.surface,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.link),
                  label: 'Connect',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label: 'Alerts',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.lightbulb),
                  label: 'AI',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Reports',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopNavItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: isSelected
                ? const Border(
                    bottom: BorderSide(color: AppTheme.neonCyan, width: 2),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.neonCyan : AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.neonCyan
                      : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationPopup() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.neonCyan, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonCyan.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Welcome to CarbonEdge",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "CarbonEdge is designed to connect with real-time factory machines to analyze operational data using AI.\n\n"
                      "Since live factory machines are not available during this demo, the app runs in Simulation Mode by default.\n\n"
                      "In this mode, the system generates realistic, real-time machine data and processes it through the same AI model and pipeline used for real-world deployments.\n\n"
                      "This allows you to experience the full functionality of CarbonEdge exactly as it would work in a live factory environment.",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (_isConnecting) ...[
                      const CircularProgressIndicator(color: AppTheme.neonCyan),
                      const SizedBox(height: 16),
                      const Text(
                        "Connecting to AI Model...",
                        style: TextStyle(
                          color: AppTheme.neonCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            setState(() {
                              _isConnecting = true;
                            });
                            await Future.delayed(const Duration(seconds: 3));
                            SimulationState.setConnected(true);
                            if (mounted) {
                              setState(() {
                                _showSimulationPopup = false;
                                _isConnecting = false;
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppTheme.neonCyan,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Connect Model",
                            style: TextStyle(
                              color: AppTheme.neonCyan,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
