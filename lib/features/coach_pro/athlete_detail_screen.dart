import 'package:flutter/material.dart';
import '../../ui_system/spacing.dart';
import '../../ui_system/app_card.dart';
import '../../ui_system/app_theme.dart';

class AthleteDetailScreen extends StatelessWidget {
  final Map<String, dynamic> athlete;
  final bool isSpanish;

  const AthleteDetailScreen({
    super.key,
    required this.athlete,
    required this.isSpanish,
  });

  String t(String en, String es) => isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(athlete["name"]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
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
          Text(t("Athlete Snapshot", "Resumen del Atleta"), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _buildSnapshotCard(context),
          const SizedBox(height: 12),
          if (_hasVisibleProfileDetails()) ...[
            _buildProfileDetailsCard(context),
          ],
          const SizedBox(height: AppSpacing.lg),
          
          // Progress Trends
          _buildSectionHeader(context, Icons.analytics_outlined, t("Advanced Biometrics", "Biometría Avanzada")),
          const SizedBox(height: AppSpacing.sm),
          _buildTrendsCard(context),
          const SizedBox(height: AppSpacing.lg),

          // Private Coach Notes
          _buildSectionHeader(context, Icons.notes, t("Coach Notes", "Notas del Coach")),
          const SizedBox(height: AppSpacing.sm),
          _buildNotesCard(context),
          const SizedBox(height: AppSpacing.lg),

          // Recent Sessions
          _buildSectionHeader(context, Icons.history, t("Latest Session", "Última Sesión")),
          const SizedBox(height: AppSpacing.sm),
          _buildRecentSession(context, date: "32 Waves Recorded • 4 AI Insights", spot: "Session #248 - Tow-In Performance", focus: "Bottom Turn"),
          const SizedBox(height: AppSpacing.xs),
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
          ),
        ],
      ),
    );
  }


  bool _hasVisibleProfileDetails() {
    return (athlete["stanceVisibleToCoach"] == true && (athlete["stance"]?.isNotEmpty ?? false)) ||
           (athlete["heightVisibleToCoach"] == true && (athlete["height"]?.isNotEmpty ?? false)) ||
           (athlete["weightVisibleToCoach"] == true && (athlete["weight"]?.isNotEmpty ?? false)) ||
           (athlete["locationVisibleToCoach"] == true && (athlete["location"]?.isNotEmpty ?? false));
  }

  Widget _buildProfileDetailsCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (athlete["stanceVisibleToCoach"] == true && (athlete["stance"]?.isNotEmpty ?? false))
            _detailRow(context, Icons.snowboarding, t("Stance", "Postura"), athlete["stance"]),
          if (athlete["heightVisibleToCoach"] == true && (athlete["height"]?.isNotEmpty ?? false))
            _detailRow(context, Icons.height, t("Height", "Altura"), athlete["height"]),
          if (athlete["weightVisibleToCoach"] == true && (athlete["weight"]?.isNotEmpty ?? false))
            _detailRow(context, Icons.monitor_weight_outlined, t("Weight", "Peso"), athlete["weight"]),
          if (athlete["locationVisibleToCoach"] == true && (athlete["location"]?.isNotEmpty ?? false))
            _detailRow(context, Icons.location_on_outlined, t("Location", "Ubicación"), athlete["location"]),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }

  Widget _buildTrendsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(
                "Consistent improvement in wave count. Rating average increased to 4.2/5 over the last 5 sessions.",
                "Mejora constante en el número de olas. El promedio de calificación aumentó a 4.2/5 en las últimas 5 sesiones."
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _fakeBar(30, Colors.grey.shade300),
                _fakeBar(45, Colors.grey.shade300),
                _fakeBar(60, Colors.green.shade400),
                _fakeBar(55, Colors.green.shade500),
                _fakeBar(80, Colors.green.shade600),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fakeBar(double height, Color color) {
    return Container(
      width: 32,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.amber.shade50.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.push_pin_outlined, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  t("Latest Annotation", "Última Anotación"),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                ),
                const Spacer(),
                Text(
                  athlete["lastSession"],
                  style: TextStyle(fontSize: 10, color: Colors.brown.withOpacity(0.5), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              t(
                "Work on keeping eyes up during bottom turn. Speed generation is looking much better on forehand.",
                "Trabajar en mantener la mirada arriba durante el bottom turn. La generación de velocidad se ve mucho mejor en el forehand.",
              ),
              style: TextStyle(color: Colors.brown.shade800, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSession(BuildContext context, {required String date, required String spot, required String focus}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.waves, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(spot, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text("${t("Focus:", "Foco:")} $focus\n$date", style: const TextStyle(fontSize: 12)),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () {
          // Future: open session log modal
        },
      ),
    );
  }
}
