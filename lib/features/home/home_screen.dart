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
import '../../ui_system/animations.dart';
import '../../models/surf_dashboard_data.dart';
import '../../models/ai_analysis_model.dart';
import '../../widgets/language_menu.dart';
import '../passport/passport_presets.dart';
import '../Settings/coach_pro_screen.dart';
import '../onboarding/guided_tour_overlay.dart';
import '../../ui_system/spacing.dart';
import '../../ui_system/app_card.dart';
import '../../ui_system/media_card.dart';
import '../../ui_system/premium_blur_panel.dart';
import '../passport/profile_info_edit_sheet.dart';
import '../../ui_system/app_theme.dart';
import '../../ui_system/upgrade_bottom_sheet.dart';
import '../surfer_pro/surfer_pro_screen.dart';
import 'profile_summary_card.dart';
import 'video_preview_modal.dart';
import '../../widgets/smart_surf_wordmark.dart';
import '../../ui_system/surf_constants.dart';
import '../../widgets/micro_tip_banner.dart';
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
  final void Function({bool edit}) onOpenPassportTab;
  final VoidCallback onOpenLogTab;
  final Function({String? title, String? content}) onOpenSurferPro;
  final GlobalKey? progressKey;
  final List<SessionLogEntry> logs;
  final List<AiAnalysisResult> aiAnalyses;
  final VoidCallback? onUnlockFirstInsight;

  // Onboarding nav callbacks
  final VoidCallback onOpenLogTab2;
  final VoidCallback onOpenMapTab;

  final void Function(String guidanceType) onGuidanceDismissed;
  final bool hasSeenDashboardGuidance;

  final VoidCallback onWelcomeModalDismissed;
  final bool hasSeenWelcomeGuide;

  final bool showReturnNudge;
  final VoidCallback onReturnNudgeDismissed;

  final bool hasSeenLogPulse;
  final VoidCallback onLogPulseShown;
  final bool hasUsedFirstFreeAIInsight;

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
    required this.aiAnalyses,
    this.onUnlockFirstInsight,
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
    required this.hasSeenDashboardGuidance,
    required this.onGuidanceDismissed,
    required this.onWelcomeModalDismissed,
    required this.hasSeenWelcomeGuide,
    required this.showReturnNudge,
    required this.onReturnNudgeDismissed,
    required this.hasSeenLogPulse,
    required this.onLogPulseShown,
    required this.hasUsedFirstFreeAIInsight,
    this.progressKey,
    this.onUnlockSurferPro,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ProfileSummaryCardState> _profileCardKey = GlobalKey<ProfileSummaryCardState>();
  final GlobalKey _logAnchorKey = GlobalKey();

  void showProfileInfoEdit() {
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

        // Firebase Sync
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
    );
  }

  String _t(String en, String es) => widget.isSpanish ? es : en;
  bool _playPulse = false;

  @override
  void initState() {
    super.initState();
    if (widget.sessionsSurfed == 0 && !widget.hasSeenLogPulse) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _playPulse = true);
          widget.onLogPulseShown();
        }
      });
    }
  }





  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = widget.displayName.trim().split(' ').first;
    final hasName = name.isNotEmpty;

    if (hour < 12) return hasName ? _t("Good morning, $name", "Buenos días, $name") : _t("Good morning", "Buenos días");
    if (hour < 17) return hasName ? _t("Good afternoon, $name", "Buenas tardes, $name") : _t("Good afternoon", "Buenas tardes");
    return hasName ? _t("Good evening, $name", "Buenas noches, $name") : _t("Good evening", "Buenas noches");
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
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 
                      AppSpacing.md, 
                      AppSpacing.md, 
                      100.0,
                    ),
                    children: [
                      MicroTipBanner(
                        prefKey: 'hasSeenDashboardGuide',
                        visible: widget.sessionsSurfed <= 2 && !widget.seenDashboardPrompt,
                        onDismiss: widget.onPromptDismissed,
                        message: _t(
                          "This is your surf dashboard. Log sessions, track your progress, and build your surf identity.",
                          "Este es tu dashboard de surf. Registra sesiones, sigue tu progreso y construye tu identidad de surf.",
                        ),
                        dismissLabel: _t("Got it", "Entendido"),
                      ),
                      // 1) Header Area (Profile)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ProfileSummaryCard(
                    key: _profileCardKey,
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
                    levelEnTitle: widget.levelEnTitle,
                    levelEnDesc: widget.levelEnDesc,
                    comfortEn: widget.comfortEn,
                    boardEn: widget.boardEn,
                    focusEn: widget.focusEn,
                    units: widget.units,
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
                      required String levelEnTitle,
                      required String levelEnDesc,
                      required String comfortEn,
                      required String boardEn,
                      required List<String> focusEn,
                    }) {
                      widget.onUpdate(
                        levelEnTitle: levelEnTitle,
                        levelEnDesc: levelEnDesc,
                        comfortEn: comfortEn,
                        boardEn: boardEn,
                        focusEn: focusEn,
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
                        levelTitle: levelEnTitle,
                        levelDesc: levelEnDesc,
                        comfortZone: comfortEn,
                        board: boardEn,
                        focusSkills: focusEn,
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

                if (widget.displayName.isEmpty && widget.stance.isEmpty && widget.height.isEmpty && widget.weight.isEmpty && widget.location.isEmpty && widget.age.isEmpty && widget.surferSummary.isEmpty)
                  _buildPassiveProfileCTA(),
                const SizedBox(height: 8),
                _buildHeroSection(),
                _buildContextLine(),

                // 2) Section Header: SURF JOURNEY
                const SizedBox(height: AppSpacing.md),
                _buildSectionHeader(_t("YOUR SURF JOURNEY", "TU VIAJE DE SURF")),
                const SizedBox(height: 8),
                _buildSurfSnapshotCard(),
                const SizedBox(height: AppSpacing.lg),
                _buildSurfRhythmCard(),
                _buildProgressionNudge(),
                _buildPassiveInsightNudge(),
                const SizedBox(height: AppSpacing.lg),
                _buildSurferProCard(),
                const SizedBox(height: 60),
                const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppTheme.primary, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t("Your sessions", "Tus sesiones"),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  if (widget.sessionsSurfed > 0 && widget.lastSurfedDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _getLastSurfText(),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ],
          ),
          Text(
            widget.sessionsSurfed.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary),
          ),
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
    final bool isBeginner = widget.logs.length < 3;

    return AppCard(
      onTap: isBeginner ? null : (isPro ? null : () => widget.onOpenSurferPro()),
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
                        : _t('Surfer Pro', 'Surfer Pro'))
                    : _t('Go deeper into your surf', 'Profundiza en tu surf'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isPro) ...[
            _buildBullet(_t('See what’s actually holding you back', 'Descubre qué te está frenando')),
            _buildBullet(_t('Spot patterns across sessions', 'Detecta patrones entre sesiones')),
            _buildBullet(_t('Get personalized suggestions', 'Recibe sugerencias más personalizadas')),
            const SizedBox(height: 8),
          ] else ...[
            Text(
              _t('Your latest insight and trends are ready.', 'Tu último insight y tendencias están listos.'),
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isBeginner && !isPro ? AppTheme.textMuted.withOpacity(0.2) : AppTheme.primary,
                foregroundColor: isBeginner && !isPro ? AppTheme.textMuted : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: isBeginner && !isPro ? null : (isPro ? widget.onOpenLogTab2 : () => widget.onOpenSurferPro()),
              child: Text(
                isBeginner && !isPro
                    ? _t('Unlock after 3 sessions', 'Desbloquear tras 3 sesiones')
                    : (isPro
                        ? _t('View session insights', 'Ver insights de sesión')
                        : _t('Explore Surfer Pro', 'Explorar Surfer Pro')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstInsightCard() {
    // Only show if user has 3+ sessions AND hasn't viewed their first insight yet
    final bool hasThreeSessions = widget.logs.length >= 3;
    final bool hasSeenFirstInsight = widget.logs.any((l) => l.aiSummaryEn != null || l.aiSummaryEs != null);

    if (!hasThreeSessions || hasSeenFirstInsight) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                _t("Get your first surf insight", "Tu primer insight de surf"),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _t(
              "We turned your session into a quick insight. Take a look, then decide if you want more.",
              "Convertimos tu sesión en un insight rápido. Échale un vistazo y decide si quieres más.",
            ),
            style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          // Primary CTA — value first
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: widget.onUnlockFirstInsight,
              child: Text(
                _t("See my insight", "Ver mi insight"),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Secondary CTA — trial, deprioritized visually
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: BorderSide(color: AppTheme.primary.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: widget.onOpenSurferPro,
              child: Text(
                _t("Start 3-day free trial", "Comenzar prueba de 3 días"),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          // Tertiary CTA — not now, lowest priority
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                _t("Not now", "Ahora no"),
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted.withOpacity(0.7),
                ),
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
                  _buildBullet(_t("technical analysis tools", "herramientas de análisis")),
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

  Widget _buildZeroStateHeroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onOpenLogTab,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t("Ready to log your surf?", "¿Listo para registrar tu surf?"),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _t("Log your surf sessions and track your progress.", "Registra tus sesiones de surf y sigue tu progreso."),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _t("Log my session", "Registrar mi sesión"),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextLine() {
    String text;
    if (widget.sessionsSurfed == 0) {
      return const SizedBox.shrink();
    } else {
      final now = DateTime.now();
      final lastSurfed = widget.lastSurfedDate;
      if (lastSurfed != null && now.difference(lastSurfed).inDays > 3) {
        text = _t("Ready to get back out there?", "¿Listo para volver al agua?");
      } else {
        text = _t("You're building your surf rhythm", "Estás construyendo tu ritmo de surf");
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: AppSpacing.lg, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildHeroSection() {
    final String greeting = _getGreeting();
    final String title = _getDynamicHeroTitle();
    // Find latest AI insight for subtext
    String? latestNextFocus;
    final lastLog = widget.logs.isNotEmpty ? widget.logs.first : null;
    final bool lastLogHasAi = lastLog != null && (widget.isSpanish ? lastLog.aiNextFocusEs != null : lastLog.aiNextFocusEn != null);

    if (widget.logs.isNotEmpty) {
      try {
        final lastWithAi = widget.logs.firstWhere((l) => widget.isSpanish ? l.aiNextFocusEs != null : l.aiNextFocusEn != null);
        latestNextFocus = widget.isSpanish ? lastWithAi.aiNextFocusEs : lastWithAi.aiNextFocusEn;
      } catch (_) {}
    }

    String? teaserText;
    if (!widget.isSurferPro && lastLog != null && !lastLogHasAi) {
      final focus = SurfConstants.getFocusSkillTranslation(lastLog.sessionFocus, widget.isSpanish);
      teaserText = widget.isSpanish 
        ? "Estás empezando a mejorar tu $focus..." 
        : "You're starting to improve your $focus...";
    }

    final String subtext = teaserText ?? latestNextFocus ?? (widget.sessionsSurfed == 0 
        ? _t("Log your first surf and see what your surfing is really telling you.", "Registra tu primer surf y mira lo que tu surf realmente te está diciendo.")
        : _t("Log your next session and keep building your rhythm.", "Registra tu próxima sesión y mantén tu ritmo."));
    
    final bool showLockedTeaser = !widget.isSurferPro && (teaserText != null);

    return PulseAnimator(
      play: _playPulse,
      maxPulses: 3,
      onComplete: () {
        if (mounted) {
          setState(() => _playPulse = false);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withOpacity(0.15),
              AppTheme.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onOpenLogTab,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary.withOpacity(0.8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtext,
                    style: showLockedTeaser
                      ? TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          // foreground only — color must be null when foreground is set
                          foreground: Paint()
                            ..shader = ui.Gradient.linear(
                              const Offset(0, 0),
                              const Offset(0, 40),
                              [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.0)],
                            ),
                        )
                      : const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textMuted,
                          height: 1.5,
                        ),
                    maxLines: showLockedTeaser ? 2 : null,
                    overflow: showLockedTeaser ? TextOverflow.clip : null,
                  ),
                  if (showLockedTeaser) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          _t("See your full progress insight", "Ver tu insight de progreso completo"),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _t("Log session", "Registrar sesión"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurfRhythmCard() {
    final now = DateTime.now();
    final monthLogs = widget.logs.where((l) => l.date.year == now.year && l.date.month == now.month).length;
    
    // Simple streak calculation
    final int streak = _calculateStreak();

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
          const SizedBox(height: 4),
          Text(_t("Keep your streak going", "Mantén tu racha"), style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
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


  Widget _buildPassiveProfileCTA() {
    // Only show if the user hasn't filled out their profile yet
    final visibleFields = getVisibleProfileFields(widget.isSpanish);
    if (visibleFields.isNotEmpty && widget.displayName.isNotEmpty) {
      return const SizedBox.shrink();
    }
    
    return AppCard(
      onTap: showProfileInfoEdit,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t("Complete your profile info", "Completa tu información de perfil"),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  _t("Add optional details to personalize your Passport", "Añade detalles opcionales para personalizar tu Pasaporte"),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildReturnNudgeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.waves, color: AppTheme.secondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t("Welcome back!", "¡Bienvenido de nuevo!"),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                onPressed: widget.onReturnNudgeDismissed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _t(
              "Want to see how your sessions are connecting?",
              "¿Quieres ver cómo se están conectando tus sesiones?"
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onReturnNudgeDismissed();
                widget.onOpenSurferPro();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_t("View Insights", "Ver información")),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateStreak() {
    if (widget.logs.isEmpty) return 0;
    final now = DateTime.now();
    final sortedDates = widget.logs
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet()
        .toList();
    sortedDates.sort((a, b) => b.compareTo(a));

    DateTime checkDate = DateTime(now.year, now.month, now.day);
    if (!sortedDates.contains(checkDate) &&
        !sortedDates.contains(checkDate.subtract(const Duration(days: 1)))) {
      return 0;
    }

    if (!sortedDates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    int streak = 0;
    int i = 0;
    while (i < sortedDates.length) {
      if (sortedDates.any((d) => d.isAtSameMomentAs(checkDate))) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
      i++;
    }
    return streak;
  }

  String _getDynamicHeroTitle() {
    if (widget.sessionsSurfed == 0) {
      return _t("Ready to log your surf?", "¿Listo para registrar tu surf?");
    }

    if (widget.logs.isNotEmpty) {
      // Prioritize latest AI Focus Tag
      try {
        final lastWithTag = widget.logs.firstWhere((l) => widget.isSpanish ? (l.aiFocusTagEs?.isNotEmpty == true) : (l.aiFocusTagEn?.isNotEmpty == true));
        final tag = widget.isSpanish ? lastWithTag.aiFocusTagEs : lastWithTag.aiFocusTagEn;
        if (tag != null && tag.isNotEmpty) {
          return tag.toUpperCase();
        }
      } catch (_) {}

      final lastLog = widget.logs.first;
      final translatedFocus = SurfConstants.getFocusSkillTranslation(
        lastLog.sessionFocus,
        widget.isSpanish,
      );
      return _t(
        "Last time: $translatedFocus",
        "Última vez: $translatedFocus",
      );
    }

    return _t("Ready to log your surf?", "¿Listo para registrar tu surf?");
  }

  String _getLastSurfText() {
    if (widget.lastSurfedDate == null) return "";
    final now = DateTime.now();
    final last = widget.lastSurfedDate!;
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    final diff = today.difference(lastDay).inDays;

    if (diff == 0) return _t("Last surf: Today", "Último surf: Hoy");
    if (diff == 1) return _t("Last surf: Yesterday", "Último surf: Ayer");
    return _t("Last surf: $diff days ago", "Último surf: hace $diff días");
  }

  List<Map<String, String>> getVisibleProfileFields(bool isSpanish) {
    return SurfDashboardData(
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
      latestMediaPath: widget.latestMediaPath,
      latestMediaType: widget.latestMediaType,
    ).getVisibleProfileFields(isSpanish);
  }

  Widget _buildProgressionNudge() {
    if (widget.isSurferPro || widget.logs.length < 5) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        onTap: () => widget.onOpenSurferPro(),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.trending_up, color: AppTheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t("You're starting to build patterns in your surfing.", "Estás empezando a crear patrones en tu surf."),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t("Unlock progress patterns to see what’s actually improving.", "Desbloquea patrones de progreso para ver qué está mejorando realmente."),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildPassiveInsightNudge() {
    if (widget.isSurferPro) return const SizedBox.shrink();
    
    // Trigger 5: 3 sessions after first insight without generating
    final firstInsightIndex = widget.logs.lastIndexWhere((l) => l.aiSummaryEn != null || l.aiSummaryEs != null);
    if (firstInsightIndex == -1) return const SizedBox.shrink();
    
    // Sessions logged after the one with insight
    final sessionsAfter = firstInsightIndex; 
    if (sessionsAfter < 3) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        onTap: widget.onOpenLogTab,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: AppTheme.secondary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t("You’ve logged a few sessions...", "Has registrado algunas sesiones..."),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t("Want to see what’s changing?", "¿Quieres ver qué está cambiando?"),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const Text("🚀", style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
