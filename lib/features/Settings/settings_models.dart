class AppSettings {
  final bool isSpanish;
  final bool isCoachPro;
  final bool isSurferPro;
  final bool hasEnteredApp;
  final bool hasSeenOnboarding;
  final bool hasSeenGuidedTour;
  final bool seenDashboardPrompt;
  final bool seenLogPrompt;
  final bool seenPassportPrompt;
  final bool showQuickStartOnLaunch;
  final String? appVersion;
  final String? appEnvId; // Used to detect build/environment changes for persistence reset
  final String units; // "metric" or "imperial"
  final String defaultMapMode; // "standard", "satellite"

  const AppSettings({
    required this.isSpanish,
    required this.isCoachPro,
    required this.isSurferPro,
    this.hasEnteredApp = false,
    this.hasSeenOnboarding = false,
    this.hasSeenGuidedTour = false,
    this.seenDashboardPrompt = false,
    this.seenLogPrompt = false,
    this.seenPassportPrompt = false,
    this.showQuickStartOnLaunch = true,
    this.appVersion,
    this.appEnvId,
    this.units = 'imperial',
    this.defaultMapMode = 'default_region',
  });

  AppSettings copyWith({
    bool? isSpanish,
    bool? isCoachPro,
    bool? isSurferPro,
    bool? hasEnteredApp,
    bool? hasSeenOnboarding,
    bool? hasSeenGuidedTour,
    bool? seenDashboardPrompt,
    bool? seenLogPrompt,
    bool? seenPassportPrompt,
    bool? showQuickStartOnLaunch,
    String? appVersion,
    String? appEnvId,
    String? units,
    String? defaultMapMode,
  }) {
    return AppSettings(
      isSpanish: isSpanish ?? this.isSpanish,
      isCoachPro: isCoachPro ?? this.isCoachPro,
      isSurferPro: isSurferPro ?? this.isSurferPro,
      hasEnteredApp: hasEnteredApp ?? this.hasEnteredApp,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      hasSeenGuidedTour: hasSeenGuidedTour ?? this.hasSeenGuidedTour,
      seenDashboardPrompt: seenDashboardPrompt ?? this.seenDashboardPrompt,
      seenLogPrompt: seenLogPrompt ?? this.seenLogPrompt,
      seenPassportPrompt: seenPassportPrompt ?? this.seenPassportPrompt,
      showQuickStartOnLaunch: showQuickStartOnLaunch ?? this.showQuickStartOnLaunch,
      appVersion: appVersion ?? this.appVersion,
      appEnvId: appEnvId ?? this.appEnvId,
      units: units ?? this.units,
      defaultMapMode: defaultMapMode ?? this.defaultMapMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'isSpanish': isSpanish,
        'isCoachPro': isCoachPro,
        'isSurferPro': isSurferPro,
        'hasEnteredApp': hasEnteredApp,
        'hasSeenOnboarding': hasSeenOnboarding,
        'hasSeenGuidedTour': hasSeenGuidedTour,
        'seenDashboardPrompt': seenDashboardPrompt,
        'seenLogPrompt': seenLogPrompt,
        'seenPassportPrompt': seenPassportPrompt,
        'showQuickStartOnLaunch': showQuickStartOnLaunch,
        'appVersion': appVersion,
        'appEnvId': appEnvId,
        'units': units,
        'defaultMapMode': defaultMapMode,
      };

  static AppSettings fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isSpanish: (json['isSpanish'] as bool?) ?? false,
      isCoachPro: (json['isCoachPro'] as bool?) ?? false,
      isSurferPro: (json['isSurferPro'] as bool?) ?? false,
      hasEnteredApp: (json['hasEnteredApp'] as bool?) ?? false,
      hasSeenOnboarding: (json['hasSeenOnboarding'] as bool?) ?? false,
      hasSeenGuidedTour: (json['hasSeenGuidedTour'] as bool?) ?? false,
      seenDashboardPrompt: (json['seenDashboardPrompt'] as bool?) ?? false,
      seenLogPrompt: (json['seenLogPrompt'] as bool?) ?? false,
      seenPassportPrompt: (json['seenPassportPrompt'] as bool?) ?? false,
      showQuickStartOnLaunch: (json['showQuickStartOnLaunch'] as bool?) ?? true,
      appVersion: json['appVersion'] as String?,
      appEnvId: json['appEnvId'] as String?,
      units: json['units'] as String? ?? 'imperial',
      defaultMapMode: json['defaultMapMode'] as String? ?? 'default_region',
    );
  }
}
