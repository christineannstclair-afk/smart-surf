import 'package:flutter/material.dart';
import '../ui_system/app_theme.dart';

class SmartSurfWordmark extends StatelessWidget {
  final bool isInverse;
  final double iconSize;
  final double fontSize;
  final double spacing;

  const SmartSurfWordmark({
    super.key,
    this.isInverse = false,
    this.iconSize = 20,
    this.fontSize = 18,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final Color smartColor = isInverse ? Colors.white : AppTheme.primary;
    final Color surfColor = AppTheme.secondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.waves_rounded,
          color: surfColor,
          size: iconSize,
        ),
        SizedBox(width: spacing),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(
                text: 'Smart ',
                style: TextStyle(color: smartColor),
              ),
              const TextSpan(
                text: 'Surf',
                style: TextStyle(color: AppTheme.secondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
