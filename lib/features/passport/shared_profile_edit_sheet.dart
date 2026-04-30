import 'package:flutter/material.dart';
import '../../ui_system/app_theme.dart';
import '../../ui_system/surf_constants.dart';
import '../../features/passport/passport_presets.dart';

class SharedProfileEditSheet extends StatefulWidget {
  final bool isSpanish;
  final String displayName;
  final String stance;
  final String height;
  final String weight;
  final String location;
  final String age;
  final String surferSummary;
  final String levelEnTitle;
  final String levelEnDesc;
  final String comfortEn;
  final String boardEn;
  final List<String> focusEn;
  final String units;

  final bool stanceVisibleToCoach;
  final bool stanceVisibleOnDashboard;
  final bool heightVisibleToCoach;
  final bool heightVisibleOnDashboard;
  final bool weightVisibleToCoach;
  final bool weightVisibleOnDashboard;
  final bool locationVisibleToCoach;
  final bool locationVisibleOnDashboard;
  final bool ageVisibleToCoach;
  final bool ageVisibleOnDashboard;

  final void Function({
    required String displayName,
    required String stance,
    required String height,
    required String weight,
    required String location,
    required String age,
    required String surferSummary,
    required String levelEnTitle,
    required String levelEnDesc,
    required String comfortEn,
    required String boardEn,
    required List<String> focusEn,
    required bool stanceVisibleToCoach,
    required bool stanceVisibleOnDashboard,
    required bool heightVisibleToCoach,
    required bool heightVisibleOnDashboard,
    required bool weightVisibleToCoach,
    required bool weightVisibleOnDashboard,
    required bool locationVisibleToCoach,
    required bool locationVisibleOnDashboard,
    required bool ageVisibleToCoach,
    required bool ageVisibleOnDashboard,
  }) onUpdate;

  const SharedProfileEditSheet({
    super.key,
    required this.isSpanish,
    required this.displayName,
    required this.stance,
    required this.height,
    required this.weight,
    required this.location,
    required this.age,
    required this.surferSummary,
    required this.levelEnTitle,
    required this.levelEnDesc,
    required this.comfortEn,
    required this.boardEn,
    required this.focusEn,
    required this.units,
    required this.stanceVisibleToCoach,
    required this.stanceVisibleOnDashboard,
    required this.heightVisibleToCoach,
    required this.heightVisibleOnDashboard,
    required this.weightVisibleToCoach,
    required this.weightVisibleOnDashboard,
    required this.locationVisibleToCoach,
    required this.locationVisibleOnDashboard,
    required this.ageVisibleToCoach,
    required this.ageVisibleOnDashboard,
    required this.onUpdate,
  });

  static void show(BuildContext context, {
    required bool isSpanish,
    required String displayName,
    required String stance,
    required String height,
    required String weight,
    required String location,
    required String age,
    required String surferSummary,
    required String levelEnTitle,
    required String levelEnDesc,
    required String comfortEn,
    required String boardEn,
    required List<String> focusEn,
    required String units,
    required bool stanceVisibleToCoach,
    required bool stanceVisibleOnDashboard,
    required bool heightVisibleToCoach,
    required bool heightVisibleOnDashboard,
    required bool weightVisibleToCoach,
    required bool weightVisibleOnDashboard,
    required bool locationVisibleToCoach,
    required bool locationVisibleOnDashboard,
    required bool ageVisibleToCoach,
    required bool ageVisibleOnDashboard,
    required void Function({
      required String displayName,
      required String stance,
      required String height,
      required String weight,
      required String location,
      required String age,
      required String surferSummary,
      required String levelEnTitle,
      required String levelEnDesc,
      required String comfortEn,
      required String boardEn,
      required List<String> focusEn,
      required bool stanceVisibleToCoach,
      required bool stanceVisibleOnDashboard,
      required bool heightVisibleToCoach,
      required bool heightVisibleOnDashboard,
      required bool weightVisibleToCoach,
      required bool weightVisibleOnDashboard,
      required bool locationVisibleToCoach,
      required bool locationVisibleOnDashboard,
      required bool ageVisibleToCoach,
      required bool ageVisibleOnDashboard,
    }) onUpdate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SharedProfileEditSheet(
        isSpanish: isSpanish,
        displayName: displayName,
        stance: stance,
        height: height,
        weight: weight,
        location: location,
        age: age,
        surferSummary: surferSummary,
        levelEnTitle: levelEnTitle,
        levelEnDesc: levelEnDesc,
        comfortEn: comfortEn,
        boardEn: boardEn,
        focusEn: focusEn,
        units: units,
        stanceVisibleToCoach: stanceVisibleToCoach,
        stanceVisibleOnDashboard: stanceVisibleOnDashboard,
        heightVisibleToCoach: heightVisibleToCoach,
        heightVisibleOnDashboard: heightVisibleOnDashboard,
        weightVisibleToCoach: weightVisibleToCoach,
        weightVisibleOnDashboard: weightVisibleOnDashboard,
        locationVisibleToCoach: locationVisibleToCoach,
        locationVisibleOnDashboard: locationVisibleOnDashboard,
        ageVisibleToCoach: ageVisibleToCoach,
        ageVisibleOnDashboard: ageVisibleOnDashboard,
        onUpdate: onUpdate,
      ),
    );
  }

  @override
  State<SharedProfileEditSheet> createState() => _SharedProfileEditSheetState();
}

class _SharedProfileEditSheetState extends State<SharedProfileEditSheet> {
  late TextEditingController nameCtrl;
  late TextEditingController heightCtrl;
  late TextEditingController weightCtrl;
  late TextEditingController locationCtrl;
  late TextEditingController ageCtrl;
  late TextEditingController summaryCtrl;
  
  late String currentStance;
  late String currentLevel;
  late String currentLevelDesc;
  late String currentComfort;
  late String currentBoard;
  late List<String> currentFocus;

  late bool stanceVisibleToCoach;
  late bool stanceVisibleOnDashboard;
  late bool heightVisibleToCoach;
  late bool heightVisibleOnDashboard;
  late bool weightVisibleToCoach;
  late bool weightVisibleOnDashboard;
  late bool locationVisibleToCoach;
  late bool locationVisibleOnDashboard;
  late bool ageVisibleToCoach;
  late bool ageVisibleOnDashboard;

  bool _showOptionalDetails = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.displayName);
    heightCtrl = TextEditingController(text: widget.height);
    weightCtrl = TextEditingController(text: widget.weight);
    locationCtrl = TextEditingController(text: widget.location);
    ageCtrl = TextEditingController(text: widget.age);
    summaryCtrl = TextEditingController(text: widget.surferSummary);
    
    currentStance = widget.stance;
    currentLevel = widget.levelEnTitle;
    currentLevelDesc = widget.levelEnDesc;
    currentComfort = widget.comfortEn;
    currentBoard = widget.boardEn;
    currentFocus = List.from(widget.focusEn);

    stanceVisibleToCoach = widget.stanceVisibleToCoach;
    stanceVisibleOnDashboard = widget.stanceVisibleOnDashboard;
    heightVisibleToCoach = widget.heightVisibleToCoach;
    heightVisibleOnDashboard = widget.heightVisibleOnDashboard;
    weightVisibleToCoach = widget.weightVisibleToCoach;
    weightVisibleOnDashboard = widget.weightVisibleOnDashboard;
    locationVisibleToCoach = widget.locationVisibleToCoach;
    locationVisibleOnDashboard = widget.locationVisibleOnDashboard;
    ageVisibleToCoach = widget.ageVisibleToCoach;
    ageVisibleOnDashboard = widget.ageVisibleOnDashboard;
  }

  String _t(String en, String es) => widget.isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Theme(
          data: Theme.of(context).copyWith(
            brightness: Brightness.light,
            textTheme: const TextTheme(
              titleLarge: TextStyle(color: Color(0xFF1E293B)),
              bodyMedium: TextStyle(color: Color(0xFF475569)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_t("Surf Profile", "Perfil de Surf"), 
                    style: const TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.w900, 
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    )
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(_t("Add your board, level, and focus skills.", "Añade tu tabla, nivel y habilidades foco."),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              _buildSectionLabel(_t("Identity", "Identidad")),
              _buildTextField(
                controller: nameCtrl,
                label: _t("Display Name", "Nombre para mostrar"),
                hint: _t("Your name", "Tu nombre"),
              ),
              const SizedBox(height: 24),
              
              _buildSectionLabel(_t("Surfing Expertise", "Experiencia de Surf")),
              
              _buildPickerField(
                label: _t("Surf Level", "Nivel de Surf"),
                value: PassportPresets.levelTitle(isSpanish: widget.isSpanish, enTitle: currentLevel),
                onTap: () => _showPresetPicker(
                  title: _t("Select Level", "Seleccionar Nivel"),
                  items: PassportPresets.levels,
                  currentEn: currentLevel,
                  onSelected: (m) => setState(() {
                    currentLevel = m["enTitle"]!;
                    currentLevelDesc = m["enDesc"]!;
                  }),
                ),
              ),
              const SizedBox(height: 16),

              _buildPickerField(
                label: _t("Typical Board", "Tabla Típica"),
                value: PassportPresets.mapValue(isSpanish: widget.isSpanish, units: widget.units, list: PassportPresets.boards, enValue: currentBoard),
                onTap: () => _showPresetPicker(
                  title: _t("Select Board", "Seleccionar Tabla"),
                  items: PassportPresets.boards,
                  currentEn: currentBoard,
                  onSelected: (m) => setState(() => currentBoard = m["en"]!),
                ),
              ),
              const SizedBox(height: 16),

              _buildPickerField(
                label: _t("Comfort Zone", "Zona de Confort"),
                value: PassportPresets.mapValue(isSpanish: widget.isSpanish, units: widget.units, list: PassportPresets.comfortZones, enValue: currentComfort),
                onTap: () => _showPresetPicker(
                  title: _t("Select Wave Height", "Seleccionar Altura de Ola"),
                  items: PassportPresets.comfortZones,
                  currentEn: currentComfort,
                  onSelected: (m) => setState(() => currentComfort = m["en"]!),
                ),
              ),
              const SizedBox(height: 16),

              _buildPickerField(
                label: _t("Focus Skills", "Habilidades Foco"),
                value: currentFocus.isEmpty ? _t("None selected", "Ninguna seleccionada") : currentFocus.join(", "),
                onTap: _showFocusPicker,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _showOptionalDetails = !_showOptionalDetails),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _t("Optional details", "Detalles opcionales"),
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A), fontSize: 16),
                      ),
                      Icon(
                        _showOptionalDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showOptionalDetails) ...[
                const SizedBox(height: 8),
                _buildSectionLabel(_t("Physical Specs", "Especificaciones Físicas")),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: _t("Stance", "Posición"),
                        value: ["Regular", "Goofy"].contains(currentStance) ? currentStance : null,
                        items: [
                          DropdownMenuItem(value: "Regular", child: Text(_t("Regular", "Regular"))),
                          DropdownMenuItem(value: "Goofy", child: Text(_t("Goofy", "Goofy"))),
                        ],
                        onChanged: (v) => setState(() => currentStance = v ?? ""),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: ageCtrl,
                        label: _t("Age", "Edad"),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: heightCtrl,
                        label: _t("Height", "Altura"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: weightCtrl,
                        label: _t("Weight", "Peso"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: locationCtrl,
                  label: _t("Location", "Ubicación"),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: summaryCtrl,
                  label: _t("Surfer Summary", "Resumen de Surfer"),
                  maxLines: 3,
                  hint: _t("A brief bio...", "Una breve biografía..."),
                ),
                const SizedBox(height: 32),
                
                _buildSectionLabel(_t("Privacy Settings", "Configuración de Privacidad")),
                _buildVisibilitySection(_t("Stance", "Posición"), stanceVisibleToCoach, stanceVisibleOnDashboard, (v) => setState(() => stanceVisibleToCoach = v), (v) => setState(() => stanceVisibleOnDashboard = v)),
                _buildVisibilitySection(_t("Age", "Edad"), ageVisibleToCoach, ageVisibleOnDashboard, (v) => setState(() => ageVisibleToCoach = v), (v) => setState(() => ageVisibleOnDashboard = v)),
                _buildVisibilitySection(_t("Height", "Altura"), heightVisibleToCoach, heightVisibleOnDashboard, (v) => setState(() => heightVisibleToCoach = v), (v) => setState(() => heightVisibleOnDashboard = v)),
                _buildVisibilitySection(_t("Weight", "Peso"), weightVisibleToCoach, weightVisibleOnDashboard, (v) => setState(() => weightVisibleToCoach = v), (v) => setState(() => weightVisibleOnDashboard = v)),
                _buildVisibilitySection(_t("Location", "Ubicación"), locationVisibleToCoach, locationVisibleOnDashboard, (v) => setState(() => locationVisibleToCoach = v), (v) => setState(() => locationVisibleOnDashboard = v)),
              ],
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: () {
                    widget.onUpdate(
                      displayName: nameCtrl.text,
                      stance: currentStance,
                      height: heightCtrl.text,
                      weight: weightCtrl.text,
                      location: locationCtrl.text,
                      age: ageCtrl.text,
                      surferSummary: summaryCtrl.text,
                      levelEnTitle: currentLevel,
                      levelEnDesc: currentLevelDesc,
                      comfortEn: currentComfort,
                      boardEn: currentBoard,
                      focusEn: currentFocus,
                      stanceVisibleToCoach: stanceVisibleToCoach,
                      stanceVisibleOnDashboard: stanceVisibleOnDashboard,
                      heightVisibleToCoach: heightVisibleToCoach,
                      heightVisibleOnDashboard: heightVisibleOnDashboard,
                      weightVisibleToCoach: weightVisibleToCoach,
                      weightVisibleOnDashboard: weightVisibleOnDashboard,
                      locationVisibleToCoach: locationVisibleToCoach,
                      locationVisibleOnDashboard: locationVisibleOnDashboard,
                      ageVisibleToCoach: ageVisibleToCoach,
                      ageVisibleOnDashboard: ageVisibleOnDashboard,
                    );
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_t("Save Profile", "Guardar Perfil"), 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilitySection(String label, bool toCoach, bool onDash, Function(bool) onCoachChanged, Function(bool) onDashChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
        ),
        _buildToggleRow(_t("Visible to Coach", "Visible para el Coach"), toCoach, onCoachChanged),
        _buildToggleRow(_t("Visible on Dashboard", "Visible en el Dashboard"), onDash, onDashChanged),
        const Divider(color: Color(0xFFF1F5F9)),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
        Switch(
          value: value, 
          onChanged: onChanged,
          activeColor: const Color(0xFF0F172A),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(label.toUpperCase(), 
        style: const TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.w800, 
          color: Color(0xFF94A3B8), 
          letterSpacing: 1.5,
        )
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    String? hint, 
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0F172A), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label, 
    required String? value, 
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField({required String label, required String value, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPresetPicker({
    required String title,
    required List<Map<String, String>> items,
    required String currentEn,
    required Function(Map<String, String>) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final en = item["en"] ?? item["enTitle"];
                  final isSelected = en == currentEn;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      widget.isSpanish ? (item["es"] ?? item["esTitle"] ?? en!) : en!,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, 
                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
                        fontSize: 16,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0F172A)) : null,
                    onTap: () {
                      onSelected(item);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFocusPicker() {
    final List<String> tempFocus = List.from(currentFocus);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPickerState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_t("Focus Skills", "Habilidades Foco"), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: SurfConstants.focusSkillPresets.length,
                  itemBuilder: (ctx, i) {
                    final opt = SurfConstants.focusSkillPresets[i];
                    final en = opt["en"]!;
                    final isSelected = tempFocus.contains(en);
                    return CheckboxListTile(
                      title: Text(widget.isSpanish ? opt["es"]! : en, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                      value: isSelected,
                      activeColor: const Color(0xFF0F172A),
                      checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) {
                        setPickerState(() {
                          if (val == true) {
                            if (!tempFocus.contains(en)) tempFocus.add(en);
                          } else {
                            tempFocus.remove(en);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      setState(() => currentFocus = tempFocus);
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(_t("Done", "Hecho"), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
