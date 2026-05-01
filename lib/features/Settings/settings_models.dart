class AppSettings {
  final bool isSpanish;
  final bool isCoachPro;
  final bool isSurferPro;
  final bool isSurferTrial;
  final bool hasEnteredApp;
  final bool hasSeenOnboarding;
  final bool hasSeenGuidedTour;
  final bool hasSeenFirstInsightPrompt;
  final bool hasUsedFirstFreeAIInsight;
  final bool hasSeenAIRepeatNudge;
  final bool seenDashboardPrompt;
  final bool seenLogPrompt;
  final bool seenPassportPrompt;
  final bool hasSeenMapTip;
  final bool hasSeenSettingsTip;
  final bool hasSeenDashboardGuidance;
  final bool hasSeenPassportGuidance;
  final bool hasSeenProfileNudge;
  final bool hasSeenWelcomeGuide;
  final bool hasSeenDashboardGuide;
  final bool hasSeenLogGuide;
  final bool hasSeenPassportGuide;
  final bool hasSeenReturnNudge;
  final bool hasSeenLogPulse;
  final bool hasSeenPostFirstSessionPassportPrompt;
  final bool hasSeenPostPassportProfilePrompt;
  final String? lastLoginDate;
  final String? appVersion;
  final String? appEnvId; // Used to detect build/environment changes for persistence reset
  final String units;
  final String defaultMapMode;
  final int insightsViewedCount;
  final int surferProPopupSuppressedUntil;
  final int lastNudgeShownAt;

  const AppSettings({
    required this.isSpanish,
    required this.isCoachPro,
    required this.isSurferPro,
    this.isSurferTrial = false,
    this.hasEnteredApp = false,
    this.hasSeenOnboarding = false,
    this.hasSeenGuidedTour = false,
    this.hasSeenFirstInsightPrompt = false,
    this.hasUsedFirstFreeAIInsight = false,
    this.hasSeenAIRepeatNudge = false,
    this.seenDashboardPrompt = false,
    this.seenLogPrompt = false,
    this.seenPassportPrompt = false,
    this.hasSeenMapTip = false,
    this.hasSeenSettingsTip = false,
    this.hasSeenDashboardGuidance = false,
    this.hasSeenPassportGuidance = false,
    this.hasSeenProfileNudge = false,
    this.hasSeenWelcomeGuide = false,
    this.hasSeenDashboardGuide = false,
    this.hasSeenLogGuide = false,
    this.hasSeenPassportGuide = false,
    this.hasSeenReturnNudge = false,
    this.hasSeenLogPulse = false,
    this.hasSeenPostFirstSessionPassportPrompt = false,
    this.hasSeenPostPassportProfilePrompt = false,
    this.lastLoginDate,
    this.appVersion,
    this.appEnvId,
    this.units = 'imperial',
    this.defaultMapMode = 'default_region',
    this.insightsViewedCount = 0,
    this.surferProPopupSuppressedUntil = 0,
    this.lastNudgeShownAt = 0,
  });

  AppSettings copyWith({
    bool? isSpanish,
    bool? isCoachPro,
    bool? isSurferPro,
    bool? isSurferTrial,
    bool? hasEnteredApp,
    bool? hasSeenOnboarding,
    bool? hasSeenGuidedTour,
    bool? hasSeenFirstInsightPrompt,
    bool? hasUsedFirstFreeAIInsight,
    bool? hasSeenAIRepeatNudge,
    bool? seenDashboardPrompt,
    bool? seenLogPrompt,
    bool? seenPassportPrompt,
    bool? hasSeenMapTip,
    bool? hasSeenSettingsTip,
    bool? hasSeenDashboardGuidance,
    bool? hasSeenPassportGuidance,
    bool? hasSeenProfileNudge,
    bool? hasSeenWelcomeGuide,
    bool? hasSeenDashboardGuide,
    bool? hasSeenLogGuide,
    bool? hasSeenPassportGuide,
    bool? hasSeenReturnNudge,
    bool? hasSeenLogPulse,
    bool? hasSeenPostFirstSessionPassportPrompt,
    bool? hasSeenPostPassportProfilePrompt,
    String? lastLoginDate,
    String? appVersion,
    String? appEnvId,
    String? units,
    String? defaultMapMode,
    int? insightsViewedCount,
    int? surferProPopupSuppressedUntil,
    int? lastNudgeShownAt,
  }) {
    return AppSettings(
      isSpanish: isSpanish ?? this.isSpanish,
      isCoachPro: isCoachPro ?? this.isCoachPro,
      isSurferPro: isSurferPro ?? this.isSurferPro,
      isSurferTrial: isSurferTrial ?? this.isSurferTrial,
      hasEnteredApp: hasEnteredApp ?? this.hasEnteredApp,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      hasSeenGuidedTour: hasSeenGuidedTour ?? this.hasSeenGuidedTour,
      hasSeenFirstInsightPrompt: hasSeenFirstInsightPrompt ?? this.hasSeenFirstInsightPrompt,
      hasUsedFirstFreeAIInsight: hasUsedFirstFreeAIInsight ?? this.hasUsedFirstFreeAIInsight,
      hasSeenAIRepeatNudge: hasSeenAIRepeatNudge ?? this.hasSeenAIRepeatNudge,
      seenDashboardPrompt: seenDashboardPrompt ?? this.seenDashboardPrompt,
      seenLogPrompt: seenLogPrompt ?? this.seenLogPrompt,
      seenPassportPrompt: seenPassportPrompt ?? this.seenPassportPrompt,
      hasSeenMapTip: hasSeenMapTip ?? this.hasSeenMapTip,
      hasSeenSettingsTip: hasSeenSettingsTip ?? this.hasSeenSettingsTip,
      hasSeenDashboardGuidance: hasSeenDashboardGuidance ?? this.hasSeenDashboardGuidance,
      hasSeenPassportGuidance: hasSeenPassportGuidance ?? this.hasSeenPassportGuidance,
      hasSeenProfileNudge: hasSeenProfileNudge ?? this.hasSeenProfileNudge,
      hasSeenWelcomeGuide: hasSeenWelcomeGuide ?? this.hasSeenWelcomeGuide,
      hasSeenDashboardGuide: hasSeenDashboardGuide ?? this.hasSeenDashboardGuide,
      hasSeenLogGuide: hasSeenLogGuide ?? this.hasSeenLogGuide,
      hasSeenPassportGuide: hasSeenPassportGuide ?? this.hasSeenPassportGuide,
      hasSeenReturnNudge: hasSeenReturnNudge ?? this.hasSeenReturnNudge,
      hasSeenLogPulse: hasSeenLogPulse ?? this.hasSeenLogPulse,
      hasSeenPostFirstSessionPassportPrompt: hasSeenPostFirstSessionPassportPrompt ?? this.hasSeenPostFirstSessionPassportPrompt,
      hasSeenPostPassportProfilePrompt: hasSeenPostPassportProfilePrompt ?? this.hasSeenPostPassportProfilePrompt,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      appVersion: appVersion ?? this.appVersion,
      appEnvId: appEnvId ?? this.appEnvId,
      units: units ?? this.units,
      defaultMapMode: defaultMapMode ?? this.defaultMapMode,
      insightsViewedCount: insightsViewedCount ?? this.insightsViewedCount,
      surferProPopupSuppressedUntil: surferProPopupSuppressedUntil ?? this.surferProPopupSuppressedUntil,
      lastNudgeShownAt: lastNudgeShownAt ?? this.lastNudgeShownAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'isSpanish': isSpanish,
        'isCoachPro': isCoachPro,
        'isSurferPro': isSurferPro,
        'isSurferTrial': isSurferTrial,
        'hasEnteredApp': hasEnteredApp,
        'hasSeenOnboarding': hasSeenOnboarding,
        'hasSeenGuidedTour': hasSeenGuidedTour,
        'hasSeenFirstInsightPrompt': hasSeenFirstInsightPrompt,
        'hasUsedFirstFreeAIInsight': hasUsedFirstFreeAIInsight,
        'hasSeenAIRepeatNudge': hasSeenAIRepeatNudge,
        'seenDashboardPrompt': seenDashboardPrompt,
        'seenLogPrompt': seenLogPrompt,
        'seenPassportPrompt': seenPassportPrompt,
        'hasSeenMapTip': hasSeenMapTip,
        'hasSeenSettingsTip': hasSeenSettingsTip,
        'hasSeenDashboardGuidance': hasSeenDashboardGuidance,
        'hasSeenPassportGuidance': hasSeenPassportGuidance,
        'hasSeenProfileNudge': hasSeenProfileNudge,
        'hasSeenWelcomeGuide': hasSeenWelcomeGuide,
        'hasSeenDashboardGuide': hasSeenDashboardGuide,
        'hasSeenLogGuide': hasSeenLogGuide,
        'hasSeenPassportGuide': hasSeenPassportGuide,
        'hasSeenReturnNudge': hasSeenReturnNudge,
        'hasSeenLogPulse': hasSeenLogPulse,
        'hasSeenPostFirstSessionPassportPrompt': hasSeenPostFirstSessionPassportPrompt,
        'hasSeenPostPassportProfilePrompt': hasSeenPostPassportProfilePrompt,
        'lastLoginDate': lastLoginDate,
        'appVersion': appVersion,
        'appEnvId': appEnvId,
        'units': units,
        'defaultMapMode': defaultMapMode,
        'insightsViewedCount': insightsViewedCount,
        'surferProPopupSuppressedUntil': surferProPopupSuppressedUntil,
        'lastNudgeShownAt': lastNudgeShownAt,
      };

  static AppSettings fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isSpanish: (json['isSpanish'] as bool?) ?? false,
      isCoachPro: (json['isCoachPro'] as bool?) ?? false,
      isSurferPro: (json['isSurferPro'] as bool?) ?? false,
      isSurferTrial: (json['isSurferTrial'] as bool?) ?? false,
      hasEnteredApp: (json['hasEnteredApp'] as bool?) ?? false,
      hasSeenOnboarding: (json['hasSeenOnboarding'] as bool?) ?? false,
      hasSeenGuidedTour: (json['hasSeenGuidedTour'] as bool?) ?? false,
      hasSeenFirstInsightPrompt: (json['hasSeenFirstInsightPrompt'] as bool?) ?? false,
      hasUsedFirstFreeAIInsight: (json['hasUsedFirstFreeAIInsight'] as bool?) ?? false,
      hasSeenAIRepeatNudge: (json['hasSeenAIRepeatNudge'] as bool?) ?? false,
      seenDashboardPrompt: (json['seenDashboardPrompt'] as bool?) ?? false,
      seenLogPrompt: (json['seenLogPrompt'] as bool?) ?? false,
      seenPassportPrompt: (json['seenPassportPrompt'] as bool?) ?? false,
      hasSeenMapTip: (json['hasSeenMapTip'] as bool?) ?? false,
      hasSeenSettingsTip: (json['hasSeenSettingsTip'] as bool?) ?? false,
      hasSeenDashboardGuidance: (json['hasSeenDashboardGuidance'] as bool?) ?? false,
      hasSeenPassportGuidance: (json['hasSeenPassportGuidance'] as bool?) ?? false,
      hasSeenProfileNudge: (json['hasSeenProfileNudge'] as bool?) ?? false,
      hasSeenWelcomeGuide: (json['hasSeenWelcomeGuide'] as bool?) ?? false,
      hasSeenDashboardGuide: (json['hasSeenDashboardGuide'] as bool?) ?? false,
      hasSeenLogGuide: (json['hasSeenLogGuide'] as bool?) ?? false,
      hasSeenPassportGuide: (json['hasSeenPassportGuide'] as bool?) ?? false,
      hasSeenReturnNudge: (json['hasSeenReturnNudge'] as bool?) ?? false,
      hasSeenLogPulse: (json['hasSeenLogPulse'] as bool?) ?? false,
      hasSeenPostFirstSessionPassportPrompt: (json['hasSeenPostFirstSessionPassportPrompt'] as bool?) ?? false,
      hasSeenPostPassportProfilePrompt: (json['hasSeenPostPassportProfilePrompt'] as bool?) ?? false,
      lastLoginDate: json['lastLoginDate'] as String?,
      appVersion: json['appVersion'] as String?,
      appEnvId: json['appEnvId'] as String?,
      units: (json['units'] as String?) ?? 'imperial',
      defaultMapMode: (json['defaultMapMode'] as String?) ?? 'default_region',
      insightsViewedCount: (json['insightsViewedCount'] as int?) ?? 0,
      surferProPopupSuppressedUntil: (json['surferProPopupSuppressedUntil'] as int?) ?? 0,
      lastNudgeShownAt: (json['lastNudgeShownAt'] as int?) ?? 0,
    );
  }
}
