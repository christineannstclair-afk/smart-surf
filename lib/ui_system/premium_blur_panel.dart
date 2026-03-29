import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'spacing.dart';

class PremiumBlurPanel extends StatelessWidget {
  final Widget child;
  final String ctaText;
  final VoidCallback onUnlock;
  final BorderRadiusGeometry? borderRadius;
  final double sigma;
  final double opacity;

  const PremiumBlurPanel({
    super.key,
    required this.child,
    required this.ctaText,
    required this.onUnlock,
    this.borderRadius,
    this.sigma = 3.0,
    this.opacity = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(24);
    final isWeb = kIsWeb;
    
    return ClipRRect(
      borderRadius: effectiveRadius,
      child: Stack(
        children: [
          // 1) The glass background (blurs what is behind the entire card)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: isWeb ? 8.0 : sigma * 2, 
                sigmaY: isWeb ? 8.0 : sigma * 2
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6), // Seafoam glass
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
                  borderRadius: effectiveRadius,
                ),
              ),
            ),
          ),

          // 2) The Content Layer (Readable!)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The custom content (Title, Subtitle, Benefits)
                child,
                
                const SizedBox(height: AppSpacing.md),
                
                // 3) The CTA Button at the bottom
                if (ctaText.isNotEmpty)
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onUnlock,
                      icon: const Icon(Icons.lock_outline_rounded, size: 20),
                      label: Text(
                        ctaText,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary, // Navy / Deep Sea Teal
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Ensure kIsWeb is available by adding import if missing at the top
