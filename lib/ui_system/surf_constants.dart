class SurfConstants {
  static const List<Map<String, String>> waveHeightOptions = [
    {"en": "1–2 ft", "metric": "30–60cm", "es": "1–2 pies"},
    {"en": "2–4 ft", "metric": "60–120cm", "es": "2–4 pies"},
    {"en": "4–6 ft", "metric": "1.2–1.8m", "es": "4–6 pies"},
    {"en": "6+ ft", "metric": ">1.8m", "es": "6+ pies"},
  ];

  static const List<Map<String, String>> conditionOptions = [
    {"en": "Clean", "es": "Limpio"},
    {"en": "Windy", "es": "Ventoso"},
    {"en": "Messy", "es": "Revuelto"},
  ];

  static const List<Map<String, String>> boardOptions = [
    {"en": "Soft-top 7 to 8 feet", "es": "Tabla Soft-top 7 a 8 pies"},
    {"en": "Soft-top 8–9 ft", "es": "Tabla Soft-top 8–9 pies"},
    {"en": "Soft-top 9–10 ft", "es": "Tabla Soft-top 9–10 pies"},
    {"en": "Longboard", "es": "Longboard"},
    {"en": "Funboard", "es": "Funboard"},
    {"en": "Mid-length", "es": "Mid-length"},
    {"en": "Fish", "es": "Fish"},
    {"en": "Shortboard", "es": "Shortboard"},
  ];

  static const List<Map<String, String>> focusSkillPresets = [
    {"en": "Pop-up timing", "es": "Timing del pop-up"},
    {"en": "Paddling position", "es": "Posición de remada"},
    {"en": "Stance/Balance", "es": "Postura/Equilibrio"},
    {"en": "Safety & etiquette", "es": "Seguridad y etiqueta"},
    {"en": "Paddle efficiency", "es": "Eficiencia de remada"},
    {"en": "Duck dive (intro)", "es": "Duck dive (intro)"},
    {"en": "Turtle roll", "es": "Turtle roll"},
    {"en": "Wave selection", "es": "Selección de olas"},
    {"en": "Lineup positioning", "es": "Posicionamiento en el lineup"},
    {"en": "Angled takeoffs", "es": "Takeoffs en ángulo"},
    {"en": "Maintaining speed down the line", "es": "Manteniendo velocidad en la pared"},
    {"en": "Generating speed", "es": "Generación de velocidad"},
    {"en": "Developing bottom turn", "es": "Perfeccionando bottom turn"},
    {"en": "Top turn and cutback", "es": "Top turn y cutback"},
    {"en": "Carving turns", "es": "Giros de carving"},
    {"en": "Compression and extension", "es": "Compresión y extensión"},
    {"en": "Reading sections", "es": "Lectura de secciones"},
    {"en": "Finishing the wave", "es": "Finalización de la ola"},
    {"en": "Backside technique", "es": "Técnica de backside"},
    {"en": "Frontside technique", "es": "Técnica de frontside"},
    {"en": "Floaters and re-entry", "es": "Floaters y re-entry"},
    {"en": "Barrel positioning", "es": "Posicionamiento en el tubo"},
    {"en": "Aerial foundations", "es": "Fundamentos de aéreos"},
  ];
  static const List<Map<String, String>> waveLocationOptions = [
    {"en": "Takeoff", "es": "Despegue"},
    {"en": "First section", "es": "Primera sección"},
    {"en": "Mid-wave", "es": "Media ola"},
    {"en": "Closing section", "es": "Sección final"},
  ];

  static String getBoardTranslation(String? enValue, bool isSpanish) {
    if (enValue == null || enValue.isEmpty) return "";
    final option = boardOptions.firstWhere((o) => o["en"] == enValue, orElse: () => {"en": enValue, "es": enValue});
    return isSpanish ? option["es"]! : option["en"]!;
  }

  static String getConditionTranslation(String? enValue, bool isSpanish) {
    if (enValue == null || enValue.isEmpty) return "";
    final option = conditionOptions.firstWhere((o) => o["en"] == enValue, orElse: () => {"en": enValue, "es": enValue});
    return isSpanish ? option["es"]! : option["en"]!;
  }

  static String getWaveHeightTranslation(String? enValue, bool isSpanish) {
    if (enValue == null || enValue.isEmpty) return "";
    final option = waveHeightOptions.firstWhere((o) => o["en"] == enValue, orElse: () => {"en": enValue, "es": enValue});
    return isSpanish ? option["es"]! : option["en"]!;
  }

  static String getWaveLocationTranslation(String? enValue, bool isSpanish) {
    if (enValue == null || enValue.isEmpty) return "";
    final option = waveLocationOptions.firstWhere((o) => o["en"] == enValue, orElse: () => {"en": enValue, "es": enValue});
    return isSpanish ? option["es"]! : option["en"]!;
  }

  static String getFocusSkillTranslation(String? enValue, bool isSpanish) {
    if (enValue == null || enValue.isEmpty) return "";
    final option = focusSkillPresets.firstWhere((o) => o["en"] == enValue, orElse: () => {"en": enValue, "es": enValue});
    return isSpanish ? option["es"]! : option["en"]!;
  }
}
