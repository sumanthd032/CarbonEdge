import 'package:flutter/material.dart';
import 'package:carbonedge/theme/app_theme.dart';
import 'package:carbonedge/widgets/neon_card.dart';

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String trend;
  final bool isPositiveTrend;
  final IconData icon;
  final Color accentColor;
  final bool isWeb;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.trend,
    required this.isPositiveTrend,
    required this.icon,
    required this.accentColor,
    this.isWeb = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      borderColor: accentColor,
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: isWeb ? 24 : 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: isWeb ? 14 : 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isWeb ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositiveTrend ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositiveTrend ? AppTheme.neonGreen : AppTheme.neonRed,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trend,
                  style: TextStyle(
                    color: isPositiveTrend
                        ? AppTheme.neonGreen
                        : AppTheme.neonRed,
                    fontSize: isWeb ? 14 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
