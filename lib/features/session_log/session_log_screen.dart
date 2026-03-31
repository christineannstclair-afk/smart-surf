import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/translation_service.dart';
import 'package:image_picker/image_picker.dart';
import 'session_log_entry.dart';
import '../passport/passport_presets.dart';
import '../home/video_preview_modal.dart';
import '../../widgets/micro_tip_banner.dart';
import '../../models/ai_analysis_model.dart';
import '../../widgets/orientation_prompt.dart';
import '../Settings/settings_models.dart';
import '../../ui_system/spacing.dart';
import '../../ui_system/app_card.dart';
import '../../ui_system/media_card.dart';
import '../../widgets/smart_surf_wordmark.dart';
import '../../widgets/language_menu.dart';
import '../../ui_system/app_theme.dart';
import 'firebase_service.dart';
import 'package:video_player/video_player.dart';
import '../../ui_system/surf_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../surfer_pro/surfer_pro_paywall.dart';
import 'ai_insight_service.dart';
import '../../core/analyze_api.dart';

class SessionLogScreen extends StatefulWidget {
  const SessionLogScreen({
    super.key,
    required this.isSpanish,
    required this.isSurferPro,
    required this.onSetLanguage,
    required this.displayName,
    required this.logs,
    required this.onAdd,
    required this.onDelete,
    required this.units,
    required this.aiAnalyses,
    this.addSessionKey,
    required this.seenLogPrompt,
    required this.onPromptDismissed,
    required this.onUpdate,
    this.onUnlockSurferPro,
    required this.sessionsThisMonth,
    required this.currentStreak,
    this.onReturnToDashboard,
  });

  final bool isSpanish;
  final bool isSurferPro;
  final void Function(bool) onSetLanguage;
  final String displayName;
  final List<SessionLogEntry> logs;
  final void Function(SessionLogEntry) onAdd;
  final void Function(SessionLogEntry) onUpdate;
  final void Function(String id) onDelete;
  final String units;
  final List<AiAnalysisResult> aiAnalyses;
  final GlobalKey? addSessionKey;
  final VoidCallback? onReturnToDashboard;
  final bool seenLogPrompt;
  final VoidCallback onPromptDismissed;
  final VoidCallback? onUnlockSurferPro;
  final int sessionsThisMonth;
  final int currentStreak;

  @override
  State<SessionLogScreen> createState() => _SessionLogScreenState();
}

class _SessionLogScreenState extends State<SessionLogScreen> {
  String t(String en, String es) => widget.isSpanish ? es : en;
  bool _isSheetOpening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.seenLogPrompt && widget.addSessionKey != null) {
        OrientationPrompt.show(
          context: context,
          isSpanish: widget.isSpanish,
          title: "",
          message: TranslationService().translate("tip_log_message", widget.isSpanish),
          anchorKey: widget.addSessionKey!,
          onDismiss: () {
            widget.onPromptDismissed();
          },
        );
      }
    });
  }

  String _getDynamicGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return t("Good morning, $name", "Buenos días, $name");
    } else if (hour >= 12 && hour < 17) {
      return t("Good afternoon, $name", "Buenas tardes, $name");
    } else if (hour >= 17 && hour < 22) {
      return t("Good evening, $name", "Buenas noches, $name");
    } else {
      return t("Hello, $name", "Hola, $name");
    }
  }

  Future<bool?> _showMediaPreviewModal(XFile file, bool isVideo) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(t("Upload this clip?", "¿Subir este clip?")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isVideo) ...[
              const Icon(Icons.videocam, size: 60, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text(
                t("Video selected", "Video seleccionado"),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ] else 
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: kIsWeb 
                    ? Image.network(file.path, height: 200, fit: BoxFit.cover)
                    : Image.file(File(file.path), height: 200, fit: BoxFit.cover),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t("Change Clip", "Cambiar clip")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t("Upload", "Subir")),
          ),
        ],
      ),
    );
  }

  Future<void> _showUploadProgressDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                t("Uploading your session clip...", "Subiendo tu clip de sesión..."),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _handleMediaSelection(String sessionId) async {
    while (true) {
      final picker = ImagePicker();
      final sourceAction = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
             children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(t("Choose Photo", "Elegir foto")),
                onTap: () => Navigator.pop(ctx, 'gallery_photo'),
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: Text(t("Choose Video (1-10s)", "Elegir video (1-10s)")),
                onTap: () => Navigator.pop(ctx, 'gallery_video'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(t("Take Photo", "Tomar foto")),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
            ],
          ),
        ),
      );

      if (sourceAction == null) return null;

      XFile? picked;
      bool isVideo = false;

      try {
        if (sourceAction == 'gallery_video') {
          picked = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 10));
          isVideo = true;
        } else {
          final source = sourceAction == 'camera' ? ImageSource.camera : ImageSource.gallery;
          picked = await picker.pickImage(source: source, maxWidth: 1080, imageQuality: 70);
          isVideo = false;
        }
      } catch (e) {
        debugPrint("Media selection error: $e");
        return null;
      }

      if (picked == null) return null;

      int durationSecs = 0;
      if (isVideo) {
        final controller = kIsWeb 
            ? VideoPlayerController.networkUrl(Uri.parse(picked.path))
            : VideoPlayerController.file(File(picked.path));
        try {
          await controller.initialize();
          durationSecs = controller.value.duration.inSeconds;
          await controller.dispose();
          if (durationSecs < 1 || durationSecs > 10) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t("Clips must be 10 seconds or shorter.", "Los clips deben durar 10 segundos o menos."))),
              );
            }
            continue; // Loop back exactly as requested
          }
        } catch (e) {
          debugPrint("Video init check failed: $e");
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(t("Could not verify video length.", "No se pudo verificar la duración del video."))),
             );
          }
          continue;
        }
      }

      // 4. Preview
      final shouldUpload = await _showMediaPreviewModal(picked, isVideo);
      if (shouldUpload == null) return null; // Dismissed
      if (shouldUpload == false) continue; // Change Clip tapped

      // 5. Upload 
      _showUploadProgressDialog();
      
      final fbResult = await FirebaseService().uploadMedia(
          localPath: picked.path,
          isProfile: false,
          isVideo: isVideo,
          sessionId: "temp_${DateTime.now().millisecondsSinceEpoch}",
          webBytes: kIsWeb ? await picked.readAsBytes() : null,
      );
      
      // Close progress dialog safely
      if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context); 
      }
      
      if (fbResult != null && fbResult.success) {
          await FirebaseService().syncSessionMediaToFirestore(
              sessionId: sessionId,
              photoUrl: fbResult.url!,
              storagePath: fbResult.path!,
              isVideo: isVideo,
          );
          return isVideo ? "video:${fbResult.url}:${durationSecs}s" : "image:${fbResult.url}";
      } else {
         final errorMsg = fbResult?.errorMessage ?? "Unknown error uploading";
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(t("Upload failed: $errorMsg", "Error al subir: $errorMsg"))),
           );
         }
         return null;
      }
    }
  }

  // To support base64 decoding on web
  String? get base64String => null; // Placeholder for logic if needed elsewhere

  Future<void> _openAddSessionSheet({SessionLogEntry? existing}) async {
    if (_isSheetOpening) return;
    setState(() => _isSheetOpening = true);
    
    final sessionId = existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final spotCtrl = TextEditingController(text: existing?.spotName == t("Current Session", "Sesión Actual") ? "" : existing?.spotName);
    final regionCtrl = TextEditingController(text: existing?.countryOrRegion);
    final feltGoodCtrl = TextEditingController(text: existing?.reflectionWhatFeltGood);
    final challengingCtrl = TextEditingController(text: existing?.reflectionWhatWasChallenging);
    final focusCtrl = TextEditingController(text: existing?.notes);
    final conditionsCtrl = TextEditingController(text: existing?.reflectionConditions);

    // Dropdown safety & validation
    final waveOptions = SurfConstants.waveHeightOptions.map((m) => m["en"]!).toList();
    final focusOptions = SurfConstants.focusSkillPresets.map((m) => m["en"]!).toList();
    final boardOptions = SurfConstants.boardOptions.map((m) => m["en"]!).toList();
    final condOptions = SurfConstants.conditionOptions.map((m) => m["en"]!).toList();

    DateTime selectedDate = existing?.date ?? DateTime.now();
    
    // Wave Size fallback
    String waveSize = (existing?.waveSize.isNotEmpty == true && waveOptions.contains(existing!.waveSize)) 
        ? existing!.waveSize 
        : waveOptions.first;

    // Focus fallback
    String selectedFocus = (existing?.sessionFocus.isNotEmpty == true) 
        ? existing!.sessionFocus.split(",").first.trim() 
        : focusOptions.first;
    if (!focusOptions.contains(selectedFocus)) selectedFocus = focusOptions.first;

    // Board fallback
    String board = (existing?.board.isNotEmpty == true && boardOptions.contains(existing!.board)) 
        ? existing!.board 
        : boardOptions.first;

    // Conditions fallback
    String conditions = (existing?.reflectionConditions?.isNotEmpty == true && condOptions.contains(existing!.reflectionConditions))
        ? existing!.reflectionConditions!
        : condOptions.first;
    conditionsCtrl.text = conditions;

    int durationMins = (existing != null && !existing.isCompleted) 
        ? DateTime.now().difference(existing.date).inMinutes.clamp(1, 480) 
        : (existing?.durationMins ?? 60);
    int rating = existing?.rating ?? 0;
    String? currentAiSummary = existing?.aiSummary;
    bool isGenerating = false;
    String? mediaPath = existing?.mediaPath;
    String? mediaType = existing?.mediaType;
    String? mediaLabel = (existing?.mediaType == 'video' && existing?.notes.contains('[Duration:') == true) 
        ? existing!.notes.split('[Duration:').last.split(']').first.trim() 
        : null;
    String? waveLocation = existing?.waveLocation;

    final created = await showModalBottomSheet<SessionLogEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSheetState) {
            Future<void> pickDate() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: ctx2,
                initialDate: selectedDate,
                firstDate: DateTime(now.year - 10),
                lastDate: DateTime(now.year + 1),
              );
              if (picked != null) {
                setSheetState(() => selectedDate = picked);
              }
            }

            String dateLabel() {
              final y = selectedDate.year.toString().padLeft(4, "0");
              final m = selectedDate.month.toString().padLeft(2, "0");
              final d = selectedDate.day.toString().padLeft(2, "0");
              return "$y-$m-$d";
            }

            Future<void> generateAI() async {
              setSheetState(() => isGenerating = true);
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                setSheetState(() {
                  isGenerating = false;
                  currentAiSummary = widget.isSpanish 
                      ? "Gran sesión en ${spotCtrl.text}. Tu técnica de remo está mejorando, pero mantén el enfoque en el pop-up rápido." 
                      : "Solid session at ${spotCtrl.text}. Your paddling technique is improving, but stay focused on quick pop-ups.";
                });
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (ctx3, controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(ctx2).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        Text(
                          t("Log Your Session", "Registrar Tu Sesión"),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          t("Session Details", "Detalles de la sesión"),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: pickDate,
                                icon: const Icon(Icons.calendar_today_outlined, size: 20),
                                label: Text(t("Date: ", "Fecha: ") + dateLabel()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: spotCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: t("Location", "Ubicación"),
                            hintText: t("Optional location (e.g. Pipeline)", "Ubicación opcional (ej. Pipeline)"),
                            prefixIcon: const Icon(Icons.place_outlined),
                            border: const OutlineInputBorder(),
                            suffixIcon: widget.logs.any((e) => e.spotName.isNotEmpty && e.spotName != t("Current Session", "Sesión Actual"))
                              ? IconButton(
                                  icon: const Icon(Icons.history, size: 20),
                                  tooltip: t("Use last location?", "¿Usar última ubicación?"),
                                  onPressed: () {
                                    final last = widget.logs.firstWhere(
                                      (e) => e.spotName.isNotEmpty && e.spotName != t("Current Session", "Sesión Actual"),
                                      orElse: () => SessionLogEntry(id: "", date: DateTime.now(), spotName: "", countryOrRegion: "", waveSize: "", sessionFocus: "", board: "", durationMins: 0, rating: 0, notes: ""),
                                    );
                                    if (last.spotName.isNotEmpty) {
                                      spotCtrl.text = last.spotName;
                                      regionCtrl.text = last.countryOrRegion;
                                    }
                                  },
                                )
                              : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: regionCtrl,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: t("Region / Country", "Región / País"),
                            prefixIcon: const Icon(Icons.public_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          t("Wave Height", "Tamaño de ola"),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: SurfConstants.waveHeightOptions.any((w) => w["en"] == waveSize) ? waveSize : null, 
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.waves_outlined),
                            border: const OutlineInputBorder(),
                            labelText: t("Wave Height", "Tamaño de ola"),
                          ),
                          items: SurfConstants.waveHeightOptions.map((m) {
                            final en = m["en"]!;
                            return DropdownMenuItem(value: en, child: Text(t(en, m["es"] ?? en)));
                          }).toList(),
                          onChanged: (v) => setSheetState(() => waveSize = v ?? waveSize),
                        ),
                        
                        const SizedBox(height: 16),
                        Text(
                          t("Conditions", "Condiciones"),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: SurfConstants.conditionOptions.any((c) => c["en"] == conditionsCtrl.text) ? conditionsCtrl.text : null,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.water_outlined),
                            border: const OutlineInputBorder(),
                            labelText: t("Conditions", "Condiciones"),
                          ),
                          items: SurfConstants.conditionOptions.map((m) {
                            final en = m["en"]!;
                            return DropdownMenuItem(value: en, child: Text(t(en, (m["es"] ?? en))));
                          }).toList(),
                          onChanged: (v) => setSheetState(() => conditionsCtrl.text = v ?? SurfConstants.conditionOptions.first["en"]!),
                        ),

                        const SizedBox(height: 16),
                        Text(
                          t("Board", "Tabla"),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          hint: Text(t("Select board...", "Seleccionar tabla...")),
                          value: SurfConstants.boardOptions.any((b) => b["en"] == board) ? board : null,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.surfing_outlined),
                            border: const OutlineInputBorder(),
                            labelText: t("Board", "Tabla"),
                          ),
                          items: SurfConstants.boardOptions.map((m) {
                            final en = m["en"]!;
                            return DropdownMenuItem(
                              value: en, 
                              child: Text(t(en, (m["es"] ?? en))),
                            );
                          }).toList(),
                          onChanged: (v) => setSheetState(() => board = v ?? board),
                        ),

                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        Text(
                          t("Focus", "Enfoque"),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 0,
                          children: [
                            ...["Pop-up timing", "Paddling position", "Stance/Balance", "Wave selection", "Maintaining speed down the line", "Developing bottom turn"].map((focus) {
                              final isSelected = selectedFocus == focus;
                              final display = SurfConstants.focusSkillPresets.firstWhere((m) => m["en"] == focus, orElse: () => {"en": focus, "es": focus});
                              return ChoiceChip(
                                label: Text(t((display["en"] ?? focus), (display["es"] ?? focus)), style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) setSheetState(() => selectedFocus = focus);
                                },
                              );
                            }),
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 16),
                              label: Text(t("+ More skills", "+ Más habilidades"), style: const TextStyle(fontSize: 12)),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: ctx2,
                                  isScrollControlled: true,
                                  showDragHandle: true,
                                  builder: (mCtx) => DraggableScrollableSheet(
                                    initialChildSize: 0.7,
                                    maxChildSize: 0.9,
                                    expand: false,
                                    builder: (_, scrollController) => Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(t("Select Focus Skill", "Seleccionar Habilidad Foco"), 
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            itemCount: SurfConstants.focusSkillPresets.length,
                                            itemBuilder: (ctx, index) {
                                              final skill = SurfConstants.focusSkillPresets[index];
                                              final en = skill["en"]!;
                                              final es = skill["es"]!;
                                              return ListTile(
                                                title: Text(t(en, es)),
                                                trailing: selectedFocus == en ? const Icon(Icons.check, color: AppTheme.primary) : null,
                                                onTap: () {
                                                  setSheetState(() => selectedFocus = en);
                                                  Navigator.pop(mCtx);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: [30, 45, 60, 90, 120, 150, 180].contains(durationMins) ? durationMins : null,
                                decoration: InputDecoration(
                                  labelText: t("Duration", "Duración"),
                                  prefixIcon: const Icon(Icons.timer_outlined),
                                  border: const OutlineInputBorder(),
                                ),
                                items: [30, 45, 60, 90, 120, 150, 180].map((m) {
                                  return DropdownMenuItem(value: m, child: Text(m < 120 ? "${m}m" : "${(m/60).toStringAsFixed(1)}h"));
                                }).toList(),
                                onChanged: (v) => setSheetState(() => durationMins = v ?? 60),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: [0, 1, 2, 3, 4, 5].contains(rating) ? rating : 0,
                                decoration: InputDecoration(
                                  labelText: t("Rating", "Valoración"),
                                  prefixIcon: const Icon(Icons.star_outline_rounded),
                                  border: const OutlineInputBorder(),
                                ),
                                items: [
                                  DropdownMenuItem(value: 0, child: Text(t("Not set", "N/A"))),
                                  const DropdownMenuItem(value: 1, child: Text("1")),
                                  const DropdownMenuItem(value: 2, child: Text("2")),
                                  const DropdownMenuItem(value: 3, child: Text("3")),
                                  const DropdownMenuItem(value: 4, child: Text("4")),
                                  const DropdownMenuItem(value: 5, child: Text("5")),
                                ],
                                onChanged: (v) => setSheetState(() => rating = v ?? 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t("Where did this happen in the wave?", "¿En qué parte de la ola pasó esto?"),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          hint: Text(t("Optional location...", "Lugar opcional...")),
                          value: ["Takeoff", "First section", "Mid-wave", "Closing section"].contains(waveLocation) ? waveLocation : null,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: "Takeoff", child: Text(t("Takeoff", "Despegue"))),
                            DropdownMenuItem(value: "First section", child: Text(t("First section", "Primera sección"))),
                            DropdownMenuItem(value: "Mid-wave", child: Text(t("Mid-wave", "Media ola"))),
                            DropdownMenuItem(value: "Closing section", child: Text(t("Closing section", "Sección final"))),
                          ],
                          onChanged: (v) => setSheetState(() => waveLocation = v),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          t("Reflection", "Reflexión"),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: feltGoodCtrl,
                          decoration: InputDecoration(
                            labelText: t("What felt good?", "¿Qué te hizo sentir bien?"),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: challengingCtrl,
                          decoration: InputDecoration(
                            labelText: t("What felt hard?", "¿Qué fue lo más difícil?"),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: focusCtrl,
                          decoration: InputDecoration(
                            labelText: t("What were you working on?", "¿En qué estabas trabajando?"),
                            border: const OutlineInputBorder(),
                          ),
                        ),

                        // Media Section
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          t("Media", "Medios"),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        MediaCard(
                          isSpanish: widget.isSpanish,
                          state: mediaPath == null ? MediaCardState.empty : (mediaType == 'video' ? MediaCardState.video : MediaCardState.image),
                          mediaPath: mediaPath,
                          mediaType: mediaType,
                          footerLabel: mediaLabel,
                          onAddMedia: () async {
                            final result = await _handleMediaSelection(sessionId);
                            if (result != null) {
                              final parts = result.split(':');
                              final type = parts[0];
                              final path = parts.sublist(1).join(':'); 
                              setSheetState(() {
                                mediaType = type;
                                if (type == 'video') {
                                  final lastColonIndex = path.lastIndexOf(':');
                                  if (lastColonIndex != -1 && path.endsWith('s')) {
                                    mediaPath = path.substring(0, lastColonIndex);
                                    mediaLabel = path.substring(lastColonIndex + 1);
                                  } else {
                                    mediaPath = path;
                                    mediaLabel = null;
                                  }
                                } else {
                                  mediaPath = path;
                                  mediaLabel = null;
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t("Upload a photo or a short surf clip (under 10 seconds).", 
                            "Sube una foto o un clip de surf corto (menos de 10 segundos)."),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                        ),
                          const SizedBox(height: AppSpacing.md),
                          const SizedBox(height: 100), // Extra space to scroll past the fixed button
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.check_circle_outline),
                                label: Text(t("Log Session", "Registrar Sesión")),
                                 onPressed: () async {
                                  final spot = spotCtrl.text.trim().isEmpty ? t("Location not specified", "Ubicación no especificada") : spotCtrl.text.trim();

                                  SessionLogEntry entry = SessionLogEntry(
                                    id: sessionId,
                                    date: selectedDate,
                                    spotName: spot,
                                    countryOrRegion: regionCtrl.text.trim(),
                                    waveSize: waveSize,
                                    sessionFocus: selectedFocus,
                                    board: board,
                                    durationMins: durationMins,
                                    rating: rating,
                                    notes: (mediaType == 'video' && mediaLabel != null)
                                      ? (focusCtrl.text.contains('[Duration:') ? focusCtrl.text : "${focusCtrl.text.trim()}\n[Duration: $mediaLabel]")
                                      : focusCtrl.text.trim(),
                                    reflectionWhatFeltGood: feltGoodCtrl.text.trim(),
                                    reflectionWhatWasChallenging: challengingCtrl.text.trim(),
                                    reflectionConditions: conditionsCtrl.text.trim(),
                                    aiSummary: currentAiSummary,
                                    isCompleted: true,
                                    mediaPath: mediaPath,
                                    mediaType: mediaType,
                                    waveLocation: waveLocation,
                                    email: FirebaseAuth.instance.currentUser?.email,
                                  );

                                  FirebaseService().logEvent('log_session_created');

                                  if (mediaPath == null) {
                                    final shouldAddClip = await showModalBottomSheet<bool>(
                                      context: context,
                                      builder: (ctx) => SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 24),
                                            Text(t("Got a photo or video from that session?", "¿Tienes una foto o video de esa sesión?"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 16),
                                            ListTile(
                                              leading: const Icon(Icons.add_a_photo, color: AppTheme.primary),
                                              title: Text(t("Add Photo or Video", "Añadir Foto o Video"), style: const TextStyle(fontWeight: FontWeight.bold)),
                                              onTap: () => Navigator.pop(ctx, true),
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.skip_next_outlined),
                                              title: Text(t("Skip for now", "Omitir por ahora")),
                                              onTap: () => Navigator.pop(ctx, false),
                                            ),
                                            const SizedBox(height: 16),
                                          ]
                                        )
                                      )
                                    );

                                    if (shouldAddClip == true) {
                                      final result = await _handleMediaSelection(sessionId);
                                      if (result != null) {
                                          final parts = result.split(':');
                                          final type = parts[0];
                                          final path = parts.sublist(1).join(':'); 
                                          
                                          String newPath = path;
                                          String newNotes = entry.notes;

                                          if (type == 'video') {
                                            final lastColonIndex = path.lastIndexOf(':');
                                            if (lastColonIndex != -1 && path.endsWith('s')) {
                                              newPath = path.substring(0, lastColonIndex);
                                              newNotes = "${entry.notes}\n[Duration: ${path.substring(lastColonIndex + 1)}]";
                                            }
                                          }

                                          entry = entry.copyWith(
                                            mediaType: type,
                                            mediaPath: newPath,
                                            notes: newNotes,
                                          );

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(t("Session saved ✔ Clip added to your passport", "Sesión guardada ✔ Clip añadido a tu passport")))
                                            );
                                          }
                                        }
                                      }
                                    }

                                    Navigator.pop(ctx, entry);
                                  },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );

    if (mounted) {
      setState(() => _isSheetOpening = false);
    }

    if (created != null) {
      widget.onAdd(created);
      _showSessionLoggedModal(created);
    }
  }

  // DELETED: _showGeneratingInsightLoader is now managed inline by _SessionDetailSheet

  void _showSessionLoggedModal(SessionLogEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t("Session logged", "Sesión registrada")),
        content: Text(t("Your surf passport was updated.", "Tu surf passport ha sido actualizado.")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t("Close", "Cerrar")),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _SessionDetailSheet.show(
                context, 
                session: entry, 
                isSpanish: widget.isSpanish, 
                units: widget.units, 
                isSurferPro: widget.isSurferPro,
                onAdd: widget.onAdd,
                logs: widget.logs,
                autoGenerate: true,
              );
            },
            child: Text(t("Analyze with AI ✨", "Analizar con IA ✨")),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Combine logs and aiAnalyses into a single chronological list
    final combined = <dynamic>[
      ...widget.logs,
      ...widget.aiAnalyses,
    ]..sort((a, b) => (b.date as DateTime).compareTo(a.date as DateTime));

    final activeSession = widget.logs.cast<SessionLogEntry?>().firstWhere(
          (e) => e != null && !e.isCompleted,
          orElse: () => null,
        );

    final latestLoggedSession = widget.logs.cast<SessionLogEntry?>().firstWhere(
          (e) => e != null && e.isCompleted,
          orElse: () => null,
        );

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildHeroHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MicroTipBanner(
                            prefKey: 'hasSeenLogsTip',
                            message: t(
                              'Start a session before you paddle out. Log your surf when you\'re done.',
                              'Inicia una sesión antes de entrar al agua. Registra tu surf cuando hayas terminado.',
                            ),
                            dismissLabel: t('Got it', 'Entendido'),
                          ),
                          const SizedBox(height: 16),
                          if (activeSession != null)
                            _CurrentSessionCard(
                              isSpanish: widget.isSpanish,
                              session: activeSession,
                              onLog: () => _openAddSessionSheet(existing: activeSession),
                              onDiscard: () => widget.onDelete(activeSession.id),
                            )
                          else
                            _PreSurfCheckInCard(
                              isSpanish: widget.isSpanish,
                              onStart: (entry) {
                                widget.onAdd(entry);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t("Session started!", "¡Sesión iniciada!"))),
                                );
                              },
                            ),
                          const SizedBox(height: 24),

                          if (latestLoggedSession != null) ...[
                            _SurfInsightTriggerCard(
                              session: latestLoggedSession,
                              isSpanish: widget.isSpanish,
                              isSurferPro: widget.isSurferPro,
                              onAdd: widget.onAdd,
                              onUnlockSurferPro: widget.onUnlockSurferPro,
                              totalSessions: widget.logs.where((e) => e.isCompleted).length,
                              sessionsThisMonth: widget.logs.where((e) => 
                                e.isCompleted && 
                                e.date.month == DateTime.now().month && 
                                e.date.year == DateTime.now().year
                              ).length,
                              currentStreak: _calculateStreak(widget.logs.where((e) => e.isCompleted).toList()),
                              logs: widget.logs,
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (widget.isSurferPro && widget.logs.isNotEmpty) ...[
                            _TrendInsights(logs: widget.logs, isSpanish: widget.isSpanish),
                            const SizedBox(height: 16),
                          ],
                          if (combined.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                t("No sessions logged yet. Start with a quick pre-surf check-in.",
                                    "Aún no hay sesiones registradas. Comienza con un rápido check-in pre-surf."),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                              ),
                            )
                          else
                            ...combined.map((item) {
                              if (item is AiAnalysisResult) {
                                return _buildAiAnalysisCard(item);
                              }

                              final e = item as SessionLogEntry;
                              return _SessionCard(
                                session: e,
                                isSpanish: widget.isSpanish,
                                units: widget.units,
                                isSurferPro: widget.isSurferPro,
                                onDelete: () => widget.onDelete(e.id),
                                onTap: () => _SessionDetailSheet.show(
                                  context, 
                                  session: e, 
                                  isSpanish: widget.isSpanish, 
                                  units: widget.units, 
                                  isSurferPro: widget.isSurferPro,
                                  onAdd: widget.onAdd,
                                  logs: widget.logs,
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: activeSession != null 
        ? null 
        : FloatingActionButton.extended(
            key: widget.addSessionKey,
            onPressed: _openAddSessionSheet,
            icon: const Icon(Icons.add),
            label: Text(t("Log Session", "Registrar sesión")),
          ),
    );
  }

  int _calculateStreak(List<SessionLogEntry> logs) {
    if (logs.isEmpty) return 0;
    
    // Sort by date descending
    final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
    
    int streak = 0;
    DateTime lastDate = DateTime.now();
    
    // Normalize to date (ignoring time)
    DateTime toDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
    
    DateTime currentCheck = toDate(lastDate);
    
    for (var session in sorted) {
      final sessionDate = toDate(session.date);
      if (sessionDate == currentCheck) {
        streak++;
        currentCheck = currentCheck.subtract(const Duration(days: 1));
      } else if (sessionDate.isBefore(currentCheck)) {
        // Gap found
        break;
      }
      // If sessionDate is after currentCheck, it's either today (already handled) or a duplicate day (ignore)
    }
    
    return streak;
  }

  Widget _buildAiAnalysisCard(AiAnalysisResult a) {
    final y = a.date.year.toString().padLeft(4, "0");
    final m = a.date.month.toString().padLeft(2, "0");
    final d = a.date.day.toString().padLeft(2, "0");
    final dateLabel = "$y-$m-$d";

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  t("AI Video Analysis", "Análisis de Video IA"),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Colors.amber.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              dateLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(t("Focus", "Enfoque") + ": ${a.focusArea}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(t("Solid", "Sólido") + ": ${a.looksSolid}", style: const TextStyle(fontSize: 13, height: 1.3)),
            const SizedBox(height: 8),
            Text(t("Improvement", "Mejora") + ": ${a.primaryImprovement}", style: const TextStyle(fontSize: 13, height: 1.3)),
            const SizedBox(height: 8),
            Text(t("Drill", "Ejercicio") + ": ${a.drillToPractice}", style: const TextStyle(fontSize: 13, height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Teal background block - Fixed height to ensure 20-30px overhang with 16:9 card
            Container(
              height: 410, 
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SmartSurfWordmark(
                          isInverse: true,
                          onTap: widget.onReturnToDashboard,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getDynamicGreeting(widget.displayName),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          LanguageMenu(
                            isSpanish: widget.isSpanish,
                            onSetLanguage: widget.onSetLanguage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t("Ready to log\nyour surf?", "¿Listo para registrar\ntu sesión?"),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Media card with specific top offset to place it below greeting
            Positioned(
              top: 290, 
              left: 16,
              right: 16,
              child: MediaCard(
                state: MediaCardState.image,
                imageWidget: Image.network(
                  'https://images.unsplash.com/photo-1502680390469-be75c86b636f?auto=format&fit=crop&q=80&w=800',
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    color: AppTheme.surfaceVariant,
                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 48),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Spacer for the overhanging media card (Approx 110px overhang + 20px gap)
        const SizedBox(height: 130), 
      ],
    );
  }
}

class _PreSurfCheckInCard extends StatefulWidget {
  final bool isSpanish;
  final Function(SessionLogEntry) onStart;

  const _PreSurfCheckInCard({required this.isSpanish, required this.onStart});

  @override
  State<_PreSurfCheckInCard> createState() => _PreSurfCheckInCardState();
}

class _PreSurfCheckInCardState extends State<_PreSurfCheckInCard> {
  String? selectedWaveSize;
  String? selectedFocus;
  String? selectedConditions;
  String? selectedBoard;

  String t(String en, String es) => widget.isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                t("Pre-Surf Check-In", "Check-In Pre-Surf"),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            t("Quick check-in before you paddle out.",
                "Check-in rápido antes de entrar al agua."),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          _SelectorLabel(t("Wave height", "Tamaño de ola")),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: SurfConstants.waveHeightOptions.map((m) {
              final size = m["en"]!;
              final isSelected = selectedWaveSize == size;
              return ChoiceChip(
                label: Text(t(size, m["es"]!), style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                selected: isSelected,
                onSelected: (val) => setState(() => selectedWaveSize = val ? size : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _SelectorLabel(t("Focus", "Enfoque")),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: [
              ...["Pop-up timing", "Paddling position", "Stance/Balance", "Wave selection", "Maintaining speed down the line", "Developing bottom turn"].map((focus) {
                final isSelected = selectedFocus == focus;
                final display = SurfConstants.focusSkillPresets.firstWhere((m) => m["en"] == focus, orElse: () => {"en": focus, "es": focus});
                return ChoiceChip(
                  label: Text(t((display["en"] ?? focus), (display["es"] ?? focus)), style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => selectedFocus = focus);
                  },
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: Text(t("+ More skills", "+ Más habilidades"), style: const TextStyle(fontSize: 12)),
                onPressed: () => _showAllSkillsModal(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SelectorLabel(t("Conditions", "Condiciones")),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: SurfConstants.conditionOptions.map((m) {
              final cond = m["en"]!;
              final isSelected = selectedConditions == cond;
              return ChoiceChip(
                label: Text(t(cond, m["es"]!), style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                selected: isSelected,
                onSelected: (val) => setState(() => selectedConditions = val ? cond : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _SelectorLabel(t("Board", "Tabla")),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: SurfConstants.boardOptions.map((m) {
              final en = m["en"]!;
              final es = m["es"]!;
              final isSelected = selectedBoard == en;
              return ChoiceChip(
                label: Text(t(en, es), style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                selected: isSelected,
                onSelected: (val) => setState(() => selectedBoard = val ? en : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                final entry = SessionLogEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: DateTime.now(),
                  spotName: t("Current Session", "Sesión Actual"),
                  countryOrRegion: "",
                  waveSize: selectedWaveSize ?? "",
                  sessionFocus: selectedFocus ?? "",
                  board: selectedBoard ?? SurfConstants.boardOptions.first["en"]!,
                  durationMins: 0,
                  rating: 0,
                  notes: "",
                  reflectionConditions: selectedConditions ?? "",
                  isCompleted: false,
                );
                widget.onStart(entry);
              },
              child: Text(t("Start Session", "Iniciar Sesión"), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllSkillsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(t("Select Focus Skill", "Seleccionar Habilidad Foco"), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: SurfConstants.focusSkillPresets.length,
                itemBuilder: (ctx, index) {
                  final skill = SurfConstants.focusSkillPresets[index];
                  final en = skill["en"]!;
                  final es = skill["es"]!;
                  return ListTile(
                    title: Text(t(en, es)),
                    trailing: selectedFocus == en ? const Icon(Icons.check, color: AppTheme.primary) : null,
                    onTap: () {
                      setState(() => selectedFocus = en);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorLabel extends StatelessWidget {
  final String label;
  const _SelectorLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 1.0,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}

class _ReflectionShortcut extends StatelessWidget {
  final String label;
  final String content;

  const _ReflectionShortcut({required this.label, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Expanded(child: Text(content, style: const TextStyle(fontSize: 11))),
        ],
      ),
    );
  }
}

class _TrendInsights extends StatelessWidget {
  final List<SessionLogEntry> logs;
  final bool isSpanish;

  const _TrendInsights({required this.logs, required this.isSpanish});

  String t(String en, String es) => isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    final completedLogs = logs.where((e) => e.isCompleted).toList();
    final count = completedLogs.length;
    
    String titleText = "";
    String bodyText = "";
    String insightText = "";

    if (count == 0) {
      return const SizedBox.shrink();
    } else if (count == 1) {
      titleText = t("MOMENTUM BUILDING", "CONSTRUYENDO IMPULSO");
      bodyText = t("Your first session is logged! Keep it up to unlock deep trend analysis.", 
                   "¡Tu primera sesión está registrada! Sigue así para desbloquear el análisis de tendencias profundo.");
      insightText = t("Tip: Consistently logging focus skills helps the AI identify technical patterns.",
                      "Consejo: Registrar consistentemente las habilidades foco ayuda a la IA a identificar patrones técnicos.");
    } else if (count < 4) {
      titleText = t("EARLY TRENDS", "TENDENCIAS TEMPRANAS");
      // Find most frequent wave size
      final waveSizes = completedLogs.map((e) => e.waveSize).where((s) => s.isNotEmpty).toList();
      String waveInsight = "";
      if (waveSizes.isNotEmpty) {
        final Map<String, int> counts = {};
        for (var s in waveSizes) {
          counts[s] = (counts[s] ?? 0) + 1;
        }
        final mostFreq = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        waveInsight = t("You're surfing most often in $mostFreq waves. ", 
                        "Estás surfeando más seguido en olas de $mostFreq. ");
      }
      
      bodyText = t("With $count sessions, we're starting to see your rhythm. ${waveInsight}Consistency is the foundation of progress.", 
                   "Con $count sesiones, empezamos a ver tu ritmo. ${waveInsight}La consistencia es la base del progreso.");
      insightText = t("Log a 4th session to unlock deeper technical pattern analysis.", 
                      "Registra una 4ª sesión para desbloquear el análisis de patrones técnicos más profundo.");
    } else {
      titleText = t("DEEP TREND ANALYSIS", "ANÁLISIS DE TENDENCIAS PROFUNDO");
      
      // Analyze Recurring Focus Skills
      final focusSkills = completedLogs.map((e) => e.sessionFocus).where((s) => s.isNotEmpty).toList();
      String focusInsight = "";
      if (focusSkills.isNotEmpty) {
        final Map<String, int> counts = {};
        for (var s in focusSkills) {
          counts[s] = (counts[s] ?? 0) + 1;
        }
        final mostFreq = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        final freqCount = counts[mostFreq];
        focusInsight = t("You've focused on '$mostFreq' in $freqCount sessions. ", 
                         "Te has enfocado en '$mostFreq' en $freqCount sesiones. ");
      }

      // Analyze Challenges
      final challenges = completedLogs.map((e) => e.reflectionWhatWasChallenging).where((s) => s != null && s.isNotEmpty).toList();
      String challengeInsight = "";
      if (challenges.isNotEmpty) {
        challengeInsight = t("Your reflections highlight recurring challenges with technical stability.", 
                             "Tus reflexiones resaltan desafíos recurrentes con la estabilidad técnica.");
      }

      bodyText = t("Impressive consistency with $count sessions! $focusInsight$challengeInsight", 
                   "¡Impresionante consistencia con $count sesiones! $focusInsight$challengeInsight");
      insightText = t("Next Step: Try shifting focus to a complementary skill to round out your progression.", 
                      "Siguiente paso: Intenta cambiar el enfoque a una habilidad complementaria para completar tu progresión.");
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                titleText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bodyText,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            insightText,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CurrentSessionCard extends StatefulWidget {
  final bool isSpanish;
  final SessionLogEntry session;
  final VoidCallback onLog;
  final VoidCallback onDiscard;

  const _CurrentSessionCard({
    required this.isSpanish,
    required this.session,
    required this.onLog,
    required this.onDiscard,
  });

  @override
  State<_CurrentSessionCard> createState() => _CurrentSessionCardState();
}

class _CurrentSessionCardState extends State<_CurrentSessionCard> {
  late DateTime _startTime;
  late final _timer = Stream.periodic(const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    _startTime = widget.session.date;
  }

  @override
  void didUpdateWidget(covariant _CurrentSessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.session.id != oldWidget.session.id || widget.session.date != oldWidget.session.date) {
      _startTime = widget.session.date;
    }
  }

  String t(String en, String es) => widget.isSpanish ? es : en;

  String _formatDuration(Duration d) {
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$hh:$mm:$ss";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _timer,
      builder: (context, _) {
        final elapsed = DateTime.now().difference(_startTime);
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        t("Current Session", "Sesión Actual"),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                      ),
                    ],
                  ),
                  Text(
                    _formatDuration(elapsed),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      fontFamily: 'Courier',
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SessionMeta(icon: Icons.calendar_today, text: t("Started: ", "Inició: ") + widget.session.date.toString().substring(11, 16)),
                  const SizedBox(width: 16),
                  if (widget.session.board.isNotEmpty)
                    _SessionMeta(
                      icon: Icons.surfing, 
                      text: SurfConstants.getBoardTranslation(widget.session.board, widget.isSpanish)
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: widget.onLog,
                        child: Text(t("End & Log Session", "Finalizar y Registrar"), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(t("Discard Session?", "¿Descartar Sesión?")),
                              content: Text(t("This will delete your current active timer and session draft.", "Esto eliminará tu temporizador activo y el borrador de la sesión.")),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t("Cancel", "Cancelar"))),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    widget.onDiscard();
                                  }, 
                                  child: Text(t("Discard", "Descartar"), style: const TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                        child: Text(t("Discard", "Descartar"), style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionLogEntry session;
  final bool isSpanish;
  final String units;
  final bool isSurferPro;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.isSpanish,
    required this.units,
    required this.isSurferPro,
    required this.onDelete,
    required this.onTap,
  });

  String t(String en, String es) => isSpanish ? es : en;

  String get _displayTitle {
    String? rawTitle;
    
    // Priority 1: Reflection/Notes
    if (session.notes.isNotEmpty) {
      rawTitle = session.notes;
    } else if (session.reflectionWhatFeltGood?.isNotEmpty == true) {
      rawTitle = session.reflectionWhatFeltGood;
    }
    
    if (rawTitle != null && rawTitle.trim().isNotEmpty) {
      // First short line
      final lines = rawTitle.trim().split('\n');
      return lines.first;
    }

    // Priority 2: Conditions/Waves
    if (session.waveSize.isNotEmpty) {
      final sizeTrans = SurfConstants.waveHeightOptions.firstWhere((m) => m["en"] == session.waveSize, orElse: () => {"en": session.waveSize, "es": session.waveSize});
      return "${t(session.waveSize, sizeTrans["es"]!)} ${t("practice session", "sesión de práctica")}";
    }

    // Priority 3: Fallback
    final d = session.date;
    return "${t("Session", "Sesión")} – ${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  String _formatDate(DateTime d) {
    const monthsEn = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dic"];
    const monthsEs = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
    final mIndex = (d.month - 1).clamp(0, 11);
    final m = isSpanish ? monthsEs[mIndex] : monthsEn[mIndex];
    return "$m ${d.day}";
  }

  @override
  Widget build(BuildContext context) {
    final waveSizeTrans = session.waveSize.isNotEmpty 
        ? SurfConstants.waveHeightOptions.firstWhere(
            (m) => m["en"] == session.waveSize, 
            orElse: () => {"en": session.waveSize, "es": session.waveSize})["es"]!
        : "";

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _JournalMeta(emoji: "📅", label: _formatDate(session.date)),
                      if (session.waveSize.isNotEmpty)
                        _JournalMeta(emoji: "🌊", label: t(session.waveSize, waveSizeTrans)),
                      if (session.board.isNotEmpty)
                        _JournalMeta(emoji: "🏄", label: SurfConstants.getBoardTranslation(session.board, isSpanish).split(" · ").first),
                      if (session.durationMins > 0)
                        _JournalMeta(emoji: "⏱", label: "${session.durationMins}m"),
                      if (session.waveLocation != null)
                        _JournalMeta(
                          emoji: "🌊", 
                          label: SurfConstants.getWaveLocationTranslation(session.waveLocation, isSpanish),
                        ),
                    ],
                  ),
                ),
                Column(
                   children: [
                    if (session.mediaPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: MediaCard(
                            state: session.mediaType == 'video' ? MediaCardState.video : MediaCardState.image,
                            mediaPath: session.mediaPath,
                            mediaType: session.mediaType,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
      ),
    );
  }
}

class _JournalMeta extends StatelessWidget {
  final String emoji;
  final String label;
  const _JournalMeta({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// _SessionDetailSheet is now a StatefulWidget below

class _SessionDetailSheet extends StatefulWidget {
  final SessionLogEntry session;
  final bool isSpanish;
  final String units;
  final bool isSurferPro;
  final Function(SessionLogEntry) onAdd;
  final List<SessionLogEntry> logs;
  final bool autoGenerate;

  const _SessionDetailSheet({
    super.key,
    required this.session,
    required this.isSpanish,
    required this.units,
    required this.isSurferPro,
    required this.onAdd,
    required this.logs,
    this.autoGenerate = false,
  });

  static void show(BuildContext context, {
    required SessionLogEntry session, 
    required bool isSpanish, 
    required String units, 
    required bool isSurferPro,
    required Function(SessionLogEntry) onAdd,
    required List<SessionLogEntry> logs,
    bool autoGenerate = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _SessionDetailSheet(
        session: session,
        isSpanish: isSpanish,
        units: units,
        isSurferPro: isSurferPro,
        onAdd: onAdd,
        logs: logs,
        autoGenerate: autoGenerate,
      ),
    );
  }

  @override
  State<_SessionDetailSheet> createState() => _SessionDetailSheetState();
}

class _SessionDetailSheetState extends State<_SessionDetailSheet> {
  bool _isGenerating = false;
  late SessionLogEntry _currentSession;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    if (widget.autoGenerate && 
        widget.isSurferPro && 
        (_currentSession.aiSummaryEn == null || _currentSession.aiSummaryEn!.isEmpty)) {
      // Small delay to let the sheet open smoothly before starting heavy work
      Future.delayed(const Duration(milliseconds: 500), _generateInsight);
    }
  }

  String t(String en, String es) => widget.isSpanish ? es : en;

  Future<void> _generateInsight() async {
    if (_isGenerating) return;
    if (!widget.isSurferPro) return;

    setState(() => _isGenerating = true);

    try {
      debugPrint("DetailSheet: CALLING BACKEND...");
      final aiResult = await AnalyzeApi.analyzeReflection(
        focus: _currentSession.sessionFocus,
        workedOn: _currentSession.notes,
        feltHard: _currentSession.reflectionWhatWasChallenging ?? '',
        feltGood: _currentSession.reflectionWhatFeltGood ?? '',
        conditions: _currentSession.reflectionConditions ?? '',
        notes: _currentSession.notes,
        language: widget.isSpanish ? 'es' : 'en',
      );

      final apiSummaryEn = (aiResult['session_insight_en'] ?? (widget.isSpanish ? null : aiResult['session_insight'])) as String?;
      final apiPatternEn = (aiResult['progress_pattern_en'] ?? (widget.isSpanish ? null : aiResult['progress_pattern'])) as String?;
      final apiFocusEn = (aiResult['next_session_focus_en'] ?? (widget.isSpanish ? null : aiResult['next_session_focus'])) as String?;
      
      final apiSummaryEs = (aiResult['session_insight_es'] ?? (widget.isSpanish ? aiResult['session_insight'] : null)) as String?;
      final apiPatternEs = (aiResult['progress_pattern_es'] ?? (widget.isSpanish ? aiResult['progress_pattern'] : null)) as String?;
      final apiFocusEs = (aiResult['next_session_focus_es'] ?? (widget.isSpanish ? aiResult['next_session_focus'] : null)) as String?;

      if ((apiSummaryEn == null || apiSummaryEn.isEmpty) && (apiSummaryEs == null || apiSummaryEs.isEmpty)) {
        throw Exception("Empty AI response"); 
      }

      final updated = _currentSession.copyWith(
        aiSummaryEn: apiSummaryEn,
        aiProgressPatternEn: apiPatternEn,
        aiNextFocusEn: apiFocusEn,
        aiSummaryEs: apiSummaryEs,
        aiProgressPatternEs: apiPatternEs,
        aiNextFocusEs: apiFocusEs,
        aiSummary: widget.isSpanish ? (apiSummaryEs ?? apiSummaryEn) : (apiSummaryEn ?? apiSummaryEs),
        aiProgressPattern: widget.isSpanish ? (apiPatternEs ?? apiPatternEn) : (apiPatternEn ?? apiPatternEs),
        aiNextFocus: widget.isSpanish ? (apiFocusEs ?? apiFocusEn) : (apiFocusEn ?? apiFocusEs),
      );

      if (mounted) {
        setState(() => _currentSession = updated);
        widget.onAdd(updated);
      }
    } catch (e) {
      debugPrint("DetailSheet: FALLBACK -> $e");
      final insight = AiInsightService.generate(
        session: _currentSession, 
        isSpanish: widget.isSpanish, 
        previousLogs: widget.logs
      );
      
      final updated = _currentSession.copyWith(
        aiSummaryEn: insight['summaryEn'],
        aiProgressPatternEn: insight['patternEn'],
        aiNextFocusEn: insight['nextFocusEn'],
        aiSummaryEs: insight['summaryEs'],
        aiProgressPatternEs: insight['patternEs'],
        aiNextFocusEs: insight['nextFocusEs'],
        aiSummary: widget.isSpanish ? insight['summaryEs'] : insight['summaryEn'],
        aiProgressPattern: widget.isSpanish ? insight['patternEs'] : insight['patternEn'],
        aiNextFocus: widget.isSpanish ? insight['nextFocusEs'] : insight['nextFocusEn'],
      );
      
      if (mounted) {
        setState(() => _currentSession = updated);
        widget.onAdd(updated);
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      t("Session Detail", "Detalle de la Sesión"),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.primary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_currentSession.mediaPath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MediaCard(
                    isSpanish: widget.isSpanish,
                    state: _currentSession.mediaType == 'video' ? MediaCardState.video : MediaCardState.image,
                    mediaPath: _currentSession.mediaPath,
                    mediaType: _currentSession.mediaType,
                    onTap: () {
                      if (_currentSession.mediaType == 'video' && _currentSession.mediaPath != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPreviewModal(
                              videoPath: _currentSession.mediaPath!,
                              isSpanish: widget.isSpanish,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              _buildInfoGrid(context),
              const Divider(height: 48),
              
              if (_currentSession.sessionFocus.isNotEmpty) ...[
                _buildField(t("Focus Skill", "Habilidad Foco"), "🎯 " + SurfConstants.getFocusSkillTranslation(_currentSession.sessionFocus, widget.isSpanish)),
                const SizedBox(height: 20),
              ],
              if (_currentSession.reflectionConditions?.isNotEmpty == true) ...[
                _buildField(t("Conditions", "Condiciones"), "☁️ " + SurfConstants.getConditionTranslation(_currentSession.reflectionConditions, widget.isSpanish)),
                const SizedBox(height: 20),
              ],
              if (_currentSession.notes.isNotEmpty) ...[
                _buildField(t("What were you working on?", "¿En qué estabas trabajando?"), _currentSession.notes),
                const SizedBox(height: 20),
              ],
              if (_currentSession.reflectionWhatFeltGood?.isNotEmpty == true) ...[
                _buildField(t("What felt good?", "¿Qué te hizo sentir bien?"), "✨ " + _currentSession.reflectionWhatFeltGood!),
                const SizedBox(height: 20),
              ],
              if (_currentSession.reflectionWhatWasChallenging?.isNotEmpty == true) ...[
                _buildField(t("What was challenging?", "¿Qué fue lo más difícil?"), "🌊 " + _currentSession.reflectionWhatWasChallenging!),
                const SizedBox(height: 20),
              ],

              // Clean, Centralized AI Section
              const Divider(height: 48),
              _buildAiSection(context),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiSection(BuildContext context) {
    final summary = widget.isSpanish ? _currentSession.aiSummaryEs : _currentSession.aiSummaryEn;
    final hasInsight = summary != null && summary.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              t("AI SURF INSIGHT", "INSIGHT DE SURF IA"),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: AppTheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            if (hasInsight && !_isGenerating)
               TextButton.icon(
                onPressed: _generateInsight,
                icon: const Icon(Icons.refresh, size: 14),
                label: Text(t("Refresh", "Actualizar"), style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isGenerating)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(height: 16),
                Text(t("Generating insight...", "Generando insight..."), 
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          )
        else if (hasInsight)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(t("Lesson", "Lección"), summary, isItalic: true, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              if ((widget.isSpanish ? _currentSession.aiProgressPatternEs : _currentSession.aiProgressPatternEn)?.isNotEmpty == true) ...[
                _buildField(t("Pattern", "Patrón"), (widget.isSpanish ? _currentSession.aiProgressPatternEs : _currentSession.aiProgressPatternEn)!, isItalic: true),
                const SizedBox(height: 20),
              ],
              if ((widget.isSpanish ? _currentSession.aiNextFocusEs : _currentSession.aiNextFocusEn)?.isNotEmpty == true) ...[
                 _buildFocusCard(t("Next Priority", "Próxima Prioridad"), (widget.isSpanish ? _currentSession.aiNextFocusEs : _currentSession.aiNextFocusEn)!, widget.isSpanish),
              ],
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Text(
                  t("Unlock your technical potential with a custom AI insight.", 
                    "Desbloquea tu potencial técnico con un insight de IA personalizado."),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _generateInsight,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(t("Analyze with AI ✨", "Analizar con IA ✨")),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFocusCard(String title, String content, bool isSpanish) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: [
        _buildInfoItem("📅", t("Date", "Fecha"), 
          "${_currentSession.date.year}-${_currentSession.date.month.toString().padLeft(2, '0')}-${_currentSession.date.day.toString().padLeft(2, '0')}"),
        if (_currentSession.spotName.isNotEmpty && _currentSession.spotName != t("Current Session", "Sesión Actual"))
          _buildInfoItem("📍", t("Location", "Ubicación"), _currentSession.spotName == "Location not specified" ? t("Location not specified", "Ubicación no especificada") : _currentSession.spotName),
        if (_currentSession.countryOrRegion.isNotEmpty)
          _buildInfoItem("🌎", t("Region", "Región"), _currentSession.countryOrRegion),
        if (_currentSession.waveSize.isNotEmpty)
          _buildInfoItem("🌊", t("Waves", "Olas"), SurfConstants.getWaveHeightTranslation(_currentSession.waveSize, widget.isSpanish)),
        if (_currentSession.board.isNotEmpty)
          _buildInfoItem("🏄", t("Board", "Tabla"), SurfConstants.getBoardTranslation(_currentSession.board, widget.isSpanish)),
        if (_currentSession.waveSize != null && _currentSession.waveSize!.isNotEmpty)
          _buildInfoItem("🌊", t("Conditions", "Condiciones"), 
            "${SurfConstants.getWaveHeightTranslation(_currentSession.waveSize, widget.isSpanish)} · ${SurfConstants.getConditionTranslation(_currentSession.reflectionConditions, widget.isSpanish)}"),
        if (_currentSession.durationMins > 0)
          _buildInfoItem("⏱", t("Duration", "Duración"), "${_currentSession.durationMins}m"),
        if (_currentSession.rating > 0)
          _buildInfoItem("⭐", t("Rating", "Valoración"), "${_currentSession.rating}/5"),
        if (_currentSession.waveLocation != null && _currentSession.waveLocation!.isNotEmpty)
          _buildInfoItem("🌊", t("Wave Context", "Contexto de Ola"), 
            SurfConstants.getWaveLocationTranslation(_currentSession.waveLocation, widget.isSpanish)),
      ],
    );
  }

  Widget _buildInfoItem(String emoji, String label, String value) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value, {bool isItalic = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            fontWeight: isItalic ? FontWeight.w500 : FontWeight.w400,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SessionMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SessionMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SurfInsightTriggerCard extends StatefulWidget {
  final SessionLogEntry session;
  final bool isSpanish;
  final bool isSurferPro;
  final void Function(SessionLogEntry) onAdd;
  final VoidCallback? onUnlockSurferPro;

  const _SurfInsightTriggerCard({
    required this.session,
    required this.isSpanish,
    required this.isSurferPro,
    required this.onAdd,
    this.onUnlockSurferPro,
    required this.totalSessions,
    required this.sessionsThisMonth,
    required this.currentStreak,
    required this.logs,
  });

  final int totalSessions;
  final int sessionsThisMonth;
  final int currentStreak;
  final List<SessionLogEntry> logs;

  @override
  State<_SurfInsightTriggerCard> createState() => _SurfInsightTriggerCardState();
}
class _SurfInsightTriggerCardState extends State<_SurfInsightTriggerCard> {
  @override
  Widget build(BuildContext context) {
    final t = widget.isSpanish;
    
    // Check if we have insights in the current language
    final String? summary = t ? widget.session.aiSummaryEs : widget.session.aiSummaryEn;
    final String? pattern = t ? widget.session.aiProgressPatternEs : widget.session.aiProgressPatternEn;
    final String? nextFocus = t ? widget.session.aiNextFocusEs : widget.session.aiNextFocusEn;

    final bool hasInsight = summary != null && summary.isNotEmpty;

    if (!hasInsight) {
      // Intentional Moment: Dashboard Trigger
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  t ? "Insight de Surf" : "Surf Insight",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              t ? "Obtén comentarios de IA sobre tu última sesión." : "Get AI feedback on your latest session.",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => _SessionDetailSheet.show(
                  context, 
                  session: widget.session, 
                  isSpanish: widget.isSpanish, 
                  units: "imperial", // Units managed inside the sheet details
                  isSurferPro: widget.isSurferPro,
                  onAdd: widget.onAdd,
                  logs: widget.logs,
                  autoGenerate: true,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(t ? "Generar Insight ✨" : "Generate Surf Insight ✨", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                t 
                  ? "Los insights de IA se generan a partir de tus datos y reflexiones. Están destinados a apoyar tu aprendizaje."
                  : "AI insights are generated from your session data and reflections to support your learning.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10, 
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Loaded Output State
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                t ? "Insight de Surf" : "Surf Insight",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInsightSection(t ? "Insight de la Sesión" : "Session Insight", summary!),
          if (pattern != null && pattern.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInsightSection(t ? "Patrón de Progreso" : "Progress Pattern", pattern),
          ],
          const SizedBox(height: 20),
          _buildFocusCard(t ? "Próximo Enfoque" : "Next Session Focus", nextFocus!, t),
        ],
      ),
    );
  }

  Widget _buildFocusCard(String title, String content, bool isSpanish) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppTheme.primary,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
