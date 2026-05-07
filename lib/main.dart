import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'ui_system/app_theme.dart';
import 'features/coach_pro/subscription_service.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/passport/passport_screen.dart';
import 'features/onboarding/guided_tour_overlay.dart';
import 'features/onboarding/splash_screen.dart';

import 'features/session_log/session_log_entry.dart';
import 'features/session_log/session_log_screen.dart';

import 'features/map/map_models.dart';
import 'features/map/map_screen.dart';

import 'features/Settings/settings_models.dart';
import 'features/Settings/settings_screen.dart';
import 'widgets/orientation_prompt.dart';
import 'widgets/success_banner.dart';
import 'storage/app_storage.dart';
import 'models/surf_dashboard_data.dart';
import 'models/reflection_model.dart';
import 'models/ai_analysis_model.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'core/subscription_config.dart';
import 'features/surfer_pro/surfer_pro_paywall.dart';
import 'features/surfer_pro/surfer_pro_screen.dart';
import 'features/session_log/firebase_service.dart';

import 'core/translation_service.dart';
import 'core/analyze_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService().initialize();
  await TranslationService().initialize();
  runApp(const SmartSurfApp());
}

class SmartSurfApp extends StatefulWidget {
  const SmartSurfApp({super.key});

  @override
  State<SmartSurfApp> createState() => _SmartSurfAppState();
}

class _SmartSurfAppState extends State<SmartSurfApp> {
  bool _isBooting = true;
  bool _showSplash = true;
  bool _showOnboarding = true;
  bool _enteredThisSession = false;
  bool _showReturnNudge = false;
  int _index = 0;

  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey<SessionLogScreenState> _addSessionKey = GlobalKey<SessionLogScreenState>();
  final GlobalKey<SurfPassportScreenState> _passportKey = GlobalKey<SurfPassportScreenState>();
  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();
  OverlayEntry? _tourOverlay;

  final SubscriptionService _subService = SubscriptionService();
  StreamSubscription<User?>? _authSubscription;
  AppSettings _settings = const AppSettings(isSpanish: false, isCoachPro: false, isSurferPro: false, isSurferTrial: false);

  final List<SessionReflection> _reflections = [];
  final List<AiAnalysisResult> _aiAnalyses = [];
  final List<SessionLogEntry> _sessionLogs = [];

  bool get _isSpanish => _settings.isSpanish;

  void _triggerAddSession() {
    setState(() => _index = 2); // Switch to Log tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addSessionKey.currentState?.openAddSessionSheet();
    });
  }

  void _updateSettings(AppSettings newSettings) {
    setState(() => _settings = newSettings);
    AppStorage.saveSettings(newSettings);
  }

  void _setLanguage(bool spanish) {
    _updateSettings(_settings.copyWith(isSpanish: spanish));
  }



  void _resetOnboarding() {
    setState(() {
      _levelEnTitle = "";
      _levelEnDesc = "";
      _comfortEn = "";
      _boardEn = "";
      _focusEn = [];
      _stance = "";
      _displayName = "";
      _profilePhotoPath = null;
      _height = "";
      _weight = "";
      _location = "";
      _age = "";
      _surferSummary = "";
    });
    AppStorage.clearTourFlags();
    _updateSettings(_settings.copyWith(
      hasEnteredApp: false, 
      hasSeenOnboarding: false, 
      hasSeenGuidedTour: false, 
      seenPassportPrompt: false,
      hasSeenDashboardGuidance: false,
      hasSeenPassportGuidance: false,
      hasSeenProfileNudge: false,
      hasSeenMapTip: false,
      hasSeenSettingsTip: false,
      hasSeenWelcomeGuide: false,
      appVersion: '1.0.1'
    ));
    if (mounted) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(_isSpanish ? 'Onboarding reiniciado.' : 'Smart Surf reset!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _initPurchaseListener() {
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      debugPrint('[Purchases] CustomerInfo updated. checking entitlements...');
      final isCoachPro = customerInfo.entitlements.all[SubscriptionConfig.entitlementCoachPro]?.isActive ?? false;
      final isSurferPro = customerInfo.entitlements.all[SubscriptionConfig.entitlementSurferPro]?.isActive ?? false;
      
      if (_settings.isCoachPro != isCoachPro || _settings.isSurferPro != isSurferPro) {
        debugPrint('[Purchases] Entitlement state changed! Coach: $isCoachPro, Surfer: $isSurferPro');
        _updateSettings(_settings.copyWith(
          isCoachPro: isCoachPro,
          isSurferPro: isSurferPro,
        ));
      }
    });
  }

  void _initAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.userChanges().listen((user) async {
      debugPrint('[AuthSync] User changed: ${user?.uid}');
      if (user != null) {
        await _subService.logIn(user.uid);
      } else {
        await _subService.logOut();
      }
      
      // After identity switch, refresh entitlements
      final coachActive = await _subService.isCoachProActive();
      final surferActive = await _subService.isSurferProActive();
      
      if (_settings.isCoachPro != coachActive || _settings.isSurferPro != surferActive) {
        debugPrint('[AuthSync] Entitlements changed after identity switch. Refreshing UI.');
        _updateSettings(_settings.copyWith(
          isCoachPro: coachActive,
          isSurferPro: surferActive,
        ));
      }
    });
  }

// Canonical values stored in EN
  String _levelEnTitle = "";
  String _levelEnDesc = "";
  String _comfortEn = "";
  String _boardEn = "";
  List<String> _focusEn = const [];
  String _stance = "";
  String _displayName = "";
  String? _profilePhotoPath;
  String _height = "";
  String _weight = "";
  String _location = "";
  String _age = "";
  String _surferSummary = "";
  bool _stanceVisibleToCoach = false;
  bool _stanceVisibleOnDashboard = true;
  bool _heightVisibleToCoach = false;
  bool _heightVisibleOnDashboard = true;
  bool _weightVisibleToCoach = false;
  bool _weightVisibleOnDashboard = true;
  bool _locationVisibleToCoach = false;
  bool _locationVisibleOnDashboard = true;
  bool _ageVisibleToCoach = false;
  bool _ageVisibleOnDashboard = true;
  // Derived from logs
  SessionLogEntry? get _latestLoggedSession => _sessionLogs.isEmpty ? null : _sessionLogs.first;
  int get _sessionsSurfed => _sessionLogs.where((s) => s.isCompleted).length;
  DateTime? get _lastSurfedDate => _sessionLogs.isEmpty ? null : _sessionLogs.first.date;
  
  int get _sessionsThisMonth {
    final now = DateTime.now();
    return _sessionLogs.where((s) => s.isCompleted && s.date.year == now.year && s.date.month == now.month).length;
  }

  int get _currentStreak {
    if (_sessionLogs.isEmpty) return 0;
    // Simple streak: consecutive days with sessions
    int streak = 0;
    DateTime date = DateTime.now();
    // Normalize to date only
    date = DateTime(date.year, date.month, date.day);
    
    while (true) {
      final hasSession = _sessionLogs.any((s) => 
        s.isCompleted && 
        s.date.year == date.year && 
        s.date.month == date.month && 
        s.date.day == date.day
      );
      if (hasSession) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  String? get _latestMediaPath {
    try {
      return _sessionLogs.firstWhere((s) => s.mediaPath != null).mediaPath;
    } catch (_) {
      return null;
    }
  }
  String? get _latestMediaType {
    try {
      return _sessionLogs.firstWhere((s) => s.mediaPath != null).mediaType;
    } catch (_) {
      return null;
    }
  }

  String _t(String en, String es) => _isSpanish ? es : en;

  void _updateProfile({
    required String levelEnTitle,
    required String levelEnDesc,
    required String comfortEn,
    required String boardEn,
    required List<String> focusEn,
    required String stance,
    required String height,
    required String weight,
    required String location,
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
    String? latestMediaPath,
    String? latestMediaType,
    required String age,
    required String surferSummary,
    required bool ageVisibleToCoach,
    required bool ageVisibleOnDashboard,
    required String units,
  }) {
    setState(() {
      _levelEnTitle = levelEnTitle;
      _levelEnDesc = levelEnDesc;
      _comfortEn = comfortEn;
      _boardEn = boardEn;
      _focusEn = focusEn;
      _stance = stance;
      _height = height;
      _weight = weight;
      _location = location;
      _displayName = displayName;
      _profilePhotoPath = profilePhotoPath;
      _age = age;
      _surferSummary = surferSummary;
      _stanceVisibleToCoach = stanceVisibleToCoach;
      _stanceVisibleOnDashboard = stanceVisibleOnDashboard;
      _heightVisibleToCoach = heightVisibleToCoach;
      _heightVisibleOnDashboard = heightVisibleOnDashboard;
      _weightVisibleToCoach = weightVisibleToCoach;
      _weightVisibleOnDashboard = weightVisibleOnDashboard;
      _locationVisibleToCoach = locationVisibleToCoach;
      _locationVisibleOnDashboard = locationVisibleOnDashboard;
      _ageVisibleToCoach = ageVisibleToCoach;
      _ageVisibleOnDashboard = ageVisibleOnDashboard;
    // derived from logs now
    });
    
    // If latestMediaPath/Type is passed specifically (e.g. from an edit directly but not through _addSession)
    // we find the latest session and update it.
    if (latestMediaPath != null) {
      final latest = _latestLoggedSession;
      if (latest != null) {
        final updated = latest.copyWith(
          mediaPath: latestMediaPath,
          mediaType: latestMediaType ?? 'image',
        );
        _addSession(updated);
      }
    }

    AppStorage.saveProgress(SurfDashboardData(
      levelTitle: _levelEnTitle,
      levelDesc: _levelEnDesc,
      comfortZone: _comfortEn,
      board: _boardEn,
      focusSkills: _focusEn,
      stance: _stance,
      height: _height,
      weight: _weight,
      location: _location,
      displayName: _displayName,
      profilePhotoPath: _profilePhotoPath,
      stanceVisibleToCoach: _stanceVisibleToCoach,
      stanceVisibleOnDashboard: _stanceVisibleOnDashboard,
      heightVisibleToCoach: _heightVisibleToCoach,
      heightVisibleOnDashboard: _heightVisibleOnDashboard,
      weightVisibleToCoach: _weightVisibleToCoach,
      weightVisibleOnDashboard: _weightVisibleOnDashboard,
      locationVisibleToCoach: _locationVisibleToCoach,
      locationVisibleOnDashboard: _locationVisibleOnDashboard,
      latestMediaPath: _latestMediaPath,
      latestMediaType: _latestMediaType,
      age: _age,
      surferSummary: _surferSummary,
      ageVisibleToCoach: _ageVisibleToCoach,
      ageVisibleOnDashboard: _ageVisibleOnDashboard,
      email: FirebaseAuth.instance.currentUser?.email,
    ));
    
    // Objective 4.2: Aggressively sync to Firestore
    FirebaseService().saveFullProfile(SurfDashboardData(
      levelTitle: _levelEnTitle,
      levelDesc: _levelEnDesc,
      comfortZone: _comfortEn,
      board: _boardEn,
      focusSkills: _focusEn,
      stance: _stance,
      height: _height,
      weight: _weight,
      location: _location,
      displayName: _displayName,
      profilePhotoPath: _profilePhotoPath,
      stanceVisibleToCoach: _stanceVisibleToCoach,
      stanceVisibleOnDashboard: _stanceVisibleOnDashboard,
      heightVisibleToCoach: _heightVisibleToCoach,
      heightVisibleOnDashboard: _heightVisibleOnDashboard,
      weightVisibleToCoach: _weightVisibleToCoach,
      weightVisibleOnDashboard: _weightVisibleOnDashboard,
      locationVisibleToCoach: _locationVisibleToCoach,
      locationVisibleOnDashboard: _locationVisibleOnDashboard,
      latestMediaPath: _latestMediaPath,
      latestMediaType: _latestMediaType,
      age: _age,
      surferSummary: _surferSummary,
      ageVisibleToCoach: _ageVisibleToCoach,
      ageVisibleOnDashboard: _ageVisibleOnDashboard,
      email: FirebaseAuth.instance.currentUser?.email,
    ));
  }




  void _addSession(SessionLogEntry entry, {bool showBanner = false}) {
    setState(() {
      // If updating an existing session (by ID), replace it. Otherwise add new.
      final idx = _sessionLogs.indexWhere((e) => e.id == entry.id);
      if (idx != -1) {
        _sessionLogs[idx] = entry;
      } else {
        _sessionLogs.insert(0, entry);
      }
      _sessionLogs.sort((a, b) => b.date.compareTo(a.date));

      if (showBanner) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(_isSpanish ? "Sesión registrada" : "Session logged"),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Objective 4: Auto-Add Logged Surf Spot to Map
      if (entry.isCompleted && entry.spotName.isNotEmpty && entry.spotName != (_isSpanish ? "Sesión Actual" : "Current Session")) {
        final bool alreadyExists = _spots.any((s) => s.name.toLowerCase() == entry.spotName.toLowerCase());
        if (!alreadyExists) {
          final newSpot = SurfSpot(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: entry.spotName,
            region: entry.countryOrRegion,
            lat: 0.0, 
            lng: 0.0,
            createdAt: DateTime.now(),
          );
          _spots.add(newSpot);
          AppStorage.saveSpots(_spots);
        }
      }
    });
    AppStorage.saveSessions(_sessionLogs);
    AppStorage.saveProgress(SurfDashboardData(
      levelTitle: _levelEnTitle,
      levelDesc: _levelEnDesc,
      comfortZone: _comfortEn,
      board: _boardEn,
      focusSkills: _focusEn,
      stance: _stance,
      height: _height,
      weight: _weight,
      location: _location,
      displayName: _displayName,
      profilePhotoPath: _profilePhotoPath,
      stanceVisibleToCoach: _stanceVisibleToCoach,
      stanceVisibleOnDashboard: _stanceVisibleOnDashboard,
      heightVisibleToCoach: _heightVisibleToCoach,
      heightVisibleOnDashboard: _heightVisibleOnDashboard,
      weightVisibleToCoach: _weightVisibleToCoach,
      weightVisibleOnDashboard: _weightVisibleOnDashboard,
      locationVisibleToCoach: _locationVisibleToCoach,
      locationVisibleOnDashboard: _locationVisibleOnDashboard,
      latestMediaPath: _latestMediaPath,
      latestMediaType: _latestMediaType,
      age: _age,
      surferSummary: _surferSummary,
      ageVisibleToCoach: _ageVisibleToCoach,
      ageVisibleOnDashboard: _ageVisibleOnDashboard,
      email: FirebaseAuth.instance.currentUser?.email,
    ));
    
    // Objective 4.2: Aggressively sync to Firestore
    FirebaseService().saveSessionToFirestore(entry);
    
    // Sync to Firestore
    FirebaseService().saveFullProfile(SurfDashboardData(
      levelTitle: _levelEnTitle,
      levelDesc: _levelEnDesc,
      comfortZone: _comfortEn,
      board: _boardEn,
      focusSkills: _focusEn,
      stance: _stance,
      height: _height,
      weight: _weight,
      location: _location,
      displayName: _displayName,
      profilePhotoPath: _profilePhotoPath,
      stanceVisibleToCoach: _stanceVisibleToCoach,
      stanceVisibleOnDashboard: _stanceVisibleOnDashboard,
      heightVisibleToCoach: _heightVisibleToCoach,
      heightVisibleOnDashboard: _heightVisibleOnDashboard,
      weightVisibleToCoach: _weightVisibleToCoach,
      weightVisibleOnDashboard: _weightVisibleOnDashboard,
      locationVisibleToCoach: _locationVisibleToCoach,
      locationVisibleOnDashboard: _locationVisibleOnDashboard,
      latestMediaPath: _latestMediaPath,
      latestMediaType: _latestMediaType,
      age: _age,
      surferSummary: _surferSummary,
      ageVisibleToCoach: _ageVisibleToCoach,
      ageVisibleOnDashboard: _ageVisibleOnDashboard,
      email: FirebaseAuth.instance.currentUser?.email,
    ));
  }

  Future<SessionLogEntry?> _unlockFirstInsight() async {
    if (_sessionLogs.length < 3) return null;
    
    // Most recent completed session
    final lastSession = _sessionLogs.firstWhere((e) => e.isCompleted, orElse: () => _sessionLogs.first);
    // forceRefresh:true ensures we never send a stale cached token (avoids 401)
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (idToken == null) return null;

    try {
      final result = await AnalyzeApi.analyzeReflection(
        idToken: idToken,
        sessionId: lastSession.id,
        focus: lastSession.sessionFocus,
        workedOn: lastSession.sessionFocus,
        feltHard: lastSession.reflectionWhatWasChallenging ?? "",
        feltGood: lastSession.reflectionWhatFeltGood ?? "",
        conditions: lastSession.reflectionConditions ?? "",
        notes: lastSession.notes,
        language: _isSpanish ? "es" : "en",
      );

      final updatedSession = lastSession.copyWith(
        aiSummaryEn: result['session_insight_en'],
        aiSummaryEs: result['session_insight_es'],
        aiProgressPatternEn: result['progress_pattern_en'],
        aiProgressPatternEs: result['progress_pattern_es'],
        aiNextFocusEn: result['next_session_focus_en'],
        aiNextFocusEs: result['next_session_focus_es'],
      );
      
      _addSession(updatedSession);
      return updatedSession;

    } catch (e) {
      debugPrint("Error unlocking first insight: $e");
      if (mounted) {
        String message = _isSpanish ? "Error al desbloquear insight" : "Error unlocking insight";
        if (e.toString().contains('DAILY_LIMIT_REACHED')) {
          message = _isSpanish 
            ? "Daily insight limit reached. You can generate up to 3 insights per day."
            : "Daily insight limit reached. You can generate up to 3 insights per day.";
        }
        _messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      return null;
    }
  }
  Future<SessionLogEntry?> _generateInsight(SessionLogEntry session) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "unknown";
    final String utcDayKey = DateTime.now().toUtc().toIso8601String().split('T')[0];
    final bool hasExisting = (session.aiSummaryEn?.isNotEmpty == true) || (session.aiSummary?.isNotEmpty == true);
    
    debugPrint("--- [PaywallGate] ---");
    debugPrint("[PaywallGate] Session ID: ${session.id}");
    debugPrint("[PaywallGate] hasExisting: $hasExisting");
    debugPrint("[PaywallGate] usedFirstFree: ${_settings.hasUsedFirstFreeAIInsight}");
    
    // 1. If it's an existing insight, we always allow opening it (re-opening doesn't count against limit or need pro)
    if (hasExisting) {
      debugPrint("[PaywallGate] ALLOWED: Existing insight.");
    } else {
      // 2. Daily Limit Check (Max 3 per UTC day)
      final dailyInfo = await FirebaseService().getDailyInsightInfo(utcDayKey);
      final int dailyCount = dailyInfo['count'];
      final List<dynamic> sessionIds = dailyInfo['sessionIds'];
      
      debugPrint("--- [DailyLimitAudit] ---");
      debugPrint("[Limit] User ID: $userId");
      debugPrint("[Limit] UTC Day: $utcDayKey");
      debugPrint("[Limit] Current Count: $dailyCount");
      debugPrint("[Limit] Sessions counted today:");
      if (sessionIds.isEmpty && dailyCount > 0) {
        debugPrint("  - (Legacy sessions without IDs tracked: $dailyCount)");
      } else {
        for (var sid in sessionIds) {
          debugPrint("  - $sid");
        }
      }
      
      FirebaseService().logEvent('insight_limit_check', parameters: {
        'dailyInsightCount': dailyCount,
        'dailyLimitAllowed': dailyCount < 3 ? 1 : 0,
        'utcDayKey': utcDayKey,
      });

      if (dailyCount >= 3) {
        debugPrint("[Limit] BLOCKED: Daily limit of 3 reached.");
        debugPrint("[Limit] dailyLimitReachedDetected: true");
        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(_isSpanish 
              ? "Límite diario de insights alcanzado. Puedes generar hasta 3 insights por día."
              : "Daily insight limit reached. You can generate up to 3 insights per day."),
            backgroundColor: AppTheme.primary,
          ),
        );
        debugPrint("[Limit] snackbarShown: true");
        debugPrint("[Limit] loadingStopped: true (via return null)");
        return null;
      }

      // 3. Eligibility Check for NEW insights
      debugPrint("[InsightEligibility] Checking eligibility for NEW insight...");
      bool isEligible = false;
      bool isPro = await SubscriptionService().isSurferProActive();
      
      // Log initial state
      FirebaseService().logEvent('insight_eligibility_start', parameters: {
        'usedFirstFree': _settings.hasUsedFirstFreeAIInsight ? "true" : "false",
        'isPro': isPro ? "true" : "false",
        'sessionId': session.id,
      });

      if (!_settings.hasUsedFirstFreeAIInsight) {
        debugPrint("[InsightEligibility] ALLOWED: Using first free insight.");
        isEligible = true;
      } else {
        debugPrint("[EntitlementCheck] First free used. Pro status: $isPro");
        if (isPro) {
          isEligible = true;
        } else {
          debugPrint("[PaywallGate] BLOCKED: No active Pro entitlement. Opening Paywall.");
          if (mounted) {
            final bool? purchaseResult = await openSurferProPaywall(
              context, 
              source: 'generate_insight_gate', 
              isSpanish: _isSpanish
            );
            
            final bool purchaseSuccess = purchaseResult ?? false;
            debugPrint("[PurchaseFlow] Paywall closed. success: $purchaseSuccess");
            
            if (purchaseSuccess) {
              // Re-verify entitlement after purchase
              isPro = await SubscriptionService().isSurferProActive();
              debugPrint("[PurchaseFlow] Entitlement active after purchase: $isPro");
              
              FirebaseService().logEvent('purchase_flow_result', parameters: {
                'purchaseSuccess': "true",
                'entitlementActiveAfterPurchase': isPro ? "true" : "false",
                'pendingInsightSessionId': session.id,
                'continuingPendingGeneration': isPro ? "true" : "false",
              });

              if (isPro) {
                isEligible = true;
                _updateSettings(_settings.copyWith(isSurferPro: true));
              }
            } else {
              FirebaseService().logEvent('purchase_flow_result', parameters: {
                'purchaseSuccess': "false",
                'pendingInsightSessionId': session.id,
                'continuingPendingGeneration': "false",
              });
            }
          }
        }
      }

      if (!isEligible) {
        debugPrint("[PaywallGate] FINAL BLOCKED: User is not eligible for a new insight.");
        return null;
      }
      debugPrint("[PaywallGate] FINAL ALLOWED: Proceeding to AI generation.");
    }

    final bool willGenerate = !hasExisting;
    debugPrint("--- [DailyLimitAudit] ---");
    debugPrint("[Limit] User ID: $userId");
    debugPrint("[Limit] UTC Day: $utcDayKey");
    debugPrint("[Limit] Session ID: ${session.id}");
    debugPrint("[Limit] Existing Insight: $hasExisting");
    debugPrint("[Limit] Will Generate New: $willGenerate");
    
    debugPrint("--- [AI Generation Debug] ---");
    debugPrint("[AI Gen] Session ID: ${session.id}");
    debugPrint("[AI Gen] User ID: ${FirebaseAuth.instance.currentUser?.uid}");
    debugPrint("[AI Gen] Total Logs: ${_sessionLogs.length}");
    debugPrint("[AI Gen] hasSeenWelcomeGuide: ${_settings.hasSeenWelcomeGuide}");
    debugPrint("[AI Gen] seenFirstPrompt: ${_settings.hasSeenFirstInsightPrompt}");
    debugPrint("[AI Gen] usedFirstFree: ${_settings.hasUsedFirstFreeAIInsight}");
    debugPrint("[AI Gen] isPro: ${_settings.isSurferPro}");
    
    // forceRefresh:true ensures we never send a stale cached token (avoids 401)
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (idToken == null) {
      debugPrint("[AI Gen] FAILED: No ID token available (user not signed in)");
      return null;
    }
    debugPrint("[AI Gen] Token fetched (starts with ${idToken.substring(0, 10)}...)");

    try {
      debugPrint("[AI Gen] Calling Backend API...");
      final result = await AnalyzeApi.analyzeReflection(
        idToken: idToken,
        sessionId: session.id,
        focus: session.sessionFocus,
        workedOn: session.sessionFocus,
        feltHard: session.reflectionWhatWasChallenging ?? "",
        feltGood: session.reflectionWhatFeltGood ?? "",
        conditions: session.reflectionConditions ?? "",
        notes: session.notes,
        language: _isSpanish ? "es" : "en",
        waveHeight: session.waveSize,
        board: session.board,
      );

      debugPrint("[AI Gen] SUCCESS: Backend responded.");
      debugPrint("[AI Gen] Payload: $result");

      final updatedSession = session.copyWith(
        aiSummaryEn: result['session_insight_en'],
        aiSummaryEs: result['session_insight_es'],
        aiProgressPatternEn: result['progress_pattern_en'],
        aiProgressPatternEs: result['progress_pattern_es'],
        aiNextFocusEn: result['next_session_focus_en'],
        aiNextFocusEs: result['next_session_focus_es'],
        aiFocusTagEn: result['focus_tag_en'],
        aiFocusTagEs: result['focus_tag_es'],
      );
      
      _addSession(updatedSession);

      if (willGenerate) {
        if (!_settings.hasUsedFirstFreeAIInsight) {
          debugPrint("[AI Gen] Marking first free insight as USED.");
          _updateSettings(_settings.copyWith(hasUsedFirstFreeAIInsight: true));
        }
        await FirebaseService().incrementDailyInsightCount(utcDayKey, session.id);
        debugPrint("[Limit] Daily count incremented for $utcDayKey");
      }

      debugPrint("[AI Gen] Flow complete.");
      return updatedSession;

    } catch (e) {
      debugPrint("[AI Gen] ERROR: $e");
      if (mounted) {
        String errorMsg = _isSpanish ? "Ocurrió un error. Revisa tu conexión." : "An error occurred. Please check your connection.";
        
        if (e.toString().contains('AUTH_ERROR')) {
          errorMsg = _isSpanish ? "Sesión expirada o inválida. Revisa tu cuenta." : "Authentication failed. ${e.toString().split('AUTH_ERROR: ').last}";
        } else if (e.toString().contains('DAILY_LIMIT_REACHED')) {
          debugPrint("[Limit] dailyLimitReachedDetected: true (from backend)");
          errorMsg = _isSpanish 
            ? "Límite de insights alcanzado. Puedes generar hasta 3 insights por día." 
            : "Daily insight limit reached. You can generate up to 3 insights per day.";
          debugPrint("[Limit] snackbarShown: true");
          debugPrint("[Limit] loadingStopped: true (via return null in catch)");
        } else if (e.toString().contains('PAYWALL_REQUIRED')) {
          debugPrint("[AI Gen] Paywall required. Showing modal.");
          openSurferProPaywall(context, source: 'backend_gate', isSpanish: _isSpanish);
          return null; // Return early, don't show snackbar for paywall
        } else if (e.toString().contains('BACKEND_ERROR')) {
          errorMsg = _isSpanish ? "Insight no disponible en este momento." : "Insight unavailable right now.";
        }

        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }


  void _showSurferProUpgradePrompt(BuildContext context, {
    String? title, 
    String? content, 
    bool isSoftUpsell = false,
    VoidCallback? onSeeThisOneFirst,
  }) {
    if (isSoftUpsell && _settings.surferProPopupSuppressedUntil > _sessionLogs.length) {
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title ?? (_isSpanish ? '¿Quieres ayuda para entender tus sesiones?' : 'want help figuring out your sessions?'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(content ?? (_isSpanish 
          ? 'Obtén insights sencillos después de cada surf para que sepas exactamente en qué enfocarte después.' 
          : 'get simple insights after each surf so you know what to focus on next')),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    openSurferProPaywall(context, source: 'soft_upsell_modal', isSpanish: _isSpanish);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_isSpanish ? 'empezar prueba gratis de 3 días' : 'start free 3-day trial'),
                ),
              ),
              if (onSeeThisOneFirst != null)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onSeeThisOneFirst();
                    },
                    child: Text(_isSpanish ? 'ver este primero' : 'see this one first'),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _updateSettings(_settings.copyWith(
                      surferProPopupSuppressedUntil: _sessionLogs.length + 2,
                    ));
                  },
                  child: Text(_isSpanish ? 'seguir explorando' : 'keep exploring', style: const TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _addAiAnalysis(AiAnalysisResult r) {
    setState(() => _aiAnalyses.insert(0, r));
    AppStorage.saveAiAnalyses(_aiAnalyses);
  }

  void _deleteSession(String id) {
    setState(() => _sessionLogs.removeWhere((e) => e.id == id));
    AppStorage.saveSessions(_sessionLogs);
    FirebaseService().deleteSessionFromFirestore(id);
  }

  Future<void> _performFullReset() async {
    // 1. Clear all local state
    setState(() {
      _sessionLogs.clear();
      _aiAnalyses.clear();
      _reflections.clear();
      _spots.clear();
      _focusEn = [];
      _levelEnTitle = "";
      _levelEnDesc = "";
      _comfortEn = "";
      _boardEn = "";
      _displayName = "";
      _profilePhotoPath = null;
      _index = 0;
      _showOnboarding = true;
      _enteredThisSession = false;
      _location = "";
      _age = "";
      _stance = "";
      _height = "";
      _weight = "";
      _surferSummary = "";
      
      // Ensure specific onboarding flags are reset for reliable testing
      _settings = _settings.copyWith(
        hasSeenOnboarding: false,
        seenDashboardPrompt: false,
        seenLogPrompt: false,
        seenPassportPrompt: false,
        hasEnteredApp: false,
        hasSeenWelcomeGuide: false,
        hasSeenGuidedTour: false,
        hasSeenFirstInsightPrompt: false,
        hasUsedFirstFreeAIInsight: false,
        hasSeenAIRepeatNudge: false,
        hasSeenMapTip: false,
        hasSeenSettingsTip: false,
        hasSeenDashboardGuidance: false,
        hasSeenPassportGuidance: false,
        hasSeenProfileNudge: false,
        hasSeenDashboardGuide: false,
        hasSeenLogGuide: false,
        hasSeenPassportGuide: false,
        hasSeenReturnNudge: false,
        hasSeenLogPulse: false,
        hasSeenPostFirstSessionPassportPrompt: false,
        hasSeenPostPassportProfilePrompt: false,
        isCoachPro: false,
        isSurferPro: false,
        isSurferTrial: false,
        insightsViewedCount: 0,
        surferProPopupSuppressedUntil: 0,
        lastNudgeShownAt: 0,
      );
    });

    // 2. Clear persistent storage
    await AppStorage.clearAll();
    
    // 3. Clear cloud state if authenticated
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        
        // Delete sessions collection
        final sessions = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sessions')
            .get();
        for (var doc in sessions.docs) {
          batch.delete(doc.reference);
        }
        
        // Delete user document
        batch.delete(FirebaseFirestore.instance.collection('users').doc(uid));

        // Delete stats collection (Daily insight counters)
        final stats = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('stats')
            .get();
        for (var doc in stats.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        await FirebaseAuth.instance.signOut();
        debugPrint("Cloud Reset: SUCCESS for $uid");
      } catch (e) {
        debugPrint("Cloud Reset: ERROR: $e");
      }
    }

    if (mounted) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(_isSpanish ? 'Datos restablecidos por completo' : 'App data fully reset'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Spots
  List<SurfSpot> _spots = [];
  void _setSpots(List<SurfSpot> spots) {
    setState(() => _spots = spots);
    AppStorage.saveSpots(spots);
  }

// Reflections
  void _addReflection(SessionReflection r) {
    setState(() => _reflections.insert(0, r));
    AppStorage.saveReflections(_reflections);
  }

  void _showSurferPro({String? title, String? content}) {
    if (_sessionLogs.length < 3) return; // Beginner Flow Gating
    FirebaseService().logEvent('surfer_pro_opened');
    if (_navigatorKey.currentContext != null) {
      if (_settings.isSurferPro) {
        showSurferProModal(
          context: _navigatorKey.currentContext!,
          isSpanish: _isSpanish,
          isSurferPro: _settings.isSurferPro,
          reflections: _reflections,
          onAddReflection: _addReflection,
          aiAnalyses: _aiAnalyses,
          onAddAiAnalysis: _addAiAnalysis,
        );
      } else {
        openSurferProPaywall(
          _navigatorKey.currentContext!,
          source: 'dashboard_explore',
          isSpanish: _isSpanish,
        );
      }
    }
  }

  void _onReturnToDashboard() {
    setState(() => _index = 0);
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  void initState() {
    super.initState();
    _initPurchaseListener();
    _initAuthListener();
    _boot();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    // 0. Initialize Subscription Service
    debugPrint('[AppBoot] Verifying entitlements on launch...');
    bool isCoachPro = false;
    bool isSurferPro = false;
    bool isSurferTrial = false;

    try {
      await _subService.init();
      
      // Ensure current user is logged into RevenueCat at boot
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint('[AppBoot] Syncing identity for already logged in user: ${currentUser.uid}');
        await _subService.logIn(currentUser.uid);
      }
      
      isCoachPro = await _subService.isCoachProActive();
      isSurferPro = await _subService.isSurferProActive();
      isSurferTrial = await _subService.isSurferTrialActive();
      
      debugPrint('[AppBoot] Verification complete. Coach: $isCoachPro, Surfer: $isSurferPro');
    } catch (e) {
      debugPrint('[AppBoot] Error during verification: $e');
      // On error, we remain with default 'false' values (fail-safe)
    }

    // 1. Initialize Firebase & Auth centrally

    // 2. Load disk cache, then aggressively override with authenticated stable Links from Firestore
    final rawData = await AppStorage.loadAll();
    final data = await FirebaseService().hydrateLocalsFromFirestore(rawData);

    // Calculate return nudge
    bool showReturnNudge = false;
    if (data.settings.lastLoginDate != null) {
      final lastLogin = DateTime.tryParse(data.settings.lastLoginDate!);
      if (lastLogin != null) {
        final diff = DateTime.now().difference(lastLogin).inDays;
        if (diff >= 3 && !data.settings.hasSeenReturnNudge) {
          showReturnNudge = true;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _settings = data.settings.copyWith(
        isCoachPro: isCoachPro,
        isSurferPro: isSurferPro,
        isSurferTrial: isSurferTrial,
        lastLoginDate: DateTime.now().toIso8601String(),
      );
      _showReturnNudge = showReturnNudge;
      final user = FirebaseAuth.instance.currentUser;
      _showOnboarding = user == null || !_settings.hasSeenOnboarding;
      _isBooting = false;
      
      // If we skip onboarding because hasSeenOnboarding is true, we mark this session as "entered" 
      // from prior history, triggering the QuickStart modal immediately.
      if (!_showOnboarding) {
        _enteredThisSession = true;
      }
      
      _levelEnTitle = data.progress.levelTitle;
      _levelEnDesc = data.progress.levelDesc;
      _comfortEn = data.progress.comfortZone;
      _boardEn = data.progress.board;
      _focusEn = data.progress.focusSkills;
      _stance = data.progress.stance;
      _height = data.progress.height;
      _weight = data.progress.weight;
      _location = data.progress.location;
      _displayName = data.progress.displayName;
      _profilePhotoPath = data.progress.profilePhotoPath;
      _stanceVisibleToCoach = data.progress.stanceVisibleToCoach;
      _stanceVisibleOnDashboard = data.progress.stanceVisibleOnDashboard;
      _heightVisibleToCoach = data.progress.heightVisibleToCoach;
      _heightVisibleOnDashboard = data.progress.heightVisibleOnDashboard;
      _weightVisibleToCoach = data.progress.weightVisibleToCoach;
      _weightVisibleOnDashboard = data.progress.weightVisibleOnDashboard;
      _locationVisibleToCoach = data.progress.locationVisibleToCoach;
      _locationVisibleOnDashboard = data.progress.locationVisibleOnDashboard;
      _age = data.progress.age;
      _surferSummary = data.progress.surferSummary;
      _ageVisibleToCoach = data.progress.ageVisibleToCoach;
      _ageVisibleOnDashboard = data.progress.ageVisibleOnDashboard;
      // _latestMediaPath/Type no longer stored as state in app state, derived from _sessionLogs loaded below

      _sessionLogs.clear();
      _sessionLogs.addAll(data.sessions);

      _reflections.clear();
      _reflections.addAll(data.reflections);

      _aiAnalyses.clear();
      _aiAnalyses.addAll(data.aiAnalyses);

      _spots = data.spots;
    });
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Smart Surf',
      theme: AppTheme.themeData,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    debugPrint('--- BUILD HOME DEBUG ---');
    debugPrint('Current Index: $_index');
    debugPrint('Show Onboarding: $_showOnboarding');
    debugPrint('hasSeenWelcomeGuide: ${_settings.hasSeenWelcomeGuide}');

    if (_showSplash) {
      return SplashScreen(onFinish: () {
        setState(() => _showSplash = false);
      });
    }

    if (_isBooting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showOnboarding) {
      return OnboardingScreen(
        isSpanish: _isSpanish,
        onSetLanguage: _setLanguage,
        onFinish: (name, profilePhotoPath, comfortZone, boardType) {
          // Update profile data
          if (name != null) _displayName = name;
          if (profilePhotoPath != null) _profilePhotoPath = profilePhotoPath;
          if (comfortZone != null) _comfortEn = comfortZone;
          if (boardType != null) _boardEn = boardType;


          // Save profile progress
          AppStorage.saveProgress(SurfDashboardData(
            levelTitle: _levelEnTitle,
            levelDesc: _levelEnDesc,
            comfortZone: _comfortEn,
            board: _boardEn,
            focusSkills: _focusEn,
            stance: _stance,
            height: _height,
            weight: _weight,
            location: _location,
            displayName: _displayName,
            profilePhotoPath: _profilePhotoPath,
            stanceVisibleToCoach: _stanceVisibleToCoach,
            stanceVisibleOnDashboard: _stanceVisibleOnDashboard,
            heightVisibleToCoach: _heightVisibleToCoach,
            heightVisibleOnDashboard: _heightVisibleOnDashboard,
            weightVisibleToCoach: _weightVisibleToCoach,
            weightVisibleOnDashboard: _weightVisibleOnDashboard,
            locationVisibleToCoach: _locationVisibleToCoach,
            locationVisibleOnDashboard: _locationVisibleOnDashboard,
            latestMediaPath: _latestMediaPath,
            latestMediaType: _latestMediaType,
            age: _age,
            surferSummary: _surferSummary,
            ageVisibleToCoach: _ageVisibleToCoach,
            ageVisibleOnDashboard: _ageVisibleOnDashboard,
          ));

          // Mark as entered and onboarding seen
          _updateSettings(_settings.copyWith(
            hasEnteredApp: true,
            hasSeenOnboarding: true,
          ));

          setState(() {
            _showOnboarding = false;
            _enteredThisSession = true;
            // First-Time User Logic: Redirect to Session Log instead of Dashboard
            if (_sessionLogs.isEmpty) {
              debugPrint('First time user: Setting index to 2 (Log Screen)');
              _index = 2;
            } else {
              debugPrint('Returning user: Setting index to 0 (Dashboard)');
              _index = 0;
            }
          });

          // Aggressively sync the profile to Firestore now that we are logged in
          final progressData = SurfDashboardData(
            levelTitle: _levelEnTitle,
            levelDesc: _levelEnDesc,
            comfortZone: _comfortEn,
            board: _boardEn,
            focusSkills: _focusEn,
            stance: _stance,
            height: _height,
            weight: _weight,
            location: _location,
            displayName: _displayName,
            profilePhotoPath: _profilePhotoPath,
            stanceVisibleToCoach: _stanceVisibleToCoach,
            stanceVisibleOnDashboard: _stanceVisibleOnDashboard,
            heightVisibleToCoach: _heightVisibleToCoach,
            heightVisibleOnDashboard: _heightVisibleOnDashboard,
            weightVisibleToCoach: _weightVisibleToCoach,
            weightVisibleOnDashboard: _weightVisibleOnDashboard,
            locationVisibleToCoach: _locationVisibleToCoach,
            locationVisibleOnDashboard: _locationVisibleOnDashboard,
            latestMediaPath: _latestMediaPath,
            latestMediaType: _latestMediaType,
            age: _age,
            surferSummary: _surferSummary,
            ageVisibleToCoach: _ageVisibleToCoach,
            ageVisibleOnDashboard: _ageVisibleOnDashboard,
            email: FirebaseAuth.instance.currentUser?.email,
          );
          
          FirebaseService().saveFullProfile(progressData);
        },
      );
    }


    final pages = <Widget>[
// 0 = Surf Dashboard
      HomeScreen(
        key: _homeKey,
        isSpanish: _isSpanish,
        isCoachPro: _settings.isCoachPro,
        isSurferPro: _settings.isSurferPro,
        isSurferTrial: _settings.isSurferTrial,
        onSetLanguage: _setLanguage,
        onUnlockSurferPro: () {}, // Handled by listener
        levelEnTitle: _levelEnTitle,
        levelEnDesc: _levelEnDesc,
        comfortEn: _comfortEn,
        boardEn: _boardEn,
        focusEn: _focusEn,
        stance: _stance,
        height: _height,
        weight: _weight,
        location: _location,
        displayName: _displayName,
        profilePhotoPath: _profilePhotoPath,
        stanceVisibleToCoach: _stanceVisibleToCoach,
        stanceVisibleOnDashboard: _stanceVisibleOnDashboard,
        heightVisibleToCoach: _heightVisibleToCoach,
        heightVisibleOnDashboard: _heightVisibleOnDashboard,
        weightVisibleToCoach: _weightVisibleToCoach,
        weightVisibleOnDashboard: _weightVisibleOnDashboard,
        locationVisibleToCoach: _locationVisibleToCoach,
        locationVisibleOnDashboard: _locationVisibleOnDashboard,
        sessionsSurfed: _sessionsSurfed,
        lastSurfedDate: _lastSurfedDate,
        latestMediaPath: _latestMediaPath,
        latestMediaType: _latestMediaType,
        age: _age,
        surferSummary: _surferSummary,
        ageVisibleToCoach: _ageVisibleToCoach,
        ageVisibleOnDashboard: _ageVisibleOnDashboard,
        units: _settings.units,
        onUpdate: _updateProfile,
        onOpenPassportTab: ({bool edit = false}) {
          if (edit) {
            // Open the edit profile sheet directly from Home if requested
            _homeKey.currentState?.showProfileInfoEdit();
          } else {
            setState(() => _index = 1);
          }
        },
        onOpenLogTab: _triggerAddSession,
        onOpenSurferPro: _showSurferPro,
        logs: _sessionLogs,
        aiAnalyses: _aiAnalyses,
        onUnlockFirstInsight: _unlockFirstInsight,
        progressKey: _progressKey,
        onOpenLogTab2: () => setState(() => _index = 2),
        onOpenMapTab: () => setState(() => _index = 3),
        onPromptDismissed: () => _updateSettings(_settings.copyWith(seenDashboardPrompt: true)),
        seenDashboardPrompt: _settings.seenDashboardPrompt,
        hasSeenDashboardGuidance: _settings.hasSeenDashboardGuidance,
        onGuidanceDismissed: (type) {
          if (type == "dashboard") {
            _updateSettings(_settings.copyWith(hasSeenDashboardGuidance: true));
          }
        },
        hasSeenWelcomeGuide: _settings.hasSeenWelcomeGuide,
        onWelcomeModalDismissed: () => _updateSettings(_settings.copyWith(hasSeenWelcomeGuide: true)),
        showReturnNudge: _showReturnNudge,
        onReturnNudgeDismissed: () {
          setState(() => _showReturnNudge = false);
          _updateSettings(_settings.copyWith(hasSeenReturnNudge: true));
        },
        hasSeenLogPulse: _settings.hasSeenLogPulse,
        onLogPulseShown: () => _updateSettings(_settings.copyWith(hasSeenLogPulse: true)),
        hasUsedFirstFreeAIInsight: _settings.hasUsedFirstFreeAIInsight,
      ),

// 1 = Surf Passport
      SurfPassportScreen(
        key: _passportKey,
        isSpanish: _isSpanish,
        levelEnTitle: _levelEnTitle,
        levelEnDesc: _levelEnDesc,
        comfortEn: _comfortEn,
        boardEn: _boardEn,
        focusEn: _focusEn,
        displayName: _displayName,
        profilePhotoPath: _profilePhotoPath,
        stance: _stance,
        height: _height,
        weight: _weight,
        location: _location,
        stanceVisibleToCoach: _stanceVisibleToCoach,
        stanceVisibleOnDashboard: _stanceVisibleOnDashboard,
        heightVisibleToCoach: _heightVisibleToCoach,
        heightVisibleOnDashboard: _heightVisibleOnDashboard,
        weightVisibleToCoach: _weightVisibleToCoach,
        weightVisibleOnDashboard: _weightVisibleOnDashboard,
        locationVisibleToCoach: _locationVisibleToCoach,
        locationVisibleOnDashboard: _locationVisibleOnDashboard,
        latestMediaPath: _latestMediaPath,
        latestMediaType: _latestMediaType,
        age: _age,
        surferSummary: _surferSummary,
        ageVisibleToCoach: _ageVisibleToCoach,
        ageVisibleOnDashboard: _ageVisibleOnDashboard,
        sessionsSurfed: _sessionsSurfed,
        lastSurfedDate: _lastSurfedDate,
        units: _settings.units,
        onSetLanguage: _setLanguage,
        onUpdate: _updateProfile,
        onPromptDismissed: () => _updateSettings(_settings.copyWith(seenPassportPrompt: true)),
        seenPassportPrompt: _settings.seenPassportPrompt,
        hasSeenPassportGuidance: _settings.hasSeenPassportGuidance,
        onGuidanceDismissed: (type) {
          if (type == "passport") {
            _updateSettings(_settings.copyWith(hasSeenPassportGuidance: true));
          }
        },
        logs: _sessionLogs,
        onReturnToDashboard: _onReturnToDashboard,
      ),

// 2 = Session Logs
      SessionLogScreen(
        key: _addSessionKey,
        isSpanish: _isSpanish,
        isSurferPro: _settings.isSurferPro,
        focusEn: _focusEn,
        onSetLanguage: _setLanguage,
        displayName: _displayName,
        logs: _sessionLogs,
        onAdd: _addSession,
        onDelete: _deleteSession,
        onUpdate: _addSession,
        onUpdateProfile: _updateProfile,
        onUnlockFirstInsight: _unlockFirstInsight,
        onGenerateInsight: (session) async => await _generateInsight(session),
        onInsightViewed: () {
          if (!_settings.isSurferPro) {
            final newCount = _settings.insightsViewedCount + 1;
            _updateSettings(_settings.copyWith(insightsViewedCount: newCount));
            
            // Trigger 2: After 3 insights viewed
            if (newCount >= 3 && _settings.surferProPopupSuppressedUntil <= _sessionLogs.length) {
               _showSurferProUpgradePrompt(
                 context,
                 title: _isSpanish ? '¿Te ayudan estos insights?' : 'finding these insights helpful?',
                 content: _isSpanish 
                    ? 'Obtén feedback personalizado después de cada surf con Surfer Pro.' 
                    : 'get personalized feedback after every single surf with surfer pro.',
                 isSoftUpsell: true,
               );
            }
          }
        },
        onOpenSurferPro: ({title, content, isSoftUpsell = false, onSeeThisOneFirst}) {
          _showSurferProUpgradePrompt(
            context, 
            title: title, 
            content: content, 
            isSoftUpsell: isSoftUpsell,
            onSeeThisOneFirst: onSeeThisOneFirst,
          );
        },
        onKeepExploring: () {
          _updateSettings(_settings.copyWith(
            surferProPopupSuppressedUntil: _sessionLogs.length + 2,
            hasSeenFirstInsightPrompt: true,
          ));
        },
        units: _settings.units,
        aiAnalyses: _aiAnalyses,
        addSessionKey: _addSessionKey,
        seenLogPrompt: _settings.seenLogPrompt,
        onPromptDismissed: () => _updateSettings(_settings.copyWith(seenLogPrompt: true)),
        sessionsThisMonth: _sessionsThisMonth,
        currentStreak: _currentStreak,
        onReturnToDashboard: () => setState(() => _index = 0),
        hasSeenWelcomeGuide: _settings.hasSeenWelcomeGuide,
        onWelcomeModalDismissed: () => _updateSettings(_settings.copyWith(hasSeenWelcomeGuide: true)),
        hasSeenPostFirstSessionPassportPrompt: _settings.hasSeenPostFirstSessionPassportPrompt,
        onPassportPromptSeen: () => _updateSettings(_settings.copyWith(hasSeenPostFirstSessionPassportPrompt: true)),
        hasSeenPostPassportProfilePrompt: _settings.hasSeenPostPassportProfilePrompt,
        onProfileInfoPromptSeen: () => _updateSettings(_settings.copyWith(hasSeenPostPassportProfilePrompt: true)),
        hasSeenFirstInsightPrompt: _settings.hasSeenFirstInsightPrompt,
        onInsightPromptSeen: () => _updateSettings(_settings.copyWith(hasSeenFirstInsightPrompt: true)),
        hasUsedFirstFreeAIInsight: _settings.hasUsedFirstFreeAIInsight,
        onFirstFreeAIInsightUsed: () {
          _updateSettings(_settings.copyWith(hasUsedFirstFreeAIInsight: true));
          if (!_settings.isSurferPro) {
            // Show the nudge immediately after they've closed their first free insight payoff
            _showSurferProUpgradePrompt(
              context,
              title: _isSpanish ? "¡Increíble insight!" : "Killer insight!",
              content: _isSpanish 
                ? "Obtén feedback personalizado después de cada sesión con Surfer Pro." 
                : "Get personalized feedback after every single session with Surfer Pro.",
              isSoftUpsell: true,
            );
          }
        },
        lastNudgeShownAt: _settings.lastNudgeShownAt,
        onSurferProNudgeSeen: (count) {
          _updateSettings(_settings.copyWith(lastNudgeShownAt: count));
        },
        levelEnTitle: _levelEnTitle,
        levelEnDesc: _levelEnDesc,
        comfortEn: _comfortEn,
        boardEn: _boardEn,
        stance: _stance,
        height: _height,
        weight: _weight,
        location: _location,
        age: _age,
        surferSummary: _surferSummary,
        profilePhotoPath: _profilePhotoPath,
        stanceVisibleToCoach: _stanceVisibleToCoach,
        stanceVisibleOnDashboard: _stanceVisibleOnDashboard,
        heightVisibleToCoach: _heightVisibleToCoach,
        heightVisibleOnDashboard: _heightVisibleOnDashboard,
        weightVisibleToCoach: _weightVisibleToCoach,
        weightVisibleOnDashboard: _weightVisibleOnDashboard,
        locationVisibleToCoach: _locationVisibleToCoach,
        locationVisibleOnDashboard: _locationVisibleOnDashboard,
        ageVisibleToCoach: _ageVisibleToCoach,
        ageVisibleOnDashboard: _ageVisibleOnDashboard,
      ),

// 3 = Map
      MapScreen(
        isSpanish: _isSpanish,
        onSetLanguage: _setLanguage,
        spots: _spots,
        onSpotsChanged: _setSpots,
        mapKey: _mapKey,
        onReturnToDashboard: _onReturnToDashboard,
        hasSeenMapTip: _settings.hasSeenMapTip,
        onMapTipDismissed: () => _updateSettings(_settings.copyWith(hasSeenMapTip: true)),
      ),

// 4 = Settings
      SettingsScreen(
        settings: _settings,
        onChanged: _updateSettings,
        onResetOnboarding: _resetOnboarding,
        onOpenSurferPro: _showSurferPro,
        onResetSessions: _performFullReset,
        onResetAppState: _performFullReset,
        onRunTour: () {
          AppStorage.clearTourFlags();
          _updateSettings(_settings.copyWith(
            seenDashboardPrompt: false,
            seenPassportPrompt: false,
            seenLogPrompt: false,
            hasSeenMapTip: false,
            hasSeenSettingsTip: false,
          ));
          setState(() => _index = 0);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            (_homeKey.currentState as dynamic)?.startTour();
          });
        },
      ),
    ];

    return Scaffold(
      body: pages[_index],
      floatingActionButton: _index == 2 ? FloatingActionButton.extended(
        onPressed: _triggerAddSession,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_t("Log session", "Registrar sesión")),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 9,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textMuted,
        selectedLabelStyle: const TextStyle(height: 1.1),
        unselectedLabelStyle: const TextStyle(height: 1.1),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.trending_up),
            label: _t('Dashboard', 'Dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.badge),
            label: _t('Surf\nPassport', 'Surf\nPasaporte'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: _t('Log', 'Log'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: _t('Map', 'Mapa'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: _t('Settings', 'Ajustes'),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isSpanish;

  const _BenefitItem({
    required this.icon,
    required this.text,
    required this.isSpanish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
