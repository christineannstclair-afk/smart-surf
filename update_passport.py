import re

file_path = r'c:\Users\StCla\surf_passport - Copy\lib\features\passport\passport_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# I will replace the inside of the ListView (lines 111-180 approx)
old_listview_children = """          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t(
                        "A living snapshot of your current surf level and progression. Share this with your surf coaches and surf schools.",
                        "Un registro vivo de tu nivel de surf actual y progresión. Comparte esto con tus coaches o escuelas de surf."
                      ),
                      style: TextStyle(
                        fontSize: 13, 
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _PassportCard(
              title: _t("Level", "Nivel"),
              value: levelTitle,
              subtitle: levelDescShown,
              icon: Icons.trending_up_rounded,
            ),
            const SizedBox(height: 12),
            _PassportCard(
              title: _t("Comfort Zone", "Zona de confort"),
              value: comfortLabel,
              icon: Icons.waves_rounded,
            ),
            const SizedBox(height: 12),
            _PassportCard(
              title: _t("Board", "Tabla"),
              value: boardLabel,
              icon: Icons.surfing_rounded,
            ),
            const SizedBox(height: 12),
            _PassportCard(
              title: _t("Focus", "Enfoque"),
              icon: Icons.center_focus_strong_rounded,
              value: focus.isEmpty
                  ? _t("Not set", "No definido")
                  : focus
                        .map(
                          (en) => PassportPresets.focusLabel(
                            isSpanish: isSpanish,
                            enSkill: en,
                          ),
                        )
                        .join(" • "),
            ),
            const SizedBox(height: 12),
            _PassportCard(
              title: _t("Sessions", "Sesiones"),
              value: _t("$sessionsSurfed total", "$sessionsSurfed total"),
              subtitle: _dateLine(lastSurfedDate),
              icon: Icons.history_rounded,
            ),
          ],"""

new_listview_children = """          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Kai Lenny • Santa Cruz, CA",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _t("Proficient in wave selection and trimming.", "Competente en selección de olas y recorridos."),
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
            
            Text(
              _t("Performance Stats", "Estadísticas de Rendimiento"),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 12),
            _PassportCard(
              title: _t("Current Level", "Nivel Actual"),
              value: levelTitle,
              subtitle: levelDescShown,
              icon: Icons.trending_up_rounded,
            ),
            const SizedBox(height: 12),
            _PassportCard(
              title: _t("Sessions Logged", "Sesiones Registradas"),
              value: _t("$sessionsSurfed Sessions", "$sessionsSurfed Sesiones"),
              subtitle: _t("+12% this month", "+12% este mes"),
              icon: Icons.history_rounded,
            ),
            const SizedBox(height: 12),
            _PassportCard(
              title: _t("Comfort Zone", "Zona de Confort"),
              value: comfortLabel,
              subtitle: "8-10ft Overhead",
              icon: Icons.waves_rounded,
            ),

            const SizedBox(height: 24),
            Text(
              _t("Top Skills", "Habilidades Principales"),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 12),
            _PassportCard(
              title: _t("Focus", "Enfoque"),
              icon: Icons.center_focus_strong_rounded,
              value: focus.isEmpty
                  ? _t("Not set", "No definido")
                  : focus
                        .map(
                          (en) => PassportPresets.focusLabel(
                            isSpanish: isSpanish,
                            enSkill: en,
                          ),
                        )
                        .join(" • "),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {},
                child: Text(_t("View All Skills", "Ver Todas las Habilidades")),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              _t("Active Quiver", "Quiver Activo"),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 12),
            _PassportCard(
              title: _t("Board Size", "Tamaño de Tabla"),
              value: boardLabel,
              subtitle: "Pyzel Ghost (5'10\" x 18 7/8\" x 2 5/16\" • 28.5L)",
              icon: Icons.surfing_rounded,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share),
                label: Text(_t("Share Passport", "Compartir Passport")),
              ),
            ),
            const SizedBox(height: 24),
          ],"""
content = content.replace(old_listview_children, new_listview_children)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated passport_screen.dart copy")
