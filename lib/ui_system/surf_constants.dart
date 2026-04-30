class SurfConstants {
  static const List<Map<String, String>> waveHeightOptions = [
    {"en": "Whitewater · any size (Beginner)", "metric_en": "Whitewater (Beginner)", "metric_es": "Espuma (Principiante)", "es": "Espuma · cualquier tamaño (Principiante)"},
    {"en": "1–2ft green waves (Early progression)", "metric_en": "30–60cm (Early progression)", "metric_es": "30–60cm (Progreso inicial)", "es": "Olas verdes 1–2 pies (Progreso inicial)"},
    {"en": "2–3ft (Knee to waist high)", "metric_en": "60–90cm", "metric_es": "60–90cm", "es": "2–3 pies (Rodilla a cintura)"},
    {"en": "3–4ft (Waist to chest high)", "metric_en": "90–120cm", "metric_es": "90–120cm", "es": "3–4 pies (Cintura a pecho)"},
    {"en": "4–6ft (Chest to head high)", "metric_en": "1.2–1.8m", "metric_es": "1.2–1.8m", "es": "4–6 pies (Pecho a cabeza)"},
    {"en": "6ft+ (Overhead)", "metric_en": ">1.8m", "metric_es": ">1.8m", "es": "6 pies+ (Por encima de la cabeza)"},
  ];

  static const List<Map<String, String>> conditionOptions = [
    {"en": "Clean", "es": "Limpio"},
    {"en": "Windy", "es": "Ventoso"},
    {"en": "Messy", "es": "Revuelto"},
  ];

  static const List<Map<String, String>> boardOptions = [
    {"en": "Soft-top 7–8 ft (Beginner)", "es": "Tabla Soft-top 7–8 pies (Principiante)"},
    {"en": "Soft-top 8–9 ft (Beginner)", "es": "Tabla Soft-top 8–9 pies (Principiante)"},
    {"en": "Soft-top 9–10 ft (Beginner+)", "es": "Tabla Soft-top 9–10 pies (Principiante+)"},
    {"en": "Longboard (Stable)", "es": "Longboard (Estable)"},
    {"en": "Funboard (Progression)", "es": "Funboard (Progreso)"},
    {"en": "Mid-length (Intermediate)", "es": "Mid-length (Intermedio)"},
    {"en": "Fish (Intermediate+)", "es": "Fish (Intermedio+)"},
    {"en": "Shortboard (Advanced)", "es": "Shortboard (Avanzado)"},
  ];

  static const List<Map<String, String>> masterFocusSkills = [
    {"en": "Pop-up timing", "es": "Timing del pop-up"},
    {"en": "Paddling position", "es": "Posición de remada"},
    {"en": "Stance & balance", "es": "Postura y equilibrio"},
    {"en": "Wave selection", "es": "Selección de olas"},
    {"en": "Maintaining speed", "es": "Manteniendo velocidad"},
    {"en": "Turning", "es": "Giros"},
    {"en": "Reading waves", "es": "Lectura de olas"},
    {"en": "Positioning on the board", "es": "Posicionamiento en la tabla"},
  ];

  static const List<Map<String, String>> focusSkillPresets = [
    // --- New & Updated Names for UI & Storage ---
    {"en": "Pop-up timing", "es": "Timing del pop-up"},
    {"en": "Paddling position", "es": "Posición de remada"},
    {"en": "Stance & balance", "es": "Postura y equilibrio"},
    {"en": "Wave selection", "es": "Selección de olas"},
    {"en": "Maintaining speed", "es": "Manteniendo velocidad"},
    {"en": "Turning", "es": "Giros"},
    {"en": "Reading waves", "es": "Lectura de olas"},
    {"en": "Positioning on the board", "es": "Posicionamiento en la tabla"},
    {"en": "Paddling efficiency", "es": "Eficiencia de remada"},
    {"en": "Getting outside", "es": "Llegar al line-up"},
    {"en": "Angled takeoff", "es": "Takeoff en ángulo"},
    {"en": "Generating speed", "es": "Generación de velocidad"},
    {"en": "Bottom turn", "es": "Bottom turn"},
    {"en": "Turning on the wave", "es": "Giros en la ola"},
    {"en": "Staying with the wave", "es": "Mantenerse en la ola"},
    // --- Legacy / Removed Names for backwards compatibility with old sessions ---
    {"en": "Stance/Balance", "es": "Postura/Equilibrio"},
    {"en": "Safety & etiquette", "es": "Seguridad y etiqueta"},
    {"en": "Paddle efficiency", "es": "Eficiencia de remada"},
    {"en": "Duck dive (intro)", "es": "Duck dive (intro)"},
    {"en": "Turtle roll", "es": "Turtle roll"},
    {"en": "Lineup positioning", "es": "Posicionamiento en el lineup"},
    {"en": "Angled takeoffs", "es": "Takeoffs en ángulo"},
    {"en": "Maintaining speed down the line", "es": "Manteniendo velocidad en la pared"},
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

  static String getWaveHeightTranslation(String? enValue, bool isSpanish, {String units = 'imperial'}) {
    if (enValue == null || enValue.isEmpty) return "";
    final option = waveHeightOptions.firstWhere((o) => o["en"] == enValue, orElse: () => {"en": enValue, "es": enValue});
    
    if (units == 'metric') {
      if (isSpanish) return option["metric_es"] ?? option["es"] ?? enValue;
      return option["metric_en"] ?? option["en"] ?? enValue;
    }
    
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
