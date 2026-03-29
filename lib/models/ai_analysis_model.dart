class AiAnalysisResult {
  final String id;
  final DateTime date;
  final String waveType;
  final String focusArea;
  final String experienceLevel;
  final String looksSolid;
  final String primaryImprovement;
  final String drillToPractice;
  final String? videoPath;

  // Real Metrics from backend
  final double popupTimeSeconds;
  final double kneeAngleMin;
  final double stanceWidthRatio;
  final double backAngleAtStand;
  final double stabilityScore;
  final double confidenceScore;

  const AiAnalysisResult({
    required this.id,
    required this.date,
    required this.waveType,
    required this.focusArea,
    required this.experienceLevel,
    required this.looksSolid,
    required this.primaryImprovement,
    required this.drillToPractice,
    required this.popupTimeSeconds,
    required this.kneeAngleMin,
    required this.stanceWidthRatio,
    required this.backAngleAtStand,
    required this.stabilityScore,
    required this.confidenceScore,
    this.videoPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'waveType': waveType,
        'focusArea': focusArea,
        'experienceLevel': experienceLevel,
        'looksSolid': looksSolid,
        'primaryImprovement': primaryImprovement,
        'drillToPractice': drillToPractice,
        'videoPath': videoPath,
        'popupTimeSeconds': popupTimeSeconds,
        'kneeAngleMin': kneeAngleMin,
        'stanceWidthRatio': stanceWidthRatio,
        'backAngleAtStand': backAngleAtStand,
        'stabilityScore': stabilityScore,
        'confidenceScore': confidenceScore,
      };

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) =>
      AiAnalysisResult(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        waveType: json['waveType'] as String,
        focusArea: json['focusArea'] as String,
        experienceLevel: json['experienceLevel'] as String,
        looksSolid: json['looksSolid'] as String,
        primaryImprovement: json['primaryImprovement'] as String,
        drillToPractice: json['drillToPractice'] as String,
        videoPath: json['videoPath'] as String?,
        popupTimeSeconds: (json['popupTimeSeconds'] as num?)?.toDouble() ?? 0.0,
        kneeAngleMin: (json['kneeAngleMin'] as num?)?.toDouble() ?? 0.0,
        stanceWidthRatio: (json['stanceWidthRatio'] as num?)?.toDouble() ?? 0.0,
        backAngleAtStand: (json['backAngleAtStand'] as num?)?.toDouble() ?? 0.0,
        stabilityScore: (json['stabilityScore'] as num?)?.toDouble() ?? 0.0,
        confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      );
}
