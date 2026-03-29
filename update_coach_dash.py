import re

# 1. Update coach_dashboard_screen.dart
file_path_dash = r'c:\Users\StCla\surf_passport - Copy\lib\features\coach_pro\coach_dashboard_screen.dart'
with open(file_path_dash, 'r', encoding='utf-8') as f:
    dash = f.read()

# Title
dash = dash.replace(
    'title: Text(t("Coach Dashboard", "Panel de Coach"), key: _titleKey),',
    'title: Text(t("Coach Performance Console", "Consola de Rendimiento Coach"), key: _titleKey),'
)

# Roster Header
old_dashboard_start = """  Widget _buildDashboard(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _athletes.length,
      itemBuilder: (context, index) {"""
new_dashboard_start = """  Widget _buildDashboard(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            t("Athlete Roster", "Lista de Atletas"),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        ..._athletes.asMap().entries.map((entry) {
          final index = entry.key;
          final athlete = entry.value;"""
dash = dash.replace(old_dashboard_start, new_dashboard_start)

old_dashboard_end = """        );
      },
    );
  }"""
new_dashboard_end = """        );
        }).toList(),
      ],
    );
  }"""
dash = dash.replace(old_dashboard_end, new_dashboard_end)

# Mock Athletes
old_mocks = """  final List<Map<String, dynamic>> _mockAthletes = const [
    {
      "id": "1",
      "name": "Sarah Jenkins",
      "level": "Intermediate",
      "levelEs": "Intermedio",
      "sessions": 12,
      "lastSession": "2 days ago",
      "lastSessionEs": "Hace 2 días",
    },
    {
      "id": "2",
      "name": "Mike Rivera",
      "level": "Advanced",
      "levelEs": "Avanzado",
      "sessions": 45,
      "lastSession": "1 week ago",
      "lastSessionEs": "Hace 1 semana",
    },
    {
      "id": "3",
      "name": "David Chen",
      "level": "Beginner",
      "levelEs": "Principiante",
      "sessions": 3,
      "lastSession": "Today",
      "lastSessionEs": "Hoy",
    },
  ];"""
new_mocks = """  final List<Map<String, dynamic>> _mockAthletes = const [
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
  ];"""
dash = dash.replace(old_mocks, new_mocks)

# Paywall Preview Text
old_paywall = """                  Text(
                    t(
                      "Elevate your coaching. Unlock Coach Pro to view athlete profiles, manage your roster, and provide structured feedback.",
                      "Eleva tu nivel como entrenador. Desbloquea Coach Pro para ver perfiles de atletas, gestionar tu lista y dar feedback estructurado."
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),"""
new_paywall = """                  Text(
                    t(
                      "Upgrade to Coach Pro: Unlock deep biometric analysis and kinematic wave modeling.",
                      "Actualiza a Coach Pro: Desbloquea análisis biométrico profundo y modelado cinemático de olas."
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),"""
dash = dash.replace(old_paywall, new_paywall)

# Unlock Console Button
dash = dash.replace(
    'label: Text(t("Coach? Unlock Coach Pro", "¿Eres coach? Desbloquea Coach Pro")),',
    'label: Text(t("Unlock Console", "Desbloquear Consola")),'
)

with open(file_path_dash, 'w', encoding='utf-8') as f:
    f.write(dash)


# 2. Update athlete_detail_screen.dart
file_path_detail = r'c:\Users\StCla\surf_passport - Copy\lib\features\coach_pro\athlete_detail_screen.dart'
with open(file_path_detail, 'r', encoding='utf-8') as f:
    detail = f.read()

# Add strings to app bar / header area
old_app_bar = """      appBar: AppBar(
        title: Text(athlete["name"]),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t("Edit notes coming soon!", "¡Editar notas próximamente!")),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),"""
new_app_bar = """      appBar: AppBar(
        title: Text(athlete["name"]),
      ),"""
detail = detail.replace(old_app_bar, new_app_bar)

old_body_children = """        children: [
          // Athlete Snapshot
          _buildSnapshotCard(context),"""
new_body_children = """        children: [
          Row(
            children: [
              ActionChip(label: Text(t("Enroll", "Inscribir")), onPressed: () {}),
              const SizedBox(width: 8),
              ActionChip(label: Text(t("Pro Status", "Estado Pro")), onPressed: () {}),
              const SizedBox(width: 8),
              ActionChip(label: Text(t("Scan Passport", "Escanear Passport")), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 16),
          // Athlete Snapshot
          Text(t("Athlete Snapshot", "Resumen del Atleta"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _buildSnapshotCard(context),"""
detail = detail.replace(old_body_children, new_body_children)

# Advanced Biometrics instead of Progress Trends
detail = detail.replace(
    '_buildSectionHeader(context, Icons.analytics_outlined, t("Progress Trends", "Tendencias de Progreso")),',
    '_buildSectionHeader(context, Icons.analytics_outlined, t("Advanced Biometrics", "Biometría Avanzada")),'
)

# Latest Session instead of Recent Sessions
old_recent_sessions = """          // Recent Sessions
          _buildSectionHeader(context, Icons.history, t("Recent Sessions", "Sesiones Recientes")),
          const SizedBox(height: 12),
          _buildRecentSession(context, date: "Oct 12, 2026", spot: "Pipeline, HI", focus: "Bottom Turn"),
          _buildRecentSession(context, date: "Oct 10, 2026", spot: "Sunset Beach, HI", focus: "Positioning"),"""

new_recent_sessions = """          // Recent Sessions
          _buildSectionHeader(context, Icons.history, t("Latest Session", "Última Sesión")),
          const SizedBox(height: 12),
          _buildRecentSession(context, date: "32 Waves Recorded • 4 AI Insights", spot: "Session #248 - Tow-In Performance", focus: "Bottom Turn"),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.rate_review),
                label: Text(t("Review Session", "Revisar Sesión")),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_comment),
                label: Text(t("Add Insight", "Agregar Insight")),
              ),
            ],
          ),"""
detail = detail.replace(old_recent_sessions, new_recent_sessions)

# Data Labels update in snapshot card
old_snapshot_card = """                  Text(
                    t("Current Level", "Nivel Actual"),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t(athlete["level"], athlete["levelEs"]),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 40, color: Theme.of(context).dividerColor.withOpacity(0.2)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    t("Total Sessions", "Sesiones Totales"),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${athlete['sessions']}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),"""

new_snapshot_card = """                  Text(
                    t("Top Skills", "Habilidades"),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t(athlete["level"], athlete["levelEs"]),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 40, color: Theme.of(context).dividerColor.withOpacity(0.2)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    t("Board / Avg. Score / Fitness", "Tabla / Puntaje Promedio / Estado Físico"),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "5'10 / 8.5 / Peak",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),"""
detail = detail.replace(old_snapshot_card, new_snapshot_card)

with open(file_path_detail, 'w', encoding='utf-8') as f:
    f.write(detail)

print("Updated Coach Dashboard copy")
