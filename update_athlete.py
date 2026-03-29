import re

file_path = r'c:\Users\StCla\surf_passport - Copy\lib\features\coach_pro\athlete_detail_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

profile_details_code = """
  bool _hasVisibleProfileDetails() {
    return (athlete["stanceVisibleToCoach"] == true && (athlete["stance"]?.isNotEmpty ?? false)) ||
           (athlete["heightVisibleToCoach"] == true && (athlete["height"]?.isNotEmpty ?? false)) ||
           (athlete["weightVisibleToCoach"] == true && (athlete["weight"]?.isNotEmpty ?? false)) ||
           (athlete["locationVisibleToCoach"] == true && (athlete["location"]?.isNotEmpty ?? false));
  }

  Widget _buildProfileDetailsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
"""

if "_buildProfileDetailsCard" not in content:
    content = content.replace("  Widget _buildSnapshotCard(BuildContext context) {", profile_details_code + "\n  Widget _buildSnapshotCard(BuildContext context) {")


listview_insert = """          // Athlete Snapshot
          _buildSnapshotCard(context),
          const SizedBox(height: 12),
          if (_hasVisibleProfileDetails()) ...[
            _buildProfileDetailsCard(context),
          ],
          const SizedBox(height: 24),"""

content = content.replace("          // Athlete Snapshot\n          _buildSnapshotCard(context),\n          const SizedBox(height: 24),", listview_insert)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated athlete_detail_screen.dart")
