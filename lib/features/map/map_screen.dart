import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../session_log/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/micro_tip_banner.dart';
import '../../widgets/language_menu.dart';

import 'surf_spots_data.dart';
import 'map_models.dart';
import '../../ui_system/app_theme.dart';
import '../../ui_system/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/smart_surf_wordmark.dart';

class MapScreen extends StatefulWidget {
  final bool isSpanish;
  final ValueChanged<bool> onSetLanguage;
  final List<SurfSpot> spots;
  final ValueChanged<List<SurfSpot>> onSpotsChanged;
  final GlobalKey? mapKey;
  final VoidCallback? onReturnToDashboard;
  final bool hasSeenMapTip;
  final VoidCallback onMapTipDismissed;

  const MapScreen({
    super.key,
    required this.isSpanish,
    required this.onSetLanguage,
    required this.spots,
    required this.onSpotsChanged,
    required this.hasSeenMapTip,
    required this.onMapTipDismissed,
    this.mapKey,
    this.onReturnToDashboard,
  });

@override
State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    FirebaseService().logEvent('map_used');
  }

  String _t(String en, String es) => widget.isSpanish ? es : en;

static const LatLng _initialCenter = LatLng(15.0, 121.0);

LatLng _center = _initialCenter;
LatLng? _picked;
String _query = '';
List<Map<String, dynamic>> _searchResults = [];

List<SurfSpot> get _allSpots => [...widget.spots];

List<SurfSpot> get _filteredSpots {
final q = _query.trim().toLowerCase();
if (q.isEmpty) return _allSpots;

return _allSpots.where((s) {
return s.name.toLowerCase().contains(q) ||
s.country.toLowerCase().contains(q) ||
s.region.toLowerCase().contains(q) ||
s.difficulty.toLowerCase().contains(q);
}).toList();
}

@override
void didUpdateWidget(covariant MapScreen oldWidget) {
super.didUpdateWidget(oldWidget);
if (widget.spots.isNotEmpty &&
oldWidget.spots.length != widget.spots.length) {
final last = widget.spots.last;
_center = LatLng(last.lat, last.lng);
}
}

void _addSpot(SurfSpot spot) {
final next = [...widget.spots, spot];
widget.onSpotsChanged(next);

setState(() {
_center = LatLng(spot.lat, spot.lng);
_picked = null;
_query = '';
});
}

void _handleSearch(String v) {
setState(() {
_query = v;
final q = v.trim().toLowerCase();
if (q.length > 1) {
final searchSource = [...globalSurfSpots, ...widget.spots];
_searchResults = searchSource
.where((spot) =>
spot.name.toLowerCase().contains(q) ||
spot.country.toLowerCase().contains(q) ||
spot.region.toLowerCase().contains(q))
.take(15)
.map((s) => {
'name': '${s.name}, ${s.country}',
'lat': s.lat,
'lng': s.lng,
'spot': s,
})
.toList();
} else {
_searchResults = [];
}
});
}

void _selectSearchResult(Map<String, dynamic> loc) {
final p = LatLng(loc['lat'], loc['lng']);
setState(() {
_center = p;
_picked = p;
_searchResults = [];
_query = loc['name'];
});
FocusScope.of(context).unfocus();
}

void _deleteSpot(String id) {
final next = widget.spots.where((s) => s.id != id).toList();
widget.onSpotsChanged(next);
}

@override
void dispose() {
_sheetController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final spots = _filteredSpots;

return LayoutBuilder(
builder: (context, constraints) {
final isWide = constraints.maxWidth > 800;

return Scaffold(
appBar: isWide
? AppBar(
title: SmartSurfWordmark(onTap: widget.onReturnToDashboard),
titleSpacing: 16,
centerTitle: false,
actions: [
_buildLanguageToggle(),
],
)
: null,
floatingActionButton: isWide
? FloatingActionButton.extended(
onPressed: () => _openAddSpotSheet(context),
icon: const Icon(Icons.add_location_alt),
label: Text(_t('Add spot', 'Agregar spot')),
)
: null,
body: SafeArea(
top: true,
bottom: false,
child: Column(
children: [
MicroTipBanner(
  prefKey: 'hasSeenMapTip',
  visible: !widget.hasSeenMapTip,
  onDismiss: widget.onMapTipDismissed,
  message: _t(
    "Save surf spots you want to remember.\nSearch or tap Add Spot to get started.",
    "Guarda los spots de surf que quieras recordar.\nBusca o toca Agregar Spot para comenzar.",
  ),
  dismissLabel: _t('Got it', 'Entendido'),
),
Expanded(
child: isWide ? _buildWideLayout(spots) : _buildMobileLayout(spots),
),
],
),
),
);
},
);
}

Widget _buildLanguageToggle() {
return LanguageMenu(
isSpanish: widget.isSpanish,
onSetLanguage: widget.onSetLanguage,
);
}

Widget _buildWideLayout(List<SurfSpot> spots) {
return Column(
children: [
Padding(
padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
child: Column(
children: [
TextField(
decoration: InputDecoration(
prefixIcon: const Icon(Icons.search),
hintText: _t('Search for beaches...', 'Buscar playas...'),
border: const OutlineInputBorder(),
),
onChanged: _handleSearch,
),
if (_searchResults.isNotEmpty) _buildAutocompleteOverlay(),
],
),
),
Expanded(
child: Row(
children: [
Expanded(
flex: 8,
child: AppCard(
padding: EdgeInsets.zero,
child: _buildMap(spots),
),
),
Expanded(
flex: 4,
child: AppCard(
padding: EdgeInsets.zero,
child: _buildSpotList(spots),
),
),
],
),
),
],
);
}

Widget _buildMobileLayout(List<SurfSpot> spots) {
return Stack(
children: [
Positioned.fill(
child: _buildMap(spots),
),

Positioned(
top: 8,
left: 16,
right: 16,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: EdgeInsets.only(bottom: 12),
child: SmartSurfWordmark(onTap: widget.onReturnToDashboard),
),
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Material(
elevation: 2,
shadowColor: AppTheme.primary.withOpacity(0.15),
borderRadius: BorderRadius.circular(28),
color: AppTheme.surface,
child: TextField(
decoration: InputDecoration(
prefixIcon: const Icon(
Icons.search,
size: 22,
color: AppTheme.primary,
),
hintText: _t('Search Surf Spots...', 'Buscar spots de surf...'),
filled: true,
fillColor: AppTheme.surface,
contentPadding: const EdgeInsets.symmetric(
horizontal: 20,
vertical: 16,
),
border: OutlineInputBorder(
borderSide: BorderSide.none,
borderRadius: BorderRadius.circular(28),
),
),
onChanged: _handleSearch,
),
),
if (_searchResults.isNotEmpty)
Padding(
padding: const EdgeInsets.only(top: 8),
child: _buildAutocompleteOverlay(),
),
],
),
),
const SizedBox(width: 12),
_buildLanguageToggle(),
],
),
],
),
),

DraggableScrollableSheet(
controller: _sheetController,
initialChildSize: 0.25,
minChildSize: 0.15,
maxChildSize: 0.85,
snap: true,
snapSizes: const [0.15, 0.25, 0.85],
builder: (context, scrollController) {
return Container(
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.surface,
borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.15),
blurRadius: 12,
spreadRadius: 2,
offset: const Offset(0, -2),
),
],
),
child: Column(
children: [
Center(
child: GestureDetector(
  behavior: HitTestBehavior.opaque,
  onVerticalDragUpdate: (details) {
    if (_sheetController.isAttached) {
      final delta = details.primaryDelta ?? 0;
      final currentSize = _sheetController.size;
      final screenHeight = MediaQuery.of(context).size.height;
      if (screenHeight > 0) {
        _sheetController.jumpTo(
          (currentSize - (delta / screenHeight)).clamp(0.15, 0.85),
        );
      }
    }
  },
  child: SizedBox(
    height: 48,
    width: double.infinity,
    child: Center(
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  ),
  onVerticalDragEnd: (details) {
    if (_sheetController.isAttached) {
      final currentSize = _sheetController.size;
      const snapPoints = [0.15, 0.25, 0.85];
      double nearest = snapPoints.first;
      double minDelta = (currentSize - nearest).abs();
      for (final p in snapPoints) {
        final d = (currentSize - p).abs();
        if (d < minDelta) {
          minDelta = d;
          nearest = p;
        }
      }
      _sheetController.animateTo(
        nearest,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  },
),
),
Expanded(
child: _buildSpotList(
spots,
controller: scrollController,
),
),
],
),
);
},
),

Positioned(
bottom: MediaQuery.of(context).size.height * 0.25 + 16,
right: 16,
child: FloatingActionButton.extended(
elevation: 4,
onPressed: () => _openAddSpotSheet(context),
icon: const Icon(Icons.add_location_alt),
label: Text(_t('Add spot', 'Agregar spot')),
),
),
],
);
}

Widget _buildMap(List<SurfSpot> spots) {
return Container(
key: widget.mapKey,
color: Colors.white,
child: Center(
child: Text(
_t('Map coming soon', 'Mapa próximamente'),
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.w600,
color: Colors.black45,
),
),
),
);
}

void _openAddSpotSheet(BuildContext context, {String? initialName}) {
showModalBottomSheet(
context: context,
isScrollControlled: true,
backgroundColor: Colors.transparent,
builder: (ctx) => _AddSpotSheet(
picked: _picked,
initialName: initialName,
onSaved: (spot) {
_addSpot(spot);
Navigator.pop(ctx);
},
isSpanish: widget.isSpanish,
),
);
}

Widget _buildAutocompleteOverlay() {
return Material(
elevation: 8,
borderRadius: BorderRadius.circular(12),
clipBehavior: Clip.antiAlias,
child: Container(
constraints: const BoxConstraints(maxHeight: 250),
color: Theme.of(context).colorScheme.surface,
child: ListView(
shrinkWrap: true,
padding: EdgeInsets.zero,
children: [
..._searchResults.map((loc) => Column(
mainAxisSize: MainAxisSize.min,
children: [
ListTile(
dense: true,
leading: const Icon(
Icons.location_on_outlined,
size: 18,
color: AppTheme.primary,
),
title: Text(loc['name']),
onTap: () => _selectSearchResult(loc),
),
const Divider(height: 1),
],
)),
ListTile(
dense: true,
leading: const Icon(
Icons.add_location_alt_outlined,
size: 18,
color: Colors.green,
),
title: Text(
_t(
'Add custom spot: "${_query.trim()}"',
'Agregar spot personalizado: "${_query.trim()}"',
),
style: const TextStyle(
fontWeight: FontWeight.bold,
color: Colors.green,
),
),
onTap: () {
setState(() => _searchResults = []);
_openAddSpotSheet(context, initialName: _query.trim());
},
),
],
),
),
);
}

Widget _buildSpotList(List<SurfSpot> spots, {ScrollController? controller}) {
return Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Padding(
padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
child: Row(
children: [
Expanded(
child: Text(
_t('Saved Spots', 'Spots Guardados'),
style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
),
Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
decoration: BoxDecoration(
color: AppTheme.primaryContainer,
borderRadius: BorderRadius.circular(12),
),
child: Text(
'${spots.length} ${_t("spots found active today", "spots activos encontrados hoy")}',
style: const TextStyle(
fontSize: 13,
fontWeight: FontWeight.w600,
color: AppTheme.textPrimary,
),
),
),
],
),
),
const Divider(height: 1),
Expanded(
child: spots.isEmpty
? SingleChildScrollView(
    controller: controller,
    physics: const AlwaysScrollableScrollPhysics(),
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Text(
        _t(
          'No spots yet. Tap "Add spot" to log your first location.',
          'Aún no hay spots. Toca "Agregar spot" para registrar tu primera ubicación.',
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  )
: ListView.builder(
controller: controller,
physics: const AlwaysScrollableScrollPhysics(),
itemCount: spots.length,
padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
itemBuilder: (context, i) {
final s = spots[i];
return Padding(
padding: const EdgeInsets.only(bottom: AppSpacing.sm),
child: AppCard(
padding: EdgeInsets.zero,
child: ListTile(
contentPadding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 4,
),
title: Text(
s.name,
style: const TextStyle(fontWeight: FontWeight.w600),
),
subtitle: Padding(
padding: const EdgeInsets.only(top: 4),
child: Text(
'${s.region.isNotEmpty ? "${s.region}, " : ""}${s.country} • ${_t(
s.difficulty,
s.difficulty == "Beginner"
? "Principiante"
: s.difficulty == "Intermediate"
? "Intermedio"
: s.difficulty == "Advanced"
? "Avanzado"
: "Intermedio Inicial",
)}',
style: const TextStyle(color: AppTheme.textMuted),
),
),
trailing: IconButton(
icon: const Icon(
Icons.delete_outline,
color: Colors.redAccent,
),
onPressed: () => _deleteSpot(s.id),
),
onTap: () {
final p = LatLng(s.lat, s.lng);
setState(() {
_center = p;
});
if (_sheetController.isAttached) {
_sheetController.animateTo(
0.25,
duration: const Duration(milliseconds: 300),
curve: Curves.easeOut,
);
}
},
),
),
);
},
),
),
],
);
}
}

class _AddSpotSheet extends StatefulWidget {
final LatLng? picked;
final String? initialName;
final ValueChanged<SurfSpot> onSaved;
final bool isSpanish;

const _AddSpotSheet({
required this.picked,
this.initialName,
required this.onSaved,
required this.isSpanish,
});

@override
State<_AddSpotSheet> createState() => _AddSpotSheetState();
}

class _AddSpotSheetState extends State<_AddSpotSheet> {
late TextEditingController _name;
final TextEditingController _country = TextEditingController();
final TextEditingController _region = TextEditingController();
final TextEditingController _notes = TextEditingController();
String _difficulty = 'Beginner';

double? _lat;
double? _lng;

String _t(String en, String es) => widget.isSpanish ? es : en;

@override
void initState() {
super.initState();
_name = TextEditingController(text: widget.initialName ?? '');
if (widget.picked != null) {
_lat = widget.picked!.latitude;
_lng = widget.picked!.longitude;
}
}

@override
void dispose() {
_name.dispose();
_country.dispose();
_region.dispose();
_notes.dispose();
super.dispose();
}

bool get _canSave {
return _name.text.trim().isNotEmpty &&
_country.text.trim().isNotEmpty;
}

@override
Widget build(BuildContext context) {
final bottom = MediaQuery.of(context).viewInsets.bottom;

return Container(
decoration: BoxDecoration(
color: AppTheme.surface,
borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.2),
blurRadius: 20,
offset: const Offset(0, -5),
),
],
),
padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
child: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Row(
children: [
const Icon(
Icons.add_location_alt,
color: AppTheme.primary,
size: 28,
),
const SizedBox(width: 12),
Expanded(
child: Text(
_t('Add Surf Spot', 'Agregar spot de surf'),
style: const TextStyle(
fontWeight: FontWeight.w900,
fontSize: 22,
letterSpacing: -0.5,
color: AppTheme.textPrimary,
),
),
),
IconButton(
onPressed: () => Navigator.pop(context),
icon: const Icon(Icons.close_rounded),
),
],
),
const SizedBox(height: 24),
_buildField(
controller: _name,
label: _t('Spot Name', 'Nombre del spot'),
hint: _t('e.g. Pipeline', 'ej. Pipeline'),
icon: Icons.place_rounded,
),
const SizedBox(height: 16),
_buildField(
controller: _country,
label: _t('Country / Region', 'País / Región'),
hint: _t('e.g. Hawaii, USA', 'ej. Hawái, EE. UU.'),
icon: Icons.public_rounded,
),
const SizedBox(height: 16),
_buildDifficultyDropdown(),
const SizedBox(height: 16),
_buildField(
controller: _notes,
label: _t('Notes (optional)', 'Notas (opcional)'),
hint: _t('e.g. Best on north swell', 'ej. Mejor con swell del norte'),
icon: Icons.notes_rounded,
maxLines: 3,
),
const SizedBox(height: 20),
Row(
children: [
Expanded(
child: _buildField(
label: _t('Latitude (optional)', 'Latitud (opcional)'),
hint: widget.picked != null
? widget.picked!.latitude.toStringAsFixed(6)
: '0.0000',
keyboardType: const TextInputType.numberWithOptions(
decimal: true,
signed: true,
),
onChanged: (v) => setState(() => _lat = double.tryParse(v)),
),
),
const SizedBox(width: 12),
Expanded(
child: _buildField(
label: _t('Longitude (optional)', 'Longitud (opcional)'),
hint: widget.picked != null
? widget.picked!.longitude.toStringAsFixed(6)
: '0.0000',
keyboardType: const TextInputType.numberWithOptions(
decimal: true,
signed: true,
),
onChanged: (v) => setState(() => _lng = double.tryParse(v)),
),
),
],
),
if (widget.picked != null && (_lat == null || _lng == null)) ...[
const SizedBox(height: 12),
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: AppTheme.primary.withOpacity(0.05),
borderRadius: BorderRadius.circular(12),
),
child: Row(
children: [
const Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
const SizedBox(width: 8),
Expanded(
child: Text(
_t(
'Using your tapped location on the map.',
'Usando la ubicación seleccionada en el mapa.',
),
style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
),
),
],
),
),
],
const SizedBox(height: 32),
SizedBox(
height: 56,
child: FilledButton(
onPressed: !_canSave
? null
: () {
final lat = _lat ?? widget.picked?.latitude ?? 0.0;
final lng = _lng ?? widget.picked?.longitude ?? 0.0;

final spot = SurfSpot(
id: DateTime.now().millisecondsSinceEpoch.toString(),
name: _name.text.trim(),
country: _country.text.trim(),
region: '',
lat: lat,
lng: lng,
difficulty: _difficulty,
notes: _notes.text.trim(),
createdAt: DateTime.now(),
);

widget.onSaved(spot);
},
style: FilledButton.styleFrom(
backgroundColor: AppTheme.primary,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
elevation: 0,
),
child: Text(
_t('Save Spot', 'Guardar spot'),
style: const TextStyle(
fontWeight: FontWeight.w900,
fontSize: 16,
),
),
),
),
],
),
),
);
}

Widget _buildField({
TextEditingController? controller,
required String label,
required String hint,
IconData? icon,
int maxLines = 1,
TextInputType keyboardType = TextInputType.text,
ValueChanged<String>? onChanged,
}) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.only(left: 4, bottom: 8),
child: Text(
label,
style: const TextStyle(
fontSize: 13,
fontWeight: FontWeight.w700,
color: AppTheme.textPrimary,
),
),
),
TextField(
controller: controller,
maxLines: maxLines,
keyboardType: keyboardType,
onChanged: (v) {
if (onChanged != null) onChanged(v);
setState(() {});
},
style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
decoration: InputDecoration(
hintText: hint,
hintStyle: const TextStyle(color: Colors.black26),
prefixIcon: icon != null
? Icon(icon, size: 20, color: AppTheme.primary.withOpacity(0.5))
: null,
filled: true,
fillColor: Colors.white,
contentPadding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 16,
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: const BorderSide(color: AppTheme.primary, width: 2),
),
),
),
],
);
}

Widget _buildDifficultyDropdown() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.only(left: 4, bottom: 8),
child: Text(
_t('Skill Level (optional)', 'Nivel (opcional)'),
style: const TextStyle(
fontSize: 13,
fontWeight: FontWeight.w700,
color: AppTheme.textPrimary,
),
),
),
DropdownButtonFormField<String>(
value: [
"Beginner",
"Beginner to Intermediate",
"Intermediate",
"Advanced"
].contains(_difficulty)
? _difficulty
: "Beginner",
style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
decoration: InputDecoration(
filled: true,
fillColor: Colors.white,
contentPadding:
const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: const BorderSide(color: AppTheme.primary, width: 2),
),
),
items: [
DropdownMenuItem(
value: 'Beginner',
child: Text(_t('Beginner', 'Principiante')),
),
DropdownMenuItem(
value: 'Beginner to Intermediate',
child: Text(_t('Beginner to Intermediate', 'Principiante a Intermedio')),
),
DropdownMenuItem(
value: 'Intermediate',
child: Text(_t('Intermediate', 'Intermedio')),
),
DropdownMenuItem(
value: 'Advanced',
child: Text(_t('Advanced', 'Avanzado')),
),
],
onChanged: (v) => setState(() => _difficulty = v ?? 'Beginner'),
),
],
);
}
}
