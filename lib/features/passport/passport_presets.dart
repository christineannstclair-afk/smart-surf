import '../../ui_system/surf_constants.dart';

class PassportPresets {
  // LEVELS (store EN canonical, display EN/ES)
  // Order: Beginner -> Advanced
  static const List<Map<String, String>> levels = [
    {
      "enTitle": "Whitewater Beginner",
      "esTitle": "Espuma (principiante)",
      "enDesc": "Rides broken waves straight · learning pop-up",
      "esDesc": "Surfea espuma recto · aprendiendo takeoff",
    },
    {
      "enTitle": "Assisted Green Waves",
      "esTitle": "Olas verdes con ayuda",
      "enDesc": "Catches small green waves · needs guidance sometimes",
      "esDesc": "Atrapa olas verdes pequeñas · a veces necesita guía",
    },
    {
      "enTitle": "Independent Green Waves",
      "esTitle": "Olas verdes independientes",
      "enDesc": "Catches own waves · trims down the line · developing turns",
      "esDesc": "Atrapa sus propias olas · recorre la pared · giros en desarrollo",
    },
    {
      "enTitle": "Developing Turns",
      "esTitle": "Giros en progreso",
      "enDesc": "Bottom turns · generating speed · wave reading",
      "esDesc": "Bottom turns · generando velocidad · lectura de ola",
    },
    {
      "enTitle": "Early Intermediate",
      "esTitle": "Intermedio inicial",
      "enDesc": "More consistent · reading waves better",
      "esDesc": "Más consistente · lee mejor las olas",
    },

    // NEW (added)
    {
      "enTitle": "Confident Intermediate",
      "esTitle": "Intermedio seguro",
      "enDesc": "Links turns · controls speed and direction",
      "esDesc": "Encadena giros · controla velocidad y dirección",
    },
    {
      "enTitle": "Advanced / Self-Directed",
      "esTitle": "Avanzado / autónomo",
      "enDesc": "Reads waves independently · no coaching required",
      "esDesc": "Lee olas de forma independiente · no requiere coach",
    },
  ];

  // COMFORT ZONES
  static const List<Map<String, String>> comfortZones = SurfConstants.waveHeightOptions;

   // BOARDS
  static const List<Map<String, String>> boards = SurfConstants.boardOptions;

   // FOCUS SKILLS (Canonical Source of Truth)
  static const List<Map<String, String>> focusSkills = SurfConstants.focusSkillPresets;

  // WAVE SIZES (canonical: "1–2 ft", "2–4 ft", etc)
  static const List<Map<String, String>> waveSizes = SurfConstants.waveHeightOptions;

  static const List<Map<String, String>> conditions = SurfConstants.conditionOptions;

  static String formatWaveSize(String enValue, String units) {
    final match = waveSizes.firstWhere(
      (m) => m["en"] == enValue,
      orElse: () => {"en": enValue},
    );
    if (units == 'metric') return match["metric_en"] ?? enValue;
    return match["en"] ?? enValue;
  }
  static List<String> get focusPresets =>
      SurfConstants.masterFocusSkills.map((m) => m["en"]!).toList();

  static List<Map<String, String>> get focusPresetMaps => SurfConstants.masterFocusSkills;

  // HELPERS
  static String levelTitle({required bool isSpanish, required String enTitle}) {
    final match = levels.firstWhere(
      (m) => m["enTitle"] == enTitle,
      orElse: () => {"enTitle": enTitle, "esTitle": enTitle},
    );
    return isSpanish
        ? (match["esTitle"] ?? enTitle)
        : (match["enTitle"] ?? enTitle);
  }

  static String levelDesc({
    required bool isSpanish,
    required String enTitle,
    required String enDescFallback,
  }) {
    final match = levels.firstWhere(
      (m) => m["enTitle"] == enTitle,
      orElse: () => {"enDesc": enDescFallback, "esDesc": enDescFallback},
    );
    return isSpanish
        ? (match["esDesc"] ?? enDescFallback)
        : (match["enDesc"] ?? enDescFallback);
  }

  static String mapValue({
    required bool isSpanish,
    required String units,
    required List<Map<String, String>> list,
    required String enValue,
  }) {
    final match = list.firstWhere(
      (m) => m["en"] == enValue,
      orElse: () => {"en": enValue, "es": enValue},
    );

    final isMetric = units == 'metric';
    if (isMetric) {
      if (isSpanish) return match["metric_es"] ?? match["es"] ?? enValue;
      return match["metric_en"] ?? match["en"] ?? enValue;
    }

    return isSpanish ? (match["es"] ?? enValue) : (match["en"] ?? enValue);
  }

  static String focusLabel({required bool isSpanish, required String enSkill}) {
    final match = focusSkills.firstWhere(
      (m) => m["en"] == enSkill,
      orElse: () => {"en": enSkill, "es": enSkill},
    );
    return isSpanish ? (match["es"] ?? enSkill) : (match["en"] ?? enSkill);
  }

  // Returns only focus skills that exist in the presets (prevents “hidden 3rd”)
  static List<String> normalizeFocus(List<String> current) {
    // We now allow custom skills, so we just filter for non-empty and unique
    return current.where((s) => s.trim().isNotEmpty).toSet().toList();
  }
}
