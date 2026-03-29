class SurfDashboardData {
  final String levelTitle;
  final String levelDesc;
  final String comfortZone;
  final String board;
  final List<String> focusSkills;

  final String age;
  final String displayName;
  final String? profilePhotoPath;
  final String stance;
  final String height;
  final String weight;
  final String location;
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

  const SurfDashboardData({
    required this.levelTitle,
    required this.levelDesc,
    required this.comfortZone,
    required this.board,
    required this.focusSkills,
    required this.age,
    required this.stance,
    required this.height,
    required this.weight,
    required this.location,
    required this.displayName,
    this.profilePhotoPath,
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
  });

  Map<String, dynamic> toJson() => {
        'levelTitle': levelTitle,
        'levelDesc': levelDesc,
        'comfortZone': comfortZone,
        'board': board,
        'focusSkills': focusSkills,
        'age': age,
        'stance': stance,
        'height': height,
        'weight': weight,
        'location': location,
        'displayName': displayName,
        'profilePhotoPath': profilePhotoPath,
        'surferSummary': surferSummary,
        'stanceVisibleToCoach': stanceVisibleToCoach,
        'stanceVisibleOnDashboard': stanceVisibleOnDashboard,
        'heightVisibleToCoach': heightVisibleToCoach,
        'heightVisibleOnDashboard': heightVisibleOnDashboard,
        'weightVisibleToCoach': weightVisibleToCoach,
        'weightVisibleOnDashboard': weightVisibleOnDashboard,
        'locationVisibleToCoach': locationVisibleToCoach,
        'locationVisibleOnDashboard': locationVisibleOnDashboard,
        'ageVisibleToCoach': ageVisibleToCoach,
        'ageVisibleOnDashboard': ageVisibleOnDashboard,
        'latestMediaPath': latestMediaPath,
        'latestMediaType': latestMediaType,
      };

  static SurfDashboardData fromJson(Map<String, dynamic> json) {
    return SurfDashboardData(
      levelTitle: json['levelTitle'] as String? ?? 'Independent Green Waves',
      levelDesc: json['levelDesc'] as String? ?? 'Catches own waves · trims down the line',
      comfortZone: json['comfortZone'] as String? ?? '1–3ft green waves · beach break',
      board: json['board'] as String? ?? 'Soft-top 7–8 ft',
      focusSkills: (json['focusSkills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [
            'Angled takeoffs',
            'Bottom turns',
            'Speed down the line',
          ],
      age: json['age'] as String? ?? '',
      stance: json['stance'] as String? ?? 'Regular',
      height: json['height'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
      location: json['location'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      profilePhotoPath: json['profilePhotoPath'] as String?,
      surferSummary: json['surferSummary'] as String? ?? '',
      stanceVisibleToCoach: json['stanceVisibleToCoach'] as bool? ?? false,
      stanceVisibleOnDashboard: json['stanceVisibleOnDashboard'] as bool? ?? true,
      heightVisibleToCoach: json['heightVisibleToCoach'] as bool? ?? false,
      heightVisibleOnDashboard: json['heightVisibleOnDashboard'] as bool? ?? true,
      weightVisibleToCoach: json['weightVisibleToCoach'] as bool? ?? false,
      weightVisibleOnDashboard: json['weightVisibleOnDashboard'] as bool? ?? true,
      locationVisibleToCoach: json['locationVisibleToCoach'] as bool? ?? false,
      locationVisibleOnDashboard: json['locationVisibleOnDashboard'] as bool? ?? true,
      ageVisibleToCoach: json['ageVisibleToCoach'] as bool? ?? false,
      ageVisibleOnDashboard: json['ageVisibleOnDashboard'] as bool? ?? true,
      latestMediaPath: json['latestMediaPath'] as String?,
      latestMediaType: json['latestMediaType'] as String?,
    );
  }

  SurfDashboardData copyWith({
    String? levelTitle,
    String? levelDesc,
    String? comfortZone,
    String? board,
    List<String>? focusSkills,
    String? age,
    String? displayName,
    String? profilePhotoPath,
    String? stance,
    String? height,
    String? weight,
    String? location,
    String? surferSummary,
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
    return SurfDashboardData(
      levelTitle: levelTitle ?? this.levelTitle,
      levelDesc: levelDesc ?? this.levelDesc,
      comfortZone: comfortZone ?? this.comfortZone,
      board: board ?? this.board,
      focusSkills: focusSkills ?? this.focusSkills,
      age: age ?? this.age,
      displayName: displayName ?? this.displayName,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      stance: stance ?? this.stance,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      location: location ?? this.location,
      surferSummary: surferSummary ?? this.surferSummary,
      stanceVisibleToCoach: stanceVisibleToCoach ?? this.stanceVisibleToCoach,
      stanceVisibleOnDashboard: stanceVisibleOnDashboard ?? this.stanceVisibleOnDashboard,
      heightVisibleToCoach: heightVisibleToCoach ?? this.heightVisibleToCoach,
      heightVisibleOnDashboard: heightVisibleOnDashboard ?? this.heightVisibleOnDashboard,
      weightVisibleToCoach: weightVisibleToCoach ?? this.weightVisibleToCoach,
      weightVisibleOnDashboard: weightVisibleOnDashboard ?? this.weightVisibleOnDashboard,
      locationVisibleToCoach: locationVisibleToCoach ?? this.locationVisibleToCoach,
      locationVisibleOnDashboard: locationVisibleOnDashboard ?? this.locationVisibleOnDashboard,
      ageVisibleToCoach: ageVisibleToCoach ?? this.ageVisibleToCoach,
      ageVisibleOnDashboard: ageVisibleOnDashboard ?? this.ageVisibleOnDashboard,
      latestMediaPath: latestMediaPath ?? this.latestMediaPath,
      latestMediaType: latestMediaType ?? this.latestMediaType,
    );
  }
}
