import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/Settings/settings_models.dart';
import '../models/surf_dashboard_data.dart';
import '../features/session_log/session_log_entry.dart';
import '../features/map/map_models.dart';
import '../models/reflection_model.dart';
import '../models/ai_analysis_model.dart';

class AppStorageData {
  final AppSettings settings;
  final SurfDashboardData progress;
  final List<SessionLogEntry> sessions;
  final List<SurfSpot> spots;
  final List<SessionReflection> reflections;
  final List<AiAnalysisResult> aiAnalyses;

  const AppStorageData({
    required this.settings,
    required this.progress,
    required this.sessions,
    required this.spots,
    required this.reflections,
    required this.aiAnalyses,
  });
}

class AppStorage {
  static const _settingsKey = 'swell_settings_v1';
  static const _progressKey = 'swell_progress_v1';
  static const _sessionsKey = 'swell_sessions_v1';
  static const _spotsKey = 'surf_spots_v1';
  static const _reflectionsKey = 'surfer_reflections_v1';
  static const _aiAnalysisKey = 'surfer_ai_analysis_v1';

  static const _currentAppVersion = '1.0.1';
  static const _currentAppEnvId = 'prod-2026-03-13'; // Increment to force clean slate for unauth users

  static Future<AppStorageData> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Settings
    AppSettings settings = const AppSettings(
      isSpanish: false,
      isCoachPro: false,
      isSurferPro: false,
      hasEnteredApp: false,
      hasSeenOnboarding: false,
      hasSeenGuidedTour: false,
      seenDashboardPrompt: false,
      seenLogPrompt: false,
      seenPassportPrompt: false,
      showQuickStartOnLaunch: true,
      appVersion: _currentAppVersion,
      appEnvId: _currentAppEnvId,
      units: 'imperial',
      defaultMapMode: 'standard',
    );
    final settingsRaw = prefs.getString(_settingsKey);
    if (settingsRaw != null && settingsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(settingsRaw) as Map<String, dynamic>;
        settings = AppSettings.fromJson(decoded);

        // Environment Reset Logic:
        // If the environment has changed, and the user hasn't explicitly logged into Firebase
        // (meaning strictly local data), we clear all data to prevent stale state.
        if (settings.appEnvId != _currentAppEnvId) {
            await hardReset();
            // Start fresh with new env ID
            settings = settings.copyWith(
              appEnvId: _currentAppEnvId,
              appVersion: _currentAppVersion,
              hasSeenOnboarding: false,
              hasEnteredApp: false,
            );
            await saveSettings(settings);
            // Return default empty data for the rest
            return AppStorageData(
              settings: settings,
              progress: _defaultProgress(),
              sessions: [],
              spots: [],
              reflections: [],
              aiAnalyses: [],
            );
        }

        // Remove the aggressive reset logic that was forcing hasEnteredApp = false
        // to ensure the user doesn't get pushed back to onboarding.
        if (settings.appVersion != _currentAppVersion) {
            settings = settings.copyWith(appVersion: _currentAppVersion);
            await saveSettings(settings);
        }
      } catch (_) {}
    }

    // Load remaining data using helper methods for cleanliness
    return AppStorageData(
      settings: settings,
      progress: _loadProgress(prefs),
      sessions: _loadSessions(prefs),
      spots: _loadSpots(prefs),
      reflections: _loadReflections(prefs),
      aiAnalyses: _loadAiAnalyses(prefs),
    );
  }

  static SurfDashboardData _defaultProgress() {
    return const SurfDashboardData(
      levelTitle: "",
      levelDesc: "",
      comfortZone: "",
      board: "",
      focusSkills: [],
      stance: "Regular",
      height: "",
      weight: "",
      location: "",
      displayName: "",
      profilePhotoPath: null,
      stanceVisibleToCoach: false,
      stanceVisibleOnDashboard: true,
      heightVisibleToCoach: false,
      heightVisibleOnDashboard: true,
      weightVisibleToCoach: false,
      weightVisibleOnDashboard: true,
      locationVisibleToCoach: false,
      locationVisibleOnDashboard: true,
      latestMediaPath: null,
      latestMediaType: null,
      age: "",
      surferSummary: "",
      ageVisibleToCoach: false,
      ageVisibleOnDashboard: true,
    );
  }

  static SurfDashboardData _loadProgress(SharedPreferences prefs) {
    final progressRaw = prefs.getString(_progressKey);
    if (progressRaw != null && progressRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(progressRaw) as Map<String, dynamic>;
        return SurfDashboardData.fromJson(decoded);
      } catch (_) {}
    }
    return _defaultProgress();
  }

  static List<SessionLogEntry> _loadSessions(SharedPreferences prefs) {
    List<SessionLogEntry> sessions = [];
    final sessionsRaw = prefs.getString(_sessionsKey);
    if (sessionsRaw != null && sessionsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(sessionsRaw);
        if (decoded is List) {
          for (final m in decoded) {
            if (m is Map) {
              try {
                sessions.add(SessionLogEntry.fromJson(Map<String, dynamic>.from(m)));
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }
    return sessions;
  }

  static List<SurfSpot> _loadSpots(SharedPreferences prefs) {
    List<SurfSpot> spots = [];
    final spotsRaw = prefs.getString(_spotsKey);
    if (spotsRaw != null && spotsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(spotsRaw);
        if (decoded is List) {
          for (final m in decoded) {
            if (m is Map) {
              try {
                spots.add(SurfSpot.fromJson(Map<String, dynamic>.from(m)));
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }
    return spots;
  }

  static List<SessionReflection> _loadReflections(SharedPreferences prefs) {
    List<SessionReflection> reflections = [];
    final reflectionsRaw = prefs.getString(_reflectionsKey);
    if (reflectionsRaw != null && reflectionsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(reflectionsRaw);
        if (decoded is List) {
          for (final m in decoded) {
            if (m is Map) {
              try {
                reflections.add(SessionReflection.fromJson(Map<String, dynamic>.from(m)));
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }
    return reflections;
  }

  static List<AiAnalysisResult> _loadAiAnalyses(SharedPreferences prefs) {
    List<AiAnalysisResult> aiAnalyses = [];
    final aiAnalysesRaw = prefs.getString(_aiAnalysisKey);
    if (aiAnalysesRaw != null && aiAnalysesRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(aiAnalysesRaw);
        if (decoded is List) {
          for (final m in decoded) {
            if (m is Map) {
              try {
                aiAnalyses.add(AiAnalysisResult.fromJson(Map<String, dynamic>.from(m)));
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }
    return aiAnalyses;
  }

  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  static Future<void> saveProgress(SurfDashboardData progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  static Future<void> saveSessions(List<SessionLogEntry> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final data = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_sessionsKey, jsonEncode(data));
  }

  static Future<void> saveSpots(List<SurfSpot> spots) async {
    final prefs = await SharedPreferences.getInstance();
    final data = spots.map((s) => s.toJson()).toList();
    await prefs.setString(_spotsKey, jsonEncode(data));
  }

  static Future<void> saveReflections(List<SessionReflection> reflections) async {
    final prefs = await SharedPreferences.getInstance();
    final data = reflections.map((r) => r.toJson()).toList();
    await prefs.setString(_reflectionsKey, jsonEncode(data));
  }

  static Future<void> saveAiAnalyses(List<AiAnalysisResult> aiAnalyses) async {
    final prefs = await SharedPreferences.getInstance();
    final data = aiAnalyses.map((r) => r.toJson()).toList();
    await prefs.setString(_aiAnalysisKey, jsonEncode(data));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> clearTourFlags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasSeenMapTip');
    await prefs.remove('hasSeenSettingsTip');
    await prefs.remove('hasSeenPassportTip');
    await prefs.remove('hasSeenDashboardTip');
  }

  static Future<void> hardReset() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear everything including keys we might not track in loadAll
    await prefs.clear();
  }
}
