class SessionLogEntry {
  final String id;
  final DateTime date;

  final String spotName;
  final String countryOrRegion;

  final String waveSize; // "1–2 ft", "2–4 ft", etc.
  final String sessionFocus; // "Paddling", "Pop up", etc.
  final String board; // "Soft top", etc.

  final int durationMins; // 0 if unknown
  final int rating; // 1-5, 0 if not set
  final String notes;
  final String? reflectionWhatFeltGood;
  final String? reflectionWhatWasChallenging;
  final String? reflectionConditions;
  final String? aiSummaryEn;
  final String? aiSummaryEs;
  final String? aiProgressPatternEn;
  final String? aiProgressPatternEs;
  final String? aiNextFocusEn;
  final String? aiNextFocusEs;
  
  // Legacy fields for backward compatibility
  final String? aiSummary;
  final String? aiProgressPattern;
  final String? aiNextFocus;
  
  final bool isCompleted;
  final String? mediaPath;
  final String? mediaType; // "image" or "video"
  final String? waveLocation; // "Takeoff", "First section", "Mid-wave", "Closing section"
  final String? email;

  const SessionLogEntry({
    required this.id,
    required this.date,
    required this.spotName,
    required this.countryOrRegion,
    required this.waveSize,
    required this.sessionFocus,
    required this.board,
    required this.durationMins,
    required this.rating,
    required this.notes,
    this.reflectionWhatFeltGood,
    this.reflectionWhatWasChallenging,
    this.reflectionConditions,
    this.aiSummary,
    this.aiProgressPattern,
    this.aiNextFocus,
    this.aiSummaryEn,
    this.aiSummaryEs,
    this.aiProgressPatternEn,
    this.aiProgressPatternEs,
    this.aiNextFocusEn,
    this.aiNextFocusEs,
    this.isCompleted = true,
    this.mediaPath,
    this.mediaType,
    this.waveLocation,
    this.email,
  });

  SessionLogEntry copyWith({
    String? id,
    DateTime? date,
    String? spotName,
    String? countryOrRegion,
    String? waveSize,
    String? sessionFocus,
    String? board,
    int? durationMins,
    int? rating,
    String? notes,
    String? reflectionWhatFeltGood,
    String? reflectionWhatWasChallenging,
    String? reflectionConditions,
    String? aiSummary,
    String? aiProgressPattern,
    String? aiNextFocus,
    String? aiSummaryEn,
    String? aiSummaryEs,
    String? aiProgressPatternEn,
    String? aiProgressPatternEs,
    String? aiNextFocusEn,
    String? aiNextFocusEs,
    bool? isCompleted,
    String? mediaPath,
    String? mediaType,
    String? waveLocation,
    String? email,
  }) {
    return SessionLogEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      spotName: spotName ?? this.spotName,
      countryOrRegion: countryOrRegion ?? this.countryOrRegion,
      waveSize: waveSize ?? this.waveSize,
      sessionFocus: sessionFocus ?? this.sessionFocus,
      board: board ?? this.board,
      durationMins: durationMins ?? this.durationMins,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      reflectionWhatFeltGood: reflectionWhatFeltGood ?? this.reflectionWhatFeltGood,
      reflectionWhatWasChallenging: reflectionWhatWasChallenging ?? this.reflectionWhatWasChallenging,
      reflectionConditions: reflectionConditions ?? this.reflectionConditions,
      aiSummary: aiSummary ?? this.aiSummary,
      aiProgressPattern: aiProgressPattern ?? this.aiProgressPattern,
      aiNextFocus: aiNextFocus ?? this.aiNextFocus,
      aiSummaryEn: aiSummaryEn ?? this.aiSummaryEn,
      aiSummaryEs: aiSummaryEs ?? this.aiSummaryEs,
      aiProgressPatternEn: aiProgressPatternEn ?? this.aiProgressPatternEn,
      aiProgressPatternEs: aiProgressPatternEs ?? this.aiProgressPatternEs,
      aiNextFocusEn: aiNextFocusEn ?? this.aiNextFocusEn,
      aiNextFocusEs: aiNextFocusEs ?? this.aiNextFocusEs,
      isCompleted: isCompleted ?? this.isCompleted,
      mediaPath: mediaPath ?? this.mediaPath,
      mediaType: mediaType ?? this.mediaType,
      waveLocation: waveLocation ?? this.waveLocation,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'spotName': spotName,
        'countryOrRegion': countryOrRegion,
        'waveSize': waveSize,
        'sessionFocus': sessionFocus,
        'board': board,
        'durationMins': durationMins,
        'rating': rating,
        'notes': notes,
        'reflectionWhatFeltGood': reflectionWhatFeltGood,
        'reflectionWhatWasChallenging': reflectionWhatWasChallenging,
        'reflectionConditions': reflectionConditions,
        'aiSummary': aiSummary,
        'aiProgressPattern': aiProgressPattern,
        'aiNextFocus': aiNextFocus,
        'aiSummaryEn': aiSummaryEn,
        'aiSummaryEs': aiSummaryEs,
        'aiProgressPatternEn': aiProgressPatternEn,
        'aiProgressPatternEs': aiProgressPatternEs,
        'aiNextFocusEn': aiNextFocusEn,
        'aiNextFocusEs': aiNextFocusEs,
        'isCompleted': isCompleted,
        'mediaPath': mediaPath,
        'mediaType': mediaType,
        'waveLocation': waveLocation,
        'email': email,
      };

  static SessionLogEntry fromJson(Map<String, dynamic> json) {
    return SessionLogEntry(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      spotName: json['spotName'] as String? ?? '',
      countryOrRegion: json['countryOrRegion'] as String? ?? '',
      waveSize: json['waveSize'] as String? ?? '',
      sessionFocus: json['sessionFocus'] as String? ?? '',
      board: json['board'] as String? ?? '',
      durationMins: json['durationMins'] as int? ?? 0,
      rating: json['rating'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
      reflectionWhatFeltGood: json['reflectionWhatFeltGood'] as String?,
      reflectionWhatWasChallenging: json['reflectionWhatWasChallenging'] as String?,
      reflectionConditions: json['reflectionConditions'] as String?,
      aiSummary: json['aiSummary'] as String?,
      aiProgressPattern: json['aiProgressPattern'] as String?,
      aiNextFocus: json['aiNextFocus'] as String?,
      aiSummaryEn: json['aiSummaryEn'] as String?,
      aiSummaryEs: json['aiSummaryEs'] as String?,
      aiProgressPatternEn: json['aiProgressPatternEn'] as String?,
      aiProgressPatternEs: json['aiProgressPatternEs'] as String?,
      aiNextFocusEn: json['aiNextFocusEn'] as String?,
      aiNextFocusEs: json['aiNextFocusEs'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? true,
      mediaPath: json['mediaPath'] as String?,
      mediaType: json['mediaType'] as String?,
      waveLocation: json['waveLocation'] as String?,
      email: json['email'] as String?,
    );
  }
}
