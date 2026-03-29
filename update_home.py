import re

file_path = r'c:\Users\StCla\surf_passport - Copy\lib\features\home\home_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Properties
props_to_add = """  final String stance;
  final String height;
  final String weight;
  final String location;
  final bool stanceVisibleToCoach;
  final bool stanceVisibleOnDashboard;
  final bool heightVisibleToCoach;
  final bool heightVisibleOnDashboard;
  final bool weightVisibleToCoach;
  final bool weightVisibleOnDashboard;
  final bool locationVisibleToCoach;
  final bool locationVisibleOnDashboard;"""

content = content.replace("  final List<String> focusEn;", "  final List<String> focusEn;\n" + props_to_add)

# 2. Constructor
cons_to_add = """    required this.stance,
    required this.height,
    required this.weight,
    required this.location,
    required this.stanceVisibleToCoach,
    required this.stanceVisibleOnDashboard,
    required this.heightVisibleToCoach,
    required this.heightVisibleOnDashboard,
    required this.weightVisibleToCoach,
    required this.weightVisibleOnDashboard,
    required this.locationVisibleToCoach,
    required this.locationVisibleOnDashboard,"""

content = content.replace("    required this.focusEn,", "    required this.focusEn,\n" + cons_to_add)

# 3. onUpdate typedef
typedef_to_add = """    required String stance,
    required String height,
    required String weight,
    required String location,
    required bool stanceVisibleToCoach,
    required bool stanceVisibleOnDashboard,
    required bool heightVisibleToCoach,
    required bool heightVisibleOnDashboard,
    required bool weightVisibleToCoach,
    required bool weightVisibleOnDashboard,
    required bool locationVisibleToCoach,
    required bool locationVisibleOnDashboard,"""

content = content.replace("    required List<String> focusEn,", "    required List<String> focusEn,\n" + typedef_to_add)

# 4. onUpdate calls
call_to_add = """                          stance: widget.stance,
                          height: widget.height,
                          weight: widget.weight,
                          location: widget.location,
                          stanceVisibleToCoach: widget.stanceVisibleToCoach,
                          stanceVisibleOnDashboard: widget.stanceVisibleOnDashboard,
                          heightVisibleToCoach: widget.heightVisibleToCoach,
                          heightVisibleOnDashboard: widget.heightVisibleOnDashboard,
                          weightVisibleToCoach: widget.weightVisibleToCoach,
                          weightVisibleOnDashboard: widget.weightVisibleOnDashboard,
                          locationVisibleToCoach: widget.locationVisibleToCoach,
                          locationVisibleOnDashboard: widget.locationVisibleOnDashboard,"""

# We need to find `focusEn: widget.focusEn,` or `focusEn: lines,` in widget.onUpdate(
content = content.replace('focusEn: lines,', 'focusEn: lines,\n' + call_to_add)
content = content.replace('focusEn: widget.focusEn,', 'focusEn: widget.focusEn,\n' + call_to_add)

# 5. Rename Surf Progress to Surf Dashboard
content = content.replace('title: Text(_t("Surf Progress", "Progreso")),', 'title: Text(_t("Surf Dashboard", "Dashboard de Surf")),')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated home_screen.dart")
