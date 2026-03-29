import re

file_path = r'c:\Users\StCla\surf_passport - Copy\lib\features\coach_pro\coach_dashboard_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update the Main Scaffold background and list padding
content = content.replace(
    """      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),""",
    """      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),"""
)

# 2. Update Athlete Cards (in ListView.builder) to match the "Tap Card" style
old_card_builder = """        return Card(
          key: isFirst ? _athleteKey : null,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () {
              // Navigate to detail
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
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(
                athlete["name"][0],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              athlete["name"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(t(athlete["level"], athlete["levelEs"])),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.waves, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      "${athlete["sessions"]} ${t('sessions', 'sesiones')}",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      t(athlete["lastSession"], athlete["lastSessionEs"]),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );"""

# The new Tap Card matching style
new_card_builder = """        return Card(
          key: isFirst ? _athleteKey : null,
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      athlete["name"][0],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          athlete["name"],
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t(athlete["level"], athlete["levelEs"]),
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.waves, size: 14, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              "${athlete["sessions"]} ${t('sessions', 'sesiones')}",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              t(athlete["lastSession"], athlete["lastSessionEs"]),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
        );"""

content = content.replace(old_card_builder, new_card_builder)


# 3. Update the Gated blurred view to strictly use stack filtering from home_screen
old_gated_view = """    return Stack(
      children: [
        // Blurred Mock background
        Opacity(
          opacity: 0.5,
          child: IgnorePointer(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (ctx, i) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.grey.shade300),
                    title: Container(height: 16, width: 100, color: Colors.grey.shade300),
                    subtitle: Container(height: 12, width: 60, color: Colors.grey.shade200),
                    trailing: Container(height: 24, width: 40, color: Colors.grey.shade300),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.transparent),
          ),
        ),
        // Gating Content
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.amber.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline, size: 32, color: Colors.amber),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t("Coach Pro Access", "Acceso Coach Pro"),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t(
                      "Elevate your coaching. Unlock Coach Pro to view athlete profiles, manage your roster, and provide structured feedback.",
                      "Eleva tu nivel como entrenador. Desbloquea Coach Pro para ver perfiles de atletas, gestionar tu lista y dar feedback estructurado."
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        showCoachProModal(context, widget.isSpanish);
                      },
                      child: Text(
                        t("Explore Coach Pro", "Explora Coach Pro"),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );"""

new_gated_view = """    final mockList = ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      itemCount: 4,
      itemBuilder: (ctx, i) {
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(backgroundColor: Colors.grey.shade300),
                const SizedBox(width: 12),
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

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: mockList,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_outline, color: Colors.amber, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t(
                      "Elevate your coaching. Unlock Coach Pro to view athlete profiles, manage your roster, and provide structured feedback.",
                      "Eleva tu nivel como entrenador. Desbloquea Coach Pro para ver perfiles de atletas, gestionar tu lista y dar feedback estructurado."
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => showCoachProModal(context, widget.isSpanish),
                    icon: const Icon(Icons.star_outline),
                    label: Text(t("Coach? Unlock Coach Pro", "¿Eres coach? Desbloquea Coach Pro")),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );"""

content = content.replace(old_gated_view, new_gated_view)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated coach_dashboard_screen.dart")
