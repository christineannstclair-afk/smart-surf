import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../ui_system/spacing.dart';
import '../../widgets/smart_surf_wordmark.dart';
import '../../widgets/language_menu.dart';
import 'passport_presets.dart';
import '../home/video_preview_modal.dart';
import '../session_log/firebase_service.dart';
import '../session_log/session_log_entry.dart';
import '../../ui_system/spacing.dart';
import '../../ui_system/app_card.dart';
import '../../ui_system/media_card.dart';
import '../../ui_system/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../models/surf_dashboard_data.dart';
import '../../widgets/micro_tip_banner.dart';
import '../Settings/settings_models.dart';
import '../../ui_system/surf_constants.dart';
import 'surf_passport_edit_sheet.dart';
import 'profile_info_edit_sheet.dart';

class SurfPassportScreen extends StatefulWidget {
  final bool isSpanish;
  final void Function(bool) onSetLanguage;
  final String levelEnTitle;
  final String levelEnDesc;
  final String comfortEn;
  final String boardEn;
  final List<String> focusEn;
  final String displayName;
  final String? profilePhotoPath;
  final String stance;
  final String height;
  final String weight;
  final String location;
  final String age;
  final String surferSummary;
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
  final String? latestMediaPath;
  final String? latestMediaType;
  final int sessionsSurfed;
  final DateTime? lastSurfedDate;
  final String units;
  final bool seenPassportPrompt;
  final VoidCallback onPromptDismissed;
  final List<SessionLogEntry> logs;
  final VoidCallback? onReturnToDashboard;

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
    required bool ageVisibleToCoach,
    required bool ageVisibleOnDashboard,
    required int sessionsSurfed,
    required DateTime? lastSurfedDate,
    String? latestMediaPath,
    String? latestMediaType,
    required String units,
  }) onUpdate;

  const SurfPassportScreen({
    super.key,
    required this.isSpanish,
    required this.onSetLanguage,
    required this.levelEnTitle,
    required this.levelEnDesc,
    required this.comfortEn,
    required this.boardEn,
    required this.focusEn,
    required this.displayName,
    this.profilePhotoPath,
    required this.stance,
    required this.height,
    required this.weight,
    required this.location,
    required this.age,
    this.surferSummary = '',
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
    this.latestMediaPath,
    this.latestMediaType,
    required this.sessionsSurfed,
    required this.lastSurfedDate,
    required this.units,
    required this.onUpdate,
    required this.onPromptDismissed,
    required this.seenPassportPrompt,
    required this.hasSeenPassportGuidance,
    required this.onGuidanceDismissed,
    required this.logs,
    this.onReturnToDashboard,
  });

  final bool hasSeenPassportGuidance;
  final void Function(String type) onGuidanceDismissed;

  @override
  State<SurfPassportScreen> createState() => SurfPassportScreenState();
}

class SurfPassportScreenState extends State<SurfPassportScreen> {
  final GlobalKey _passportAnchorKey = GlobalKey();
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    FirebaseService().logEvent('surf_passport_viewed');
  }

  String _t(String en, String es) => widget.isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Ocean
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.secondary,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E293B),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );

    final levelTitle = PassportPresets.levelTitle(isSpanish: widget.isSpanish, enTitle: widget.levelEnTitle);
    final levelDesc = PassportPresets.levelDesc(isSpanish: widget.isSpanish, enTitle: widget.levelEnTitle, enDescFallback: widget.levelEnDesc);
    final comfortLabel = PassportPresets.mapValue(isSpanish: widget.isSpanish, units: widget.units, list: PassportPresets.comfortZones, enValue: widget.comfortEn);
    final boardLabel = PassportPresets.mapValue(isSpanish: widget.isSpanish, units: widget.units, list: PassportPresets.boards, enValue: widget.boardEn);
    final focus = PassportPresets.normalizeFocus(widget.focusEn);

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 50,
          titleSpacing: 16,
          centerTitle: false,
          title: SmartSurfWordmark(
            isInverse: true,
            onTap: widget.onReturnToDashboard,
          ),
          actions: [
            LanguageMenu(isSpanish: widget.isSpanish, onSetLanguage: widget.onSetLanguage),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.seenPassportPrompt)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488), // Teal
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t("Your Surf Passport is a quick snapshot of your level, board, comfort zone, and focus skills. Share it with a coach or surf school.", 
                                   "Tu Pasaporte de Surf es un resumen rápido de tu nivel, tabla, zona de confort y habilidades a mejorar. Compártelo con un entrenador o escuela de surf."),
                                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: widget.onPromptDismissed,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: Text(
                                    _t("Got it", "Entendido"),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        color: const Color(0xFF0F172A),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Latest Session Media (Dynamic fetch: most recent with media)
                            _buildLastSessionMediaHeader(),
                            
                            // Identity Block
                            _buildIdentityRow(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _t("A quick snapshot of your surfing level, setup, and recent sessions.", 
                                       "Un resumen rápido de tu nivel de surf, equipo y sesiones recientes."),
                                    style: TextStyle(
                                      fontSize: 14, 
                                      color: Colors.white.withOpacity(0.8),
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: _sharePassport,
                                    icon: const Icon(Icons.ios_share, size: 18),
                                    label: Text(_t("Share Passport", "Compartir Passport")),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.secondary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const SizedBox(height: 6),

                            // Hero Level Block
                            _buildLevelHero(levelTitle, levelDesc),
                            const SizedBox(height: 12),

                            // Snapshot Grid
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.7,
                              children: [
                                _InfoBlock(
                                  title: _t("Comfort Zone", "Zona de confort"),
                                  value: comfortLabel,
                                  icon: Icons.waves_rounded,
                                  onEdit: () => openEditModal(action: 'comfort'),
                                ),
                                _InfoBlock(
                                  title: _t("Board", "Tabla"),
                                  value: boardLabel,
                                  icon: Icons.straighten_outlined,
                                  onEdit: () => openEditModal(action: 'board'),
                                ),
                                _InfoBlock(title: _t("Sessions Logged", "Sesiones"), value: widget.sessionsSurfed.toString(), icon: Icons.history_edu_rounded),
                                _InfoBlock(title: _t("Last Surfed", "Última vez"), value: _fmtShortDate(widget.lastSurfedDate), icon: Icons.calendar_today_rounded),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildFocusSkillsSection(focus),

                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Share Button
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityRow() {
    final bool isVideoProfile = widget.profilePhotoPath?.toLowerCase().endsWith('.mp4') == true ||
                                widget.profilePhotoPath?.toLowerCase().endsWith('.mov') == true ||
                                widget.profilePhotoPath?.startsWith('video:') == true;

    final ImageProvider? profileImage = (widget.profilePhotoPath?.isNotEmpty == true && !isVideoProfile)
        ? (widget.profilePhotoPath!.startsWith('http') || widget.profilePhotoPath!.startsWith('data:image')
            ? NetworkImage(widget.profilePhotoPath!)
            : null)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: openProfileInfoModal,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF334155),
                          backgroundImage: profileImage,
                          onBackgroundImageError: profileImage != null
                              ? (exception, stackTrace) => debugPrint("Profile photo error: $exception")
                              : null,
                          child: profileImage == null 
                            ? const Icon(Icons.person, size: 30, color: Colors.white24) 
                            : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.displayName.isEmpty ? _t("Complete your profile", "Completa tu perfil") : widget.displayName,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: SurfDashboardData(
                                  levelTitle: widget.levelEnTitle,
                                  levelDesc: widget.levelEnDesc,
                                  comfortZone: widget.comfortEn,
                                  board: widget.boardEn,
                                  focusSkills: widget.focusEn,
                                  age: widget.age,
                                  displayName: widget.displayName,
                                  profilePhotoPath: widget.profilePhotoPath,
                                  surferSummary: widget.surferSummary,
                                  stance: widget.stance,
                                  height: widget.height,
                                  weight: widget.weight,
                                  location: widget.location,
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
                                ).getVisibleProfileFields(widget.isSpanish).map((field) {
                                  IconData icon = Icons.info_outline;
                                  switch (field['label']?.toLowerCase()) {
                                    case 'stance': 
                                    case 'posición':
                                      icon = Icons.directions_run_rounded; break;
                                    case 'location': 
                                    case 'ubicación':
                                    case 'local':
                                      icon = Icons.location_on_outlined; break;
                                    case 'height': 
                                    case 'altura':
                                      icon = Icons.straighten_rounded; break;
                                    case 'weight': 
                                    case 'peso':
                                      icon = Icons.monitor_weight_outlined; break;
                                    case 'age': 
                                    case 'edad':
                                      icon = Icons.cake_outlined; break;
                                  }
                                  return _inlineMeta(icon, field['value'] ?? '');
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Icon(Icons.edit_outlined, size: 18, color: Colors.white.withOpacity(0.35)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelHero(String title, String desc, {Key? key}) {
    final bool isUnset = widget.levelEnTitle.isEmpty || widget.levelEnTitle == "None";
    
    return Stack(
      key: key,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.secondary.withOpacity(0.25), const Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.secondary.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: AppTheme.secondary.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: InkWell(
            onTap: () => openEditModal(action: 'level'),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t("SURF LEVEL", "NIVEL DE SURF"),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.secondary.withOpacity(0.95), letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isUnset ? _t("Tap to set your surf level", "Toca para definir tu nivel") : title,
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.w900, 
                      color: isUnset ? Colors.white38 : Colors.white, 
                      letterSpacing: -0.5
                    ),
                  ),
                  if (!isUnset) ...[
                    const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: IgnorePointer(
            child: Icon(Icons.edit_outlined, size: 18, color: Colors.white.withOpacity(0.35)),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusSkillsSection(List<String> focus) {
    return AppCard(
      onTap: () => openEditModal(action: 'focus'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _t("CURRENT FOCUS", "ENFOQUE ACTUAL").toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.secondary, letterSpacing: 1.2),
              ),
              IgnorePointer(
                child: Icon(Icons.edit_outlined, size: 18, color: Colors.white.withOpacity(0.35)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          () {
            // Find latest AI Focus/Next Focus
            String? latestAiFocus;
            if (widget.logs.isNotEmpty) {
              try {
                final lastWithAi = widget.logs.firstWhere((l) => 
                  widget.isSpanish 
                    ? (l.aiFocusTagEs?.isNotEmpty == true || l.aiNextFocusEs?.isNotEmpty == true)
                    : (l.aiFocusTagEn?.isNotEmpty == true || l.aiNextFocusEn?.isNotEmpty == true)
                );
                latestAiFocus = widget.isSpanish 
                  ? (lastWithAi.aiFocusTagEs ?? lastWithAi.aiNextFocusEs)
                  : (lastWithAi.aiFocusTagEn ?? lastWithAi.aiNextFocusEn);
              } catch (_) {}
            }

            if (latestAiFocus == null && focus.isEmpty) {
              return Text(_t("Add what you're working on", "Agrega en qué estás trabajando"), style: const TextStyle(color: Colors.white38, fontSize: 13));
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (latestAiFocus != null)
                  _FocusChip(
                    label: latestAiFocus,
                    isPrimary: true,
                  ),
                ...focus.map((en) => _FocusChip(label: PassportPresets.focusLabel(isSpanish: widget.isSpanish, enSkill: en))),
              ],
            );
          }(),
        ],
      ),
    );
  }

  // Removed _saveToPersistentStorage since we now use Firebase

  Widget _buildMediaSection() {
    final hasMedia = widget.latestMediaPath != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t("LATEST SESSION MEDIA", "ÚLTIMO MEDIA").toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.secondary, letterSpacing: 1.2),
        ),
        const SizedBox(height: 10),
        MediaCard(
          isSpanish: widget.isSpanish,
          isEditable: false,
          state: !hasMedia ? MediaCardState.empty : (widget.latestMediaType == 'video' ? MediaCardState.video : MediaCardState.image),
          onAddMedia: null, // Read-only for MVP
          onTap: () {
            if (widget.latestMediaType == 'video' && widget.latestMediaPath != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPreviewModal(
                    videoPath: widget.latestMediaPath!,
                    isSpanish: widget.isSpanish,
                  ),
                ),
              );
            }
          },
          mediaPath: widget.latestMediaPath,
          mediaType: widget.latestMediaType,
        ),
      ],
    );
  }

  Future<void> _sharePassport() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    FirebaseService().logEvent('export_passport');
    try {
      final uint8List = await _screenshotController.capture(pixelRatio: 2.0);
      if (uint8List != null) {
        final doc = pw.Document();
        final memoryImage = pw.MemoryImage(uint8List);
        
        final lastMediaSession = widget.logs
            .where((s) => s.mediaPath != null && s.mediaPath!.isNotEmpty)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        
        final String? sharingMediaUrl = lastMediaSession.isNotEmpty ? lastMediaSession.first.mediaPath : widget.latestMediaPath;
        final bool isSharingVideo = (lastMediaSession.isNotEmpty ? lastMediaSession.first.mediaType == 'video' : widget.latestMediaType == 'video');

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                 children: [
                    pw.Text("${widget.displayName ?? 'Surfer'}'s Surf Passport", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 15),
                    pw.Expanded(child: pw.Image(memoryImage, fit: pw.BoxFit.contain)),
                   
                    // Requirement: If there's an HTTPS video URL, embed a clickable hyperlink below the layout
                   if (sharingMediaUrl != null && isSharingVideo)
                     pw.Container(
                       margin: const pw.EdgeInsets.only(top: 20, bottom: 20),
                       child: pw.UrlLink(
                         destination: sharingMediaUrl,
                         child: pw.Text(_t("Watch video", "Ver video"), style: pw.TextStyle(
                           color: PdfColors.blue,
                           decoration: pw.TextDecoration.underline,
                           fontSize: 18,
                         )),
                       ),
                     ),
                ],
              );
            },
          ),
        );
        
        final pdfBytes = await doc.save();

        if (kIsWeb) {
          final xFile = XFile.fromData(pdfBytes, mimeType: 'application/pdf', name: 'surf_passport.pdf');
          await Share.shareXFiles([xFile], text: _t("Check out my Surf Passport!", "¡Mira mi Surf Passport!"));
        } else {
          final tempDir = await getTemporaryDirectory();
          final file = await File('${tempDir.path}/surf_passport.pdf').create();
          await file.writeAsBytes(pdfBytes);
          await Share.shareXFiles([XFile(file.path)], text: _t("Check out my Surf Passport!", "¡Mira mi Surf Passport!"));
        }
      }
    } catch (e) {
      debugPrint("Sharing PDF error: $e");
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }


  Widget _buildLastSessionMediaHeader() {
    // Find most recent session with mediaUrl, sorted by date descending
    final sessionsWithMedia = widget.logs
        .where((s) => s.mediaPath != null && s.mediaPath!.isNotEmpty)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final latestSession = sessionsWithMedia.isNotEmpty ? sessionsWithMedia.first : null;
    final String? mediaPath = latestSession?.mediaPath ?? widget.latestMediaPath;
    final String? mediaType = latestSession?.mediaType ?? widget.latestMediaType;
    final bool hasMedia = mediaPath != null;

    if (!hasMedia) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _t("LAST SESSION", "ÚLTIMA SESIÓN").toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.secondary, letterSpacing: 1.2),
              ),
              if (latestSession != null) ...[
                const SizedBox(width: 8),
                Text(
                  "• ${_fmtShortDate(latestSession.date)}",
                  style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          MediaCard(
            isSpanish: widget.isSpanish,
            isEditable: false,
            state: mediaType == 'video' ? MediaCardState.video : MediaCardState.image,
            onAddMedia: null,
            onTap: () {
              if (mediaType == 'video' && mediaPath != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPreviewModal(
                      videoPath: mediaPath,
                      isSpanish: widget.isSpanish,
                    ),
                  ),
                );
              }
            },
            mediaPath: mediaPath,
            mediaType: mediaType,
          ),
        ],
      ),
    );
  }

  Widget _inlineMeta(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.secondary),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtShortDate(DateTime? d) {
    if (d == null) return "—";
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  void openProfileInfoModal() {
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
      }) {
        widget.onUpdate(
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
          profilePhotoPath: widget.profilePhotoPath,
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
          sessionsSurfed: widget.sessionsSurfed,
          lastSurfedDate: widget.lastSurfedDate,
          units: widget.units,
        );
      },
    );
  }

  void openEditModal({String? action}) {
    SurfPassportEditSheet.show(
      context,
      isSpanish: widget.isSpanish,
      levelEnTitle: widget.levelEnTitle,
      levelEnDesc: widget.levelEnDesc,
      comfortEn: widget.comfortEn,
      boardEn: widget.boardEn,
      focusEn: widget.focusEn,
      units: widget.units,
      initialAction: action,
      onUpdate: ({
        required String levelEnTitle,
        required String levelEnDesc,
        required String comfortEn,
        required String boardEn,
        required List<String> focusEn,
      }) {
        widget.onUpdate(
          displayName: widget.displayName,
          stance: widget.stance,
          height: widget.height,
          weight: widget.weight,
          location: widget.location,
          age: widget.age,
          surferSummary: widget.surferSummary,
          levelEnTitle: levelEnTitle,
          levelEnDesc: levelEnDesc,
          comfortEn: comfortEn,
          boardEn: boardEn,
          focusEn: focusEn,
          profilePhotoPath: widget.profilePhotoPath,
          sessionsSurfed: widget.sessionsSurfed,
          lastSurfedDate: widget.lastSurfedDate,
          units: widget.units,
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
        );
      },
    );
  }



  Widget _buildSurfProgressSection() {
    // Collect the 2 most recent insights
    final sortedLogs = List<SessionLogEntry>.from(widget.logs)..sort((a, b) => b.date.compareTo(a.date));
    
    // Updated filter to look for either legacy or localized AI fields
    final targetInsights = sortedLogs.where((l) {
      final hasNextFocus = l.aiNextFocus != null || l.aiNextFocusEn != null || l.aiNextFocusEs != null;
      return hasNextFocus;
    }).take(2).toList();
    
    if (targetInsights.isEmpty) return const SizedBox.shrink();

    final latest = targetInsights.first;
    
    // Choose the best field based on current language
    final nextFocus = widget.isSpanish 
      ? (latest.aiNextFocusEs?.isNotEmpty == true ? latest.aiNextFocusEs! : (latest.aiNextFocus?.isNotEmpty == true ? latest.aiNextFocus! : ''))
      : (latest.aiNextFocusEn?.isNotEmpty == true ? latest.aiNextFocusEn! : (latest.aiNextFocus?.isNotEmpty == true ? latest.aiNextFocus! : ''));
      
    final progressPattern = widget.isSpanish
      ? (latest.aiProgressPatternEs?.isNotEmpty == true ? latest.aiProgressPatternEs! : latest.aiProgressPattern)
      : (latest.aiProgressPatternEn?.isNotEmpty == true ? latest.aiProgressPatternEn! : latest.aiProgressPattern);

    if (nextFocus.isEmpty && progressPattern == null) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t("Surf Progress", "Progreso de Surf").toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.secondary, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          if (nextFocus.isNotEmpty)
            _progressRow(_t("Recent Focus", "Foco Reciente"), nextFocus),
          if (progressPattern != null) ...[
            const SizedBox(height: 10),
            _progressRow(_t("Consistency Trend", "Tendencia de Consistencia"), progressPattern),
          ],
        ],
      ),
    );
  }

  Widget _progressRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4)),
      ],
    );
  }

  Widget _buildGuidanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _t("Passport: This is your shareable surf snapshot. Share it with coaches or friends!", 
                 "Passport: Este es tu resumen de surf para compartir. ¡Compártelo con coaches o amigos!"),
              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.white54),
            onPressed: () => widget.onGuidanceDismissed("passport"),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onEdit;

  const _InfoBlock({required this.title, required this.value, required this.icon, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Stack(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.secondary.withOpacity(0.95), letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onEdit != null)
            Positioned(
              top: -4,
              right: -4,
              child: IgnorePointer(
                child: Icon(Icons.edit_outlined, size: 16, color: Colors.white.withOpacity(0.35)),
              ),
            ),
        ],
      ),
    );
  }
}

class _FocusChip extends StatelessWidget {
  final String label;
  final bool isPrimary;
  const _FocusChip({required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? AppTheme.primary.withOpacity(0.2) : AppTheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isPrimary ? AppTheme.primary.withOpacity(0.4) : AppTheme.secondary.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
