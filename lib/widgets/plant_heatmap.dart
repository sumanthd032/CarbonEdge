import 'package:carbonedge/data/machine_data.dart';
import 'package:carbonedge/theme/app_theme.dart';
import 'package:carbonedge/widgets/neon_card.dart';
import 'package:flutter/material.dart';

class PlantHeatmap extends StatelessWidget {
  final bool isMobile;
  final String selectedMachine;

  const PlantHeatmap({
    super.key,
    this.isMobile = false,
    this.selectedMachine = MachineData.defaultMachine,
  });

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Plant Heatmap Visualization",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (!isMobile)
                Row(
                  children: [
                    _buildLegendItem("Normal", AppTheme.neonGreen),
                    const SizedBox(width: 16),
                    _buildLegendItem("Drift", AppTheme.neonOrange),
                    const SizedBox(width: 16),
                    _buildLegendItem("Anomaly", AppTheme.neonRed),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (isMobile) _buildMobileView() else _buildDesktopView(),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMobileView() {
    return Column(
      children: [
        _buildMobileItem("Kiln A", "Normal", AppTheme.neonGreen),
        _buildMobileItem("Kiln B", "Normal", AppTheme.neonGreen),
        _buildMobileItem(
          "Kiln C",
          "Anomaly: 1350°C High",
          AppTheme.neonRed,
          isAnomaly: true,
        ),
        _buildMobileItem("Motor 7", "Drift", AppTheme.neonOrange),
        _buildMobileItem("Motor 8", "Normal", AppTheme.neonGreen),
        _buildMobileItem("Motor 9", "Normal", AppTheme.neonGreen),
      ],
    );
  }

  Widget _buildMobileItem(
    String name,
    String status,
    Color color, {
    bool isAnomaly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopView() {
    // Simple deterministic random based on selected machine to vary the state of other nodes
    final random = selectedMachine.hashCode;
    bool isAnomaly(int index) => (random + index) % 5 == 0;
    bool isDrift(int index) => (random + index) % 3 == 0;

    Color getStatusColor(int index, String name) {
      if (name == selectedMachine) return AppTheme.neonCyan; // Highlight selected
      if (isAnomaly(index)) return AppTheme.neonRed;
      if (isDrift(index)) return AppTheme.neonOrange;
      return AppTheme.neonGreen;
    }

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          // Background schematic (simplified lines)
          Positioned(
            top: 50,
            left: 50,
            right: 50,
            child: Container(height: 2, color: AppTheme.surfaceLight),
          ),
          Positioned(
            top: 150,
            left: 50,
            right: 50,
            child: Container(height: 2, color: AppTheme.surfaceLight),
          ),
          // Nodes
          Positioned(
            top: 30,
            left: 80,
            child: _buildNode("Kiln A", getStatusColor(1, "Kiln A"), isSelected: selectedMachine == "Kiln A"),
          ),
          Positioned(
            top: 30,
            left: 200,
            child: _buildNode("Kiln B", getStatusColor(2, "Kiln B"), isSelected: selectedMachine == "Kiln B"),
          ),
          Positioned(
            top: 30,
            left: 320,
            child: _buildNode(
              "Kiln C",
              getStatusColor(3, "Kiln C"),
              hasAlert: isAnomaly(3),
              alertText: "Anomaly\n1350°C",
              isSelected: selectedMachine == "Kiln C",
            ),
          ),
          Positioned(
            top: 130,
            left: 80,
            child: _buildNode("Motor 3", getStatusColor(4, "Motor 3")),
          ),
          Positioned(
            top: 130,
            left: 200,
            child: _buildNode("Motor 4", getStatusColor(5, "Motor 4")),
          ),
          Positioned(
            top: 130,
            left: 320,
            child: _buildNode("Motor 5", getStatusColor(6, "Motor 5")),
          ),
          Positioned(
            top: 130,
            left: 440,
            child: _buildNode("Motor 6", getStatusColor(7, "Motor 6")),
          ),
          Positioned(
            top: 130,
            left: 560,
            child: _buildNode("Motor 7", getStatusColor(8, "Motor 7")),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(
    String label,
    Color color, {
    bool hasAlert = false,
    String? alertText,
    bool isSelected = false,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.neonCyan : color,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? AppTheme.neonCyan : color).withValues(alpha: 0.5),
                    blurRadius: isSelected ? 12 : 8,
                    spreadRadius: isSelected ? 4 : 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            if (hasAlert)
              Positioned(
                bottom: 32,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    alertText ?? "",
                    style: TextStyle(color: color, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
