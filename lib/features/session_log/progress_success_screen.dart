import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../ui_system/app_theme.dart';
import '../../ui_system/spacing.dart';
import 'session_log_entry.dart';
import 'insight_payoff_screen.dart';
import '../surfer_pro/surfer_pro_paywall.dart';

enum InsightFlowState { success, analyzing }

class ProgressSuccessScreen extends StatefulWidget {
  final SessionLogEntry session;
  final bool isSpanish;
  final VoidCallback onLogAnother;
  final VoidCallback onViewSession;
  final List<SessionLogEntry> allSessions;
  final bool isSurferPro;
  final Future<SessionLogEntry?> Function(SessionLogEntry) onGenerateInsight;
  final VoidCallback? onFirstFreeAIUsed;

  const ProgressSuccessScreen({
    super.key,
    required this.session,
    required this.isSpanish,
    required this.onLogAnother,
    required this.onViewSession,
    required this.allSessions,
    required this.isSurferPro,
    required this.onGenerateInsight,
    this.onFirstFreeAIUsed,
  });

  @override
  State<ProgressSuccessScreen> createState() => _ProgressSuccessScreenState();
}

class _ProgressSuccessScreenState extends State<ProgressSuccessScreen> {
  late InsightFlowState _state;

  @override
  void initState() {
    super.initState();
    // ProgressSuccessScreen should now only show the success confirmation.
    // AI insights are handled via the manual prompt flow in SessionLogScreen.
    _state = InsightFlowState.success;
  }

  String t(String en, String es) => widget.isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _buildCurrentState(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentState() {
    switch (_state) {
      case InsightFlowState.analyzing:
        return _buildAnalyzingState();
      case InsightFlowState.success:
        return _buildSuccessState();
    }
  }

  Widget _buildAnalyzingState() {
    return Column(
      key: const ValueKey('analyzing'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          strokeWidth: 3,
          color: AppTheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          t("Analyzing your session...", "Analizando tu sesión..."),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          t("Personalizing your insight", "Personalizando tu insight"),
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    final prompts = _generatePrompts();
    return Column(
      key: const ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle, color: AppTheme.primary, size: 48),
        ),
        const SizedBox(height: 32),
        Text(
          t("Session saved 👍", "Sesión guardada 👍"),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        if (prompts.isNotEmpty)
          Text(
            prompts.first,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: widget.onViewSession,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              t("Continue", "Continuar"),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }





  List<String> _generatePrompts() {
    final List<String> result = [];
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    final isAlreadyIncluded = widget.allSessions.any((s) => s.id == widget.session.id);
    final totalSessions = isAlreadyIncluded ? widget.allSessions.length : widget.allSessions.length + 1;
    final allIncludedSessions = isAlreadyIncluded ? widget.allSessions : [...widget.allSessions, widget.session];

    final sessionsThisWeek = allIncludedSessions.where((s) => s.date.isAfter(startOfWeek)).length;
    
    if (totalSessions <= 1) {
      result.add(t("First session logged. Great start.", "Primera sesión registrada. Gran comienzo."));
    } else {
      final messages = [
        t("Every session gives you a clearer picture of your surf.", "Cada sesión te da una visión más clara de tu surf."),
        t("Nice work. Small notes now help you see progress later.", "Buen trabajo. Pequeñas notas ahora te ayudarán a ver tu progreso después."),
        t("You’re building consistency, one surf at a time.", "Estás creando consistencia, una sesión a la vez."),
        t("Session logged. Your surf story is starting to take shape.", "Sesión registrada. Tu historia de surf empieza a tomar forma."),
        t("Good job. Keep showing up and tracking what you notice.", "Buen trabajo. Sigue apareciendo y registrando lo que notas."),
      ];
      result.add(messages[totalSessions % messages.length]);
    }

    return result;
  }
}

