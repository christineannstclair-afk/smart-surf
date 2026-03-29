import re

file_path = r'c:\Users\StCla\surf_passport - Copy\lib\features\home\home_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _editProfileDetails method
method_code = """
  Future<void> _editProfileDetails() async {
    final heightController = TextEditingController(text: widget.height);
    final weightController = TextEditingController(text: widget.weight);
    final locationController = TextEditingController(text: widget.location);

    String stance = widget.stance;
    bool s_coach = widget.stanceVisibleToCoach;
    bool s_dash = widget.stanceVisibleOnDashboard;
    bool h_coach = widget.heightVisibleToCoach;
    bool h_dash = widget.heightVisibleOnDashboard;
    bool w_coach = widget.weightVisibleToCoach;
    bool w_dash = widget.weightVisibleOnDashboard;
    bool l_coach = widget.locationVisibleToCoach;
    bool l_dash = widget.locationVisibleOnDashboard;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Widget _buildFieldRow(String label, TextEditingController controller, String hint, bool dash, bool coach, Function(bool) onDash, Function(bool) onCoach) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 4),
                   TextField(
                     controller: controller,
                     decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
                   ),
                   Row(
                     children: [
                       const Text("Visible on Dashboard", style: TextStyle(fontSize: 12)),
                       Switch(value: dash, onChanged: onDash),
                       const SizedBox(width: 8),
                       const Text("Visible to Coach", style: TextStyle(fontSize: 12)),
                       Switch(value: coach, onChanged: onCoach),
                     ],
                   ),
                   const SizedBox(height: 12),
                ],
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t("Profile Details", "Detalles del Perfil"),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 16),
                      const Text("Stance", style: TextStyle(fontWeight: FontWeight.bold)),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Regular', label: Text('Regular')),
                          ButtonSegment(value: 'Goofy', label: Text('Goofy')),
                        ],
                        selected: {stance},
                        onSelectionChanged: (set) => setModalState(() => stance = set.first),
                      ),
                      Row(
                        children: [
                          const Text("Visible on Dashboard", style: TextStyle(fontSize: 12)),
                          Switch(value: s_dash, onChanged: (v) => setModalState(() => s_dash = v)),
                          const SizedBox(width: 8),
                          const Text("Visible to Coach", style: TextStyle(fontSize: 12)),
                          Switch(value: s_coach, onChanged: (v) => setModalState(() => s_coach = v)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildFieldRow("Height", heightController, "e.g. 5'10\"", h_dash, h_coach, (v) => setModalState(() => h_dash = v), (v) => setModalState(() => h_coach = v)),
                      _buildFieldRow("Weight", weightController, "e.g. 165 lbs", w_dash, w_coach, (v) => setModalState(() => w_dash = v), (v) => setModalState(() => w_coach = v)),
                      _buildFieldRow("Location", locationController, "e.g. San Diego, CA", l_dash, l_coach, (v) => setModalState(() => l_dash = v), (v) => setModalState(() => l_coach = v)),
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onUpdate(
                              levelEnTitle: widget.levelEnTitle,
                              levelEnDesc: widget.levelEnDesc,
                              comfortEn: widget.comfortEn,
                              boardEn: widget.boardEn,
                              focusEn: widget.focusEn,
                              stance: stance,
                              height: heightController.text.trim(),
                              weight: weightController.text.trim(),
                              location: locationController.text.trim(),
                              stanceVisibleToCoach: s_coach,
                              stanceVisibleOnDashboard: s_dash,
                              heightVisibleToCoach: h_coach,
                              heightVisibleOnDashboard: h_dash,
                              weightVisibleToCoach: w_coach,
                              weightVisibleOnDashboard: w_dash,
                              locationVisibleToCoach: l_coach,
                              locationVisibleOnDashboard: l_dash,
                              sessionsSurfed: widget.sessionsSurfed,
                              lastSurfedDate: widget.lastSurfedDate,
                            );
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            _t("Save", "Guardar"),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
"""

if "_editProfileDetails" not in content:
    # insert before _updateComfort
    content = content.replace("  void _updateComfort(String next) {", method_code + "\n  void _updateComfort(String next) {")

# 2. Add Edit Profile Details card and the specific field cards
build_cards = """            // Tour target: Session Logs nav button"""

new_cards = """
            _tapCard(
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

if "Edit Profile Details" not in content:
    content = content.replace(build_cards, new_cards)


with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated home UI")
