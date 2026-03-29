import re

file_path = r'c:\Users\StCla\surf_passport - Copy\lib\features\coach_pro\coach_dashboard_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

imports = """import '../../models/surf_dashboard_data.dart';\n"""
if "import '../../models/" not in content:
    content = content.replace("import '../onboarding/guided_tour_overlay.dart';", "import '../onboarding/guided_tour_overlay.dart';\n" + imports)

props_to_add = """  final SurfDashboardData? surferData;
  final int sessionsSurfed;
  final DateTime? lastSurfedDate;"""
if "final int sessionsSurfed;" not in content:
    content = content.replace("  final bool isCoachPro;", "  final bool isCoachPro;\n" + props_to_add)

cons_to_add = """    this.surferData,
    this.sessionsSurfed = 0,
    this.lastSurfedDate,"""
if "this.surferData" not in content:
    content = content.replace("    required this.isCoachPro,", "    required this.isCoachPro,\n" + cons_to_add)

# We need a dynamic getter instead of static final List
dynamic_athletes = """
  List<Map<String, dynamic>> get _athletes {
    final list = List<Map<String, dynamic>>.from(_mockAthletes);
    if (widget.surferData != null) {
      final sd = widget.surferData!;
      list.insert(0, {
        "id": "self",
        "name": "Self (Preview)",
        "level": sd.levelTitle,
        "levelEs": sd.levelTitle, // Simplifying for preview
        "sessions": widget.sessionsSurfed,
        "lastSession": widget.lastSurfedDate == null ? "Never" : "Recent",
        "lastSessionEs": widget.lastSurfedDate == null ? "Nunca" : "Reciente",
        
        "stance": sd.stance,
        "height": sd.height,
        "weight": sd.weight,
        "location": sd.location,
        
        "stanceVisibleToCoach": sd.stanceVisibleToCoach,
        "heightVisibleToCoach": sd.heightVisibleToCoach,
        "weightVisibleToCoach": sd.weightVisibleToCoach,
        "locationVisibleToCoach": sd.locationVisibleToCoach,
      });
    }
    return list;
  }
"""

if "_athletes {" not in content:
    content = content.replace("  final List<Map<String, dynamic>> _mockAthletes = const [", dynamic_athletes + "\n  final List<Map<String, dynamic>> _mockAthletes = const [")

# Replace uses of _mockAthletes with _athletes
content = content.replace("_mockAthletes.length", "_athletes.length")
content = content.replace("_mockAthletes[index]", "_athletes[index]")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated coach_dashboard.py")
