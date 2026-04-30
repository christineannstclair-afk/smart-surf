import 'package:flutter/material.dart';
import '../../ui_system/app_theme.dart';
import '../../ui_system/spacing.dart';
import '../../ui_system/app_card.dart';
import 'session_log_entry.dart';
import '../../core/translation_service.dart';

class InsightPayoffScreen extends StatelessWidget {
  final bool isSpanish;
  final SessionLogEntry session;
  final VoidCallback onLogAnother;
  final VoidCallback onFinish;

  final String? nudgeMessage;
  final VoidCallback? onNudgeTap;
  final bool isSurferPro;

  const InsightPayoffScreen({
    super.key,
    required this.isSpanish,
    required this.session,
    required this.onLogAnother,
    required this.onFinish,
    required this.isSurferPro,
    this.nudgeMessage,
    this.onNudgeTap,
  });

  String _t(String en, String es) => isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    final nextFocus = isSpanish 
        ? (session.aiNextFocusEs ?? session.aiNextFocus) 
        : (session.aiNextFocusEn ?? session.aiNextFocus);
    final summary = isSpanish 
        ? (session.aiSummaryEs ?? session.aiSummary) 
        : (session.aiSummaryEn ?? session.aiSummary);
    final pattern = isSpanish
        ? (session.aiProgressPatternEs ?? session.aiProgressPattern)
        : (session.aiProgressPatternEn ?? session.aiProgressPattern);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                _t("Your surf insight", "Tu insight de surf"),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 32),
              
              // 1. What you worked on (Pro only)
              if (isSurferPro && summary != null && summary.isNotEmpty) ...[
                _buildInsightSection(
                  label: _t("SESSION INSIGHT", "INSIGHT DE LA SESIÓN"),
                  content: summary,
                ),
                const SizedBox(height: 24),
              ],
              
              // 2. What happened (Pro only)
              if (isSurferPro) ...[
                _buildInsightSection(
                  label: _t("PROGRESS PATTERN", "PATRÓN DE PROGRESO"),
                  content: (pattern != null && pattern.isNotEmpty)
                      ? pattern
                      : _t("You're starting to build a pattern. A few more sessions will make this clearer.", "Estás empezando a construir un patrón. Unas cuantas sesiones más lo harán más claro."),
                ),
                const SizedBox(height: 24),
              ],

              // 3. Try this next (Everyone)
              _buildInsightCard(
                context: context,
                label: _t("NEXT SESSION FOCUS", "ENFOQUE PARA LA PRÓXIMA SESIÓN"),
                content: (nextFocus != null && nextFocus.isNotEmpty) 
                  ? nextFocus 
                  : _t("We're generating your first insight. This takes a few seconds.", "Estamos generando tu primer insight. Esto toma unos segundos."),
                isPrimary: true,
              ),

              if (nudgeMessage != null) ...[
                const SizedBox(height: 32),
                _buildNudgeCard(context, nudgeMessage!),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: onLogAnother,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _t("Log another session", "Registrar otra sesión"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: onFinish,
                  child: Text(
                    _t("Back to dashboard", "Volver al dashboard"),
                    style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightSection({required String label, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppTheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildNudgeCard(BuildContext context, String message) {
    return GestureDetector(
      onTap: onNudgeTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.secondary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: AppTheme.secondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.secondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required BuildContext context,
    required String label,
    required String content,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPrimary ? AppTheme.primary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPrimary ? AppTheme.primary.withOpacity(0.2) : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isPrimary ? AppTheme.primary : AppTheme.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: isPrimary ? 20 : 16,
              fontWeight: isPrimary ? FontWeight.w900 : FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
