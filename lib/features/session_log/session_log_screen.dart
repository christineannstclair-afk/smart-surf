import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/translation_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'dart:ui' as ui;
import '../../core/permission_service.dart';

import 'package:smart_surf/features/session_log/session_log_entry.dart';
import 'package:smart_surf/features/passport/passport_presets.dart';
import 'package:smart_surf/features/home/video_preview_modal.dart';
import 'package:smart_surf/widgets/micro_tip_banner.dart';
import 'package:smart_surf/models/ai_analysis_model.dart';
import 'package:smart_surf/widgets/orientation_prompt.dart';
import 'package:smart_surf/features/Settings/settings_models.dart';
import 'package:smart_surf/ui_system/spacing.dart';
import 'package:smart_surf/ui_system/app_card.dart';
import 'package:smart_surf/ui_system/media_card.dart';
import 'package:smart_surf/widgets/smart_surf_wordmark.dart';
import 'package:smart_surf/widgets/language_menu.dart';
import 'package:smart_surf/ui_system/app_theme.dart';
import 'package:smart_surf/features/session_log/firebase_service.dart';
import 'package:smart_surf/ui_system/surf_constants.dart';
import 'package:smart_surf/features/surfer_pro/surfer_pro_paywall.dart';
import 'package:smart_surf/features/session_log/ai_insight_service.dart';
import 'package:smart_surf/core/analyze_api.dart';
import 'package:smart_surf/storage/app_storage.dart';
import 'insight_payoff_screen.dart';
import '../passport/surf_passport_edit_sheet.dart';
import '../passport/profile_info_edit_sheet.dart';
import 'package:smart_surf/ui_system/animations.dart';
import 'progress_success_screen.dart';

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
    required this.onUpdateProfile,
    required this.onUpdate,
    required this.sessionsThisMonth,
    required this.currentStreak,
    this.onReturnToDashboard,
    required this.hasSeenWelcomeGuide,
    required this.onWelcomeModalDismissed,
    required this.hasSeenPostFirstSessionPassportPrompt,
    required this.onPassportPromptSeen,
    required this.hasSeenPostPassportProfilePrompt,
    required this.onProfileInfoPromptSeen,
    this.hasSeenFirstInsightPrompt = false,
    this.onInsightPromptSeen,
    this.hasUsedFirstFreeAIInsight = false,
    this.onFirstFreeAIInsightUsed,
    this.onInsightViewed,
    required this.focusEn,
    required this.levelEnTitle,
    required this.levelEnDesc,
    required this.comfortEn,
    required this.boardEn,
    required this.stance,
    required this.height,
    required this.weight,
    required this.location,
    required this.age,
    required this.surferSummary,
    required this.profilePhotoPath,
    required this.stanceVisibleToCoach,
    required this.stanceVisibleOnDashboard,
    required this.heightVisibleToCoach,
    required this.heightVisibleOnDashboard,
    required this.weightVisibleToCoach,
    required this.weightVisibleOnDashboard,
    required this.locationVisibleToCoach,
    required this.locationVisibleOnDashboard,
    required this.ageVisibleToCoach,
    required this.ageVisibleOnDashboard,
    this.onUnlockFirstInsight,
    this.onGenerateInsight,
    this.onOpenSurferPro,
    this.onKeepExploring,
    this.lastNudgeShownAt = 0,
    this.onSurferProNudgeSeen,
  });

  final bool isSpanish;
  final bool isSurferPro;
  final void Function(bool) onSetLanguage;
  final String displayName;
  final List<SessionLogEntry> logs;
  final bool hasSeenWelcomeGuide;
  final VoidCallback onWelcomeModalDismissed;
  final bool hasSeenPostFirstSessionPassportPrompt;
  final VoidCallback onPassportPromptSeen;
  final bool hasSeenPostPassportProfilePrompt;
  final VoidCallback onProfileInfoPromptSeen;
  final bool hasSeenFirstInsightPrompt;
  final VoidCallback? onInsightPromptSeen;
  final bool hasUsedFirstFreeAIInsight;
  final VoidCallback? onFirstFreeAIInsightUsed;
  final VoidCallback? onInsightViewed;
  final VoidCallback? onKeepExploring;
  final int lastNudgeShownAt;
  final void Function(int)? onSurferProNudgeSeen;
  final List<String> focusEn;
  
  final String levelEnTitle;
  final String levelEnDesc;
  final String comfortEn;
  final String boardEn;
  final String stance;
  final String height;
  final String weight;
  final String location;
  final String age;
  final String surferSummary;
  final String? profilePhotoPath;
  final bool stanceVisibleToCoach;
  final bool stanceVisibleOnDashboard;
  final bool heightVisibleToCoach;
  final bool heightVisibleOnDashboard;
  final bool weightVisibleToCoach;
  final bool weightVisibleOnDashboard;
  final bool locationVisibleToCoach;
  final bool locationVisibleOnDashboard;
  final bool ageVisibleToCoach;
  final bool ageVisibleOnDashboard;
  final void Function(SessionLogEntry) onAdd;
  final void Function({
    required String levelEnTitle,
    required String levelEnDesc,
    required String comfortEn,
    required String boardEn,
    required List<String> focusEn,
    required String stance,
    required String height,
    required String weight,
    required String location,
    required String age,
    required String surferSummary,
    required String displayName,
    required String? profilePhotoPath,
    required bool stanceVisibleToCoach,
    required bool stanceVisibleOnDashboard,
    required bool heightVisibleToCoach,
    required bool heightVisibleOnDashboard,
    required bool weightVisibleToCoach,
    required bool weightVisibleOnDashboard,
    required bool locationVisibleToCoach,
    required bool locationVisibleOnDashboard,
    required int sessionsSurfed,
    required DateTime? lastSurfedDate,
    required String units,
    required bool ageVisibleToCoach,
    required bool ageVisibleOnDashboard,
  }) onUpdateProfile;
  final void Function(SessionLogEntry) onUpdate;
  final void Function(String id) onDelete;
  final String units;
  final List<AiAnalysisResult> aiAnalyses;
  final GlobalKey? addSessionKey;
  final VoidCallback? onReturnToDashboard;
  final bool seenLogPrompt;
  final VoidCallback onPromptDismissed;
  final int sessionsThisMonth;
  final int currentStreak;
  final Future<SessionLogEntry?> Function()? onUnlockFirstInsight;
  final Future<SessionLogEntry?> Function(SessionLogEntry)? onGenerateInsight;
  final Function({String? title, String? content, bool isSoftUpsell, VoidCallback? onSeeThisOneFirst})? onOpenSurferPro;

  @override
  State<SessionLogScreen> createState() => SessionLogScreenState();
}

class SessionLogScreenState extends State<SessionLogScreen> {
  String t(String en, String es) => widget.isSpanish ? es : en;
  bool _isSheetOpening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.seenLogPrompt && widget.addSessionKey != null && widget.logs.isEmpty && false) {
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

      bool hasPermission = false;
      bool isLimited = false;
      PermissionResult? camMicResult;
      
      if (sourceAction == 'camera') {
        camMicResult = await PermissionService().requestCameraAndMicrophone();
        hasPermission = (camMicResult == PermissionResult.granted);
      } else {
        final res = await PermissionService().handleImageSourcePermission(ImageSource.gallery);
        hasPermission = (res == PermissionResult.granted || res == PermissionResult.limited);
        isLimited = (res == PermissionResult.limited);
      }

      if (hasPermission) {
        if (isLimited && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t(
                "Photo library access is limited. Only permitted media will be visible.",
                "El acceso a la biblioteca está limitado. Solo se verán los archivos permitidos."
              )),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
           final isCam = sourceAction == 'camera';
           showDialog(
             context: context,
             builder: (ctx) => AlertDialog(
               title: Text(t("Permission Required", "Permiso Requerido")),
               content: Text(isCam 
                 ? t(
                    "Please enable Camera and Microphone permissions in Settings to capture surf clips.",
                    "Por favor, activa los permisos de Cámara y Micrófono en Ajustes para capturar clips de surf."
                   )
                 : t(
                    "Please enable Photo Library permissions in Settings to choose surf media.",
                    "Por favor, activa los permisos de la Biblioteca de Fotos en Ajustes para elegir archivos de surf."
                   )
               ),
               actions: [
                 TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
                 TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      openAppSettings();
                    },
                    child: Text(t("Settings", "Ajustes")),
                 ),
               ],
             ),
           );
        }
        return null;
      }

      try {
        if (sourceAction == 'gallery_video') {
          picked = await picker.pickVideo(
            source: ImageSource.gallery, 
            maxDuration: const Duration(seconds: 10),
          );
          isVideo = true;
        } else {
          final source = sourceAction == 'camera' ? ImageSource.camera : ImageSource.gallery;
          picked = await picker.pickImage(
            source: source, 
            maxWidth: 1080, 
            imageQuality: 70,
          );
          isVideo = false;
        }
      } catch (e) {
        debugPrint("Media selection critical error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t("Error opening camera/gallery: ", "Error al abrir cámara/galería: ") + e.toString())),
          );
        }
        return null;
      }

      if (picked == null) return null;

      // Size check (max 50 MB)
      final sizeInBytes = await picked.length();
      const maxSizeInBytes = 50 * 1024 * 1024;
      if (sizeInBytes > maxSizeInBytes) {
          if (mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(t("File Too Large", "Archivo demasiado grande")),
                  content: Text(t(
                    "Media files must be 50MB or less.",
                    "Los archivos de media deben ser de 50MB o menos."
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
          continue;
      }

      int durationSecs = 0;
      if (isVideo) {
        final controller = kIsWeb 
            ? VideoPlayerController.networkUrl(Uri.parse(picked.path))
            : VideoPlayerController.file(File(picked.path));
        try {
          await controller.initialize();
          durationSecs = controller.value.duration.inSeconds;
          final durationMs = controller.value.duration.inMilliseconds;
          debugPrint("DEBUG: Session Log Video Duration: ${durationSecs}s (${durationMs}ms)");
          await controller.dispose();
          
          if (durationMs > 10500) {
            debugPrint("DEBUG: Session Log LIMITS HIT! Showing alert...");
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
            continue;
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

      final shouldUpload = await _showMediaPreviewModal(picked, isVideo);
      if (shouldUpload == null) return null;
      if (shouldUpload == false) continue;

      _showUploadProgressDialog();
      
      final fbResult = await FirebaseService().uploadMedia(
          localPath: picked.path,
          isProfile: false,
          isVideo: isVideo,
          sessionId: "temp_${DateTime.now().millisecondsSinceEpoch}",
          webBytes: kIsWeb ? await picked.readAsBytes() : null,
      );
      
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

  Future<SessionLogEntry?> openAddSessionSheet({SessionLogEntry? existing, int startStep = 0, bool skipSuccessScreen = false}) async {
    if (_isSheetOpening) return null;
    setState(() => _isSheetOpening = true);
    final sessionId = existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    int currentStep = startStep; 

    final spotCtrl = TextEditingController(text: existing?.spotName == t("Current Session", "Sesión Actual") ? "" : existing?.spotName);
    final regionCtrl = TextEditingController(text: existing?.countryOrRegion);
    final feltGoodCtrl = TextEditingController(text: existing?.reflectionWhatFeltGood);
    final challengingCtrl = TextEditingController(text: existing?.reflectionWhatWasChallenging);
    final focusCtrl = TextEditingController(text: existing?.notes);
    final conditionsCtrl = TextEditingController(text: existing?.reflectionConditions);
    final waveCountCtrl = TextEditingController(text: existing?.waveCount?.toString() ?? "");
    final feltOffCtrl = TextEditingController(text: existing?.reflectionFeltOff);

    final waveOptions = SurfConstants.waveHeightOptions.map((m) => m["en"]!).toList();
    final boardOptions = SurfConstants.boardOptions.map((m) => m["en"]!).toList();

    DateTime selectedDate = existing?.date ?? DateTime.now();
    String waveSize = (existing?.waveSize.isNotEmpty == true && waveOptions.contains(existing!.waveSize)) 
        ? existing!.waveSize 
        : "1–2 ft";

    String selectedFocus = (existing?.sessionFocus.isNotEmpty == true) 
        ? existing!.sessionFocus.split(",").first.trim() 
        : (widget.focusEn.isNotEmpty ? widget.focusEn.first : "Pop-up timing");
    
    String board = (existing?.board.isNotEmpty == true && boardOptions.contains(existing!.board)) 
        ? existing!.board 
        : "Soft-top 7 to 8 feet";
        
    String selectedConditions = (existing?.reflectionConditions?.isNotEmpty == true && SurfConstants.conditionOptions.any((o) => o["en"] == existing!.reflectionConditions)) 
        ? existing!.reflectionConditions! 
        : "Clean";

    int durationMins = (existing?.durationMins ?? 0);
    int rating = existing?.rating ?? 0;
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
            bool _isSubmitting = false;

            if (currentStep == 0) {
              return DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (ctx3, controller) {
                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          controller: controller,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t("Quick Log", "Registro Rápido"), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 20),
                              TextField(
                                controller: spotCtrl,
                                decoration: InputDecoration(
                                  labelText: t("Location (optional)", "Ubicación (opcional)"),
                                  prefixIcon: const Icon(Icons.place_outlined),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: SurfConstants.waveHeightOptions.any((m) => m["en"] == waveSize) ? waveSize : null,
                                decoration: InputDecoration(labelText: t("Wave Height", "Tamaño de ola"), border: const OutlineInputBorder()),
                                items: SurfConstants.waveHeightOptions.map((m) => DropdownMenuItem(value: m["en"]!, child: Text(t(m["en"]!, m["es"]!)))).toList(),
                                onChanged: (v) => setSheetState(() => waveSize = v ?? waveSize),
                              ),
                              const SizedBox(height: 16),
                              Text(t("What did you focus on today?", "¿En qué te enfocaste hoy?"), style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: SurfConstants.masterFocusSkills.map((m) {
                                  final f = m["en"]!;
                                  final isSelected = selectedFocus == f;
                                  return ChoiceChip(
                                    label: Text(t(f, m["es"]!)),
                                    selected: isSelected,
                                    onSelected: (val) => setSheetState(() => selectedFocus = f),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: SurfConstants.boardOptions.any((m) => m["en"] == board) ? board : null,
                                decoration: InputDecoration(labelText: t("Board", "Tabla"), border: const OutlineInputBorder()),
                                items: SurfConstants.boardOptions.map((m) => DropdownMenuItem(value: m["en"]!, child: Text(t(m["en"]!, m["es"]!)))).toList(),
                                onChanged: (v) => setSheetState(() => board = v ?? board),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: waveCountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: t("Waves caught (optional)", "Olas atrapadas (opcional)"),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: SurfConstants.conditionOptions.any((m) => m["en"] == selectedConditions) ? selectedConditions : null,
                                decoration: InputDecoration(labelText: t("Conditions", "Condiciones"), border: const OutlineInputBorder()),
                                items: SurfConstants.conditionOptions.map((m) => DropdownMenuItem(value: m["en"]!, child: Text(t(m["en"]!, m["es"]!)))).toList(),
                                onChanged: (v) => setSheetState(() => selectedConditions = v ?? selectedConditions),
                              ),
                              const SizedBox(height: 24),
                              Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  title: Text(t("Add more (optional)", "Añadir más (opcional)"), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  tilePadding: EdgeInsets.zero,
                                  childrenPadding: const EdgeInsets.only(top: 8),
                                  children: [
                                    TextField(
                                      controller: focusCtrl,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        labelText: t("Notes", "Notas"),
                                        hintText: t("How was the session?", "¿Cómo estuvo la sesión?"),
                                        border: const OutlineInputBorder(),
                                        alignLabelWithHint: true,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    MediaCard(
                                      isSpanish: widget.isSpanish,
                                      state: mediaPath == null ? MediaCardState.empty : (mediaType == 'video' ? MediaCardState.video : MediaCardState.image),
                                      mediaPath: mediaPath,
                                      mediaType: mediaType ?? 'image',
                                      footerLabel: mediaLabel ?? t("Add session clip", "Añadir clip"),
                                      onAddMedia: () async {
                                        final result = await _handleMediaSelection(sessionId);
                                        if (result != null) {
                                          final parts = result.split(':');
                                          setSheetState(() {
                                            mediaType = parts[0];
                                            mediaPath = parts.sublist(1).join(':');
                                            if (mediaType == 'video') mediaLabel = parts.last;
                                          });
                                        }
                                      },
                                      onTap: () async {
                                        final result = await _handleMediaSelection(sessionId);
                                        if (result != null) {
                                          final parts = result.split(':');
                                          setSheetState(() {
                                            mediaType = parts[0];
                                            mediaPath = parts.sublist(1).join(':');
                                            if (mediaType == 'video') mediaLabel = parts.last;
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        t("Add a short clip or photo so you can track your progress and share with a coach.", 
                                          "Añade un clip corto o foto para seguir tu progreso y compartir con un coach."),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: AppTheme.textMuted.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: () async {
                                final bool isEditingMilestone = existing != null && widget.logs.length >= 3;
                                final bool isProAndMature = widget.isSurferPro && widget.logs.length >= 4;
                                
                                if (isEditingMilestone || isProAndMature) {
                                  setSheetState(() => currentStep = 1);
                                } else {
                                  setSheetState(() => _isSubmitting = true);
                                  final entry = SessionLogEntry(
                                    id: sessionId,
                                    date: selectedDate,
                                    spotName: spotCtrl.text.isEmpty ? t("Location not specified", "Ubicación no especificada") : spotCtrl.text,
                                    countryOrRegion: regionCtrl.text,
                                    waveSize: waveSize,
                                    sessionFocus: selectedFocus,
                                    board: board,
                                    durationMins: durationMins,
                                    rating: rating,
                                    notes: focusCtrl.text.trim(),
                                    isCompleted: true,
                                  );
                                  widget.onAdd(entry);
                                  Navigator.pop(ctx, entry);
                                }
                              },
                              child: Text(
                                ((existing != null && widget.logs.length >= 3) || (widget.isSurferPro && widget.logs.length >= 4))
                                  ? t("Continue to Reflection", "Continuar a la Reflexión")
                                  : t("Save session", "Guardar sesión"),
                                style: const TextStyle(fontWeight: FontWeight.w900)
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }

            return Scaffold(
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: true,
              body: DraggableScrollableSheet(
                initialChildSize: 0.9,
                maxChildSize: 0.95,
                expand: false,
                builder: (ctx3, controller) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t("Reflection", "Reflexión"), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 8),
                                Text(t("Lightweight & optional", "Ligero y opcional"), style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                                const SizedBox(height: 24),
                                _buildReflectionField(
                                  label: t("What felt off?", "¿Qué se sintió mal?"),
                                  controller: feltOffCtrl,
                                  hint: t("e.g. I felt late popping up...", "ej. Sentí que me paré tarde...")
                                ),
                                _buildReflectionField(
                                  label: t("What went well?", "¿Qué salió bien?"), 
                                  controller: feltGoodCtrl, 
                                  hint: t("e.g. My paddle speed felt better...", "ej. Mi velocidad de remada se sintió mejor...")
                                ),
                                const SizedBox(height: 24),
                                _buildReflectionField(
                                  label: t("What were you focusing on?", "¿En qué te enfocaste?"), 
                                  controller: conditionsCtrl, 
                                  hint: t("e.g. Staying low after takeoff...", "ej. Manteniéndome bajo después del despegue...")
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx3).viewInsets.bottom + 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: FilledButton(
                                    onPressed: _isSubmitting ? null : () async {
                                      setSheetState(() => _isSubmitting = true);
                                      final entry = SessionLogEntry(
                                        id: sessionId,
                                        date: selectedDate,
                                        spotName: spotCtrl.text.isEmpty ? t("Location not specified", "Ubicación no especificada") : spotCtrl.text,
                                        countryOrRegion: regionCtrl.text,
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
                                        reflectionFeltOff: feltOffCtrl.text.trim(),
                                        isCompleted: true,
                                        mediaPath: mediaPath,
                                        mediaType: mediaType,
                                        waveLocation: waveLocation,
                                        waveCount: int.tryParse(waveCountCtrl.text),
                                      );
                                      widget.onAdd(entry);
                                      Navigator.pop(ctx);
                                      _handleGenerateInsight(entry);
                                    },
                                    child: _isSubmitting
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : Text(
                                          t("Generate Insight", "Generar Insight"),
                                          style: const TextStyle(fontWeight: FontWeight.w900),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );

    if (mounted) setState(() => _isSheetOpening = false);

    if (created != null && !skipSuccessScreen) {
       _showSessionLoggedModal(created, currentCount: widget.logs.length);
    }
    
    return created;
  }

  Future<void> _showSessionLoggedModal(SessionLogEntry entry, {int currentCount = 0}) async {
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ProgressSuccessScreen(
            session: entry,
            isSpanish: widget.isSpanish,
            allSessions: widget.logs,
            isSurferPro: widget.isSurferPro,
            onGenerateInsight: (s) => widget.onGenerateInsight!(s),
            onFirstFreeAIUsed: widget.onFirstFreeAIInsightUsed,
            onLogAnother: () => Navigator.pop(ctx),
            onViewSession: () {
              Navigator.pop(ctx);
              Future.delayed(const Duration(milliseconds: 300), () {
                _handlePostSessionFlow(currentCount);
              });
            },
          ),
        ),
      );
    }
  }

  void _handlePostSessionFlow(int sessionCount) {
    if (!mounted) return;

    final bool isPro = widget.isSurferPro;
    final bool seenFirstPrompt = widget.hasSeenFirstInsightPrompt;
    final bool usedFirstFree = widget.hasUsedFirstFreeAIInsight;
    final int lastShown = widget.lastNudgeShownAt;

    // --- LOGGING ---
    debugPrint('--- [NudgeAudit] Logged Session #$sessionCount ---');
    debugPrint('[NudgeAudit] Subscription: isPro=$isPro');
    debugPrint('[NudgeAudit] Milestone Flags: seenFirstPrompt=$seenFirstPrompt, usedFirstFree=$usedFirstFree');
    debugPrint('[NudgeAudit] Nudge State: lastShownAt=$lastShown');

    // --- 1. FIRST FREE INSIGHT PROMPT (Session 4 milestone) ---
    // Rule: Triggers at session 4 or later if they haven't seen it and haven't used their free insight yet.
    final bool shouldShowFirstInsightPrompt = 
        !isPro && 
        sessionCount >= 4 && 
        !seenFirstPrompt && 
        !usedFirstFree;

    debugPrint('[NudgeAudit] shouldShowFirstInsightPrompt: $shouldShowFirstInsightPrompt');

    if (shouldShowFirstInsightPrompt) {
      debugPrint('[NudgeAudit] TRIGGER: First Free Insight Prompt');
      _triggerFirstInsightPrompt(sessionCount);
      return; // Return early, don't show a recurring nudge on the same session
    }

    // --- 2. RECURRING SURFER PRO NUDGE ---
    // Rule: Only after session 7, only if they've seen the first insight prompt, and only every 3 sessions after last shown.
    final bool isNudgeDue = (sessionCount - lastShown) >= 3;
    final bool isMinimumSessionMet = sessionCount >= 7;
    final bool hasClearedFirstMilestone = seenFirstPrompt || usedFirstFree;

    final bool shouldShowRecurringNudge = 
        !isPro && 
        isMinimumSessionMet && 
        hasClearedFirstMilestone && 
        isNudgeDue && 
        lastShown != sessionCount;

    debugPrint('[NudgeAudit] shouldShowRecurringNudge: $shouldShowRecurringNudge (Reason: isDue=$isNudgeDue, minMet=$isMinimumSessionMet, clearedMilestone=$hasClearedFirstMilestone)');

    if (shouldShowRecurringNudge) {
      debugPrint('[NudgeAudit] TRIGGER: Recurring Surfer Pro Nudge');
      _triggerRecurringSurferProNudge(sessionCount);
      return;
    }

    // --- 3. PASSPORT PROMPT (Session 1 only) ---
    if (sessionCount == 1 && !widget.hasSeenPostFirstSessionPassportPrompt) {
      debugPrint('[NudgeAudit] TRIGGER: Passport Prompt');
      _triggerPassportPrompt();
    }
  }

  void _triggerFirstInsightPrompt(int sessionCount) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Text(
          t("Get your first surf insight", "Tu primer insight de surf"),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        content: Text(
          t(
            "We turned your session into a quick insight. Take a look, then decide if you want more.",
            "Convertimos tu sesión en un insight rápido. Échale un vistazo y decide si quieres más.",
          ),
          style: const TextStyle(color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Primary CTA — value first
              FilledButton(
                onPressed: () async {
                  debugPrint('[FirstInsight] See my insight tapped');
                  debugPrint('[FirstInsight] Dismissing first insight modal');
                  Navigator.pop(ctx);

                  // Mark prompt as seen so it won't re-trigger
                  if (widget.onInsightPromptSeen != null) widget.onInsightPromptSeen!();
                  if (widget.onSurferProNudgeSeen != null) widget.onSurferProNudgeSeen!(sessionCount);

                  // Get the most recent completed session
                  final latestSession = widget.logs.isNotEmpty
                      ? widget.logs.firstWhere(
                          (e) => e.isCompleted,
                          orElse: () => widget.logs.first,
                        )
                      : null;

                  if (latestSession == null) {
                    debugPrint('[FirstInsight] Reflection failed: no session found');
                    return;
                  }

                  debugPrint('[FirstInsight] Opening reflection for sessionId: ${latestSession.id}');

                  try {
                    // openAddSessionSheet with startStep=1 opens the reflection form,
                    // then on submit calls _handleGenerateInsight which shows InsightPayoffScreen
                    await openAddSessionSheet(
                      existing: latestSession,
                      startStep: 1,
                      skipSuccessScreen: true,
                    );
                    debugPrint('[FirstInsight] Reflection opened successfully');
                  } catch (e) {
                    debugPrint('[FirstInsight] Reflection failed: $e');
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  t("See my insight", "Ver mi insight"),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(height: 8),
              // Secondary CTA — trial, deprioritized
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (widget.onInsightPromptSeen != null) widget.onInsightPromptSeen!();
                  openSurferProPaywall(context, source: 'first_insight_modal', isSpanish: widget.isSpanish);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  t("Start 3-day free trial", "Comenzar prueba de 3 días"),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              // Tertiary — not now
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (widget.onInsightPromptSeen != null) widget.onInsightPromptSeen!();
                  if (widget.onSurferProNudgeSeen != null) widget.onSurferProNudgeSeen!(sessionCount);
                },
                child: Text(
                  t("Keep surfing", "Seguir surfeando"),
                  style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _triggerRecurringSurferProNudge(int sessionCount) {
    String bodyText;
    if (sessionCount >= 13) {
      bodyText = t(
        "You’re starting to form real patterns. Unlock deeper insights to see what’s actually improving each session.",
        "Estás empezando a formar patrones reales. Desbloquea insights más profundos para ver qué está mejorando realmente cada sesión.",
      );
    } else if (sessionCount >= 7) {
      bodyText = t(
        "You’re building consistency. Unlock deeper insights to see what’s actually improving each session.",
        "Estás construyendo consistencia. Desbloquea insights más profundos para ver qué está mejorando realmente cada sesión.",
      );
    } else {
      bodyText = t(
        "You’re starting to build a rhythm. Unlock deeper insights to see what’s actually improving each session.",
        "Estás empezando a construir un ritmo. Desbloquea insights más profundos para ver qué está mejorando realmente cada sesión.",
      );
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Text(
          t("You're building real momentum", "Estás ganando impulso real"),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        content: Text(
          bodyText,
          style: const TextStyle(color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (widget.onSurferProNudgeSeen != null) widget.onSurferProNudgeSeen!(sessionCount);
                  openSurferProPaywall(context, source: 'momentum_modal', isSpanish: widget.isSpanish);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  t("Unlock Surfer Pro", "Desbloquear Surfer Pro"),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (widget.onSurferProNudgeSeen != null) widget.onSurferProNudgeSeen!(sessionCount);
                },
                child: Text(
                  t("Not now", "Ahora no"),
                  style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _triggerPassportPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Text(t("Nice start", "Buen comienzo"), 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))
        ),
        content: Text(t(
          "Want to set up your Surf Passport so it reflects where you’re at?",
          "¿Quieres configurar tu Pasaporte de Surf para que refleje tu nivel?"
        ), style: const TextStyle(color: Color(0xFF475569))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onPassportPromptSeen();

              if (!widget.hasSeenPostPassportProfilePrompt) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) _triggerProfileInfoPrompt();
                });
              }
            },
            child: Text(t("Skip for now", "Saltar por ahora"), style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onPassportPromptSeen();
              _openSurfPassportEdit();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(t("Set up Passport", "Configurar Pasaporte")),
          ),
        ],
      ),
    );
  }



  void _openSurfPassportEdit() {
    SurfPassportEditSheet.show(
      context,
      isSpanish: widget.isSpanish,
      levelEnTitle: widget.levelEnTitle,
      levelEnDesc: widget.levelEnDesc,
      comfortEn: widget.comfortEn,
      boardEn: widget.boardEn,
      focusEn: widget.focusEn,
      units: widget.units,
      initialAction: null,
      onUpdate: ({
        required String levelEnTitle,
        required String levelEnDesc,
        required String comfortEn,
        required String boardEn,
        required List<String> focusEn,
      }) {
        widget.onUpdateProfile(
          levelEnTitle: levelEnTitle,
          levelEnDesc: levelEnDesc,
          comfortEn: comfortEn,
          boardEn: boardEn,
          focusEn: focusEn,
          stance: widget.stance,
          height: widget.height,
          weight: widget.weight,
          location: widget.location,
          displayName: widget.displayName,
          profilePhotoPath: widget.profilePhotoPath,
          stanceVisibleToCoach: widget.stanceVisibleToCoach,
          stanceVisibleOnDashboard: widget.stanceVisibleOnDashboard,
          heightVisibleToCoach: widget.heightVisibleToCoach,
          heightVisibleOnDashboard: widget.heightVisibleOnDashboard,
          weightVisibleToCoach: widget.weightVisibleToCoach,
          weightVisibleOnDashboard: widget.weightVisibleOnDashboard,
          locationVisibleToCoach: widget.locationVisibleToCoach,
          locationVisibleOnDashboard: widget.locationVisibleOnDashboard,
          ageVisibleToCoach: widget.ageVisibleToCoach,
          ageVisibleOnDashboard: widget.ageVisibleOnDashboard,
          sessionsSurfed: widget.logs.length,
          lastSurfedDate: widget.logs.isNotEmpty ? widget.logs.first.date : null,
          age: widget.age,
          surferSummary: widget.surferSummary,
          units: widget.units,
        );

        if (!widget.hasSeenPostPassportProfilePrompt) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _triggerProfileInfoPrompt();
          });
        }
      },
    );
  }

  void _triggerProfileInfoPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Text(t("Want to add profile info?", "¿Quieres añadir información a tu perfil?"), 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))
        ),
        content: Text(t(
          "Add optional details like stance, age, height, location, and a short summary. You choose what appears on your Passport.",
          "Añade detalles opcionales como posición, edad, altura, ubicación y un breve resumen. Tú eliges qué aparece en tu Pasaporte."
        ), style: const TextStyle(color: Color(0xFF475569))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onProfileInfoPromptSeen();
            },
            child: Text(t("Skip for now", "Saltar por ahora"), style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onProfileInfoPromptSeen();
              _openProfileInfoEdit();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(t("Add profile info", "Añadir info de perfil")),
          ),
        ],
      ),
    );
  }

  void _openProfileInfoEdit() {
    ProfileInfoEditSheet.show(
      context,
      isSpanish: widget.isSpanish,
      stance: widget.stance,
      height: widget.height,
      weight: widget.weight,
      location: widget.location,
      age: widget.age,
      surferSummary: widget.surferSummary,
      displayName: widget.displayName,
      stanceVisibleToCoach: widget.stanceVisibleToCoach,
      stanceVisibleOnDashboard: widget.stanceVisibleOnDashboard,
      heightVisibleToCoach: widget.heightVisibleToCoach,
      heightVisibleOnDashboard: widget.heightVisibleOnDashboard,
      weightVisibleToCoach: widget.weightVisibleToCoach,
      weightVisibleOnDashboard: widget.weightVisibleOnDashboard,
      locationVisibleToCoach: widget.locationVisibleToCoach,
      locationVisibleOnDashboard: widget.locationVisibleOnDashboard,
      ageVisibleToCoach: widget.ageVisibleToCoach,
      ageVisibleOnDashboard: widget.ageVisibleOnDashboard,
      onUpdate: ({
        required String stance,
        required String height,
        required String weight,
        required String location,
        required String age,
        required String surferSummary,
        required String displayName,
        required bool stanceVisibleToCoach,
        required bool stanceVisibleOnDashboard,
        required bool heightVisibleToCoach,
        required bool heightVisibleOnDashboard,
        required bool weightVisibleToCoach,
        required bool weightVisibleOnDashboard,
        required bool locationVisibleToCoach,
        required bool locationVisibleOnDashboard,
        required bool ageVisibleToCoach,
        required bool ageVisibleOnDashboard,
        required String? profilePhotoPath,
      }) {
        widget.onUpdateProfile(
          stance: stance,
          height: height,
          weight: weight,
          location: location,
          age: age,
          surferSummary: surferSummary,
          levelEnTitle: widget.levelEnTitle,
          levelEnDesc: widget.levelEnDesc,
          comfortEn: widget.comfortEn,
          boardEn: widget.boardEn,
          focusEn: widget.focusEn,
          displayName: displayName,
          profilePhotoPath: profilePhotoPath,
          stanceVisibleToCoach: stanceVisibleToCoach,
          stanceVisibleOnDashboard: stanceVisibleOnDashboard,
          heightVisibleToCoach: heightVisibleToCoach,
          heightVisibleOnDashboard: heightVisibleOnDashboard,
          weightVisibleToCoach: weightVisibleToCoach,
          weightVisibleOnDashboard: weightVisibleOnDashboard,
          locationVisibleToCoach: locationVisibleToCoach,
          locationVisibleOnDashboard: locationVisibleOnDashboard,
          ageVisibleToCoach: ageVisibleToCoach,
          ageVisibleOnDashboard: ageVisibleOnDashboard,
          sessionsSurfed: widget.logs.length,
          lastSurfedDate: widget.logs.isNotEmpty ? widget.logs.first.date : null,
          units: widget.units,
        );
      },
    );
  }

  Widget _buildReflectionField({required String label, required TextEditingController controller, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: AppTheme.surfaceVariant.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final combined = <dynamic>[
      ...widget.logs,
    ]..sort((a, b) => (b.date as DateTime).compareTo(a.date as DateTime));

    return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildHeroHeader(),
                    const SizedBox(height: 60),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        children: [
                          ...combined.map((item) {
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
                                hasUsedFirstFreeAIInsight: widget.hasUsedFirstFreeAIInsight,
                                onAdd: widget.onAdd,
                                logs: widget.logs,
                                onAnalyze: () => _handleGenerateInsight(e),
                                onOpenSurferPro: widget.onOpenSurferPro,
                                onInsightViewed: widget.onInsightViewed,
                              ),
                            );
                          }),
                          
                          if (widget.logs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const FloatAnimator(
                                      child: Icon(Icons.waves_rounded, size: 54, color: AppTheme.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Text(
                                    t("Your Surf Journal", "Tu Diario de Surf"),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, height: 1.1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t("Track. Understand. Improve.", "Registra. Entiende. Mejora."),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 16),
                                  MicroTipBanner(
                                    prefKey: 'seen_history_guidance',
                                    message: t("Log your first surf and see what your surfing is really telling you.", "Registra tu primer surf y mira lo que tu surf realmente te está diciendo."),
                                    dismissLabel: t("Got it", "Entendido"),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120), // Padding for FloatingActionButton
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  int _calculateStreak(List<SessionLogEntry> logs) {
    if (logs.isEmpty) return 0;
    
    final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
    
    int streak = 0;
    DateTime lastDate = DateTime.now();
    
    DateTime toDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
    
    DateTime currentCheck = toDate(lastDate);
    
    for (var session in sorted) {
      final sessionDate = toDate(session.date);
      if (sessionDate == currentCheck) {
        streak++;
        currentCheck = currentCheck.subtract(const Duration(days: 1));
      } else if (sessionDate.isBefore(currentCheck)) {
        break;
      }
    }
    
    return streak;
  }

  Widget _buildHeroHeader() {
    final completedLogs = widget.logs.where((e) => e.isCompleted).toList();
    final sessionsThisMonth = completedLogs.where((e) => 
      e.date.month == DateTime.now().month && 
      e.date.year == DateTime.now().year
    ).length;
    final currentStreak = _calculateStreak(completedLogs);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Teal Header Block
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primary, // Deep Sea Teal
                Color(0xFF0F172A), // Deep Navy
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 220), // Pushed image down further to clear text
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and Language Menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SmartSurfWordmark(
                        isInverse: true,
                        onTap: widget.onReturnToDashboard,
                      ),
                      LanguageMenu(
                        isSpanish: widget.isSpanish,
                        onSetLanguage: widget.onSetLanguage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Dynamic Greeting
                  Text(
                    _getDynamicGreeting(widget.displayName),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Main Heading
                  Text(
                    t("Ready to log your surf?", "¿Listo para registrar tu surf?"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (completedLogs.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _HeaderStat(
                          label: t("This month", "Este mes"),
                          value: "$sessionsThisMonth",
                          isDark: false,
                        ),
                        const SizedBox(width: 32),
                        _HeaderStat(
                          label: t("Current streak", "Racha actual"),
                          value: "$currentStreak",
                          isDark: false,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // 2. Overlapping 'Poke Out' Image
        Positioned(
          bottom: -50, // Pokes out over the edge
          left: 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/abstract_surf_journey_calm_1778022747498.png',
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleGenerateInsight(SessionLogEntry entry) async {
    if (widget.onGenerateInsight == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 24),
                Text(
                  t("Analyzing your session...", "Analizando tu sesión..."),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final updated = await widget.onGenerateInsight!(entry);
      
      if (mounted) {
        Navigator.pop(context);
      }

      if (updated != null && mounted) {
        if (widget.onFirstFreeAIInsightUsed != null && !widget.hasUsedFirstFreeAIInsight) {
           widget.onFirstFreeAIInsightUsed!();
        }
        
        _SessionDetailSheet.show(
          context,
          isSpanish: widget.isSpanish,
          session: updated,
          isSurferPro: widget.isSurferPro,
          hasUsedFirstFreeAIInsight: widget.hasUsedFirstFreeAIInsight,
          units: widget.units,
          onAdd: widget.onAdd,
          logs: widget.logs,
          onInsightViewed: widget.onInsightViewed,
          onOpenSurferPro: widget.onOpenSurferPro,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t("We couldn't generate your insight yet. Please try again.", "No pudimos generar tu insight aún. Por favor intenta de nuevo.")),
        ));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t("An error occurred. Please check your connection.", "Ocurrió un error. Por favor revisa tu conexión.")),
        ));
      }
    }
  }
}

class _PreSurfCheckInCard extends StatefulWidget {
  final bool isSpanish;
  final String units;
  final Function(SessionLogEntry) onStart;

  const _PreSurfCheckInCard({required this.isSpanish, required this.onStart, required this.units});

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
                label: Text(
                  widget.units == 'metric' 
                    ? (widget.isSpanish ? (m["metric_es"] ?? m["es"]!) : (m["metric_en"] ?? m["en"]!))
                    : (widget.isSpanish ? m["es"]! : m["en"]!),
                  style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)
                ),
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
              ...SurfConstants.masterFocusSkills.map((m) {
                final focus = m["en"]!;
                final isSelected = selectedFocus == focus;
                return ChoiceChip(
                  label: Text(t(focus, m["es"]!), style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => selectedFocus = focus);
                  },
                );
              }),
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

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _HeaderStat({required this.label, required this.value, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.textPrimary : Colors.white;
    final labelColor = isDark ? AppTheme.textMuted : Colors.white70;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
        Text(label, style: TextStyle(fontSize: 12, color: labelColor, fontWeight: FontWeight.w600)),
      ],
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

  String _formatDate(DateTime d) {
    const monthsEn = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dic"];
    const monthsEs = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
    final mIndex = (d.month - 1).clamp(0, 11);
    final m = isSpanish ? monthsEs[mIndex] : monthsEn[mIndex];
    return "$m ${d.day}";
  }

  @override
  Widget build(BuildContext context) {
    final spotName = session.spotName.isNotEmpty && session.spotName != t("Current Session", "Sesión Actual")
        ? session.spotName
        : t("Surf Session", "Sesión de Surf");

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          spotName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(session.date),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${SurfConstants.getWaveHeightTranslation(session.waveSize, isSpanish, units: units)} · ${SurfConstants.getBoardTranslation(session.board, isSpanish).split(" · ").first}",
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  if (session.sessionFocus.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "🎯 ${SurfConstants.getFocusSkillTranslation(session.sessionFocus, isSpanish)}",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (session.notes.isNotEmpty)
                    Text(
                      session.notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
            if (session.mediaPath != null) ...[
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: MediaCard(
                    isSpanish: isSpanish,
                    state: session.mediaType == 'video' ? MediaCardState.video : MediaCardState.image,
                    mediaPath: session.mediaPath,
                    mediaType: session.mediaType,
                    isEditable: false,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _SessionDetailSheet extends StatefulWidget {
  final SessionLogEntry session;
  final bool isSpanish;
  final String units;
  final bool isSurferPro;
  final bool hasUsedFirstFreeAIInsight;
  final Function(SessionLogEntry) onAdd;
  final List<SessionLogEntry> logs;
  final bool autoGenerate;
  final VoidCallback? onAnalyze;
  final Function({String? title, String? content, bool isSoftUpsell, VoidCallback? onSeeThisOneFirst})? onOpenSurferPro;
  final VoidCallback? onInsightViewed;

  const _SessionDetailSheet({
    super.key,
    required this.session,
    required this.isSpanish,
    required this.units,
    required this.isSurferPro,
    required this.hasUsedFirstFreeAIInsight,
    required this.onAdd,
    required this.logs,
    this.autoGenerate = false,
    this.onAnalyze,
    this.onOpenSurferPro,
    this.onInsightViewed,
  });

  static void show(BuildContext context, {
    required SessionLogEntry session, 
    required bool isSpanish, 
    required String units, 
    required bool isSurferPro,
    required bool hasUsedFirstFreeAIInsight,
    required Function(SessionLogEntry) onAdd,
    required List<SessionLogEntry> logs,
    bool autoGenerate = false,
    VoidCallback? onAnalyze,
    Function({String? title, String? content, bool isSoftUpsell, VoidCallback? onSeeThisOneFirst})? onOpenSurferPro,
    VoidCallback? onClose,
    VoidCallback? onInsightViewed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => _SessionDetailSheet(
        session: session,
        isSpanish: isSpanish,
        units: units,
        isSurferPro: isSurferPro,
        hasUsedFirstFreeAIInsight: hasUsedFirstFreeAIInsight,
        onAdd: onAdd,
        logs: logs,
        autoGenerate: autoGenerate,
        onAnalyze: onAnalyze,
        onOpenSurferPro: onOpenSurferPro,
        onInsightViewed: onInsightViewed,
      ),
    ).then((_) {
      if (onClose != null) onClose();
    });
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
    
    // Increment viewed count if this session already has an insight
    if (!widget.isSurferPro && 
        (_currentSession.aiSummaryEn != null || _currentSession.aiSummaryEs != null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.onInsightViewed != null) {
          widget.onInsightViewed!();
        }
      });
    }
  }

  String t(String en, String es) => widget.isSpanish ? es : en;



  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          color: Colors.white,
          child: SingleChildScrollView(
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
              if (_currentSession.reflectionFeltOff?.isNotEmpty == true) ...[
                _buildField(t("What felt off?", "¿Qué se sintió mal?"), "📉 " + t(_currentSession.reflectionFeltOff!, _currentSession.reflectionFeltOff == 'Timing' ? 'Sincronización' : _currentSession.reflectionFeltOff == 'Positioning' ? 'Posicionamiento' : 'Confianza')),
                const SizedBox(height: 20),
              ],
              
              if ((_currentSession.aiNextFocusEn == null || _currentSession.aiNextFocusEn!.isEmpty) && 
                  (_currentSession.aiNextFocusEs == null || _currentSession.aiNextFocusEs!.isEmpty) &&
                  (_currentSession.aiNextFocus == null || _currentSession.aiNextFocus!.isEmpty)) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isGenerating ? null : () async {
                      // No immediate gate for the VERY first one
                      // The gating only happens if they've ALREADY used their first free one
                      if (!widget.isSurferPro && widget.hasUsedFirstFreeAIInsight) {
                        openSurferProPaywall(context, source: 'insight_payoff_cta', isSpanish: widget.isSpanish);
                        return;
                      }

                      setState(() => _isGenerating = true);
                      if (widget.onAnalyze != null) {
                        widget.onAnalyze!();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isGenerating 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(t("Generate AI Insight", "Generar Insight de IA")),
                  ),
                ),
                if (_isGenerating) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      widget.hasUsedFirstFreeAIInsight 
                        ? t("Analyzing your session...", "Analizando tu sesión...")
                        : t("We're generating your first insight. This takes a few seconds.", "Estamos generando tu primer insight. Esto toma unos segundos."),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ] else ...[
                // Show insights if they exist (regardless of Pro status if already generated)
                if (widget.isSpanish ? _currentSession.aiSummaryEs != null || _currentSession.aiSummary != null : _currentSession.aiSummaryEn != null || _currentSession.aiSummary != null) ...[
                  // Focus Tag Pill
                  if (widget.isSpanish ? _currentSession.aiFocusTagEs != null : _currentSession.aiFocusTagEn != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1.5),
                      ),
                      child: Text(
                        (widget.isSpanish ? _currentSession.aiFocusTagEs : _currentSession.aiFocusTagEn)!.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildInsightCard(
                    context: context,
                    label: t("SESSION INSIGHT", "INSIGHT DE LA SESIÓN"),
                    content: widget.isSpanish 
                        ? (_currentSession.aiSummaryEs ?? _currentSession.aiSummary ?? "") 
                        : (_currentSession.aiSummaryEn ?? _currentSession.aiSummary ?? ""),
                    isPrimary: false,
                  ),
                  const SizedBox(height: 16),
                  _buildInsightCard(
                    context: context,
                    label: t("PROGRESS PATTERN", "PATRÓN DE PROGRESO"),
                    content: widget.isSpanish
                        ? (_currentSession.aiProgressPatternEs ?? _currentSession.aiProgressPattern ?? t("Estás empezando a construir un patrón. Unas cuantas sesiones más lo harán más claro.", "You're starting to build a pattern. A few more sessions will make this clearer."))
                        : (_currentSession.aiProgressPatternEn ?? _currentSession.aiProgressPattern ?? "You're starting to build a pattern. A few more sessions will make this clearer."),
                    isPrimary: false,
                  ),
                  const SizedBox(height: 16),
                  _buildInsightCard(
                    context: context,
                    label: t("NEXT SESSION FOCUS", "ENFOQUE PARA LA PRÓXIMA SESIÓN"),
                    content: widget.isSpanish
                        ? (_currentSession.aiNextFocusEs ?? _currentSession.aiNextFocus ?? "")
                        : (_currentSession.aiNextFocusEn ?? _currentSession.aiNextFocus ?? ""),
                    isPrimary: true,
                  ),
                ],
              ],
              if (!widget.isSurferPro && (_currentSession.aiNextFocusEn != null || _currentSession.aiNextFocusEs != null)) ...[
                const SizedBox(height: 32),
                _buildInlineUpgradeCard(context),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      );
    },
    );
  }

  Widget _buildInlineUpgradeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            t("want this after every session?", "¿quieres esto después de cada sesión?"),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t("keep building your rhythm with simple insights each time you surf", 
              "sigue construyendo tu ritmo con insights sencillos cada vez que surfees"),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary.withOpacity(0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () {
                debugPrint("PAYWALL CTA tapped from insight_cta");
                debugPrint("Opening Surfer Pro paywall from insight_cta");
                openSurferProPaywall(context, source: 'insight_cta', isSpanish: widget.isSpanish);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                t("start free trial", "empezar prueba gratis"),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
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
          _buildInfoItem("🌊", t("Waves", "Olas"), SurfConstants.getWaveHeightTranslation(_currentSession.waveSize, widget.isSpanish, units: widget.units)),
        if (_currentSession.board.isNotEmpty)
          _buildInfoItem("🏄", t("Board", "Tabla"), SurfConstants.getBoardTranslation(_currentSession.board, widget.isSpanish)),
        if (_currentSession.waveSize != null && _currentSession.waveSize!.isNotEmpty)
          _buildInfoItem("🌊", t("Conditions", "Condiciones"), 
            "${SurfConstants.getWaveHeightTranslation(_currentSession.waveSize, widget.isSpanish, units: widget.units)} · ${SurfConstants.getConditionTranslation(_currentSession.reflectionConditions, widget.isSpanish)}"),
        if (_currentSession.durationMins > 0)
          _buildInfoItem("⏱", t("Duration", "Duración"), "${_currentSession.durationMins}m"),
        if (_currentSession.rating > 0)
          _buildInfoItem("⭐", t("Rating", "Valoración"), "${_currentSession.rating}/5"),
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
        color: isPrimary ? AppTheme.primaryContainer : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPrimary ? AppTheme.primary.withOpacity(0.3) : Colors.grey.shade200,
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



// Removed unused _SessionMeta


