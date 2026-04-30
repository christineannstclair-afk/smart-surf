import 'package:flutter/material.dart';
import '../../ui_system/app_theme.dart';
import '../../ui_system/surf_constants.dart';
import '../../features/passport/passport_presets.dart';

class SurfPassportEditSheet extends StatefulWidget {
  final bool isSpanish;
  final String levelEnTitle;
  final String levelEnDesc;
  final String comfortEn;
  final String boardEn;
  final List<String> focusEn;
  final String units;
  final String? initialAction;

  // We pass the full update callback to keep data syncing intact
  final void Function({
    required String levelEnTitle,
    required String levelEnDesc,
    required String comfortEn,
    required String boardEn,
    required List<String> focusEn,
  }) onUpdate;

  const SurfPassportEditSheet({
    super.key,
    required this.isSpanish,
    required this.levelEnTitle,
    required this.levelEnDesc,
    required this.comfortEn,
    required this.boardEn,
    required this.focusEn,
    required this.units,
    required this.onUpdate,
    this.initialAction,
  });

  static void show(BuildContext context, {
    required bool isSpanish,
    required String levelEnTitle,
    required String levelEnDesc,
    required String comfortEn,
    required String boardEn,
    required List<String> focusEn,
    required String units,
    required void Function({
      required String levelEnTitle,
      required String levelEnDesc,
      required String comfortEn,
      required String boardEn,
      required List<String> focusEn,
    }) onUpdate,
    String? initialAction,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SurfPassportEditSheet(
        isSpanish: isSpanish,
        levelEnTitle: levelEnTitle,
        levelEnDesc: levelEnDesc,
        comfortEn: comfortEn,
        boardEn: boardEn,
        focusEn: focusEn,
        units: units,
        onUpdate: onUpdate,
        initialAction: initialAction,
      ),
    );
  }

  @override
  State<SurfPassportEditSheet> createState() => _SurfPassportEditSheetState();
}

enum _EditSheetView { main, level, comfort, board, focus }

class _SurfPassportEditSheetState extends State<SurfPassportEditSheet> {
  _EditSheetView _currentView = _EditSheetView.main;
  late String currentLevel;
  late String currentLevelDesc;
  late String currentComfort;
  late String currentBoard;
  late List<String> currentFocus;

  @override
  void initState() {
    super.initState();
    currentLevel = widget.levelEnTitle;
    currentLevelDesc = widget.levelEnDesc;
    currentComfort = widget.comfortEn;
    currentBoard = widget.boardEn;
    currentFocus = List.from(widget.focusEn);

    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleInitialAction(widget.initialAction!);
      });
    }
  }

  void _handleInitialAction(String action) {
    if (action == 'level') setState(() => _currentView = _EditSheetView.level);
    if (action == 'comfort') setState(() => _currentView = _EditSheetView.comfort);
    if (action == 'board') setState(() => _currentView = _EditSheetView.board);
    if (action == 'focus') setState(() => _currentView = _EditSheetView.focus);
  }

  String _t(String en, String es) => widget.isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    switch (_currentView) {
      case _EditSheetView.level:
        return _buildPickerView(
          title: _t("Surf Level", "Nivel de Surf"),
          items: PassportPresets.levels,
          currentEn: currentLevel,
          onSelected: (m) {
            setState(() {
              currentLevel = m["enTitle"]!;
              currentLevelDesc = m["enDesc"]!;
              _currentView = _EditSheetView.main;
            });
          },
        );
      case _EditSheetView.comfort:
        return _buildPickerView(
          title: _t("Comfort Zone", "Zona de Confort"),
          items: PassportPresets.comfortZones,
          currentEn: currentComfort,
          onSelected: (m) {
            setState(() {
              currentComfort = m["en"]!;
              _currentView = _EditSheetView.main;
            });
          },
        );
      case _EditSheetView.board:
        return _buildPickerView(
          title: _t("Typical Board", "Tabla Típica"),
          items: PassportPresets.boards,
          currentEn: currentBoard,
          onSelected: (m) {
            setState(() {
              currentBoard = m["en"]!;
              _currentView = _EditSheetView.main;
            });
          },
        );
      case _EditSheetView.focus:
        return _buildFocusPickerView();
      case _EditSheetView.main:
      default:
        return _buildMainFormView();
    }
  }

  Widget _buildMainFormView() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_t("Surf Passport", "Pasaporte de Surf"), 
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
            Text(_t("Update your level, board, and focus skills.", "Actualiza tu nivel, tabla y habilidades foco."),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            _buildPickerField(
              label: _t("Surf Level", "Nivel de Surf"),
              value: PassportPresets.levelTitle(isSpanish: widget.isSpanish, enTitle: currentLevel),
              onTap: () => setState(() => _currentView = _EditSheetView.level),
            ),
            const SizedBox(height: 16),

            _buildPickerField(
              label: _t("Comfort Zone", "Zona de Confort"),
              value: PassportPresets.mapValue(isSpanish: widget.isSpanish, units: widget.units, list: PassportPresets.comfortZones, enValue: currentComfort),
              onTap: () => setState(() => _currentView = _EditSheetView.comfort),
            ),
            const SizedBox(height: 16),

            _buildPickerField(
              label: _t("Typical Board", "Tabla Típica"),
              value: PassportPresets.mapValue(isSpanish: widget.isSpanish, units: widget.units, list: PassportPresets.boards, enValue: currentBoard),
              onTap: () => setState(() => _currentView = _EditSheetView.board),
            ),
            const SizedBox(height: 16),

            _buildPickerField(
              label: _t("Focus Skills (Max 4)", "Habilidades Foco (Max 4)"),
              value: currentFocus.isEmpty ? _t("None selected", "Ninguna seleccionada") : currentFocus.join(", "),
              onTap: () => setState(() => _currentView = _EditSheetView.focus),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 64,
              child: FilledButton(
                onPressed: () {
                  widget.onUpdate(
                    levelEnTitle: currentLevel,
                    levelEnDesc: currentLevelDesc,
                    comfortEn: currentComfort,
                    boardEn: currentBoard,
                    focusEn: currentFocus,
                  );
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_t("Save Passport", "Guardar Pasaporte"), 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(value.isEmpty ? _t("Select", "Seleccionar") : value, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500))),
                const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerView({
    required String title,
    required List<Map<String, String>> items,
    required String currentEn,
    required void Function(Map<String, String>) onSelected,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentView = _EditSheetView.main),
                icon: const Icon(Icons.arrow_back),
              ),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final m = items[i];
                final enVal = m["enTitle"] ?? m["en"]!;
                final isSelected = enVal == currentEn;
                
                String displayStr;
                if (m.containsKey("enTitle")) {
                  displayStr = widget.isSpanish ? m["esTitle"]! : m["enTitle"]!;
                } else {
                  displayStr = PassportPresets.mapValue(isSpanish: widget.isSpanish, units: widget.units, list: items, enValue: enVal);
                }
                
                return ListTile(
                  title: Text(displayStr, style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569))),
                  trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF0F172A)) : null,
                  onTap: () => onSelected(m),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusPickerView() {
    List<String> tempFocus = List.from(currentFocus);
    return StatefulBuilder(
      builder: (ctx, setPickerState) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _currentView = _EditSheetView.main),
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(_t("Focus Skills (Max 4)", "Habilidades Foco (Max 4)"), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 16),
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
                          if (tempFocus.length >= 4) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(_t("You can select up to 4 focus skills.", "Puedes seleccionar hasta 4 habilidades foco.")),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ));
                            return;
                          }
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
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      currentFocus = tempFocus;
                      _currentView = _EditSheetView.main;
                    });
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
    );
  }
}
