import re

file_path = r'c:\Users\StCla\surf_passport - Copy\lib\features\coach_pro\athlete_detail_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update Profile Details Card (Flat Outline style)
content = content.replace(
"""  Widget _buildProfileDetailsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),""",
"""  Widget _buildProfileDetailsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),"""
)

content = content.replace(
"""          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),""",
"""          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),"""
)

# 2. Update Snapshot Card
content = content.replace(
"""  Widget _buildSnapshotCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),""",
"""  Widget _buildSnapshotCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),"""
)

content = content.replace(
"""                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),""",
"""                                fontSize: 13,
                                letterSpacing: 0.5,
                                color: Theme.of(context).colorScheme.primary,
                              ),"""
)
content = content.replace(
"""                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),""",
"""                                fontSize: 13,
                                letterSpacing: 0.5,
                                color: Theme.of(context).colorScheme.primary,
                              ),"""
)

# 3. Update Section Headers
content = content.replace(
"""  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }""",
"""  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }"""
)

# 4. Update Trends Card
content = content.replace(
"""  Widget _buildTrendsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),""",
"""  Widget _buildTrendsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),"""
)

# 5. Update Notes Card matching coach dashboard exact tints
content = content.replace(
"""  Widget _buildNotesCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  t("Coach Alex", "Coach Álex"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              t(
                  "Great weight distribution on the backhand, focus on your front knee driving through the turn next session.",
                  "Excelente distribución de peso en el backhand, la próxima sesión enfócate en impulsar la rodilla delantera durante el giro."),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }""",
"""  Widget _buildNotesCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade200,
              radius: 20,
              child: Icon(Icons.person, color: Colors.blue.shade800),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t("Coach Alex", "Coach Álex"),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t(
                        "Great weight distribution on the backhand, focus on your front knee driving through the turn next session.",
                        "Excelente distribución de peso en el backhand, la próxima sesión enfócate en impulsar la rodilla delantera durante el giro."),
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }"""
)

# 6. Update Recent Session Cards
content = content.replace(
"""  Widget _buildRecentSession(BuildContext context, {required String date, required String spot, required String focus}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.waves, color: Theme.of(context).colorScheme.secondary),
        ),
        title: Text(spot, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$date • $focus", style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () {
          // View session log detail
        },
      ),
    );
  }""",
"""  Widget _buildRecentSession(BuildContext context, {required String date, required String spot, required String focus}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // View session log detail
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.waves, color: Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      focus,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }"""
)

# 7. Overall View Padding
content = content.replace(
"""      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),""",
"""      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),"""
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated athlete_detail_screen.dart styles")
