import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
import '../../widgets/orientation_prompt.dart';
import '../Settings/settings_models.dart';
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
    required this.logs,
  });

  @override
  State<SurfPassportScreen> createState() => _SurfPassportScreenState();
}

class _SurfPassportScreenState extends State<SurfPassportScreen> {
  final GlobalKey _passportAnchorKey = GlobalKey();
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.seenPassportPrompt) {
        OrientationPrompt.show(
          context: context,
          isSpanish: widget.isSpanish,
          title: "",
          message: TranslationService().translate("tip_passport_message", widget.isSpanish),
          anchorKey: _passportAnchorKey,
          onDismiss: () {
            widget.onPromptDismissed();
          },
        );
      }
    });
  }

  String _t(String en, String es) => widget.isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Ocean
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primary,
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
          title: const SmartSurfWordmark(isInverse: true),
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
                    Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        color: const Color(0xFF0F172A),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Identity Block
                            _buildIdentityRow(),
                            const SizedBox(height: 16),

                            // Hero Level Block
                            _buildLevelHero(levelTitle, levelDesc, key: _passportAnchorKey),
                            const SizedBox(height: 12),

                            // Snapshot Grid
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 2.2,
                              children: [
                                _InfoBlock(
                                  title: _t("Comfort Zone", "Zona de confort"),
                                  value: comfortLabel,
                                  icon: Icons.waves_rounded,
                                  onEdit: _showComfortEditModal,
                                ),
                                _InfoBlock(
                                  title: _t("Board", "Tabla"),
                                  value: boardLabel,
                                  icon: Icons.straighten_outlined,
                                  onEdit: _showBoardEditModal,
                                ),
                                _InfoBlock(title: _t("Sessions Logged", "Sesiones"), value: widget.sessionsSurfed.toString(), icon: Icons.history_edu_rounded),
                                _InfoBlock(title: _t("Last Surfed", "Última vez"), value: _fmtShortDate(widget.lastSurfedDate), icon: Icons.calendar_today_rounded),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Focus Skills
                            _buildFocusSkillsSection(focus),
                            const SizedBox(height: 12),

                            // Surf Progress (Summary logic from recent insights)
                            _buildSurfProgressSection(),
                            const SizedBox(height: 24),

                            // Media Section
                            _buildMediaSection(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Share Button
                    _buildShareButton(),
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
          Stack(
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
                          widget.displayName.isEmpty ? _t("Add your name", "Agrega tu nombre") : widget.displayName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (widget.stanceVisibleToCoach && widget.stance.isNotEmpty) _inlineMeta(Icons.directions_run_rounded, widget.stance),
                            if (widget.locationVisibleToCoach && widget.location.isNotEmpty) _inlineMeta(Icons.place_rounded, widget.location),
                            if ((widget.heightVisibleToCoach && widget.height.isNotEmpty) || (widget.weightVisibleToCoach && widget.weight.isNotEmpty))
                              _inlineMeta(
                                Icons.straighten_rounded,
                                [
                                  if (widget.heightVisibleToCoach && widget.height.isNotEmpty) widget.height,
                                  if (widget.weightVisibleToCoach && widget.weight.isNotEmpty) widget.weight,
                                ].join(' · '),
                              ),
                            if (widget.ageVisibleToCoach && widget.age.isNotEmpty) _inlineMeta(Icons.cake_rounded, widget.age),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18, color: Colors.white.withOpacity(0.35)),
                  onPressed: _showProfileEditModal,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          if (widget.surferSummary.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSurferSummarySection(),
          ],
        ],
      ),
    );
  }

  Widget _buildSurferSummarySection() {
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: _showProfileEditModal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t("SURFER SUMMARY", "RESUMEN DEL SURFER"),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Text(
            widget.surferSummary,
            style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white),
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
              colors: [AppTheme.primary.withOpacity(0.25), const Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: InkWell(
            onTap: _showLevelEditModal,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t("SURF LEVEL", "NIVEL DE SURF"),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1.2),
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
                  Text(
                    desc,
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), height: 1.2, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _t("FOCUS SKILL", "HABILIDAD FOCO").toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1.2),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: Colors.white.withOpacity(0.35)),
                onPressed: _showFocusEditModal,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          focus.isEmpty
              ? Text(_t("None set yet", "Sin definir"), style: const TextStyle(color: Colors.white38, fontSize: 13))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: focus.map((en) => _FocusChip(label: PassportPresets.focusLabel(isSpanish: widget.isSpanish, enSkill: en))).toList(),
                ),
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
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.2),
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
    try {
      final uint8List = await _screenshotController.capture(pixelRatio: 2.0);
      if (uint8List != null) {
        final doc = pw.Document();
        final memoryImage = pw.MemoryImage(uint8List);
        
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                   pw.Expanded(child: pw.Image(memoryImage, fit: pw.BoxFit.contain)),
                   
                   // Requirement: If there's an HTTPS video URL, embed a clickable hyperlink below the layout
                   if (widget.latestMediaPath != null && widget.latestMediaType == 'video')
                     pw.Container(
                       margin: const pw.EdgeInsets.only(top: 20, bottom: 20),
                       child: pw.UrlLink(
                         destination: widget.latestMediaPath!,
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

  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: _isSharing ? null : _sharePassport,
        icon: _isSharing 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.ios_share_rounded, size: 20),
        label: Text(_isSharing ? _t("Generating...", "Generando...") : _t("Share Passport", "Compartir Passport"), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
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
          Icon(icon, size: 14, color: AppTheme.primary),
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

  void _callUpdate({
    String? levelEnTitle,
    String? levelEnDesc,
    String? comfortEn,
    String? boardEn,
    List<String>? focusEn,
    String? height,
    String? weight,
    String? location,
    String? stance,
    String? age,
    String? surferSummary,
    String? displayName,
    String? profilePhotoPath,
    bool? stanceVisibleToCoach,
    bool? stanceVisibleOnDashboard,
    bool? heightVisibleToCoach,
    bool? heightVisibleOnDashboard,
    bool? weightVisibleToCoach,
    bool? weightVisibleOnDashboard,
    bool? locationVisibleToCoach,
    bool? locationVisibleOnDashboard,
    bool? ageVisibleToCoach,
    bool? ageVisibleOnDashboard,
    String? latestMediaPath,
    String? latestMediaType,
  }) {
    // 1. Local update
    widget.onUpdate(
      levelEnTitle: levelEnTitle ?? widget.levelEnTitle,
      levelEnDesc: levelEnDesc ?? widget.levelEnDesc,
      comfortEn: comfortEn ?? widget.comfortEn,
      boardEn: boardEn ?? widget.boardEn,
      focusEn: focusEn ?? widget.focusEn,
      stance: stance ?? widget.stance,
      height: height ?? widget.height,
      weight: weight ?? widget.weight,
      location: location ?? widget.location,
      age: age ?? widget.age,
      surferSummary: surferSummary ?? widget.surferSummary,
      displayName: displayName ?? widget.displayName,
      profilePhotoPath: profilePhotoPath ?? widget.profilePhotoPath,
      stanceVisibleToCoach: stanceVisibleToCoach ?? widget.stanceVisibleToCoach,
      stanceVisibleOnDashboard: stanceVisibleOnDashboard ?? widget.stanceVisibleOnDashboard,
      heightVisibleToCoach: heightVisibleToCoach ?? widget.heightVisibleToCoach,
      heightVisibleOnDashboard: heightVisibleOnDashboard ?? widget.heightVisibleOnDashboard,
      weightVisibleToCoach: weightVisibleToCoach ?? widget.weightVisibleToCoach,
      weightVisibleOnDashboard: weightVisibleOnDashboard ?? widget.weightVisibleOnDashboard,
      locationVisibleToCoach: locationVisibleToCoach ?? widget.locationVisibleToCoach,
      locationVisibleOnDashboard: locationVisibleOnDashboard ?? widget.locationVisibleOnDashboard,
      ageVisibleToCoach: ageVisibleToCoach ?? widget.ageVisibleToCoach,
      ageVisibleOnDashboard: ageVisibleOnDashboard ?? widget.ageVisibleOnDashboard,
      sessionsSurfed: widget.sessionsSurfed,
      lastSurfedDate: widget.lastSurfedDate,
      latestMediaPath: latestMediaPath ?? widget.latestMediaPath,
      latestMediaType: latestMediaType ?? widget.latestMediaType,
      units: widget.units,
    );

    // 2. Firebase Sync
    final data = SurfDashboardData(
      levelTitle: levelEnTitle ?? widget.levelEnTitle,
      levelDesc: levelEnDesc ?? widget.levelEnDesc,
      comfortZone: comfortEn ?? widget.comfortEn,
      board: boardEn ?? widget.boardEn,
      focusSkills: focusEn ?? widget.focusEn,
      age: age ?? widget.age,
      displayName: displayName ?? widget.displayName,
      profilePhotoPath: profilePhotoPath ?? widget.profilePhotoPath,
      surferSummary: surferSummary ?? widget.surferSummary,
      stance: stance ?? widget.stance,
      height: height ?? widget.height,
      weight: weight ?? widget.weight,
      location: location ?? widget.location,
      stanceVisibleToCoach: stanceVisibleToCoach ?? widget.stanceVisibleToCoach,
      stanceVisibleOnDashboard: stanceVisibleOnDashboard ?? widget.stanceVisibleOnDashboard,
      heightVisibleToCoach: heightVisibleToCoach ?? widget.heightVisibleToCoach,
      heightVisibleOnDashboard: heightVisibleOnDashboard ?? widget.heightVisibleOnDashboard,
      weightVisibleToCoach: weightVisibleToCoach ?? widget.weightVisibleToCoach,
      weightVisibleOnDashboard: weightVisibleOnDashboard ?? widget.weightVisibleOnDashboard,
      locationVisibleToCoach: locationVisibleToCoach ?? widget.locationVisibleToCoach,
      locationVisibleOnDashboard: locationVisibleOnDashboard ?? widget.locationVisibleOnDashboard,
      ageVisibleToCoach: ageVisibleToCoach ?? widget.ageVisibleToCoach,
      ageVisibleOnDashboard: ageVisibleOnDashboard ?? widget.ageVisibleOnDashboard,
      latestMediaPath: latestMediaPath ?? widget.latestMediaPath,
      latestMediaType: latestMediaType ?? widget.latestMediaType,
    );
    FirebaseService().saveFullProfile(data);
  }

  void _showLevelEditModal() {
    _showPickerModal(
      title: _t("Edit Surf Level", "Editar Nivel de Surf"),
      items: PassportPresets.levels,
      currentValue: widget.levelEnTitle,
      onSelected: (m) => _callUpdate(levelEnTitle: m["enTitle"], levelEnDesc: m["enDesc"]),
      itemTitle: (m) => widget.isSpanish ? m["esTitle"]! : m["enTitle"]!,
      itemSubtitle: (m) => widget.isSpanish ? m["esDesc"]! : m["enDesc"]!,
    );
  }

  void _showComfortEditModal() {
    _showPickerModal(
      title: _t("Edit Comfort Zone", "Editar Zona de Confort"),
      items: PassportPresets.comfortZones,
      currentValue: widget.comfortEn,
      onSelected: (m) => _callUpdate(comfortEn: m["en"]),
      itemTitle: (m) => PassportPresets.mapValue(isSpanish: widget.isSpanish, units: widget.units, list: PassportPresets.comfortZones, enValue: m["en"]!),
    );
  }

  void _showBoardEditModal() {
    _showPickerModal(
      title: _t("Edit Board", "Editar Tabla"),
      items: PassportPresets.boards,
      currentValue: widget.boardEn,
      onSelected: (m) => _callUpdate(boardEn: m["en"]),
      itemTitle: (m) => PassportPresets.mapValue(isSpanish: widget.isSpanish, units: widget.units, list: PassportPresets.boards, enValue: m["en"]!),
    );
  }

  void _showFocusEditModal() {
    final List<String> currentFocus = List.from(PassportPresets.normalizeFocus(widget.focusEn));
    String? warningMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_t("Edit Focus Skill", "Editar Habilidad Foco"), style: Theme.of(context).textTheme.titleLarge),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(_t("Cancel", "Cancelar")),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t("Select up to 4 focus skills", "Selecciona hasta 4 habilidades foco"),
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                    ),
                    if (warningMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(warningMsg!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: PassportPresets.focusSkills.map((m) {
                    final en = m["en"]!;
                    final isSelected = currentFocus.contains(en);
                    return CheckboxListTile(
                      title: Text(widget.isSpanish ? m["es"]! : en),
                      value: isSelected,
                      onChanged: (val) {
                        setModalState(() {
                          warningMsg = null;
                          if (val == true) {
                            if (currentFocus.length < 4) {
                              currentFocus.add(en);
                            } else {
                              warningMsg = _t("You can choose up to 4 focus skills.", "Puedes elegir hasta 4 habilidades foco.");
                            }
                          } else {
                            currentFocus.remove(en);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () {
                      _callUpdate(focusEn: currentFocus);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_t("Focus skills updated ✔", "Habilidades foco actualizadas ✔"))),
                      );
                    },
                    child: Text(_t("Save Skills", "Guardar Habilidades"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileEditModal() {
    final nameCtrl = TextEditingController(text: widget.displayName);
    final heightCtrl = TextEditingController(text: widget.height);
    final weightCtrl = TextEditingController(text: widget.weight);
    final locationCtrl = TextEditingController(text: widget.location);
    final ageCtrl = TextEditingController(text: widget.age);
    final summaryCtrl = TextEditingController(text: widget.surferSummary);
    String currentStance = widget.stance;
    bool hv = widget.heightVisibleToCoach;
    bool wv = widget.weightVisibleToCoach;
    bool lv = widget.locationVisibleToCoach;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_t("Edit Profile", "Editar Perfil"), style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(_t("Cancel", "Cancelar")),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: _t("Name", "Nombre"), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: ["Regular", "Goofy"].contains(currentStance) ? currentStance : null,
                  decoration: InputDecoration(
                    labelText: _t("Stance", "Posición"), 
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: "Regular", child: Text(_t("Regular", "Regular"))),
                    DropdownMenuItem(value: "Goofy", child: Text(_t("Goofy", "Goofy"))),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setModalState(() => currentStance = v);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: heightCtrl,
                            decoration: InputDecoration(labelText: _t("Height", "Altura"), border: const OutlineInputBorder()),
                          ),
                          SwitchListTile(
                            title: Text(_t("Height Visible on Passport", "Altura visible en Passport"), style: const TextStyle(fontSize: 11)),
                            value: hv,
                            onChanged: (v) {
                              setModalState(() => hv = v);
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: weightCtrl,
                            decoration: InputDecoration(labelText: _t("Weight", "Peso"), border: const OutlineInputBorder()),
                          ),
                          SwitchListTile(
                            title: Text(_t("Weight Visible on Passport", "Peso visible en Passport"), style: const TextStyle(fontSize: 11)),
                            value: wv,
                            onChanged: (v) {
                              setModalState(() => wv = v);
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(labelText: _t("Location", "Ubicación"), border: const OutlineInputBorder()),
                ),
                SwitchListTile(
                  title: Text(_t("Location Visible on Passport", "Ubicación visible en Passport"), style: const TextStyle(fontSize: 13)),
                  value: lv,
                  onChanged: (v) {
                    setModalState(() => lv = v);
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                _buildEditField(
                  label: _t("Age", "Edad"),
                  controller: ageCtrl,
                  dash: true,
                  coach: true,
                  onDash: (v) {},
                  onCoach: (v) {},
                  onChanged: (v) {}, // No direct update
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: summaryCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: _t("Surfer Summary / Coach Note", "Resumen de Surfer / Nota para Coach"),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () {
                      _callUpdate(
                        displayName: nameCtrl.text,
                        stance: currentStance,
                        height: heightCtrl.text,
                        weight: weightCtrl.text,
                        location: locationCtrl.text,
                        age: ageCtrl.text,
                        surferSummary: summaryCtrl.text,
                        heightVisibleToCoach: hv,
                        weightVisibleToCoach: wv,
                        locationVisibleToCoach: lv,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_t("Profile updated ✔", "Perfil actualizado ✔"))),
                      );
                    },
                    child: Text(_t("Save Profile", "Guardar Perfil"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPickerModal({
    required String title,
    required List<Map<String, String>> items,
    required String currentValue,
    required Function(Map<String, String>) onSelected,
    required String Function(Map<String, String>) itemTitle,
    String Function(Map<String, String>)? itemSubtitle,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final enVal = item["en"] ?? item["enTitle"];
                  final isSelected = enVal == currentValue;
                  return ListTile(
                    title: Text(itemTitle(item), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppTheme.primary : null)),
                    subtitle: itemSubtitle != null ? Text(itemSubtitle(item)) : null,
                    trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
                    onTap: () {
                      onSelected(item);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required bool dash,
    required bool coach,
    required ValueChanged<bool> onDash,
    required ValueChanged<bool> onCoach,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _toggleItem(Icons.dashboard_outlined, _t("On Dash", "En Dash"), dash, onDash),
            const SizedBox(width: 12),
            _toggleItem(Icons.badge_outlined, _t("To Coach", "Para Coach"), coach, onCoach),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _toggleItem(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: value ? AppTheme.primary : AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: value ? FontWeight.bold : FontWeight.normal,
                color: value ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
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
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1.2),
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
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4)),
      ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary.withOpacity(0.9)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
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
              child: IconButton(
                icon: Icon(Icons.edit_outlined, size: 16, color: Colors.white.withOpacity(0.35)),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
        ],
      ),
    );
  }
}

class _FocusChip extends StatelessWidget {
  final String label;
  const _FocusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
