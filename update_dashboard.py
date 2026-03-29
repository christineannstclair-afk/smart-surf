import re

file_path = r'c:\Users\StCla\surf_passport - Copy\lib\features\home\home_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update the layout of the Body ListView
# Replace the existing ListView children structure

old_list_view_start = """          children: [
            // Merged Surf Level Card
            _tapCard(
              key: _levelKey,
              icon: Icons.surfing_outlined,
              titleEn: "Current Surf Level","""

new_list_view_start = """          children: [
            // Top Profile Section
            _buildProfileSection(context),
            const SizedBox(height: 24),

            // Merged Surf Level Card
            _tapCard(
              key: _levelKey,
              icon: Icons.surfing_outlined,
              titleEn: "Current Surf Level","""

content = content.replace(old_list_view_start, new_list_view_start)

# Remove the old Edit Profile Details, Stance, Height, Weight, Location cards from the middle of the list
old_middle_cards = """            _tapCard(
              icon: Icons.person_outline,
              titleEn: "Edit Profile Details",
              titleEs: "Editar Perfil",
              value: "Stance, Height, Weight, Location",
              onTap: _editProfileDetails,
            ),
            if (widget.stanceVisibleOnDashboard && widget.stance.isNotEmpty)
              _tapCard(
                icon: Icons.snowboarding,
                titleEn: "Stance",
                titleEs: "Postura",
                value: widget.stance,
                onTap: _editProfileDetails,
              ),
            if (widget.heightVisibleOnDashboard && widget.height.isNotEmpty)
              _tapCard(
                icon: Icons.height,
                titleEn: "Height",
                titleEs: "Altura",
                value: widget.height,
                onTap: _editProfileDetails,
              ),
            if (widget.weightVisibleOnDashboard && widget.weight.isNotEmpty)
              _tapCard(
                icon: Icons.monitor_weight_outlined,
                titleEn: "Weight",
                titleEs: "Peso",
                value: widget.weight,
                onTap: _editProfileDetails,
              ),
            if (widget.locationVisibleOnDashboard && widget.location.isNotEmpty)
              _tapCard(
                icon: Icons.location_on_outlined,
                titleEn: "Location",
                titleEs: "Ubicación",
                value: widget.location,
                onTap: _editProfileDetails,
              ),
            // Tour target: Session Logs nav button"""

new_middle_cards = """            // Tour target: Session Logs nav button"""

content = content.replace(old_middle_cards, new_middle_cards)


# Add the _buildProfileSection method
# We inject this right before the @override Widget build(BuildContext context)

old_build_declare = """  @override
  Widget build(BuildContext context) {"""

new_build_declare = """  Widget _buildProfileSection(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Athlete Dashboard", // Name would normally go here, using this as placeholder
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (widget.locationVisibleOnDashboard && widget.location.isNotEmpty)
                        _ProfileChip(icon: Icons.location_on_outlined, label: widget.location),
                      if (widget.stanceVisibleOnDashboard && widget.stance.isNotEmpty)
                        _ProfileChip(icon: Icons.snowboarding, label: widget.stance),
                      if (widget.heightVisibleOnDashboard && widget.height.isNotEmpty)
                        _ProfileChip(icon: Icons.height, label: widget.height),
                      if (widget.weightVisibleOnDashboard && widget.weight.isNotEmpty)
                        _ProfileChip(icon: Icons.monitor_weight_outlined, label: widget.weight),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editProfileDetails,
              tooltip: _t("Edit Profile", "Editar Perfil"),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Latest Session Media Placeholder
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1502680390469-be75c86b636f?q=80&w=1000&auto=format&fit=crop'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.videocam_outlined, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _t("Latest Session Clip", "Clip Última Sesión"),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {"""

content = content.replace(old_build_declare, new_build_declare)

# Inject _ProfileChip down below
old_end_braces = """  }
}

class _Stat extends StatelessWidget {"""

new_end_braces = """  }
}

class _ProfileChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {"""

content = content.replace(old_end_braces, new_end_braces)

# 2. Update Surfer Pro gating presentation to blur preview style

old_surfer_pro = """            // Surfer Pro CTA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      const Text(
                        "Surfer Pro",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const Spacer(),
                      if (!widget.isSurferPro)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.isSpanish ? "PREESTRENO" : "PREVIEW",
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isSpanish 
                      ? "Herramientas de automejora: reflexiones con IA y análisis de video técnico."
                      : "Self-improvement tools: AI reflection and technical video analysis.",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: widget.onOpenSurferPro,
                    icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                    label: Text(widget.isSpanish ? "Ver Funciones Pro" : "See Pro Features"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),"""


new_surfer_pro = """            // Surfer Pro Section
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Text(
                _t("Surfer Pro", "Surfer Pro"),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
            Text(
              _t(
                "Self-improvement tools: AI reflection and technical video analysis.",
                "Herramientas de automejora: reflexiones con IA y análisis de video técnico."
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _SurferProGatedSection(
              isSpanish: widget.isSpanish,
              isSurferPro: widget.isSurferPro,
              onOpenSurferPro: widget.onOpenSurferPro,
            ),
            const SizedBox(height: 16),"""

content = content.replace(old_surfer_pro, new_surfer_pro)


# Add the _SurferProGatedSection below
old_end_coach_gated = """      ],
    );
  }
}

class _MockTrendWidget extends StatelessWidget {"""

new_end_coach_gated = """      ],
    );
  }
}

class _SurferProGatedSection extends StatelessWidget {
  final bool isSpanish;
  final bool isSurferPro;
  final VoidCallback onOpenSurferPro;

  const _SurferProGatedSection({
    required this.isSpanish,
    required this.isSurferPro,
    required this.onOpenSurferPro,
  });

  String t(String en, String es) => isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.video_library_outlined, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t("AI Pop-up Analysis", "Análisis IA de Pop-up"),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t("Latest clip processed", "Último clip procesado"),
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.waves, color: Colors.teal.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t("Session Reflections", "Reflexiones de sesión"),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t("3 new insights ready", "3 nuevas observaciones listas"),
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );

    if (isSurferPro) {
      return GestureDetector(
        onTap: onOpenSurferPro,
        child: content,
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: content,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.4),
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
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.rocket_launch, color: Colors.amber, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t(
                      "Elevate your self-improvement with Surfer Pro tools.",
                      "Eleva tu automejora con las herramientas de Surfer Pro."
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onOpenSurferPro,
                    icon: const Icon(Icons.star_outline),
                    label: Text(t("See Pro Features", "Ver Funciones Pro")),
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
    );
  }
}

class _MockTrendWidget extends StatelessWidget {"""

content = content.replace(old_end_coach_gated, new_end_coach_gated)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated home_screen.dart dashboard layout")
