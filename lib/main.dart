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
import 'features/coach_pro/coach_dashboard_screen.dart';
import 'features/Settings/settings_screen.dart';
import 'widgets/orientation_prompt.dart';
import 'widgets/success_banner.dart';
import 'storage/app_storage.dart';
import 'models/surf_dashboard_data.dart';
import 'models/reflection_model.dart';
import 'models/ai_analysis_model.dart';
import 'features/surfer_pro/surfer_pro_screen.dart';
import 'features/session_log/firebase_service.dart';
import 'features/surfer_pro/surfer_pro_paywall.dart';

import 'core/translation_service.dart';

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
  bool _quickStartShown = false;
  int _index = 0;

  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _addSessionKey = GlobalKey();
  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey _homeKey = GlobalKey();
  OverlayEntry? _tourOverlay;

  final SubscriptionService _subService = SubscriptionService();
  AppSettings _settings = const AppSettings(isSpanish: false, isCoachPro: false, isSurferPro: false);

  final List<SessionReflection> _reflections = [];
  final List<AiAnalysisResult> _aiAnalyses = [];
  final List<SessionLogEntry> _sessionLogs = [];

  bool get _isSpanish => _settings.isSpanish;

  void _updateSettings(AppSettings newSettings) {
    setState(() => _settings = newSettings);
    AppStorage.saveSettings(newSettings);
  }

  void _setLanguage(bool spanish) {
    _updateSettings(_settings.copyWith(isSpanish: spanish));
  }

  void _setHasEnteredApp(bool entered) {
    _updateSettings(_settings.copyWith(hasEnteredApp: entered, appVersion: '1.0.1'));
  }

  void _resetOnboarding() {
    setState(() => _quickStartShown = false);
    _updateSettings(_settings.copyWith(
      hasEnteredApp: false, 
      hasSeenOnboarding: false, 
      hasSeenGuidedTour: false, 
      seenDashboardPrompt: false,
      seenLogPrompt: false,
      seenPassportPrompt: false,
      appVersion: '1.0.1'
    ));
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSpanish ? 'Onboarding reiniciado.' : 'Smart Surf reset!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _unlockSurferPro() {
    _updateSettings(_settings.copyWith(isSurferPro: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSpanish ? '¡Surfer Pro desbloqueado!' : 'Surfer Pro Unlocked!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

// Canonical values stored in EN
  String _levelEnTitle = "";
  String _levelEnDesc = "";
  String _comfortEn = "";
  String _boardEn = "";
  List<String> _focusEn = const [];
  String _stance = "Regular";
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
    final s = _latestLoggedSession;
    return s?.mediaPath;
  }
  String? get _latestMediaType {
    final s = _latestLoggedSession;
    return s?.mediaType;
  }

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
      
      // Sync focus skills to passport ONLY if completed
      if (entry.isCompleted && entry.sessionFocus.isNotEmpty) {
        final List<String> currentFocus = List.from(_focusEn);
        if (!currentFocus.contains(entry.sessionFocus)) {
          // Keep most recent 4
          _focusEn = [entry.sessionFocus, ...currentFocus].take(4).toList();
        }
      }

      // Objective 4: Auto-Add Logged Surf Spot to Map
      if (entry.isCompleted && entry.spotName.isNotEmpty && entry.spotName != (_isSpanish ? "Sesión Actual" : "Current Session")) {
        final bool alreadyExists = _spots.any((s) => s.name.toLowerCase() == entry.spotName.toLowerCase());
        if (!alreadyExists) {
          final newSpot = SurfSpot(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: entry.spotName,
            region: entry.countryOrRegion,
            lat: 0.0, // Default to 0.0, user can edit location later
            lng: 0.0,
            createdAt: DateTime.now(),
          );
          _spots.add(newSpot);
          AppStorage.saveSpots(_spots);
        }
      }
    });
    AppStorage.saveSessions(_sessionLogs);
    // Persist the updated focus skills in profile as well
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

    if (showBanner && _navigatorKey.currentState != null) {
      final navContext = _navigatorKey.currentState!.context;
      SessionLoggedBanner.show(
        navContext,
        isSpanish: _isSpanish,
        onViewPassport: () => setState(() => _index = 1),
      );

      // Show Surfer Pro upgrade prompt if not already pro
      if (!_settings.isSurferPro) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (_navigatorKey.currentState != null) {
            _showSurferProUpgradePrompt(_navigatorKey.currentState!.context);
          }
        });
      }
    }
  }

  void _showSurferProUpgradePrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSpanish ? 'Insight de Surf' : 'Surf Insight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isSpanish 
              ? 'Desbloquea insights de surf más profundos de tu sesión.' 
              : 'Unlock deeper surf insights from your session.'),
            const SizedBox(height: 16),
            _BenefitItem(
              icon: Icons.auto_awesome, 
              text: _isSpanish ? 'Insights de sesión con IA' : 'AI session insights', 
              isSpanish: _isSpanish
            ),
            _BenefitItem(
              icon: Icons.trending_up, 
              text: _isSpanish ? 'Patrones de progreso entre surfeos' : 'Progress patterns across surfs', 
              isSpanish: _isSpanish
            ),
            _BenefitItem(
              icon: Icons.tips_and_updates, 
              text: _isSpanish ? 'Sugerencias de enfoque para tu próxima sesión' : 'Next session focus suggestions', 
              isSpanish: _isSpanish
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isSpanish ? 'Omitir por ahora' : 'Skip for now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSurferPro();
            },
            child: Text(_isSpanish ? 'Probar Surfer Pro' : 'Try Surfer Pro'),
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
  }

  Future<void> _resetSessions() async {
    setState(() {
      _sessionLogs.clear();
      _aiAnalyses.clear();
      _reflections.clear();
      _spots.clear();
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final sessions = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sessions')
            .get();
        for (var doc in sessions.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint("Firebase: Reset sessions SUCCESS for $uid");
      } catch (e) {
        debugPrint("Firebase ERROR resetting sessions: $e");
      }
    }

    await _resetAppState();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSpanish ? 'Sesiones reiniciadas' : 'Sessions reset'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

Future<void> _resetAppState() async {
  try {
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }
  } catch (e) {
    debugPrint("Auth sign out error during reset: $e");
  }

  if (!mounted) return;

  setState(() {
    _showSplash = false;
    _showOnboarding = true;
    _enteredThisSession = false;
    _quickStartShown = false;
    _index = 0;
  });
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

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  void _showSurferPro() {
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
        showSurfInsightPaywall(
          _navigatorKey.currentContext!,
          isSpanish: _isSpanish,
          onUnlock: _unlockSurferPro,
        );
      }
    }
  }

  void _showCoachDashboard() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (ctx) => CoachDashboardScreen(
          isSpanish: _isSpanish,
          isCoachPro: _settings.isCoachPro,
          surferData: SurfDashboardData(
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
          ),
          sessionsSurfed: _sessionsSurfed,
          lastSurfedDate: _lastSurfedDate,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // 0. Handle Web Reset Parameter
    await _subService.init();
    final isCoachPro = await _subService.isCoachProActive();
    final isSurferPro = await _subService.isSurferProActive();

    // 1. Initialize Firebase & Auth centrally

    // 2. Load disk cache, then aggressively override with authenticated stable Links from Firestore
    final rawData = await AppStorage.loadAll();
    final data = await FirebaseService().hydrateLocalsFromFirestore(rawData);

    if (!mounted) return;
    setState(() {
      _settings = data.settings.copyWith(
        isCoachPro: isCoachPro,
        isSurferPro: isSurferPro,
      );
      _showOnboarding = !_settings.hasSeenOnboarding;
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

  Future<void> _showQuickStart(BuildContext context) async {
    if (_quickStartShown) return;
    if (!_enteredThisSession && !_settings.showQuickStartOnLaunch) return;

    _quickStartShown = true;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isSpanish ? "¿Qué quieres hacer hoy?" : "What do you want to do today?",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _QuickActionTile(
                icon: Icons.trending_up,
                label: _isSpanish ? "Actualiza tu Perfil" : "Update your Surf Dashboard",
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _index = 0);
                },
              ),
              _QuickActionTile(
                icon: Icons.badge,
                label: _isSpanish ? "Muestra tu Pasaporte" : "Show your Surf Passport",
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _index = 1);
                },
              ),
              _QuickActionTile(
                icon: Icons.playlist_add,
                label: _isSpanish ? "Registra una sesión" : "Log a session",
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _index = 2);
                },
              ),
            ],
          ),
        ),
      ),
    );

    // After QuickStart is dismissed, we are done
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Smart Surf',
      theme: AppTheme.themeData,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
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
          // Update profile data if provided
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
            _index = 0;
          });
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
        onSetLanguage: _setLanguage,
        onUnlockSurferPro: _unlockSurferPro,
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
        onOpenPassportTab: () => setState(() => _index = 1),
        onOpenLogTab: () => setState(() => _index = 2),
        onOpenSurferPro: _showSurferPro,
        logs: _sessionLogs,
        progressKey: _progressKey,
        onOpenLogTab2: () => setState(() => _index = 2),
        onOpenMapTab: () => setState(() => _index = 3),
        onPromptDismissed: () => _updateSettings(_settings.copyWith(seenDashboardPrompt: true)),
        seenDashboardPrompt: _settings.seenDashboardPrompt,
      ),

// 1 = Surf Passport
      SurfPassportScreen(
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
        logs: _sessionLogs,
      ),

// 2 = Session Logs
      SessionLogScreen(
        isSpanish: _isSpanish,
        isSurferPro: _settings.isSurferPro,
        onSetLanguage: _setLanguage,
        displayName: _displayName,
        logs: _sessionLogs,
        aiAnalyses: _aiAnalyses,
        onAdd: (e) => _addSession(e, showBanner: true),
        onUpdate: _addSession,
        onDelete: _deleteSession,
        units: _settings.units,
        addSessionKey: _addSessionKey,
        onPromptDismissed: () => _updateSettings(_settings.copyWith(seenLogPrompt: true)),
        seenLogPrompt: _settings.seenLogPrompt,
        onUnlockSurferPro: _unlockSurferPro,
        sessionsThisMonth: _sessionsThisMonth,
        currentStreak: _currentStreak,
      ),

// 3 = Map
      MapScreen(
        isSpanish: _isSpanish,
        onSetLanguage: _setLanguage,
        spots: _spots,
        onSpotsChanged: _setSpots,
        mapKey: _mapKey,
      ),

// 4 = Settings
      SettingsScreen(
        settings: _settings,
        onChanged: _updateSettings,
        onResetQuickstart: _resetOnboarding,
        onOpenSurferPro: _showSurferPro,
        onOpenCoachDashboard: _showCoachDashboard,
        onResetSessions: _resetSessions,
        onResetAppState: _resetAppState,
        onRunTour: () {
          _updateSettings(_settings.copyWith(
            seenDashboardPrompt: false,
            seenPassportPrompt: false,
            seenLogPrompt: false,
          ));
          setState(() => _index = 0);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            (_homeKey.currentState as dynamic)?.startTour();
          });
        },
      ),
    ];

    return Scaffold(
      body: _QuickStartWrapper(
        onInit: (innerContext) {
          // If we are NOT showing the onboarding screen, we check if we should show quickstart.
          // Because _enteredThisSession is set true AT BOOT when skipping onboarding,
          // this correctly triggers on every app reopen, but NOT on the very first ever launch
          // because on the first ever launch _enteredThisSession is false until onboarding is dismissed.
          if (!_showOnboarding && !_quickStartShown) {
            if (_enteredThisSession || _settings.showQuickStartOnLaunch) {
              _showQuickStart(innerContext);
            }
          }
        },
        child: pages[_index],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Surf Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge),
            label: 'Surf Passport',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Session Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _QuickStartWrapper extends StatefulWidget {
  final Widget child;
  final void Function(BuildContext) onInit;

  const _QuickStartWrapper({
    required this.child,
    required this.onInit,
  });

  @override
  State<_QuickStartWrapper> createState() => _QuickStartWrapperState();
}

class _QuickStartWrapperState extends State<_QuickStartWrapper> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        widget.onInit(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
