import re

file_path = r'c:\Users\StCla\surf_passport - Copy\lib\features\home\home_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Athlete Dashboard -> Athlete Profile
content = content.replace('"Athlete Dashboard", // Name would normally go here', '"Athlete Profile", // Name would normally go here')

# 2. Add "Performance Snapshot" header above "Current Surf Level" TapCard
old_list_view_start = """            // Top Profile Section
            _buildProfileSection(context),
            const SizedBox(height: 24),

            // Merged Surf Level Card"""
new_list_view_start = """            // Top Profile Section
            _buildProfileSection(context),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _t("Performance Snapshot", "Resumen de Rendimiento"),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),

            // Merged Surf Level Card"""
content = content.replace(old_list_view_start, new_list_view_start)

# 3. Change "Current Surf Level" to "Surf Level"
content = content.replace('titleEn: "Current Surf Level",', 'titleEn: "Surf Level",')

# 4. Change "Board" to "Current Board" for the TapCard title
# Specifically the one with icon: Icons.straighten_outlined
old_board_card = """            _tapCard(
              icon: Icons.straighten_outlined,
              titleEn: "Board","""
new_board_card = """            _tapCard(
              icon: Icons.straighten_outlined,
              titleEn: "Current Board","""
content = content.replace(old_board_card, new_board_card)


# 5. Add "Latest Session" header and change text to "Load Latest Session Media"
old_latest_session = """        const SizedBox(height: 16),
        // Latest Session Media Placeholder
        Container("""
new_latest_session = """        const SizedBox(height: 24),
        Text(
          _t("Latest Session", "Última Sesión"),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 12),
        // Latest Session Media Placeholder
        Container("""
content = content.replace(old_latest_session, new_latest_session)

content = content.replace('Text(\n                        _t("Latest Session Clip", "Clip Última Sesión"),', 'Text(\n                        _t("Load Latest Session Media", "Cargar Medios Última Sesión"),')


# 6. Add "Performance Analytics" header above Stats
old_stats = """            // Stats
            Card("""
new_stats = """            // Performance Analytics Section
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
              child: Text(
                _t("Performance Analytics", "Análisis de Rendimiento"),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
            // Stats
            Card("""
content = content.replace(old_stats, new_stats)

# 7. Update surfer pro preview text
old_surfer_pro_text = """            Text(
              _t(
                "Self-improvement tools: AI reflection and technical video analysis.",
                "Herramientas de automejora: reflexiones con IA y análisis de video técnico."
              ),"""
new_surfer_pro_text = """            Text(
              _t(
                "Unlock deeper insights and AI feedback. Take your surfing to the next level with advanced metrics and personalized AI coaching.",
                "Desbloquea información más profunda y feedback de IA. Lleva tu surf al siguiente nivel con métricas avanzadas."
              ),"""
content = content.replace(old_surfer_pro_text, new_surfer_pro_text)


with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated home_screen.dart copy")
