import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../../models/reflection_model.dart';
import '../../models/ai_analysis_model.dart';
import '../../core/subscription_config.dart';
import '../../ui_system/upgrade_bottom_sheet.dart';
import '../../core/analyze_api.dart';
import 'ai_analysis_screen.dart';
import '../session_log/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'surfer_pro_paywall.dart';

void showSurferProModal({
  required BuildContext context,
  required bool isSpanish,
  required bool isSurferPro,
  required List<SessionReflection> reflections,
  required Function(SessionReflection) onAddReflection,
  required List<AiAnalysisResult> aiAnalyses,
  required Function(AiAnalysisResult) onAddAiAnalysis,
}) {
  showUpgradeBottomSheet(
    context: context,
    isSpanish: isSpanish,
    child: SurferProUpgradeContent(
      isSpanish: isSpanish,
      isSurferPro: isSurferPro,
      reflections: reflections,
      onAddReflection: onAddReflection,
      aiAnalyses: aiAnalyses,
      onAddAiAnalysis: onAddAiAnalysis,
    ),
  );
}

class SurferProUpgradeContent extends StatefulWidget {
  final bool isSpanish;
  final bool isSurferPro;
  final List<SessionReflection> reflections;
  final Function(SessionReflection) onAddReflection;
  final List<AiAnalysisResult> aiAnalyses;
  final Function(AiAnalysisResult) onAddAiAnalysis;

  const SurferProUpgradeContent({
    super.key,
    required this.isSpanish,
    required this.isSurferPro,
    required this.reflections,
    required this.onAddReflection,
    required this.aiAnalyses,
    required this.onAddAiAnalysis,
  });

  @override
  State<SurferProUpgradeContent> createState() => _SurferProUpgradeContentState();
}

class _SurferProUpgradeContentState extends State<SurferProUpgradeContent> {
  final _workingOnCtrl = TextEditingController();
  final _feltHardCtrl = TextEditingController();
  final _feltGoodCtrl = TextEditingController();
  bool _isGenerating = false;

  String t(String en, String es) => widget.isSpanish ? es : en;

  void _generateReflection() async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => const AlertDialog(title: Text('Proof: Button Fired _generateReflection!')),
      );
    }

    final hasInput = _workingOnCtrl.text.trim().isNotEmpty ||
                     _feltHardCtrl.text.trim().isNotEmpty ||
                     _feltGoodCtrl.text.trim().isNotEmpty;

    if (!hasInput) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isSpanish 
                ? 'Añade al menos un detalle para generar el insight con IA.' 
                : 'Add at least one session detail to generate AI insight.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Milestone Check: If free and already has a reflection with AI, block.
    final bool hasExistingAI = widget.reflections.any((r) => r.aiSummary.isNotEmpty);
    if (!widget.isSurferPro && hasExistingAI) {
      if (mounted) {
        Navigator.pop(context); // Close modal
        openSurferProPaywall(context, source: 'surfer_pro_reflection_form_blocked', isSpanish: widget.isSpanish);
      }
      return;
    }
    
    setState(() => _isGenerating = true);
    
    String? finalSummary;
    String? finalProgressPattern;
    String? finalNextFocus;
    String? summaryEs;
    String? progressEs;
    String? nextFocusEs;

    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception("Authentication required for AI analysis");
      }

      final aiResult = await AnalyzeApi.analyzeReflection(
        idToken: idToken,
        sessionId: '', // General reflections aren't tied to a specific session_id here
        focus: '', // Safe empty string, since not captured here yet
        workedOn: _workingOnCtrl.text,
        feltHard: _feltHardCtrl.text,
        feltGood: _feltGoodCtrl.text,
        conditions: '',
        notes: '',
        language: widget.isSpanish ? 'es' : 'en',
      );

      finalSummary = (aiResult['session_insight_en'] ?? (widget.isSpanish ? null : aiResult['session_insight'])) as String?;
      finalProgressPattern = (aiResult['progress_pattern_en'] ?? (widget.isSpanish ? null : aiResult['progress_pattern'])) as String?;
      finalNextFocus = (aiResult['next_session_focus_en'] ?? (widget.isSpanish ? null : aiResult['next_session_focus'])) as String?;

      summaryEs = (aiResult['session_insight_es'] ?? (widget.isSpanish ? aiResult['session_insight'] : null)) as String?;
      progressEs = (aiResult['progress_pattern_es'] ?? (widget.isSpanish ? aiResult['progress_pattern'] : null)) as String?;
      nextFocusEs = (aiResult['next_session_focus_es'] ?? (widget.isSpanish ? aiResult['next_session_focus'] : null)) as String?;

      
      if (finalSummary != null && finalSummary.isNotEmpty) {
        print("REAL AI BILINGUAL RESPONSE RECEIVED");
      }
    } catch (e) {
      debugPrint("LLM API failed or timed out: $e");
      if (e.toString().contains("403")) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t("Daily AI limit reached (3/3). Try again tomorrow!", "Límite diario de IA alcanzado (3/3). ¡Intenta mañana!")),
                backgroundColor: Colors.orange.shade800,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          setState(() => _isGenerating = false);
          return;
      }
      print("BACKEND CALL FAILED");
    }

    // Graceful fallback to _simulate models if API fails
    if ((finalSummary == null || finalSummary!.isEmpty) && (summaryEs == null || summaryEs!.isEmpty)) {
      print("FALLBACK MOCK RESPONSE USED");
      finalSummary = _simulateAISummary(_workingOnCtrl.text, _feltHardCtrl.text, _feltGoodCtrl.text);
      finalProgressPattern = '';
      finalNextFocus = _simulateAINextFocus(_workingOnCtrl.text, _feltHardCtrl.text);
    }

    final reflection = SessionReflection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      workingOn: _workingOnCtrl.text,
      whatFeltHard: _feltHardCtrl.text,
      whatFeltGood: _feltGoodCtrl.text,
      aiSummary: finalSummary ?? '',
      aiProgressPattern: finalProgressPattern ?? '',
      aiNextFocus: finalNextFocus ?? '',
      aiSummaryEn: finalSummary,
      aiSummaryEs: summaryEs,
      aiProgressPatternEn: finalProgressPattern,
      aiProgressPatternEs: progressEs,
      aiNextFocusEn: finalNextFocus,
      aiNextFocusEs: nextFocusEs,
    );

    widget.onAddReflection(reflection);
    FirebaseService().logEvent('ai_reflection_used');

    setState(() {
      _isGenerating = false;
      _workingOnCtrl.clear();
      _feltHardCtrl.clear();
      _feltGoodCtrl.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Reflection saved!", "¡Reflexión guardada!")),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _simulateAISummary(String working, String hard, String good) {
    final w = working.trim();
    final h = hard.trim();
    final g = good.trim();

    if (w.isEmpty && h.isEmpty && g.isEmpty) {
      return t("It looks like you didn't leave many details this time, but getting in the water is a win in itself. Keep logging to track your progression pattern.",
               "Parece que esta vez no dejaste muchos detalles, pero entrar al agua ya es una victoria. Sigue registrando para seguir tu patrón de progreso.");
    }

    final bool contradiction = (h.isNotEmpty && g.isNotEmpty) && 
        (h.toLowerCase() == g.toLowerCase() || h.toLowerCase().contains(g.toLowerCase()) || g.toLowerCase().contains(h.toLowerCase()));

    if (contradiction) {
      return t("Interestingly, what challenged you ($h) was also closely tied to what felt good ($g). This friction usually means you're breaking old habits and are right on the edge of a breakthrough.",
               "Curiosamente, lo que te costó ($h) también está muy ligado a lo que se sintió bien ($g). Esta fricción suele significar que estás rompiendo viejos hábitos y a punto de dar un gran salto.");
    }

    if (h.isNotEmpty && g.isEmpty) {
      return t("You faced some heavy friction with $h today. That's a clear signal on where your physical edge currently is. Don't worry too much about $w right now; identifying the struggle is the first step to fixing it.",
               "Hoy te enfrentaste a cierta fricción pesada con $h. Esa es una señal clara de dónde está tu límite físico actual. No te preocupes demasiado por $w ahora; identificar el problema es el primer paso para solucionarlo.");
    }

    if (g.isNotEmpty && h.isEmpty) {
      return t("Strong session. Clicking with $g is exactly what we want to see. The fact that things flowed well means your original focus on $w is paying off naturally.",
               "Sesión sólida. Conectar con $g es exactamente lo que queremos ver. El hecho de que las cosas fluyeran bien significa que tu enfoque original en $w está dando frutos naturalmente.");
    }

    final summaries = [
      t("Your focus on $w set the baseline today. But the real takeaway is that while $h tested your patience, finding your flow with $g shows you are adapting in real time.",
        "Tu enfoque en $w marcó la base hoy. Pero el verdadero aprendizaje es que mientras $h puso a prueba tu paciencia, encontrar tu ritmo con $g demuestra que te estás adaptando en tiempo real."),
      t("The most important signal here isn't just that you worked on $w, but how you navigated the difficulty of $h. Feeling good about $g tells me your technical foundation is getting stronger.",
        "La señal más importante no es solo que trabajaste en $w, sino cómo manejaste la dificultad de $h. Sentir que $g fue bien me indica que tu base técnica se fortalece."),
    ];
    return summaries[Random().nextInt(summaries.length)];
  }

  String _simulateAINextFocus(String working, String hard) {
    final w = working.trim();
    final h = hard.trim();

    if (h.isNotEmpty) {
      return t("Temporary pivot: put $w on the backburner for your next paddle out. Dedicate your first 3 waves entirely to ironing out the friction with $h.",
               "Pivote temporal: pon $w en segundo plano para tu próxima entrada. Dedica tus primeras 3 olas enteramente a pulir la fricción con $h.");
    } else if (w.isNotEmpty) {
      return t("Maintain your momentum with $w, but next session, try to execute it with 10% less physical effort. Focus on pure timing and let the wave do the work.",
               "Mantén tu impulso con $w, pero en tu próxima sesión, intenta ejecutarlo con un 10% menos de esfuerzo físico. Concéntrate en el timing puro y deja que la ola trabaje.");
    } else {
      return t("Next time out, pick one highly specific, physical cue (like where your eyes look on the drop) before you even touch the water.",
               "La próxima vez, elige una señal física muy específica (como a dónde miras en el drop) antes de siquiera tocar el agua.");
    }
  }

  // Video Picker state
  XFile? _selectedVideo;
  bool _isAnalyzingVideo = false;
  bool _showVideoResult = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  void _startVideoAnalysis() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AiAnalysisScreen(
          isSpanish: widget.isSpanish,
          onSave: widget.onAddAiAnalysis,
        ),
      ),
    );
  }

  Future<void> _shareResult() async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/surfer_pro_analysis.png';
      
      final image = await _screenshotController.capture();
      if (image == null) return;
      
      final file = File(imagePath);
      await file.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: t('My Surf Pop-up Analysis generated by Smart Surf Pro!', '¡Mi análisis de Pop-up generado por Smart Surf Pro!'),
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
    }
  }

  void _showComingSoonPreview(String feature) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ComingSoonPreview(feature: feature, isSpanish: widget.isSpanish),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          _SectionTitle(title: t("AI Session Reflection", "Reflexión de Sesión con IA")),
          const SizedBox(height: 12),
          _ReflectionForm(
            workingOnCtrl: _workingOnCtrl,
            feltHardCtrl: _feltHardCtrl,
            feltGoodCtrl: _feltGoodCtrl,
            isGenerating: _isGenerating,
            onGenerate: _generateReflection,
            isSpanish: widget.isSpanish,
          ),
          
          const SizedBox(height: 32),
          _SectionTitle(title: t("AI Video Analysis", "Análisis de Video con IA")),
          const SizedBox(height: 12),
          _PremiumFeatureCard(
            icon: Icons.videocam_outlined,
            title: t("AI Video Analysis", "Análisis de Video IA"),
            subtitle: t("Technical insights to support your training (Coming Soon)", "Detalles técnicos para apoyar tu entrenamiento (Próximamente)"),
            onTap: () => _showComingSoonPreview(t("AI Video Analysis", "Análisis de Video IA")),
            accentColor: Colors.blue,
          ),
          
          if (_showVideoResult) ...[
            const SizedBox(height: 16),
            _VideoAnalysisResultCard(
              isSpanish: widget.isSpanish,
              isSurferPro: widget.isSurferPro,
              screenshotController: _screenshotController,
              onShare: _shareResult,
            ),
          ],

          const SizedBox(height: 40),
          _SectionTitle(title: t("Featured Pro Skills", "Habilidades Pro")),
          const SizedBox(height: 12),
          _LockedFeature(
            icon: Icons.local_fire_department_outlined,
            title: t("Surf Rhythm & Consistency", "Ritmo y Consistencia de Surf"),
          ),
          const SizedBox(height: 12),
          _LockedFeature(
            icon: Icons.insights_outlined,
            title: t("Progress Patterns across surfs", "Patrones de progreso entre sesiones"),
          ),

          if (widget.reflections.isNotEmpty) ...[
            const SizedBox(height: 48),
            _SectionTitle(title: t("Past Reflections", "Reflexiones Pasadas")),
            const SizedBox(height: 16),
            ...widget.reflections.map((r) => _ReflectionCard(reflection: r, isSpanish: widget.isSpanish, totalSessions: widget.reflections.length)),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isSpanish;
  const _Header({required this.isSpanish});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          isSpanish ? "Maximiza tu aprendizaje" : "Support your learning between sessions",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
    );
  }
}

class _ReflectionForm extends StatelessWidget {
  final TextEditingController workingOnCtrl;
  final TextEditingController feltHardCtrl;
  final TextEditingController feltGoodCtrl;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final bool isSpanish;

  const _ReflectionForm({
    required this.workingOnCtrl,
    required this.feltHardCtrl,
    required this.feltGoodCtrl,
    required this.isGenerating,
    required this.onGenerate,
    required this.isSpanish,
  });

  String t(String en, String es) => isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _CustomField(
              controller: workingOnCtrl,
              label: t("What were you working on?", "¿En qué estabas trabajando?"),
              hint: t("e.g. Angled takeoffs", "ej. Takeoffs en ángulo"),
            ),
            const SizedBox(height: 20),
            _CustomField(
              controller: feltHardCtrl,
              label: t("What felt hard?", "¿Qué te resultó difícil?"),
              hint: t("e.g. Timing the peak", "ej. El timing del pico"),
            ),
            const SizedBox(height: 20),
            _CustomField(
              controller: feltGoodCtrl,
              label: t("What felt good?", "¿Qué te hizo sentir bien?"),
              hint: t("e.g. Looking down the line", "ej. Mirar la pared"),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: isGenerating ? null : onGenerate,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isGenerating 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(
                      t("Generate Reflection", "Generar Reflexión"),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _CustomField({required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _PremiumFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accentColor;

  const _PremiumFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accentColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(0.1),
                accentColor.withOpacity(0.02),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedFeature extends StatelessWidget {
  final IconData icon;
  final String title;

  const _LockedFeature({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.lock_outline, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final SessionReflection reflection;
  final bool isSpanish;
  final int totalSessions;
  _ReflectionCard({required this.reflection, required this.isSpanish, required this.totalSessions});

  final ScreenshotController _screenshotController = ScreenshotController();

  void _share(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShareSheet(
        reflection: reflection,
        isSpanish: isSpanish,
        screenshotController: _screenshotController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Screenshot(
            controller: _screenshotController,
            child: Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.primary.withOpacity(0.5)),
                          const SizedBox(width: 8),
                          Text(
                            reflection.date.toString().split(' ')[0],
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSpanish 
                      ? (reflection.aiSummaryEs ?? "") 
                      : (reflection.aiSummaryEn ?? reflection.aiSummary),
                    style: const TextStyle(height: 1.5, fontSize: 15),
                  ),
                  if (totalSessions >= 3 && reflection.aiProgressPattern.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      isSpanish
                        ? (reflection.aiProgressPatternEs ?? "")
                        : (reflection.aiProgressPatternEn ?? reflection.aiProgressPattern),
                      style: const TextStyle(height: 1.5, fontSize: 15, fontStyle: FontStyle.italic),
                    ),
                  ] else if (totalSessions < 3) ...[
                    const SizedBox(height: 12),
                    Text(
                      isSpanish ? "Registra más sesiones para desbloquear patrones." : "Log more sessions to unlock patterns.",
                      style: TextStyle(height: 1.5, fontSize: 13, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.08),
                          colorScheme.primary.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.rocket_launch, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              isSpanish ? "ENFOQUE DE SURF" : "SURF FOCUS",
                              style: TextStyle(
                                fontWeight: FontWeight.w900, 
                                fontSize: 11,
                                letterSpacing: 1.2,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isSpanish
                            ? (reflection.aiNextFocusEs ?? "")
                            : (reflection.aiNextFocusEn ?? reflection.aiNextFocus),
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextButton.icon(
              onPressed: () => _share(context),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: Text(
                isSpanish ? "Compartir" : "Share",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareSheet extends StatefulWidget {
  final SessionReflection reflection;
  final bool isSpanish;
  final ScreenshotController screenshotController;

  const _ShareSheet({
    required this.reflection,
    required this.isSpanish,
    required this.screenshotController,
  });

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  bool _isExporting = false;

  String t(String en, String es) => widget.isSpanish ? es : en;

  Future<void> _shareAsText() async {
    final patternLine = widget.reflection.aiProgressPattern.isNotEmpty ? "\n📈 Pattern: ${widget.reflection.aiProgressPattern}" : "";
    final text = """
🌊 Surfer Pro Session Card
📅 Date: ${widget.reflection.date.toString().split(' ')[0]}
🎯 Focus: ${widget.reflection.workingOn}
🌱 Summary: ${widget.reflection.aiSummary}$patternLine
🚀 Surf Focus: ${widget.reflection.aiNextFocus}
""".trim();

    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Text copied to clipboard!", "¡Texto copiado al portapapeles!")),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    await Share.share(text);
  }

  Future<void> _shareAsImage() async {
    setState(() => _isExporting = true);
    try {
      final image = await widget.screenshotController.capture();
      if (image != null) {
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t("Image export is optimized for mobile.", "La exportación de imagen está optimizada para móvil.")),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final directory = (await getTemporaryDirectory()).path;
          final imagePath = await File('$directory/surf_reflection_${DateTime.now().millisecondsSinceEpoch}.png').create();
          await imagePath.writeAsBytes(image);
          await Share.shareXFiles([XFile(imagePath.path)], text: t("My Surf Session Reflection", "Mi reflexión de sesión de surf"));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t("Share Session Card", "Compartir Tarjeta"),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 32),
          _ShareOption(
            icon: Icons.text_snippet_outlined,
            title: t("Copy as Text", "Copiar como Texto"),
            subtitle: t("Perfect for messaging or notes", "Ideal para mensajes o notas"),
            onTap: _shareAsText,
          ),
          const SizedBox(height: 16),
          _ShareOption(
            icon: Icons.image_outlined,
            title: t("Share as Image", "Compartir como Imagen"),
            subtitle: t("Export a beautiful visual card", "Exportar una tarjeta visual"),
            onTap: _isExporting ? () {} : _shareAsImage,
            trailing: _isExporting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t("Cancel", "Cancelar")),
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),
            if (trailing != null) trailing! else const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _VideoAnalysisModal extends StatefulWidget {
  final bool isSpanish;
  const _VideoAnalysisModal({required this.isSpanish});

  @override
  State<_VideoAnalysisModal> createState() => _VideoAnalysisModalState();
}

class _VideoAnalysisModalState extends State<_VideoAnalysisModal> {
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  String t(String en, String es) => widget.isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              t("AI is analyzing your movement...", "La IA está analizando tu movimiento..."),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _ObservationRow(
                icon: Icons.pan_tool_outlined,
                label: t("Hand Placement", "Colocación de manos"),
                desc: t("Hands positioned slightly back from shoulders, providing stable base.", "Manos ligeramente retrasadas respecto a los hombros, base estable."),
              ),
              _ObservationRow(
                icon: Icons.timer_outlined,
                label: t("Pop-up Timing", "Timing del Pop-up"),
                desc: t("Quick transition but slight delay in extending the back leg.", "Transición rápida pero ligero retraso al extender la pierna trasera."),
              ),
              _ObservationRow(
                icon: Icons.straighten_outlined,
                label: t("Stance Width", "Ancho de la postura"),
                desc: t("Stable width, centered on the board's stringer.", "Ancho estable, centrado en el stringer de la tabla."),
              ),
              _ObservationRow(
                icon: Icons.visibility_outlined,
                label: t("Eye Direction", "Dirección de la mirada"),
                desc: t("Head is up, eyes focused down the line during the rise.", "Cabeza levantada, mirada fija en la pared durante la subida."),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.1),
                      Colors.blue.withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_outlined, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          t("RECOMMENDED FOCUS", "ENFOQUE RECOMENDADO"),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 11, 
                            letterSpacing: 1.2,
                            color: Colors.blue
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t(
                        "Try to bring your back foot forward more explosively to clean up the tail release. Focus on keeping your hands flat during the push.",
                        "Intenta adelantar el pie trasero con más explosividad para mejorar el despegue. Mantén las manos planas durante el impulso."
                      ),
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t(
                  "“This supports learning and does not replace in-person guidance.”",
                  "“Esto apoya el aprendizaje y no reemplaza la orientación presencial.”"
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(t("Got it", "Entendido"), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ObservationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;

  const _ObservationRow({required this.icon, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  desc, 
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonPreview extends StatelessWidget {
  final String feature;
  final bool isSpanish;

  const _ComingSoonPreview({required this.feature, required this.isSpanish});

  String t(String en, String es) => isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, color: colorScheme.primary, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            feature,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              t("SURFER PRO PREVIEW", "VISTA PREVIA DE SURFER PRO"),
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t(
              "This advanced technical tool is part of our upcoming Surfer Pro suite. We're currently fine-tuning the AI to give you the most accurate technical insights.",
              "Esta herramienta técnica avanzada es parte de nuestra próxima suite Surfer Pro. Actualmente estamos ajustando la IA para brindarte los detalles analíticos más precisos.",
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 32),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(t("Got it", "Entendido"), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoAnalysisResultCard extends StatelessWidget {
  final bool isSpanish;
  final bool isSurferPro;
  final ScreenshotController screenshotController;
  final VoidCallback onShare;

  const _VideoAnalysisResultCard({
    required this.isSpanish,
    required this.isSurferPro,
    required this.screenshotController,
    required this.onShare,
  });

  String t(String en, String es) => isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t("Pop-up Breakdown", "Desglose de Pop-up"),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              if (isSurferPro)
                IconButton(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: t("Share Analysis", "Compartir análisis"),
                  color: colorScheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _MetricRow(
            label: t("Entry Speed", "Velocidad de Entrada"),
            value: "12 km/h",
            rating: t("Optimal", "Óptima"),
            icon: Icons.speed,
            color: Colors.green,
          ),
          const Divider(height: 24),
          _MetricRow(
            label: t("Pop-up Time", "Tiempo de Pop-up"),
            value: "0.8s",
            rating: t("Good", "Bueno"),
            icon: Icons.timer_outlined,
            color: Colors.blue,
          ),
          const Divider(height: 24),
          _MetricRow(
            label: t("Weight Distribution", "Distribución de Peso"),
            value: "60% Front",
            rating: t("Needs adjust", "Ajustar"),
            icon: Icons.balance,
            color: Colors.orange,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t(
                      "You're slightly heavy on the front foot upon landing. Try shifting your hips back just a fraction for better first-pump projection.",
                      "Estás un poco pesado en el pie delantero al aterrizar. Intenta desplazar las caderas un poco hacia atrás para una mejor proyección inicial."
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isSurferPro) {
      return Screenshot(
        controller: screenshotController,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor, // Background for screenshot
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: content,
        ),
      );
    }

    // Blurred paywall for free users matching HomeScreen
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: content,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_outline, color: Colors.amber, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t("Unlock AI Analysis", "Desbloquea el análisis con IA"),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String rating;
  final IconData icon;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.rating,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            rating,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

