class SessionReflection {
  final String id;
  final DateTime date;
  final String workingOn;
  final String whatFeltHard;
  final String whatFeltGood;
  final String aiSummary;
  final String aiProgressPattern;
  final String aiNextFocus;

  SessionReflection({
    required this.id,
    required this.date,
    required this.workingOn,
    required this.whatFeltHard,
    required this.whatFeltGood,
    required this.aiSummary,
    required this.aiProgressPattern,
    required this.aiNextFocus,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'workingOn': workingOn,
        'whatFeltHard': whatFeltHard,
        'whatFeltGood': whatFeltGood,
        'aiSummary': aiSummary,
        'aiProgressPattern': aiProgressPattern,
        'aiNextFocus': aiNextFocus,
      };

  static SessionReflection fromJson(Map<String, dynamic> json) {
    return SessionReflection(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      workingOn: json['workingOn'] as String? ?? '',
      whatFeltHard: json['whatFeltHard'] as String? ?? '',
      whatFeltGood: json['whatFeltGood'] as String? ?? '',
      aiSummary: json['aiSummary'] as String? ?? '',
      aiProgressPattern: json['aiProgressPattern'] as String? ?? '',
      aiNextFocus: json['aiNextFocus'] as String? ?? '',
    );
  }
}
