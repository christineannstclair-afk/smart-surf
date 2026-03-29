import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Settings/coach_pro_screen.dart';
import 'athlete_detail_screen.dart';
import '../onboarding/guided_tour_overlay.dart';
import '../../models/surf_dashboard_data.dart';
import '../../ui_system/spacing.dart';
import '../../ui_system/app_card.dart';
import '../../ui_system/premium_blur_panel.dart';
import '../../ui_system/app_theme.dart';
import '../../widgets/smart_surf_wordmark.dart';


const _coachTourKey = 'hasSeenCoachTour';

class CoachDashboardScreen extends StatefulWidget {
  final bool isSpanish;
  final bool isCoachPro;
  final SurfDashboardData? surferData;
  final int sessionsSurfed;
  final DateTime? lastSurfedDate;

  const CoachDashboardScreen({
    super.key,
    required this.isSpanish,
    required this.isCoachPro,
    this.surferData,
    this.sessionsSurfed = 0,
    this.lastSurfedDate,
  });

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  String t(String en, String es) => widget.isSpanish ? es : en;

  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _athleteKey = GlobalKey();
  final GlobalKey _sessionsKey = GlobalKey();
  final GlobalKey _nameKey = GlobalKey();
  
  int _tourStep = 0;
  OverlayEntry? _tourEntry;


  List<Map<String, dynamic>> get _athletes {
    final list = List<Map<String, dynamic>>.from(_mockAthletes);
    if (widget.surferData != null) {
      final sd = widget.surferData!;
      list.insert(0, {
        "id": "self",
        "name": "Self (Preview)",
        "level": sd.levelTitle,
        "levelEs": sd.levelTitle, // Simplifying for preview
        "sessions": widget.sessionsSurfed,
        "lastSession": widget.lastSurfedDate == null ? "Never" : "Recent",
        "lastSessionEs": widget.lastSurfedDate == null ? "Nunca" : "Reciente",
        
        "stance": sd.stance,
        "height": sd.height,
        "weight": sd.weight,
        "location": sd.location,
        
        "stanceVisibleToCoach": sd.stanceVisibleToCoach,
        "heightVisibleToCoach": sd.heightVisibleToCoach,
        "weightVisibleToCoach": sd.weightVisibleToCoach,
        "locationVisibleToCoach": sd.locationVisibleToCoach,
      });
    }
    return list;
  }

  final List<Map<String, dynamic>> _mockAthletes = const [
    {
      "id": "1",
      "name": "Kai Lenny",
      "level": "Professional • Pro Squad",
      "levelEs": "Profesional",
      "sessions": 248,
      "lastSession": "Session #248 - Tow-In Performance",
      "lastSessionEs": "Sesión #248",
    },
    {
      "id": "2",
      "name": "Gabriel Medina",
      "level": "Elite • Travel Team",
      "levelEs": "Élite",
      "sessions": 150,
      "lastSession": "32 Waves Recorded • 4 AI Insights",
      "lastSessionEs": "32 Olas • 4 IA",
    },
    {
      "id": "3",
      "name": "Sarah Jenkins",
      "level": "Intermediate",
      "levelEs": "Intermedio",
      "sessions": 12,
      "lastSession": "Active Squad",
      "lastSessionEs": "Escuadrón Activo",
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isCoachPro) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final prefs = await SharedPreferences.getInstance();
        final seen = prefs.getBool(_coachTourKey) ?? false;
        if (!seen && mounted) {
          _startTourStep(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _tourEntry?.remove();
    _tourEntry = null;
    super.dispose();
  }

  Rect? _rectFor(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  void _removeTourEntry() {
    _tourEntry?.remove();
    _tourEntry = null;
  }

  List<Map<String, dynamic>> _buildSteps() {
    final bool es = widget.isSpanish;
    return [
      {
        'key': _titleKey,
        'title': es ? 'Bienvenido a Coach Pro' : 'Welcome to Coach Pro',
        'desc': es
            ? 'Este panel es tu herramienta central para gestionar, rastrear y guiar el progreso de tus atletas.'
            : 'This dashboard is your central hub to manage, track, and guide the progress of your athletes.',
      },
      {
        'key': _athleteKey,
        'title': es ? 'Tus Atletas' : 'Your Athletes',
        'desc': es
            ? 'Aquí verás a todos tus estudiantes activos junto con sus niveles de habilidad actuales.'
            : 'Here you will see all your active students along with their current skill levels.',
      },
      {
        'key': _sessionsKey,
        'title': es ? 'Rastreo de Sesiones' : 'Session Tracking',
        'desc': es
            ? 'Monitorea de un vistazo cuántas sesiones han completado y cuándo surfearon por última vez.'
            : 'Monitor at a glance how many sessions they have completed and when they last surfed.',
      },
      {
        'key': _nameKey,
        'title': es ? 'Notas e Insights' : 'Notes & Insights',
        'desc': es
            ? '¡Toca a cualquier atleta para profundizar en su progreso, registrar notas privadas y revisar su historial!'
            : 'Tap on any athlete to dive into their progress trends, leave private notes, and review their history!',
      },
    ];
  }

  void _startTourStep(int step) {
    final steps = _buildSteps();
    if (step >= steps.length) {
      _finishTour();
      return;
    }
    _tourStep = step;

    final s = steps[step];
    final key = s['key'] as GlobalKey;
    final rect = _rectFor(key);

    if (rect == null) {
      _startTourStep(step + 1);
      return;
    }

    _removeTourEntry();
    final isLast = step == steps.length - 1;

    _tourEntry = OverlayEntry(
      builder: (ctx) => GuidedTourOverlay(
        targetRect: rect,
        title: s['title'] as String,
        description: s['desc'] as String,
        nextLabel: isLast
            ? (widget.isSpanish ? '¡Comenzar!' : 'Let\'s Go!')
            : (widget.isSpanish ? 'Siguiente' : 'Next'),
        isLastStep: isLast,
        onNext: () {
          _removeTourEntry();
          _startTourStep(step + 1);
        },
        onSkip: () {
          _removeTourEntry();
          _finishTour();
        },
      ),
    );

    Overlay.of(context).insert(_tourEntry!);
  }

  Future<void> _finishTour() async {
    _removeTourEntry();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_coachTourKey, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        centerTitle: false,
        title: const SmartSurfWordmark(),
      ),
      body: !widget.isCoachPro ? _buildGatedView(context) : _buildDashboard(context),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            t("Athlete Roster", "Lista de Atletas"),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ..._athletes.asMap().entries.map((entry) {
          final index = entry.key;
          final athlete = entry.value;
          final isFirst = index == 0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            key: isFirst ? _athleteKey : null,
            padding: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AthleteDetailScreen(
                    athlete: athlete,
                    isSpanish: widget.isSpanish,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryContainer,
                  child: Text(
                    athlete["name"][0],
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      key: isFirst ? _nameKey : null,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                            athlete["name"],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        const SizedBox(height: 4),
                          Text(
                            t(athlete["level"], athlete["levelEs"]),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    key: isFirst ? _sessionsKey : null,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${athlete["sessions"]} ${t("sessions", "sesiones")}",
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t(athlete["lastSession"], athlete["lastSessionEs"]),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        );
        }).toList(),
      ],
    );
  }

  Widget _buildGatedView(BuildContext context) {
    final mockList = ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      itemCount: 4,
      itemBuilder: (ctx, i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(backgroundColor: Colors.grey.shade300),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 16, width: 100, color: Colors.grey.shade300),
                      const SizedBox(height: 4),
                      Container(height: 12, width: 60, color: Colors.grey.shade200),
                    ],
                  ),
                ),
                Container(height: 24, width: 40, color: Colors.grey.shade300),
              ],
            ),
          ),
        );
      },
    );

    return PremiumBlurPanel(
      ctaText: t("Unlock Console", "Desbloquear Consola"),
      onUnlock: () => showCoachProModal(context, widget.isSpanish),
      child: mockList,
    );
  }
}
