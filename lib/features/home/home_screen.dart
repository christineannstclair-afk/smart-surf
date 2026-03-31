import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' as ui;
import '../session_log/firebase_service.dart';
import '../session_log/session_log_entry.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/surf_dashboard_data.dart';
import '../../widgets/language_menu.dart';
import '../passport/passport_presets.dart';
import '../Settings/coach_pro_screen.dart';
import '../onboarding/guided_tour_overlay.dart';
import '../../ui_system/spacing.dart';
import '../../ui_system/app_card.dart';
import '../../ui_system/media_card.dart';
import '../../ui_system/premium_blur_panel.dart';
import '../../ui_system/app_theme.dart';
import '../../ui_system/upgrade_bottom_sheet.dart';
import '../surfer_pro/surfer_pro_screen.dart';
import 'profile_summary_card.dart';
import 'video_preview_modal.dart';
import '../../widgets/smart_surf_wordmark.dart';
import '../../widgets/orientation_prompt.dart';
import '../Settings/settings_models.dart';

class HomeScreen extends StatefulWidget {
  final bool isSpanish;
  final bool isCoachPro;
  final bool isSurferPro;
  final bool isSurferTrial;
  final void Function(bool) onSetLanguage;

  // Canonical EN values
  final String levelEnTitle;
  final String levelEnDesc;
  final String comfortEn;
  final String boardEn;
  final List<String> focusEn;
  final String stance;
  final String height;
  final String weight;
  final String location;
  final String displayName;
  final String? profilePhotoPath;
  final bool stanceVisibleToCoach;
  final bool stanceVisibleOnDashboard;
  final bool heightVisibleToCoach;
  final bool heightVisibleOnDashboard;
  final bool weightVisibleToCoach;
  final bool weightVisibleOnDashboard;
  final bool locationVisibleToCoach;
  final bool locationVisibleOnDashboard;
  final String? latestMediaPath;
  final String? latestMediaType;
  final String age;
  final String surferSummary;
  final bool ageVisibleToCoach;
  final bool ageVisibleOnDashboard;

  // Derived stats
  final int sessionsSurfed;
  final DateTime? lastSurfedDate;
  final String units;

  // Update callback
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

  final VoidCallback? onUnlockSurferPro;

  final VoidCallback onPromptDismissed;
  final bool seenDashboardPrompt;

  // Navigation helpers
  final VoidCallback onOpenPassportTab;
  final VoidCallback onOpenLogTab;
  final VoidCallback onOpenSurferPro;
  final GlobalKey? progressKey;
  final List<SessionLogEntry> logs;

  // Onboarding nav callbacks
  final VoidCallback onOpenLogTab2;
  final VoidCallback onOpenMapTab;

  const HomeScreen({
    super.key,
    required this.isSpanish,
    required this.isCoachPro,
    required this.isSurferPro,
    this.isSurferTrial = false,
    required this.onSetLanguage,
    required this.levelEnTitle,
    required this.levelEnDesc,
    required this.comfortEn,
    required this.boardEn,
    required this.focusEn,
    required this.stance,
    required this.height,
    required this.weight,
    required this.location,
    required this.displayName,
    this.profilePhotoPath,
    required this.age,
    required this.surferSummary,
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
    required this.logs,
    required this.sessionsSurfed,
    required this.lastSurfedDate,
    required this.latestMediaPath,
    required this.latestMediaType,
    required this.units,
    required this.onUpdate,
    required this.onOpenPassportTab,
    required this.onOpenLogTab,
    required this.onOpenSurferPro,
    required this.onOpenLogTab2,
    required this.onOpenMapTab,
    required this.onPromptDismissed,
    required this.seenDashboardPrompt,
    this.progressKey,
    this.onUnlockSurferPro,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _logAnchorKey = GlobalKey();
  String _t(String en, String es) => widget.isSpanish ? es : en;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.seenDashboardPrompt) {
        OrientationPrompt.show(
          context: context,
          isSpanish: widget.isSpanish,
          title: TranslationService().translate("tip_welcome_title", widget.isSpanish),
          message: TranslationService().translate("tip_welcome_message", widget.isSpanish),
          anchorKey: _logAnchorKey,
          onDismiss: () {
            widget.onPromptDismissed();
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SmartSurfWordmark(),
        centerTitle: false,
        titleSpacing: AppSpacing.md,
        actions: [
          LanguageMenu(isSpanish: widget.isSpanish, onSetLanguage: widget.onSetLanguage),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 
                AppSpacing.md, 
                AppSpacing.md, 
                100.0,
              ),
              children: [
                // 1) Header Area (Profile)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ProfileSummaryCard(
                    isSpanish: widget.isSpanish,
                    displayName: widget.displayName,
                    profilePhotoPath: widget.profilePhotoPath,
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
                    age: widget.age,
                    surferSummary: widget.surferSummary,
                    onUpdate: ({
                      required String displayName,
                      required String? profilePhotoPath,
                      required String stance,
                      required String height,
                      required String weight,
                      required String location,
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
                      required String age,
                      required String surferSummary,
                    }) {
                      widget.onUpdate(
                        levelEnTitle: widget.levelEnTitle,
                        levelEnDesc: widget.levelEnDesc,
                        comfortEn: widget.comfortEn,
                        boardEn: widget.boardEn,
                        focusEn: widget.focusEn,
                        stance: stance,
                        height: height,
                        weight: weight,
                        location: location,
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
                        sessionsSurfed: widget.sessionsSurfed,
                        lastSurfedDate: widget.lastSurfedDate,
                        latestMediaPath: widget.latestMediaPath,
                        latestMediaType: widget.latestMediaType,
                        age: age,
                        surferSummary: surferSummary,
                        units: widget.units,
                      );

                      // Centralized Firebase Sync
                      final data = SurfDashboardData(
                        levelTitle: widget.levelEnTitle,
                        levelDesc: widget.levelEnDesc,
                        comfortZone: widget.comfortEn,
                        board: widget.boardEn,
                        focusSkills: widget.focusEn,
                        age: age,
                        displayName: displayName,
                        profilePhotoPath: profilePhotoPath,
                        surferSummary: surferSummary,
                        stance: stance,
                        height: height,
                        weight: weight,
                        location: location,
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
                        latestMediaPath: widget.latestMediaPath,
                        latestMediaType: widget.latestMediaType,
                      );
                      FirebaseService().saveFullProfile(data);
                    },
                  ),
                ),

                // 2) Section Header: SURF JOURNEY
                _buildSectionHeader(_t("YOUR SURF JOURNEY AT A GLANCE", "TU VIAJE DE SURF DE UN VISTAZO")),
                const SizedBox(height: 8),

                // 3) Surf Snapshot Card
                _buildSurfSnapshotCard(),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    _t("Log your sessions. Build your surf passport.", "Registra tus sesiones. Crea tu pasaporte de surf."),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Rhythm Card
                _buildSurfRhythmCard(),
                const SizedBox(height: AppSpacing.lg),

                // Today's Surf Focus (reminds user of what they planned to work on)
                _buildTodaySurfFocusCard(),

                // Latest Insight Card (shows empty state for all with 0 sessions, or latest insight for Pro)
                _buildLatestInsightCard(),
                const SizedBox(height: AppSpacing.lg),

                // 4) Section Header: LATEST SESSION
                _buildSectionHeader(_t("LATEST SESSION", "ÚLTIMA SESIÓN")),
                const SizedBox(height: 8),

                // 5) Latest Media Card
                _buildLatestMediaCard(),
                const SizedBox(height: AppSpacing.lg),

                // 6) Section Header: NEXT SESSION FOCUS
                _buildSectionHeader(_t("NEXT SESSION FOCUS", "FOCO DE PRÓXIMA SESIÓN")),
                const SizedBox(height: 8),
                
                // 7) Focus Skill Chip/Card
                _buildFocusSkillsSection(),
                const SizedBox(height: AppSpacing.lg),

                // Surfer Pro Card (always visible, adapts to plan state)
                _buildSurferProCard(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurfSnapshotCard() {
    return AppCard(
      onTap: widget.onOpenPassportTab,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t("Surf Passport", "Pasaporte de Surf"), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _snapshotItem(
            Icons.water_drop_outlined, 
            _t("Level", "Nivel"), 
            PassportPresets.levelTitle(isSpanish: widget.isSpanish, enTitle: widget.levelEnTitle)
          ),
          _snapshotItem(
            Icons.surfing, 
            _t("Board", "Tabla"), 
            PassportPresets.mapValue(isSpanish: widget.isSpanish, units: widget.units, list: PassportPresets.boards, enValue: widget.boardEn)
          ),
          _snapshotItem(Icons.history, _t("Total Sessions", "Sesiones Totales"), widget.sessionsSurfed.toString()),
        ],
      ),
    );
  }

  Widget _snapshotItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFocusSkillsSection() {
    if (widget.focusEn.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Text(
          _t("No focus skills selected.", "No hay habilidades foco seleccionadas."), 
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.focusEn.map((en) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Text(
            widget.isSpanish ? PassportPresets.focusLabel(isSpanish: true, enSkill: en) : en,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLatestMediaCard() {
    final hasMedia = widget.latestMediaPath != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(_t("Session Media", "Medios de sesión"), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
        ),
        MediaCard(
          key: _logAnchorKey,
          isSpanish: widget.isSpanish,
          state: !hasMedia ? MediaCardState.empty : (widget.latestMediaType == 'video' ? MediaCardState.video : MediaCardState.image),
          mediaPath: widget.latestMediaPath,
          mediaType: widget.latestMediaType ?? 'image',
          footerLabel: widget.lastSurfedDate != null ? _fmtDate(widget.lastSurfedDate!) : _t("No sessions yet", "Sin sesiones aún"),
          isEditable: false,
          onTap: () {
             if (widget.latestMediaPath != null) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.black,
                  builder: (_) => VideoPreviewModal(
                    videoPath: widget.latestMediaPath!,
                    isSpanish: widget.isSpanish,
                  ),
                );
             } else {
               widget.onOpenLogTab();
             }
          },
        ),
      ],
    );
  }

  /// Compact, always-visible Surfer Pro card. Adapts for free / active / expired users.
  Widget _buildSurferProCard() {
    final bool isPro = widget.isSurferPro;
    return AppCard(
      onTap: isPro ? widget.onOpenLogTab : widget.onOpenSurferPro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPro
                      ? AppTheme.primary.withOpacity(0.15)
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPro ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isPro
                    ? (widget.isSurferTrial 
                        ? _t('Trial active', 'Prueba activa')
                        : _t('Surfer Pro active', 'Surfer Pro activo'))
                    : _t('Surfer Pro', 'Surfer Pro'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isPro
                ? _t('Your latest insight and surf trends are ready.', 'Tu último insight y tendencias de surf están listos.')
                : _t('Get AI surf insights, progress patterns, and next-session focus.', 'Obtén insights de surf con IA, patrones de progreso y enfoque próxima sesión.'),
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: isPro ? widget.onOpenLogTab : widget.onOpenSurferPro,
              child: Text(
                isPro
                    ? _t('View Surf Insights', 'Ver Insights de Surf')
                    : _t('Explore Surfer Pro', 'Explorar Surfer Pro'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProCallout() {
    return Column(
      children: [
        // Coach Pro Teaser
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.md),
          child: PremiumBlurPanel(
            ctaText: _t("Explore Coach Pro", "Explorar Coach Pro"),
            onUnlock: () {
               showCoachProModal(context, widget.isSpanish);
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.badge_rounded, color: AppTheme.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t("Coach Pro", "Coach Pro"),
                              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textPrimary, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _t("Help surfers improve faster", "Ayuda a surfistas a mejorar más rápido"),
                              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildBullet(_t("review surfer passports", "revisa pasaportes de surfers")),
                  _buildBullet(_t("track surfer sessions", "sigue sesiones de surfers")),
                  _buildBullet(_t("coaching feedback tools", "herramientas de feedback")),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    if (widget.isSpanish) return "${d.day}/${d.month}/${d.year}";
    return "${d.month}/${d.day}/${d.year}";
  }
  
  void startTour() {
    OrientationPrompt.show(
      context: context,
      isSpanish: widget.isSpanish,
      title: TranslationService().translate("tip_welcome_title", widget.isSpanish),
      message: TranslationService().translate("tip_welcome_message", widget.isSpanish),
      anchorKey: _logAnchorKey,
      onDismiss: () {
        widget.onPromptDismissed();
      },
    );
  }

  Widget _buildSurfRhythmCard() {
    final now = DateTime.now();
    final monthLogs = widget.logs.where((l) => l.date.year == now.year && l.date.month == now.month).length;
    
    // Simple streak calculation: consecutive days with at least one surf
    int streak = 0;
    if (widget.logs.isNotEmpty) {
      final sortedDates = widget.logs.map((l) => DateTime(l.date.year, l.date.month, l.date.day)).toSet().toList();
      sortedDates.sort((a, b) => b.compareTo(a));
      
      DateTime checkDate = DateTime(now.year, now.month, now.day);
      if (sortedDates.contains(checkDate) || sortedDates.contains(checkDate.subtract(const Duration(days: 1)))) {
        // Start from most recent surfd day
        int i = 0;
        if (!sortedDates.contains(checkDate)) {
           checkDate = checkDate.subtract(const Duration(days: 1));
        }
        
        while (i < sortedDates.length) {
          if (sortedDates.any((d) => d.isAtSameMomentAs(checkDate))) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
          i++;
        }
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                _t("Surf Rhythm", "Ritmo de Surf"),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _rhythmStat(_t("$monthLogs Surfs", "$monthLogs Sesiones"), _t("This Month", "Este Mes")),
              Container(width: 1, height: 30, color: Colors.white10),
              _rhythmStat(_t("$streak Sessions", "$streak Sesiones"), _t("Current Streak", "Racha Actual")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rhythmStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildLatestInsightCard() {
    final latestWithInsight = widget.logs.cast<SessionLogEntry?>().firstWhere(
      (l) => l?.aiSummary != null && l?.aiNextFocus != null, 
      orElse: () => null
    );

    // If no sessions, show empty state (even if not Pro, as hook)
    if (widget.logs.isEmpty) {
      return AppCard(
        onTap: widget.onOpenLogTab,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  _t("Surf Insight", "Insight de Surf"),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _t("Log your first surf session to receive personalized surf insights and session reflections.", 
                 "Registra tu primera sesión de surf para recibir insights personalizados y reflexiones de sesión."),
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: widget.onOpenLogTab,
                child: Text(_t("Start Session", "Iniciar Sesión")),
              ),
            ),
          ],
        ),
      );
    }

    // If no sessions at all, hide card
    if (widget.logs.isEmpty) return const SizedBox.shrink();

    // If sessions exist but no insights yet
    if (latestWithInsight == null) {
      return AppCard(
        onTap: widget.onOpenLogTab,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  _t("Latest Surf Insight", "Último Insight de Surf"),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _t(
                "You don't have any AI insights yet. Keep surfing to unlock your first technical breakdown!",
                "Aún no tienes insights de IA. ¡Sigue surfeando para desbloquear tu primer desglose técnico!"
              ),
              style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.5),
            ),
          ],
        ),
      );
    }

    final t = widget.isSpanish;
    final String? nextFocus = t ? latestWithInsight.aiNextFocusEs : latestWithInsight.aiNextFocusEn;
    final String? pattern = t ? latestWithInsight.aiProgressPatternEs : latestWithInsight.aiProgressPatternEn;

    // Legacy fallbacks
    final displayFocus = nextFocus ?? latestWithInsight.aiNextFocus ?? "";
    final displayPattern = pattern ?? latestWithInsight.aiProgressPattern;

    return AppCard(
      onTap: widget.onOpenLogTab,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _t("Latest Surf Insight", "Último Insight de Surf"),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 16),
          if (displayFocus.isNotEmpty) ...[
            Text(
              _t("LATEST FOCUS", "FOCO MÁS RECIENTE"),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            Text(
              displayFocus,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          if (displayPattern != null) ...[
            Text(
              _t("TREND SUMMARY", "RESUMEN DE TENDENCIA"),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            Text(
              displayPattern,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onOpenLogTab,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
              ),
              child: Text(_t("View Full Insight", "Ver Insight Completo"), style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySurfFocusCard() {
    final t = widget.isSpanish;
    final latestWithInsight = widget.logs.cast<SessionLogEntry?>().firstWhere(
      (l) {
        if (l == null) return false;
        final nextFocus = t ? l.aiNextFocusEs : l.aiNextFocusEn;
        final legacyFocus = l.aiNextFocus;
        return (nextFocus != null && nextFocus.trim().isNotEmpty) || (legacyFocus != null && legacyFocus.trim().isNotEmpty);
      },
      orElse: () => null
    );

    if (latestWithInsight == null) return const SizedBox.shrink();

    final String? nextFocus = t ? latestWithInsight.aiNextFocusEs : latestWithInsight.aiNextFocusEn;
    final String displayFocus = nextFocus ?? latestWithInsight.aiNextFocus ?? "";

    if (displayFocus.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  _t("Today's Surf Focus", "Foco de Surf para Hoy"),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              displayFocus,
              style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              _t("Based on your last surf session.", "Basado en tu última sesión de surf."),
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
