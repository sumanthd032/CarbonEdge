import 'package:flutter/material.dart';
import 'package:carbonedge/theme/app_theme.dart';

class NeonCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final bool glow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const NeonCard({
    super.key,
    required this.child,
    this.borderColor,
    this.glow = false,
    this.padding,
    this.margin,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppTheme.surfaceLight,
          width: 1.5,
        ),
        boxShadow: glow && borderColor != null
            ? [
                BoxShadow(
                  color: borderColor!.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
