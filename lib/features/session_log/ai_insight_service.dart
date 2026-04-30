import 'session_log_entry.dart';
import '../../ui_system/surf_constants.dart';

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
      'summaryEn': _workedOnEn(interpretation: interpretation),
      'patternEn': _whatHappenedEn(interpretation: interpretation),
      'nextFocusEn': _tryThisNextEn(interpretation: interpretation),
      
      'summaryEs': _workedOnEs(interpretation: interpretation),
      'patternEs': _whatHappenedEs(interpretation: interpretation),
      'nextFocusEs': _tryThisNextEs(interpretation: interpretation),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // English generators
  // ─────────────────────────────────────────────────────────────────────────

  static String _workedOnEn({required _SessionInterpretation interpretation}) {
    final good = interpretation.feltGood.toLowerCase();
    final hard = interpretation.challenging.toLowerCase();
    final trying = interpretation.tryingToDo.toLowerCase();
    
    if (good.isNotEmpty && hard.isNotEmpty && trying.isNotEmpty) {
      return "You were $good and trying to $hard on your $trying.";
    } else if (good.isNotEmpty && trying.isNotEmpty) {
      return "You were $good while working on your $trying.";
    } else if (trying.isNotEmpty) {
      return "You were focusing on $trying during your session today.";
    }
    return "You spent some good time practicing in the water today.";
  }

  static String _whatHappenedEn({required _SessionInterpretation interpretation}) {
    final good = interpretation.feltGood.toLowerCase();
    final hard = interpretation.challenging.toLowerCase();
    
    if (good.isNotEmpty && hard.isNotEmpty) {
      return "It sounds like $good was a success, but $hard was the tricky part.";
    } else if (hard.isNotEmpty) {
      return "It seems like $hard was a bit of a challenge during this session.";
    }
    return "Every session helps you get a little more comfortable in the waves.";
  }

  static String _tryThisNextEn({required _SessionInterpretation interpretation}) {
    switch (interpretation.topic) {
      case _CoachingTopic.waveSelection:
        return "Next time, you could try watching the waves from the beach for a few minutes to see where they break most often.";
      case _CoachingTopic.paddlingCatchingWaves:
        return "Next session, it could help to try starting your paddle just a little bit earlier to catch the wave.";
      case _CoachingTopic.popUpTakeoffTiming:
        return "Next time, you could try focusing on bringing your feet through in one smooth motion as you feel the wave's push.";
      case _CoachingTopic.balanceStability:
        return "Next session, you might try keeping your knees a bit more bent to help you stay balanced longer.";
      case _CoachingTopic.lineupAwareness:
        return "Next time, it could help to notice where other people are sitting to find the best spot for yourself.";
      case _CoachingTopic.generatingMaintainingSpeed:
        return "Next session, you might try shifting your weight a little forward when the wave slows down to keep going.";
      case _CoachingTopic.turningDirection:
        return "Next time, it could help to look toward where you want to go, and your board will usually follow.";
      case _CoachingTopic.oceanSkillsSafety:
        return "Next session, you could try focusing on your timing when paddling out to make the journey a bit easier.";
      default:
        return "Next time, you might try picking one small thing to focus on, like your hand position or where you are looking.";
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Spanish generators
  // ─────────────────────────────────────────────────────────────────────────

  static String _workedOnEs({required _SessionInterpretation interpretation}) {
    final good = interpretation.feltGood.toLowerCase();
    final hard = interpretation.challenging.toLowerCase();
    final trying = interpretation.tryingToDo.toLowerCase();
    
    if (good.isNotEmpty && hard.isNotEmpty && trying.isNotEmpty) {
      return "Estuviste $good e intentando $hard en tu $trying.";
    } else if (good.isNotEmpty && trying.isNotEmpty) {
      return "Estuviste $good mientras trabajabas en tu $trying.";
    } else if (trying.isNotEmpty) {
      return "Te enfocaste en $trying durante tu sesión de hoy.";
    }
    return "Pasaste un buen rato practicando en el agua hoy.";
  }

  static String _whatHappenedEs({required _SessionInterpretation interpretation}) {
    final good = interpretation.feltGood.toLowerCase();
    final hard = interpretation.challenging.toLowerCase();
    
    if (good.isNotEmpty && hard.isNotEmpty) {
      return "Parece que $good fue un éxito, pero $hard fue la parte difícil.";
    } else if (hard.isNotEmpty) {
      return "Parece que $hard fue un pequeño desafío durante esta sesión.";
    }
    return "Cada sesión te ayuda a sentirte un poco más cómodo entre las olas.";
  }

  static String _tryThisNextEs({required _SessionInterpretation interpretation}) {
    switch (interpretation.topic) {
      case _CoachingTopic.waveSelection:
        return "La próxima vez, podrías intentar observar las olas desde la orilla unos minutos para ver dónde rompen más seguido.";
      case _CoachingTopic.paddlingCatchingWaves:
        return "En la próxima sesión, podría ayudar intentar empezar a remar un poquito antes para agarrar la ola.";
      case _CoachingTopic.popUpTakeoffTiming:
        return "La próxima vez, podrías intentar enfocarte en llevar tus pies en un movimiento fluido al sentir el empuje de la ola.";
      case _CoachingTopic.balanceStability:
        return "En la próxima sesión, podrías intentar mantener tus rodillas un poco más flexionadas para ayudarte a mantener el equilibrio más tiempo.";
      case _CoachingTopic.lineupAwareness:
        return "La próxima vez, podría ayudar notar dónde está sentada la otra gente para encontrar el mejor lugar para ti.";
      case _CoachingTopic.generatingMaintainingSpeed:
        return "En la próxima sesión, podrías intentar mover tu peso un poco hacia adelante cuando la ola pierda fuerza para seguir avanzando.";
      case _CoachingTopic.turningDirection:
        return "La próxima vez, podría ayudar mirar hacia donde quieres ir, y tu tabla generalmente te seguirá.";
      case _CoachingTopic.oceanSkillsSafety:
        return "En la próxima sesión, podrías intentar enfocarte en tu sincronización al entrar al agua para que el trayecto sea un poco más fácil.";
      default:
        return "La próxima vez, podrías intentar elegir una cosa pequeña en la cual enfocarte, como la posición de tus manos o hacia dónde miras.";
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
    final tryingToDo = (session.reflectionConditions ?? '').trim();
    final waves = session.waveSize.trim();
    final board = session.board.trim();

    final topic = _determinePrimaryTopic(challenging.toLowerCase(), focus.toLowerCase());
    final isVague = topic == _CoachingTopic.vague;

    // Environmental context synthesis
    String envContext = "";
    if (tryingToDo.toLowerCase().contains('messy') || tryingToDo.toLowerCase().contains('windy') || tryingToDo.toLowerCase().contains('choppy')) {
      envContext = "messy";
    }

    final reasoning = "Focus skill is $focus. "
        "Surfer reported '${challenging.isNotEmpty ? challenging : 'no clear challenge'}'. "
        "Goal was $tryingToDo. "
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
      tryingToDo: tryingToDo,
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
      final translatedF = SurfConstants.getFocusSkillTranslation(f, isSpanish);
      return isSpanish 
        ? "Identificar detalles como '$translatedF' puede ayudarte a entender mejor tus sesiones con el tiempo." 
        : "Noticing details like '$f' can help you understand your sessions better over time.";
    }
    return null;
  }

  /// Rules-based insights for all session levels.
    static Map<String, String> getRuleBasedInsight({
    required String struggle,
    required String waveSize,
    required String board,
    List<SessionLogEntry> previousLogs = const [],
    bool isSpanish = false,
  }) {
    final s = struggle.trim().toLowerCase();
    final repeatCount = s.isNotEmpty
        ? previousLogs.where((e) => e.sessionFocus.trim().toLowerCase() == s).length
        : 0;
    final level = (repeatCount + 1).clamp(1, 5);

    // --- SECONDARY SKILL MAPPING ---
    final Map<String, String> skillToCoreMapping = {
      "paddling efficiency": "paddling position",
      "getting outside": "paddling position",
      "duck dive (intro)": "paddling position",
      "turtle roll": "paddling position",
      "angled takeoff": "pop-up timing",
      "generating speed": "maintaining speed",
      "staying with the wave": "maintaining speed",
      "bottom turn": "stance & balance",
      "turning on the wave": "stance & balance",
      "developing bottom turn": "stance & balance",
      "top turn and cutback": "stance & balance",
      "carving turns": "stance & balance",
    };

    if (skillToCoreMapping.containsKey(s)) {
      final coreTarget = skillToCoreMapping[s]!;
      final mappedTmplEn = _getInsightTemplates(coreTarget, 1, false);
      final mappedTmplEs = _getInsightTemplates(coreTarget, 1, true);
      
      if (mappedTmplEn != null && mappedTmplEs != null) {
        return {
          "summaryEn": "That’s a great area to work on.",
          "summaryEs": "Es un área fantástica para trabajar.",
          "patternEn": "It naturally builds on staying balanced and carrying speed.",
          "patternEs": "Se construye sobre la base del equilibrio y la velocidad.",
          "nextFocusEn": mappedTmplEn["nextFocus"]!,
          "nextFocusEs": mappedTmplEs["nextFocus"]!,
        };
      }
    }

    final tmplEn = s.isNotEmpty ? _getInsightTemplates(s, level, false) : null;
    final tmplEs = s.isNotEmpty ? _getInsightTemplates(s, level, true) : null;

    if (tmplEn != null && tmplEs != null) {
      return {
        "summaryEn": tmplEn["summary"]!,
        "summaryEs": tmplEs["summary"]!,
        "patternEn": tmplEn["pattern"]!,
        "patternEs": tmplEs["pattern"]!,
        "nextFocusEn": tmplEn["nextFocus"]!,
        "nextFocusEs": tmplEs["nextFocus"]!,
      };
    }

    return {
      "summaryEn": "Great job getting out there today.",
      "summaryEs": "Gran trabajo metiéndote al agua hoy.",
      "patternEn": "Consistent water time naturally builds confidence.",
      "patternEs": "La constancia en el agua te da mucha confianza.",
      "nextFocusEn": "Next time, you could try focusing on one specific detail, like your paddle rhythm.",
      "nextFocusEs": "La próxima vez, intenta centrarte en un detalle, como tu ritmo de remada.",
    };

  }

  static Map<String, String>? _getInsightTemplates(String struggle, int level, bool isSpanish) {
    final map = {
      "pop-up timing": {
        1: {
          "en": {
            "summary": "You're getting up just as the wave breaks.",
            "pattern": "You might feel the board move faster than expected in the critical zone.",
            "nextFocus": "Next time, you could try popping up right when you feel the initial push.",
          },
          "es": {
            "summary": "Te estás levantando justo cuando la ola rompe.",
            "pattern": "Podrías sentir que la tabla se mueve más rápido en la zona crítica.",
            "nextFocus": "La próxima vez, podrías intentar levantarte justo al sentir el primer empuje.",
          }
        },
        2: {
          "en": {
            "summary": "Your timing is becoming much more consistent.",
            "pattern": "Looking at the horizon instead of the board helps your body react naturally.",
            "nextFocus": "Try keeping your eyes on the beach as you pop up next time.",
          },
          "es": {
            "summary": "Tu sincronización es cada vez más consistente.",
            "pattern": "Mirar al horizonte en vez de a la tabla ayuda a tu cuerpo a reaccionar mejor.",
            "nextFocus": "Prueba a mantener la mirada en la orilla mientras te levantas la próxima vez.",
          }
        },
        3: {
          "en": {
            "summary": "You're catching waves but might feel a loss of momentum.",
            "pattern": "Bringing your front foot forward quickly helps keep the board's speed.",
            "nextFocus": "Next session, you might try landing low to absorb the wave's energy.",
          },
          "es": {
            "summary": "Agarras las olas pero podrías sentir que pierdes impulso.",
            "pattern": "Llevar el pie delantero rápido ayuda a mantener la velocidad de la tabla.",
            "nextFocus": "En la próxima sesión, podrías probar aterrizar bajo para absorber la energía.",
          }
        },
        4: {
          "en": {
            "summary": "You've been giving your pop-up consistent attention lately.",
            "pattern": "Swinging your front foot between your hands in one motion snaps everything into place.",
            "nextFocus": "A small thing to try next time is focusing on a faster arm extension.",
          },
          "es": {
            "summary": "Has estado prestando mucha atención a tu despegue últimamente.",
            "pattern": "Llevar el pie delantero entre las manos en un solo movimiento lo acomoda todo.",
            "nextFocus": "Algo pequeño que intentar es enfocarte en una extensión de brazos más rápida.",
          }
        },
        5: {
          "en": {
            "summary": "You’ve put solid work into this focus area.",
            "pattern": "You’ve been coming back to this a lot. Next time, you could try slowing it down slightly to feel the timing more clearly.",
            "nextFocus": "If it still feels stuck, trying something like wave selection might unlock it.",
          },
          "es": {
            "summary": "Has trabajado mucho en esta área de enfoque.",
            "pattern": "Has vuelto a esto mucho. La próxima podrías intentar hacerlo más lento para sentir el tiempo mejor.",
            "nextFocus": "Si te sientes estancado, probar con selección de olas podría desbloquearlo.",
          }
        }
      },

      "paddling position": {
        1: {
          "en": {
            "summary": "You're exploring where you lie on the board.",
            "pattern": "You might notice the board glides best when the nose is just above the water.",
            "nextFocus": "Next time, you could try moving an inch forward to see if you catch waves easier.",
          },
          "es": {
            "summary": "Estás explorando tu posición sobre la tabla.",
            "pattern": "Podrías notar que la tabla desliza mejor con la punta casi rozando el agua.",
            "nextFocus": "La próxima vez, podrías intentar moverte un poco adelante para entrar mejor.",
          }
        },
        2: {
          "en": {
            "summary": "You're finding the exact balance point for your board.",
            "pattern": "Lifting your chest slightly keeps your weight centered and your breathing easy.",
            "nextFocus": "Next session, you might experiment with keeping your feet touching.",
          },
          "es": {
            "summary": "Estás encontrando el punto de equilibrio exacto.",
            "pattern": "Levantar el pecho ayuda a centrar el peso y a respirar mejor al remar.",
            "nextFocus": "En la próxima sesión, podrías experimentar manteniendo los pies juntos.",
          }
        },
        3: {
          "en": {
            "summary": "You're building a strong foundation for board control.",
            "pattern": "A centered body position lets you use your weight to steer before you stand.",
            "nextFocus": "Try focusing on deep, long strokes to maximize your glide next time.",
          },
          "es": {
            "summary": "Estás construyendo una base sólida de control.",
            "pattern": "Un cuerpo centrado permite usar el peso para dirigir antes de pararse.",
            "nextFocus": "Intenta enfocarte en brazadas largas y profundas para deslizarte más.",
          }
        },
        4: {
          "en": {
            "summary": "You've spent several sessions refining your paddling.",
            "pattern": "Smooth paddling makes the transition to your pop-up feel much more natural.",
            "nextFocus": "A small thing to try next time is reaching further forward with each stroke.",
          },
          "es": {
            "summary": "Llevas varias sesiones refinando tu remada.",
            "pattern": "Una remada fluida hace que la transición al despegue sea mucho más natural.",
            "nextFocus": "Algo pequeño que intentar es alcanzar más adelante con cada brazada.",
          }
        },
        5: {
          "en": {
            "summary": "You’ve spent consistent time on your paddling.",
            "pattern": "You’ve been coming back to this a lot. Next time, you could try slowing it down slightly to feel the timing more clearly.",
            "nextFocus": "If it still feels stuck, trying something like wave selection might unlock it.",
          },
          "es": {
            "summary": "Le has dedicado mucho tiempo a tu remada.",
            "pattern": "Has vuelto a esto mucho. La próxima podrías intentar hacerlo más lento para sentir el tiempo mejor.",
            "nextFocus": "Si te sientes estancado, probar con selección de olas podría desbloquearlo.",
          }
        }
      },

      "stance & balance": {
        1: {
          "en": {
            "summary": "You're exploring how to feel steady during your ride.",
            "pattern": "You might notice the board is easier to control when you bend at the knees instead of the waist.",
            "nextFocus": "Next time, you could try keeping your center of gravity low and grounded.",
          },
          "es": {
            "summary": "Estás explorando cómo sentirte estable durante el recorrido.",
            "pattern": "Podrías notar que la tabla es más fácil de controlar si doblas las rodillas en vez de la cintura.",
            "nextFocus": "La próxima vez, podrías intentar mantener tu centro de gravedad bajo.",
          }
        },
        2: {
          "en": {
            "summary": "You're focusing on keeping the board stable and centered.",
            "pattern": "A wider stance naturally provides a more secure platform as you ride.",
            "nextFocus": "Next session, you might experiment with keeping your feet shoulder-width apart.",
          },
          "es": {
            "summary": "Te enfocas en mantener la tabla estable y centrada.",
            "pattern": "Una postura más ancha da naturalmente una plataforma más segura al surfear.",
            "nextFocus": "En la próxima sesión, podrías experimentar con los pies al ancho de hombros.",
          }
        },
        3: {
          "en": {
            "summary": "You're learning to move naturally with the flow of the wave.",
            "pattern": "Small weight shifts help you steer without losing your centered balance.",
            "nextFocus": "Try pointing your front arm where you want to go to help guide your movement.",
          },
          "es": {
            "summary": "Estás aprendiendo a moverte naturalmente con el flujo de la ola.",
            "pattern": "Pequeños cambios de peso ayudan a dirigir sin perder el equilibrio centrado.",
            "nextFocus": "Intenta apuntar tu brazo delantero hacia donde quieres ir para guiar el movimiento.",
          }
        },
        4: {
          "en": {
            "summary": "You've been practicing your stance consistently lately.",
            "pattern": "Keeping your upper body relaxed helps the board stay steady under your feet.",
            "nextFocus": "A small thing to try next time is looking further ahead instead of at the board.",
          },
          "es": {
            "summary": "Has estado practicando tu postura consistentemente últimamente.",
            "pattern": "Mantener la parte superior relajada ayuda a que la tabla siga estable bajo tus pies.",
            "nextFocus": "Algo pequeño que intentar es mirar más adelante en vez de a la tabla.",
          }
        },
        5: {
          "en": {
            "summary": "You’ve spent consistent time on your balance.",
            "pattern": "You’ve been coming back to this a lot. Next time, you could try slowing it down slightly to feel the timing more clearly.",
            "nextFocus": "If it still feels stuck, trying something like maintaining speed might unlock it.",
          },
          "es": {
            "summary": "Has dedicado mucho tiempo a tu equilibrio.",
            "pattern": "Has vuelto a esto mucho. La próxima podrías intentar hacerlo más lento para sentir el tiempo mejor.",
            "nextFocus": "Si te sientes estancado, probar con mantener velocidad podría desbloquearlo.",
          }
        }
      },

      "wave selection": {
        1: {
          "en": {
            "summary": "You're learning to spot the best waves for your session.",
            "pattern": "You might notice that waves with a clear peak break more predictably.",
            "nextFocus": "Next time, you could try watching the horizon for unbroken bumps.",
          },
          "es": {
            "summary": "Estás aprendiendo a detectar las mejores olas.",
            "pattern": "Podrías notar que las olas con un pico claro rompen de forma más predecible.",
            "nextFocus": "La próxima vez, podrías intentar observar montículos sin romper al horizonte.",
          }
        },
        2: {
          "en": {
            "summary": "You're focusing on reading how the ocean moves.",
            "pattern": "Watching how sets build up helps you predict where the next peak will form.",
            "nextFocus": "Next session, you might experiment with waiting for a wave with more open face.",
          },
          "es": {
            "summary": "Te enfocas en leer cómo se mueve el mar.",
            "pattern": "Observar cómo crecen las series ayuda a predecir dónde se formará el pico.",
            "nextFocus": "En la próxima sesión, podrías esperar por una ola con la cara más abierta.",
          }
        },
        3: {
          "en": {
            "summary": "You're becoming much better at picking your waves.",
            "pattern": "Positioning yourself near the initial peak usually provides the longest possible ride.",
            "nextFocus": "Try paddling slightly closer to where you anticipate the break starting.",
          },
          "es": {
            "summary": "Eres cada vez mejor eligiendo tus olas.",
            "pattern": "Posicionarse cerca del pico inicial suele dar el recorrido más largo.",
            "nextFocus": "Intenta remar un poco más cerca de donde preveas que empezará a romper.",
          }
        },
        4: {
          "en": {
            "summary": "Wave selection has been a consistent focus for you lately.",
            "pattern": "Letting a mediocre wave pass often gives you a much better one right behind it.",
            "nextFocus": "A small thing to try next session is being a bit more patient for the right peak.",
          },
          "es": {
            "summary": "La selección de olas ha sido un enfoque constante últimamente.",
            "pattern": "Dejar pasar una ola mediocre suele darte una mucho mejor justo detrás.",
            "nextFocus": "Algo pequeño que probar es tener un poco más de paciencia por el pico ideal.",
          }
        },
        5: {
          "en": {
            "summary": "You’ve spent consistent time refining your selection.",
            "pattern": "You’ve been coming back to this a lot. Next time, you could try slowing it down slightly to feel the timing more clearly.",
            "nextFocus": "If it still feels stuck, trying something like pop-up timing might unlock it.",
          },
          "es": {
            "summary": "Has dedicado mucho tiempo a refinar tu selección.",
            "pattern": "Has vuelto a esto mucho. La próxima podrías intentar hacerlo más lento para sentir el tiempo mejor.",
            "nextFocus": "Si te sientes estancado, probar con pop-up timing podría desbloquearlo.",
          }
        }
      },

      "maintaining speed": {
        1: {
          "en": {
            "summary": "You're focusing on keeping the board moving forward.",
            "pattern": "You might notice the board glides easier when your weight is shifted slightly toward the nose.",
            "nextFocus": "Next time, you could try leaning forward when you feel the board slowing down.",
          },
          "es": {
            "summary": "Te enfocas en mantener la tabla moviéndose hacia adelante.",
            "pattern": "Podrías notar que la tabla desliza mejor si el peso se mueve hacia la punta.",
            "nextFocus": "La próxima vez, podrías intentar inclinarte adelante si sientes que frenas.",
          }
        },
        2: {
          "en": {
            "summary": "You're working on flowing smoothly with the wave.",
            "pattern": "Staying slightly higher on the wave face usually provides more natural push.",
            "nextFocus": "Next session, you might try holding a higher line to keep your momentum.",
          },
          "es": {
            "summary": "Estás trabajando en fluir suavemente con la ola.",
            "pattern": "Mantenerse un poco más alto en la cara suele dar más empuje natural.",
            "nextFocus": "En la próxima sesión, podrías intentar una línea más alta para no perder inercia.",
          }
        },
        3: {
          "en": {
            "summary": "You're learning how to generate your own speed.",
            "pattern": "Small, active movements through flat sections help you maintain your drive.",
            "nextFocus": "Try unweighting your knees slightly as you move up the wave face next time.",
          },
          "es": {
            "summary": "Estás aprendiendo a generar tu propia velocidad.",
            "pattern": "Pequeños movimientos activos en zonas planas ayudan a mantener el impulso.",
            "nextFocus": "Intenta aligerar las rodillas mientras subes por la pared la próxima vez.",
          }
        },
        4: {
          "en": {
            "summary": "You've been giving your speed consistent attention lately.",
            "pattern": "Looking further down the line naturally pulls your weight forward and builds drive.",
            "nextFocus": "A small thing to try next time is focusing on the next section before you get there.",
          },
          "es": {
            "summary": "Has prestado mucha atención a tu velocidad últimamente.",
            "pattern": "Mirar más allá en la pared inclina tu peso adelante y genera impulso.",
            "nextFocus": "Algo pequeño que intentar es enfocarte en la siguiente sección antes de llegar.",
          }
        },
        5: {
          "en": {
            "summary": "You’ve spent consistent time on your momentum.",
            "pattern": "You’ve been coming back to this a lot. Next time, you could try slowing it down slightly to feel the timing more clearly.",
            "nextFocus": "If it still feels stuck, trying something like your stance might unlock it.",
          },
          "es": {
            "summary": "Has dedicado mucho tiempo a tu inercia.",
            "pattern": "Has vuelto a esto mucho. La próxima podrías intentar hacerlo más lento para sentir el tiempo mejor.",
            "nextFocus": "Si te sientes estancado, probar con tu postura podría desbloquearlo.",
          }
        }
      }

    };

    final category = map.keys.firstWhere((k) => struggle.contains(k), orElse: () => "");
    if (category.isNotEmpty) {
        final levelTemplates = map[category]?[level];
        if (levelTemplates != null) {
            return isSpanish ? levelTemplates["es"] : levelTemplates["en"];
        }
    }
    
    if (struggle.contains("pop") || struggle.contains("timing")) {
      final levelTemplates = map["pop-up timing"]?[level];
      if (levelTemplates != null) return isSpanish ? levelTemplates["es"] : levelTemplates["en"];
    }
    if (struggle.contains("paddle") || struggle.contains("remar")) {
      final levelTemplates = map["paddling position"]?[level];
      if (levelTemplates != null) return isSpanish ? levelTemplates["es"] : levelTemplates["en"];
    }
    if (struggle.contains("balance") || struggle.contains("equil")) {
      final levelTemplates = map["stance & balance"]?[level];
      if (levelTemplates != null) return isSpanish ? levelTemplates["es"] : levelTemplates["en"];
    }
    if (struggle.contains("choose") || struggle.contains("selec") || struggle.contains("wave")) {
      final levelTemplates = map["wave selection"]?[level];
      if (levelTemplates != null) return isSpanish ? levelTemplates["es"] : levelTemplates["en"];
    }
    if (struggle.contains("speed") || struggle.contains("velocidad")) {
      final levelTemplates = map["maintaining speed"]?[level];
      if (levelTemplates != null) return isSpanish ? levelTemplates["es"] : levelTemplates["en"];
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
  final String tryingToDo;
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
    required this.tryingToDo,
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
