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
}
