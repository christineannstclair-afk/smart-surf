import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../ui_system/app_theme.dart';
import '../../ui_system/spacing.dart';
import '../../ui_system/upgrade_bottom_sheet.dart';
import '../../core/subscription_config.dart';

void showSurfInsightPaywall(BuildContext context, {bool isSpanish = false, VoidCallback? onUnlock}) {
  showUpgradeBottomSheet(
    context: context,
    isSpanish: isSpanish,
    child: SurfInsightPaywall(onUnlock: onUnlock, isSpanish: isSpanish),
  );
}

class SurfInsightPaywall extends StatelessWidget {
  final VoidCallback? onUnlock;
  final bool isSpanish;

  const SurfInsightPaywall({super.key, this.onUnlock, this.isSpanish = false});

  String _t(String en, String es) => isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header showing brand / icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 48),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            "Surfer Pro",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            _t("Turn your surf sessions into real insights.", "Convierte tus sesiones de surf en insights reales."),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),

          // Feature List
          _buildFeatureRow(context, _t("AI Surf Insights from your sessions", "Insights de IA de tus sesiones")),
          const SizedBox(height: 16),
          _buildFeatureRow(context, _t("Progress patterns across recent surfs", "Patrones de progreso en sesiones recientes")),
          const SizedBox(height: 16),
          _buildFeatureRow(context, _t("Next session focus suggestions", "Sugerencias de enfoque para tu próxima sesión")),
          const SizedBox(height: 48),

          // Pricing display with glass effect highlighting
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.15),
                      AppTheme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_t("Monthly", "Mensual"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(SubscriptionConfig.surferMonthlyStr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primary)),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_t("Annual", "Anual"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(SubscriptionConfig.surferAnnualStr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Action Buttons
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: () {
                if (onUnlock != null) {
                  onUnlock!();
                }
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _t("Start Free Trial", "Comenzar prueba gratis"),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _t("Continue with Free Version", "Continuar con la versión gratuita"),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: AppTheme.primary.withOpacity(0.8), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
