import 'session_log_entry.dart';

/// Generates AI Surf Insights from session data.
///
/// Tone: Calm, Precise, Analytical.
/// Tone Guidelines:
/// - Avoid: "I'm stoked", "That's awesome", "Great win".
/// - Prefer: "Today's session suggests...", "This pattern indicates...", "Technical mechanics suggest...".
/// - Maximum 3 sentences per section.
class AiInsightService {
  /// Generates the three insight sections.
  static Map<String, String> generate({
    required SessionLogEntry session,
    List<SessionLogEntry> previousLogs = const [],
    bool isSpanish = false,
  }) {
    final totalSessions = previousLogs.length + 1;
    final interpretation = _interpretSession(session);
    final topic = interpretation.topic;

    // Pattern detection
    final pattern = _detectPatterns(session, previousLogs, isSpanish);

    return {
      'summaryEn': _sessionInsightEn(interpretation: interpretation, topic: topic),
      'patternEn': _progressPatternEn(
        totalSessions: totalSessions, 
        pattern: pattern, 
        interpretation: interpretation,
        topic: topic
      ),
      'nextFocusEn': _nextFocusEn(interpretation: interpretation, topic: topic),
      
      'summaryEs': _sessionInsightEs(interpretation: interpretation, topic: topic),
      'patternEs': _progressPatternEs(
        totalSessions: totalSessions, 
        pattern: pattern, 
        interpretation: interpretation,
        topic: topic
      ),
      'nextFocusEs': _nextFocusEs(interpretation: interpretation, topic: topic),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // English generators
  // ─────────────────────────────────────────────────────────────────────────

  static String _sessionInsightEn({
    required _SessionInterpretation interpretation,
    required _CoachingTopic topic,
  }) {
    if (interpretation.isVague) {
      return "It sounds like that session had a lot going on at once. That's normal when you're learning to read the water.";
    }

    final envContext = interpretation.environmentalContext.isNotEmpty 
        ? " Given the ${interpretation.environmentalContext} conditions, " 
        : " ";

    switch (interpretation.topic) {
      case _CoachingTopic.waveSelection:
        return "Improving your wave selection is the foundation of a good ride.${envContext}Watching the sets and choosing stronger waves sets you up for much better positioning.";
      case _CoachingTopic.lineupAwareness:
        return "Navigating the lineup effectively is just as important as riding the wave.${envContext}Understanding priority and finding your spot helps you catch waves without fighting the crowd.";
      case _CoachingTopic.paddlingCatchingWaves:
        return "Catching waves earlier requires focused paddle speed.${envContext}Matching the wave's energy with strong, deep strokes ensures you don't get left behind.";
      case _CoachingTopic.popUpTakeoffTiming:
        return "A stable ride starts with a controlled pop-up.${envContext}Focusing on your takeoff timing prevents nose dives and gets you to your feet before the wave gets too steep.";
      case _CoachingTopic.balanceStability:
        return "Staying on your feet requires a solid, centered stance.${envContext}Focusing on your balance and keeping your knees bent helps absorb the bumps for a more stable ride.";
      case _CoachingTopic.generatingMaintainingSpeed:
        return "Keeping your momentum through flat sections requires active weight shifting.${envContext}Compressing and extending your body helps generate the speed needed to make it down the line.";
      case _CoachingTopic.turningDirection:
        return "Maneuvering the board starts with looking where you want to go.${envContext}Applying pressure to your rails during your turns helps you carve back toward the power source.";
      case _CoachingTopic.oceanSkillsSafety:
        return "Managing ocean conditions safely is essential for a productive session.${envContext}Mastering skills like the duck dive or turtle roll helps you navigate the impact zone with confidence.";
      case _CoachingTopic.vague:
        return "It sounds like that session had a lot going on at once. That's normal when you're learning to read the water.";
    }
  }

  static String _progressPatternEn({
    int totalSessions = 0,
    String? pattern,
    required _SessionInterpretation interpretation,
    required _CoachingTopic topic,
  }) {
    // Only use generic if topic is truly vague
    if (topic == _CoachingTopic.vague || interpretation.isVague) {
      return "Logging sessions like this helps you start noticing small improvements over time.";
    }

    switch (topic) {
      case _CoachingTopic.waveSelection:
        return "You're starting to notice that choosing the right wave is a skill in itself.";
      case _CoachingTopic.lineupAwareness:
        return "You're starting to read the lineup more and recognize when waves are yours to take.";
      case _CoachingTopic.paddlingCatchingWaves:
        return "You're starting to notice how paddle timing affects whether you catch the wave cleanly.";
      case _CoachingTopic.popUpTakeoffTiming:
        return "Getting to your feet is becoming more consistent, and now timing your takeoff is the next step.";
      case _CoachingTopic.balanceStability:
        return "You're getting onto waves more often, and now you're working on staying steady through the ride.";
      case _CoachingTopic.generatingMaintainingSpeed:
        return "You're starting to notice how small weight shifts affect your speed down the line.";
      case _CoachingTopic.turningDirection:
        return "You're beginning to connect your body movement with how the board changes direction.";
      case _CoachingTopic.oceanSkillsSafety:
        return "You're building more comfort in the water, which helps everything else improve.";
      default:
        return "Logging sessions like this helps you start noticing small improvements over time.";
    }
  }

  static String _nextFocusEn({
    required _SessionInterpretation interpretation,
    required _CoachingTopic topic,
  }) {
    switch (topic) {
      case _CoachingTopic.waveSelection:
        return "Next session, focus purely on watching the waves break before paddling for them.";
      case _CoachingTopic.lineupAwareness:
        return "Next time out, pay closer attention to where the peak is shifting in the lineup.";
      case _CoachingTopic.paddlingCatchingWaves:
        return "Next session, try to start your paddle two strokes earlier to match the wave's speed.";
      case _CoachingTopic.popUpTakeoffTiming:
        return "Next time, focus on bringing your feet directly under you in one smooth motion.";
      case _CoachingTopic.balanceStability:
        return "Next session, focus on keeping your center of gravity low and your arms steady.";
      case _CoachingTopic.generatingMaintainingSpeed:
        return "Next time out, focus on shifting your weight forward to drive through the slow sections.";
      case _CoachingTopic.turningDirection:
        return "Next session, try to actively turn your head and shoulders in the direction you want to carve.";
      case _CoachingTopic.oceanSkillsSafety:
        return "Next time, focus on your breathing and timing when passing through the impact zone.";
      case _CoachingTopic.vague:
        return "Next session, try focusing on one small, specific goal related to your focus skill.";
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Spanish generators
  // ─────────────────────────────────────────────────────────────────────────

  static String _sessionInsightEs({
    required _SessionInterpretation interpretation,
    required _CoachingTopic topic,
  }) {
    if (interpretation.isVague) {
      return "Parece que en esa sesión pasaron muchas cosas a la vez. Eso es normal cuando todavía estás aprendiendo a leer el agua.";
    }

    final envContext = interpretation.environmentalContext.isNotEmpty 
        ? " Dado que las condiciones estaban ${interpretation.environmentalContext}, " 
        : " ";

    switch (topic) {
      case _CoachingTopic.waveSelection:
        return "Mejorar tu selección de olas es la base de una buena sesión.${envContext}Observar las series y elegir olas con más fuerza te posiciona mucho mejor.";
      case _CoachingTopic.lineupAwareness:
        return "Navegar el pico de manera efectiva es tan importante como correr la ola.${envContext}Entender la prioridad y encontrar tu sitio te ayuda a agarrar olas sin pelear con la multitud.";
      case _CoachingTopic.paddlingCatchingWaves:
        return "Agarrar las olas más temprano requiere velocidad de remada.${envContext}Igualar la energía de la ola con brazadas fuertes y profundas asegura que no te quedes atrás.";
      case _CoachingTopic.popUpTakeoffTiming:
        return "Una bajada estable comienza con un pop-up controlado.${envContext}Centrarte en la sincronización de tu despegue evita que claves la punta y te pone de pie antes de que la ola esté muy vertical.";
      case _CoachingTopic.balanceStability:
        return "Mantenerte en pie requiere una postura sólida y centrada.${envContext}Centrarte en el equilibrio y mantener las rodillas flexionadas ayuda a absorber los baches para un viaje más estable.";
      case _CoachingTopic.generatingMaintainingSpeed:
        return "Mantener tu impulso en las secciones planas requiere cambiar el peso activamente.${envContext}Comprimir y extender tu cuerpo ayuda a generar la velocidad necesaria para seguir la línea.";
      case _CoachingTopic.turningDirection:
        return "Maniobrar la tabla comienza mirando hacia donde quieres ir.${envContext}Aplicar presión en los cantos durante los giros te ayuda a volver hacia la zona de poder de la ola.";
      case _CoachingTopic.oceanSkillsSafety:
        return "Gestionar las condiciones del océano de forma segura es esencial.${envContext}Dominar habilidades como el pato (duck dive) o la tortuga te ayuda a pasar la zona de impacto con confianza.";
      case _CoachingTopic.vague:
        return "Parece que en esa sesión pasaron muchas cosas a la vez. Eso es normal cuando todavía estás aprendiendo a leer el agua.";
    }
  }

  static String _progressPatternEs({
    int totalSessions = 0,
    String? pattern,
    required _SessionInterpretation interpretation,
    required _CoachingTopic topic,
  }) {
    // Solo usar genérico si el tema es verdaderamente vago
    if (topic == _CoachingTopic.vague || interpretation.isVague) {
      return "Anotar sesiones como esta te ayuda a empezar a notar pequeñas mejoras con el tiempo.";
    }

    switch (topic) {
      case _CoachingTopic.waveSelection:
        return "Estás empezando a notar que elegir la ola adecuada es una habilidad en sí misma.";
      case _CoachingTopic.lineupAwareness:
        return "Estás empezando a leer el pico de forma más activa y a reconocer cuándo las olas son para ti.";
      case _CoachingTopic.paddlingCatchingWaves:
        return "Estás empezando a notar cómo la sincronización de la remada influye en si entras limpiamente en la ola.";
      case _CoachingTopic.popUpTakeoffTiming:
        return "Ponerte de pie es cada vez más consistente, y ahora sincronizar el despegue es el siguiente paso.";
      case _CoachingTopic.balanceStability:
        return "Estás entrando en las olas con más frecuencia, y ahora estás trabajando en mantenerte estable durante el recorrido.";
      case _CoachingTopic.generatingMaintainingSpeed:
        return "Estás empezando a notar cómo pequeños cambios de peso afectan tu velocidad en la pared de la ola.";
      case _CoachingTopic.turningDirection:
        return "Estás empezando a conectar el movimiento de tu cuerpo con cómo la tabla cambia de dirección.";
      case _CoachingTopic.oceanSkillsSafety:
        return "Estás ganando más confianza en el agua, lo que ayuda a que todo lo demás mejore.";
      default:
        return "Anotar sesiones como esta te ayuda a empezar a notar pequeñas mejoras con el tiempo.";
    }
  }

  static String _nextFocusEs({
    required _SessionInterpretation interpretation,
    required _CoachingTopic topic,
  }) {
    switch (topic) {
      case _CoachingTopic.waveSelection:
        return "En la próxima sesión, enfócate puramente en observar cómo rompen las olas antes de remar hacia ellas.";
      case _CoachingTopic.lineupAwareness:
        return "La próxima vez, presta más atención a cómo se mueve el pico en el lineup.";
      case _CoachingTopic.paddlingCatchingWaves:
        return "En la próxima sesión, intenta empezar a remar dos brazadas antes para igualar la velocidad de la ola.";
      case _CoachingTopic.popUpTakeoffTiming:
        return "La próxima vez, enfócate en llevar los pies directamente debajo de ti en un movimiento suave.";
      case _CoachingTopic.balanceStability:
        return "En la próxima sesión, enfócate en mantener tu centro de gravedad bajo y los brazos estables.";
      case _CoachingTopic.generatingMaintainingSpeed:
        return "La próxima vez, enfócate en echar tu peso hacia adelante para impulsar la tabla en las secciones lentas.";
      case _CoachingTopic.turningDirection:
        return "En la próxima sesión, intenta girar activamente la cabeza y los hombros en la dirección a la que quieres ir.";
      case _CoachingTopic.oceanSkillsSafety:
        return "La próxima vez, enfócate en tu respiración y sincronización al pasar por la zona de impacto.";
      case _CoachingTopic.vague:
        return "En la próxima sesión, intenta centrarte en un objetivo pequeño y específico relacionado con tu habilidad de enfoque.";
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Analysis Helpers
  // ─────────────────────────────────────────────────────────────────────────

  static _SessionInterpretation _interpretSession(SessionLogEntry session) {
    final focus = session.sessionFocus.trim();
    final challenging = (session.reflectionWhatWasChallenging ?? '').trim();
    final workingOn = (session.notes).trim(); // notes often used for what working on
    final feltGood = (session.reflectionWhatFeltGood ?? '').trim();
    final conditions = (session.reflectionConditions ?? '').trim().toLowerCase();
    final waves = session.waveSize.trim();
    final board = session.board.trim();

    final topic = _determinePrimaryTopic(challenging.toLowerCase(), focus.toLowerCase());
    final isVague = topic == _CoachingTopic.vague;

    // Environmental context synthesis
    String envContext = "";
    if (conditions.contains('messy') || conditions.contains('windy') || conditions.contains('choppy')) {
      envContext = "messy";
    } else if (conditions.contains('clean') || conditions.contains('glassy')) {
      envContext = "clean";
    }

    final reasoning = "Focus skill is $focus. "
        "Surfer reported '${challenging.isNotEmpty ? challenging : 'no clear challenge'}'. "
        "Conditions were ${conditions.isNotEmpty ? conditions : 'unknown'}. "
        "Coaching angle: prioritize ${topic.name} anchored by Primary Challenge.";

    return _SessionInterpretation(
      topic: topic,
      isVague: isVague,
      environmentalContext: envContext,
      reasoningSummary: reasoning,
      focusSkill: focus,
      challenging: challenging,
      workingOn: workingOn,
      feltGood: feltGood,
      waveSize: waves,
      boardType: board,
    );
  }

  static _CoachingTopic _determinePrimaryTopic(String challenging, String? focus) {
    final text = challenging.trim().toLowerCase();
    final focusText = (focus ?? '').trim().toLowerCase();
    
    // 1. Check for specific surf topics in the challenge text (Strongest Signal)
    final textTopic = _detectTopicFromText(text);
    if (textTopic != null) return textTopic;

    // 2. Fallback to Focus Skill category if no clear topic in text
    final focusCategory = _getCategoryFromFocus(focusText);
    if (focusCategory != _CoachingTopic.vague) return focusCategory;

    // 3. Confidence Safety Layer (Vague/Explicit Fallback check)
    if (text.isEmpty || text.length < 5) return _CoachingTopic.vague;
    
    final vaguePhrases = [
      'everything felt off', 'not sure what happened', 'hard session', 'waves were weird', 'nothing really worked',
      'todo se sintió mal', 'no sé qué pasó', 'sesión difícil', 'olas raras', 'nada funcionó',
      'messy', 'weird', 'off', 'nothing', 'bad', 'worked', 'raro', 'mal', 'nada', 'desastre', 'caos'
    ];
    if (vaguePhrases.any((v) => text.contains(v))) {
      return _CoachingTopic.vague;
    }

    return _CoachingTopic.vague;
  }

  static _CoachingTopic _getCategoryFromFocus(String focus) {
    final f = focus.toLowerCase();
    
    if (f.contains('selection') || f.contains('reading') || f.contains('choosing')) return _CoachingTopic.waveSelection;
    if (f.contains('positioning') || f.contains('lineup') || f.contains('priority')) return _CoachingTopic.lineupAwareness;
    if (f.contains('paddling') || f.contains('paddle')) return _CoachingTopic.paddlingCatchingWaves;
    if (f.contains('pop-up') || f.contains('takeoff') || f.contains('timing')) return _CoachingTopic.popUpTakeoffTiming;
    if (f.contains('balance') || f.contains('stance')) return _CoachingTopic.balanceStability;
    if (f.contains('speed') || f.contains('compression')) return _CoachingTopic.generatingMaintainingSpeed;
    if (f.contains('turn') || f.contains('cutback') || f.contains('carving')) return _CoachingTopic.turningDirection;
    if (f.contains('duck dive') || f.contains('turtle') || f.contains('safety')) return _CoachingTopic.oceanSkillsSafety;
    
    return _CoachingTopic.vague;
  }

  static _CoachingTopic? _detectTopicFromText(String text) {
    if (text.isEmpty) return null;
    
    // 1. Wave Selection
    if (text.contains('which waves to ride') || text.contains('choosing waves') || text.contains('picking waves') || 
        text.contains('reading waves') || text.contains('watching sets') || text.contains('stronger waves') || 
        text.contains('wrong wave')) {
      return _CoachingTopic.waveSelection;
    }

    // 2. Lineup Awareness
    if (text.contains('when it was my turn') || text.contains('lineup positioning') || text.contains('priority') || 
        text.contains('crowded lineup') || text.contains('sitting deeper') || text.contains('sitting wider') || 
        text.contains('waiting for my wave')) {
      return _CoachingTopic.lineupAwareness;
    }

    // 3. Paddling / Catching Waves
    if (text.contains('paddling fast enough') || text.contains('paddle speed') || text.contains('catching waves earlier') || 
        text.contains('wave passed under me') || text.contains('missed the wave') || text.contains('getting onto the wave')) {
      return _CoachingTopic.paddlingCatchingWaves;
    }

    // 4. Pop-Up / Takeoff Timing
    if (text.contains('standing too late') || text.contains('pop-up timing') || text.contains('nose dive') || 
        text.contains('late takeoff') || text.contains('getting to my feet')) {
      return _CoachingTopic.popUpTakeoffTiming;
    }

    // 5. Balance / Stability
    if (text.contains('staying on my feet') || text.contains('balance') || text.contains('wobbly') || 
        text.contains('unstable') || text.contains('falling off')) {
      return _CoachingTopic.balanceStability;
    }

    // 6. Generating / Maintaining Speed
    if (text.contains('losing speed') || text.contains('generating speed') || text.contains('shifting weight for speed') || 
        text.contains('keeping momentum') || text.contains('slowing down') || text.contains('speed down the line')) {
      return _CoachingTopic.generatingMaintainingSpeed;
    }

    // 7. Turning / Direction
    if (text.contains('turning') || text.contains('carving') || text.contains('cutback') || 
        text.contains('bottom turn') || text.contains('top turn') || text.contains('steering') || 
        text.contains('going down the line')) {
      return _CoachingTopic.turningDirection;
    }

    // 8. Ocean Skills / Safety
    if (text.contains('duck dive') || text.contains('turtle roll') || text.contains('waves crashing') || 
        text.contains('safety') || text.contains('etiquette') || text.contains('paddling out')) {
      return _CoachingTopic.oceanSkillsSafety;
    }

    return null;
  }

  static bool _arePhasesCompatible(_CoachingTopic p1, _CoachingTopic p2) {
    return p1 == p2;
  }

  static _CoachingTopic _detectSuccessPhase(String text) {
    if (text.isEmpty) return _CoachingTopic.vague;
    final topic = _detectTopicFromText(text.toLowerCase());
    return topic ?? _CoachingTopic.vague;
  }

  static bool _mentionsWave(String text) {
    final waveTerms = ['wave', 'ola', 'power', 'fuerza', 'push', 'empuje', 'energy', 'energia'];
    return waveTerms.any((v) => text.toLowerCase().contains(v));
  }

  static String? _detectPatterns(SessionLogEntry current, List<SessionLogEntry> previous, bool isSpanish) {
    if (previous.isEmpty) return null;
    final foci = [current, ...previous].map((e) => e.sessionFocus.trim()).where((s) => s.isNotEmpty).toList();
    if (foci.length < 2) return null;
    final counts = <String, int>{};
    for (var f in foci) counts[f] = (counts[f] ?? 0) + 1;
    final top = counts.entries.where((e) => e.value >= 2).toList()..sort((a,b) => b.value.compareTo(a.value));
    if (top.isNotEmpty) {
      final f = top.first.key;
      return isSpanish 
        ? "Identificar detalles como '$f' puede ayudarte a entender mejor tus sesiones con el tiempo." 
        : "Noticing details like '$f' can help you understand your sessions better over time.";
    }
    return null;
  }
}

class _SessionInterpretation {
  final _CoachingTopic topic;
  final bool isVague;
  final String environmentalContext;
  final String reasoningSummary;
  final String focusSkill;
  final String challenging;
  final String workingOn;
  final String feltGood;
  final String waveSize;
  final String boardType;

  _SessionInterpretation({
    required this.topic,
    required this.isVague,
    required this.environmentalContext,
    required this.reasoningSummary,
    required this.focusSkill,
    required this.challenging,
    required this.workingOn,
    required this.feltGood,
    required this.waveSize,
    required this.boardType,
  });
}

enum _CoachingTopic {
  waveSelection,
  lineupAwareness,
  paddlingCatchingWaves,
  popUpTakeoffTiming,
  balanceStability,
  generatingMaintainingSpeed,
  turningDirection,
  oceanSkillsSafety,
  vague,
}
