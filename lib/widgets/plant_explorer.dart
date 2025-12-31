import 'package:carbonedge/data/machine_data.dart';
import 'package:carbonedge/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PlantExplorer extends StatefulWidget {
  final Function(String) onMachineSelected;

  const PlantExplorer({super.key, required this.onMachineSelected});

  @override
  State<PlantExplorer> createState() => _PlantExplorerState();
}

class _PlantExplorerState extends State<PlantExplorer> {
  String _selectedItem = MachineData.defaultMachine;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final Map<String, List<Map<String, dynamic>>> _allData = {
    "Kilns": MachineData.machines
        .where((m) => m.contains("Kiln"))
        .map((m) => {"title": m, "color": AppTheme.neonGreen})
        .toList(),
    "Furnaces": [
      {"title": "Furnace Line 1", "color": AppTheme.neonGreen},
      {"title": "Furnace Line 2", "color": AppTheme.neonGreen},
      {"title": "Furnace Line 3", "color": AppTheme.neonOrange},
    ],
    "Motors": [
      {"title": "Motor 1", "color": AppTheme.neonGreen},
      {"title": "Motor 7", "color": AppTheme.neonRed},
    ],
    "Fans": [
      {"title": "Fans 1", "color": AppTheme.neonGreen},
    ],
    "Compressors": [
      {"title": "Machine", "color": AppTheme.neonGreen},
    ],
    "Mills": [
      {"title": "Mills", "color": AppTheme.neonGreen},
      {"title": "Compressors", "color": AppTheme.neonGreen},
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<Map<String, dynamic>>> _getFilteredData() {
    if (_searchQuery.isEmpty) {
      return _allData;
    }

    final filtered = <String, List<Map<String, dynamic>>>{};
    _allData.forEach((section, items) {
      final filteredItems = items.where((item) {
        final title = item["title"] as String;
        return title.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();

      if (filteredItems.isNotEmpty) {
        filtered[section] = filteredItems;
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredData();

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          right: BorderSide(color: AppTheme.surfaceLight, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Plant Explorer",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search",
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: filteredData.entries.map((entry) {
                return _buildSection(
                  entry.key,
                  entry.value.map((item) {
                    return _buildItem(
                      item["title"] as String,
                      item["color"] as Color,
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      initiallyExpanded: true,
      iconColor: AppTheme.textSecondary,
      collapsedIconColor: AppTheme.textSecondary,
      children: children,
    );
  }

  Widget _buildItem(String title, Color statusColor) {
    final isSelected = _selectedItem == title;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedItem = title;
        });
        widget.onMachineSelected(title);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.neonCyan.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.neonCyan : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
