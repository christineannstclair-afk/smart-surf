import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:smart_surf/models/ai_analysis_model.dart';
import 'package:smart_surf/core/analyze_api.dart';
import 'package:smart_surf/storage/app_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AiAnalysisScreen extends StatefulWidget {
  final bool isSpanish;
  final Function(AiAnalysisResult) onSave;

  const AiAnalysisScreen({
    super.key,
    required this.isSpanish,
    required this.onSave,
  });

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  int _currentStep = 0; // 0: Upload, 1: Preview, 2: Compress, 3: Questions, 4: Loading, 5: Results
  
  XFile? _videoFile;
  VideoPlayerController? _videoController;
  double _fileSizeMB = 0;
  bool _isVideoLoading = false;
  double _compressionProgress = 0.0;
  double _uploadProgress = 0.0;
  String? _uploadError;

  String _waveType = '';
  String _focusArea = '';
  String _expLevel = '';

  AiAnalysisResult? _result;

  String t(String en, String es) => widget.isSpanish ? es : en;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() => _currentStep++);
  }

  Future<void> _pickVideo({required ImageSource source}) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 10),
    );
    if (video != null) {
      await _initializeVideo(video);
    }
  }

  Future<void> _initializeVideo(XFile video) async {
    setState(() {
      _isVideoLoading = true;
      _videoFile = video;
    });

    if (!kIsWeb) {
      final file = File(video.path);
      final bytes = await file.length();
      _fileSizeMB = bytes / (1024 * 1024);
      _videoController = VideoPlayerController.file(file);
    } else {
      final bytes = await video.length();
      _fileSizeMB = bytes / (1024 * 1024);
      _videoController = VideoPlayerController.networkUrl(Uri.parse(video.path));
    }

    try {
      await _videoController!.initialize();
    } catch (e) {
      debugPrint("Video init error: $e");
    }
    
    if (!mounted) return;

    setState(() => _isVideoLoading = false);

    final duration = _videoController!.value.duration;
    debugPrint("DEBUG: Video Duration: ${duration.inSeconds}s (${duration.inMilliseconds}ms)");
    debugPrint("DEBUG: File Size: $_fileSizeMB MB");
    
    // Limits check - using 10.5 to allow for tiny encoding offsets while keeping 10s as user rule
    if (duration.inMilliseconds > 10500 || _fileSizeMB > 50) {
      debugPrint("DEBUG: LIMITS HIT! Showing alert...");
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(t("Video Too Long", "Video demasiado largo")),
            content: Text(t(
              "Videos must be 10 seconds or less.",
              "Los videos deben durar 10 segundos o menos."
            )),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      _videoController?.dispose();
      _videoController = null;
      _videoFile = null;
      return;
    }

    // Move to preview step
    setState(() {
      _currentStep = 1;
    });
  }

 Future<void> _startCompressionOrSkip() async {
if (kIsWeb) {
setState(() => _currentStep = 3);
return;
}

if (_fileSizeMB > 25) {
setState(() {
_currentStep = 2;
_compressionProgress = 0.0;
});

final tempDir = await getTemporaryDirectory();
final outPath =
'${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp4';

final durationMs = _videoController?.value.duration.inMilliseconds ?? 0;

setState(() {
_videoFile = XFile(outPath);
_currentStep = 3;
});
} else {
setState(() => _currentStep = 3);
}
}

  void _generateAnalysis() async {
    if (_waveType.isEmpty || _focusArea.isEmpty || _expLevel.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("Please answer all questions.", "Por favor responde todas las preguntas.")),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_videoFile == null) {
      // Allow testing without video for debugging/fallback
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t("No video selected. Real analysis requires video.", "Video no seleccionado.")),
        ),
      );
      return;
    }

    setState(() {
      _currentStep = 4; // go to loading
      _uploadProgress = 0.0;
      _uploadError = null;
    });

    try {
      debugPrint("AiAnalysis: Requesting video analysis...");
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception("Authentication required for AI analysis");
      }

      final responseData = await AnalyzeApi.uploadAndAnalyze(
        _videoFile!,
        idToken: idToken,
        sessionId: 'pop_up_${DateTime.now().millisecondsSinceEpoch}', // Unique ID for this generation attempt
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
      );

      final metrics = responseData['metrics'];
      final feedback = responseData['feedback'];

      final result = AiAnalysisResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        waveType: _waveType,
        focusArea: _focusArea,
        experienceLevel: _expLevel,
        looksSolid: feedback['looks_solid'],
        primaryImprovement: feedback['primary_improvement'],
        drillToPractice: feedback['drill_to_practice'],
        popupTimeSeconds: (metrics['popup_time_seconds'] as num).toDouble(),
        kneeAngleMin: (metrics['knee_angle_min'] as num).toDouble(),
        stanceWidthRatio: (metrics['stance_width_ratio'] as num).toDouble(),
        backAngleAtStand: (metrics['back_angle_at_stand'] as num).toDouble(),
        stabilityScore: (metrics['stability_score'] as num).toDouble(),
        confidenceScore: (metrics['confidence_score'] as num).toDouble(),
        // Do not store the video locally by default to save space & for privacy
        videoPath: null,
      );

      if (mounted) {
        await AppStorage.incrementAiUsageCount();
        setState(() {
          _result = result;
          _currentStep = 5; // Go to results
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = e.toString();
        });
        
        if (e.toString().contains("DAILY_LIMIT_REACHED")) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t(
                "Daily insight limit reached. You can generate up to 3 insights per day.", 
                "Daily insight limit reached. You can generate up to 3 insights per day."
              )),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Stop loading state
          setState(() => _currentStep = 3);
        }
      }
    }
  }

  void _finish() {
    if (_result != null) widget.onSave(_result!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t("Analyze My Surf", "Analizar Mi Surf")),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "BETA",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildUploadStep();
      case 1: return _buildPreviewStep();
      case 2: return _buildCompressStep();
      case 3: return _buildQuestionsStep();
      case 4: return _buildLoadingStep();
      case 5: return _buildResultsStep();
      default: return const SizedBox.shrink();
    }
  }

  // --- STEP 0: Capture ---
  Widget _buildUploadStep() {
    return Padding(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t(
                      "Beta Version: This AI tool is in early testing and does not replace a real, human surf coach.",
                      "Versión Beta: Esta herramienta no reemplaza a un entrenador humano."
                    ),
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            t("For best tracking results:", "Para mejores resultados:"),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildChecklistItem(Icons.boy, t("Full body visible", "Cuerpo completo visible")),
          const SizedBox(height: 8),
          _buildChecklistItem(Icons.video_camera_front, t("Side angle profile", "Perfil lateral")),
          const SizedBox(height: 8),
          _buildChecklistItem(Icons.light_mode, t("Good lighting", "Buena iluminación")),
          const SizedBox(height: 32),
          const Icon(Icons.video_camera_back_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            t("Capture a Pop-up", "Captura un Pop-up"),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            t(
              "Our AI will analyze your biomechanics and movement sequence.",
              "Nuestra IA analizará tu biomecánica y secuencia de movimientos."
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          if (_isVideoLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                t("MAX 10s VIDEO", "MAX 10s VIDEO"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  letterSpacing: 1.1,
                ),
              ),
            ),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () => _pickVideo(source: ImageSource.camera),
                icon: const Icon(Icons.videocam),
                label: Text(
                  t("Record pop-up", "Grabar pop-up"),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _pickVideo(source: ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: Text(
                  t("Choose from library", "Elegir de la biblioteca"),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() => _videoFile = null);
                setState(() => _currentStep = 3);
              },
              child: Text(t("Skip (Text-only analysis)", "Saltar (Análisis solo de texto)")),
            ),
          ],
        ],
      ),
    );
  }

  // --- STEP 1: Preview ---
  Widget _buildPreviewStep() {
    return Padding(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Text(t("Selection", "Selección"), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _videoController?.dispose();
                    _videoController = null;
                    setState(() {
                      _videoFile = null;
                      _currentStep = 0;
                    });
                  }
                )
             ],
          ),
          const SizedBox(height: 16),
          if (_videoController != null && _videoController!.value.isInitialized)
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard(
                 Icons.timer_outlined, 
                 t("Duration", "Duración"), 
                 "${_videoController?.value.duration.inSeconds ?? 0}s"
              ),
              _buildMetricCard(
                 Icons.storage_outlined, 
                 t("Size", "Tamaño"), 
                 "${_fileSizeMB.toStringAsFixed(1)} MB"
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _startCompressionOrSkip,
              icon: const Icon(Icons.check),
              label: Text(
                t("Continue", "Continuar"),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // --- STEP 2: Compress ---
  Widget _buildCompressStep() {
    return Padding(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _compressionProgress > 0 ? _compressionProgress : null,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                ),
              ),
              Text(
                "${(_compressionProgress * 100).toInt()}%",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            t("Optimizing video...", "Optimizando video..."),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16)
             ),
             child: Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Icon(Icons.electric_bolt, color: Colors.amber, size: 20),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Text(
                     t(
                       "Why we compress: Smaller file size means a faster upload and less data used on your cellular plan.",
                       "Por qué comprimimos: Menor tamaño de archivo asegura una subida más rápida y menos uso de datos."
                     ),
                     style: const TextStyle(fontSize: 13, height: 1.4),
                   ),
                 )
               ],
             ),
          )
        ],
      ),
    );
  }

  // --- STEP 3: Questions ---
  Widget _buildQuestionsStep() {
    return SingleChildScrollView(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t("A bit of context", "Un poco de contexto"),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            t("Help the AI understand your session.", "Ayuda a la IA a entender tu sesión."),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          _buildPicker(
            label: t("What type of wave?", "¿Qué tipo de ola?"),
            options: ["Beach break", "Point break", "Reef break"],
            optionsEs: ["Fondo de arena", "Punta de rocas", "Arrecife"],
            current: _waveType,
            onSelect: (val) => setState(() => _waveType = val),
          ),
          const SizedBox(height: 24),

          _buildPicker(
            label: t("What is your focus area?", "¿Cuál es tu área de enfoque?"),
            options: ["Pop-up", "Bottom Turn", "Cutback", "Speed Generation"],
            optionsEs: ["Pop-up", "Bottom Turn", "Cutback", "Generar velocidad"],
            current: _focusArea,
            onSelect: (val) => setState(() => _focusArea = val),
          ),
          const SizedBox(height: 24),

          _buildPicker(
            label: t("Your experience level?", "¿Tu nivel de experiencia?"),
            options: ["Beginner", "Intermediate", "Advanced"],
            optionsEs: ["Principiante", "Intermedio", "Avanzado"],
            current: _expLevel,
            onSelect: (val) => setState(() => _expLevel = val),
          ),

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _generateAnalysis,
              child: Text(
                t("Generate Analysis", "Generar Análisis"),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker({
    required String label, 
    required List<String> options, 
    required List<String> optionsEs, 
    required String current, 
    required Function(String) onSelect
  }) {
    final opts = widget.isSpanish ? optionsEs : options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(options.length, (i) {
            final isSelected = options[i] == current;
            return ChoiceChip(
              label: Text(opts[i]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onSelect(options[i]);
              },
            );
          }),
        ),
      ],
    );
  }

  // --- STEP 4: Loading ---
  Widget _buildLoadingStep() {
    if (_uploadError != null) {
      return Center(
        key: const ValueKey("error"),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 24),
              Text(
                t("Upload Failed", "Error al subir"),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.red),
              ),
              const SizedBox(height: 12),
              Text(
                t("It looks like the connection timed out or the server was unavailable. Please try again.", "Parece que la conexión falló. Por favor intenta de nuevo."),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _generateAnalysis,
                  child: Text(
                    t("Try Again", "Intentar de nuevo"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      key: const ValueKey(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                ),
              ),
              Text(
                "${(_uploadProgress * 100).toInt()}%",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _uploadProgress >= 0.9 
              ? t("Analyzing biometrics...", "Analizando biometría...") 
              : t("Uploading video...", "Subiendo video..."),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  // --- STEP 5: Results ---
  Widget _buildResultsStep() {
    if (_result == null) return const SizedBox.shrink();
    
    final bool isLowConfidence = _result!.confidenceScore < 0.4;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Confidence indicator
    String confLabel = isLowConfidence ? t("Low Confidence", "Poca Confianza") 
        : (_result!.confidenceScore > 0.7 ? t("High Confidence", "Alta Confianza") : t("Medium Confidence", "Confianza Media"));
    Color confColor = isLowConfidence ? Colors.red : (_result!.confidenceScore > 0.7 ? Colors.green : Colors.amber);

    return SingleChildScrollView(
      key: const ValueKey(5),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, size: 32, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t("Surfer Pro Insights", "Insights de Surfer Pro"),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                 decoration: BoxDecoration(
                   color: confColor.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Row(
                   children: [
                     Icon(isLowConfidence ? Icons.warning_amber_rounded : Icons.check_circle_outline, size: 14, color: confColor),
                     const SizedBox(width: 6),
                     Text(
                       confLabel.toUpperCase(),
                       style: TextStyle(color: confColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                     ),
                   ],
                 ),
              )
            ],
          ),
          const SizedBox(height: 24),

          // Real Metrics Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricStat(t("Pop-up Time", "Tiempo Pop-up"), "${_result!.popupTimeSeconds.toStringAsFixed(1)}s", Icons.timer_outlined, Colors.blue),
                    _buildMetricStat(t("Knee Bend", "Flexión Rodilla"), "${_result!.kneeAngleMin.toInt()}°", Icons.sports_gymnastics, Colors.orange),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricStat(t("Stance Width", "Ancho Postura"), "${_result!.stanceWidthRatio.toStringAsFixed(1)}x", Icons.straighten, Colors.purple),
                    _buildMetricStat(t("Stability", "Estabilidad"), "${_result!.stabilityScore.toInt()}/100", Icons.balance, Colors.green),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Honest AI Guardrails
          if (isLowConfidence)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.privacy_tip_outlined, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t("We couldn't see your full body clearly.", "No pudimos ver tu cuerpo completo con claridad."),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      "Because the tracking confidence is low, we cannot provide accurate biomechanical feedback. Please ensure the camera sees your full body from a side angle with good lighting.",
                      "Debido a la poca confianza del seguimiento, no podemos ofrecer feedback preciso. Asegúrate de grabar de perfil, con buena luz y cuerpo completo."
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.red),
                  ),
                ],
              ),
            )
          else ...[
            _buildFeedbackBox(
              title: t("What Looks Solid", "Lo Que Se Ve Sólido"),
              icon: Icons.check_circle_rounded,
              color: Colors.green,
              text: _result!.looksSolid,
            ),
            const SizedBox(height: 16),
            _buildFeedbackBox(
              title: t("Primary Improvement", "Mejora Principal"),
              icon: Icons.track_changes_rounded,
              color: Colors.amber.shade800,
              text: _result!.primaryImprovement,
            ),
            const SizedBox(height: 16),
            _buildFeedbackBox(
              title: t("Drill to Practice", "Ejercicio Para Practicar"),
              icon: Icons.fitness_center_rounded,
              color: Colors.blue,
              text: _result!.drillToPractice,
            ),
          ],
          
          const SizedBox(height: 48),
          
          Text(
            t("Disclaimer: Insights are based on detected body landmarks, not wave quality.", "Aviso: Los resultados se basan en la detección de postura, no en la calidad de la ola."),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _finish,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                t("Save Metric to History", "Guardar Métrica en Historial"),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
         Icon(icon, color: color, size: 28),
         const SizedBox(height: 8),
         Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
         const SizedBox(height: 4),
         Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildChecklistItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFeedbackBox({
    required String title,
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}
