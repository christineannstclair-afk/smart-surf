import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/subscription_config.dart';
import '../../ui_system/app_theme.dart';
import '../../widgets/language_menu.dart';
import '../../widgets/micro_tip_banner.dart';
import 'coach_pro_screen.dart';
import 'legal_pages.dart';
import 'settings_models.dart';

class SettingsScreen extends StatelessWidget {
final AppSettings settings;
final ValueChanged<AppSettings> onChanged;
final VoidCallback onResetQuickstart;
final VoidCallback onOpenSurferPro;
final VoidCallback onRunTour;
final VoidCallback onResetSessions;
final VoidCallback onResetAppState;

const SettingsScreen({
super.key,
required this.settings,
required this.onChanged,
required this.onResetQuickstart,
required this.onOpenSurferPro,
required this.onRunTour,
required this.onResetSessions,
required this.onResetAppState,
});

bool get isSpanish => settings.isSpanish;

String _t(String en, String es) => isSpanish ? es : en;

void _showExportData(BuildContext context) {
showDialog(
context: context,
builder: (ctx) => AlertDialog(
title: Text(_t('Export Data', 'Exportar Datos')),
content: Text(_t('Coming soon', 'Próximamente')),
actions: [
TextButton(
onPressed: () => Navigator.pop(ctx),
child: Text(_t('OK', 'Aceptar')),
),
],
),
);
}

void _confirmClearData(BuildContext context) {
showDialog(
context: context,
builder: (ctx) => AlertDialog(
title: Text(_t('Reset App Data?', '¿Restablecer datos de la app?')),
content: Text(
_t(
'This will permanently delete all your surf spots, sessions, and passport settings. This action cannot be undone.',
'Esto eliminará permanentemente todos tus spots, sesiones y configuraciones del pasaporte. Esta acción no se puede deshacer.',
),
),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(_t('Cancel', 'Cancelar')),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            onResetAppState();
          },
          child: Text(
            _t('Reset Data', 'Restablecer Datos'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}

void _confirmResetSessions(BuildContext context) {
showDialog(
context: context,
builder: (ctx) => AlertDialog(
title: Text(_t('Reset Demo Data?', '¿Restablecer datos de prueba?')),
content: Text(
_t(
'This will clear all stored session logs, spots, insights, and local state for development testing. This action cannot be undone.',
'Esto borrará todas las sesiones, spots, insights y el estado local para pruebas de desarrollo. Esta acción no se puede deshacer.',
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(ctx),
child: Text(_t('Cancel', 'Cancelar')),
),
TextButton(
onPressed: () {
Navigator.pop(ctx);
onResetSessions();
},
child: Text(
_t('Reset Demo Data', 'Reiniciar Datos de Prueba'),
style: const TextStyle(color: Colors.red),
),
),
],
),
);
}

void _confirmSignOut(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(_t('Sign Out?', '¿Cerrar sesión?')),
      content: Text(
        _t(
          'You will be signed out and returned to the welcome screen.',
          'Cerrarás sesión y volverás a la pantalla de bienvenida.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(_t('Cancel', 'Cancelar')),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);

            onResetAppState();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _t(
                      'Signed out successfully.',
                      'Sesión cerrada correctamente.',
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Text(
            _t('Sign Out', 'Cerrar sesión'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text(_t('Settings', 'Ajustes')),
actions: [
LanguageMenu(
isSpanish: isSpanish,
onSetLanguage: (val) =>
onChanged(settings.copyWith(isSpanish: val)),
),
],
),
body: ListView(
children: [
MicroTipBanner(
prefKey: 'hasSeenSettingsTip',
message: _t(
'Manage your experience here—options for QuickStart, signing out, resetting data or the tour, exploring Coach Pro, and legal info.',
'Gestiona tu experiencia aquí: opciones para QuickStart, cerrar sesión, restablecer datos o el tour, explorar Coach Pro e información legal.',
),
dismissLabel: _t('Got it', 'Entendido'),
),
const Padding(
padding: EdgeInsets.symmetric(horizontal: 16),
child: Divider(height: 1),
),

    ListTile(
leading: const Icon(Icons.auto_awesome, color: Colors.amber),
title: Text(
_t('Surfer Pro', 'Surfer Pro'),
style: Theme.of(context).textTheme.titleMedium,
),
subtitle: Text(
_t(
'AI Reflection & Video Analysis',
'Reflexión con IA y Análisis de Video',
),
style: Theme.of(context).textTheme.bodySmall,
),
trailing: Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
decoration: BoxDecoration(
color: settings.isSurferPro
? Colors.blue.withOpacity(0.15)
: Colors.grey.withOpacity(0.15),
borderRadius: BorderRadius.circular(12),
),
child: Text(
settings.isSurferPro
? (settings.isSurferTrial 
    ? _t('Trial Active', 'Prueba Activa')
    : _t('Pro Active', 'Pro Activa'))
: _t('Get Pro', 'Obtener Pro'),
style: TextStyle(
color: settings.isSurferPro ? Colors.blue : Colors.grey,
fontWeight: FontWeight.bold,
fontSize: 12,
),
),
),
onTap: onOpenSurferPro,
),
    const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1),
    ),
    SwitchListTile(
secondary: const Icon(Icons.rocket_launch_outlined),
title: Text(
_t('Show QuickStart on launch', 'Mostrar Atajo al Inicio'),
style: Theme.of(context).textTheme.titleMedium,
),
subtitle: Text(
_t(
'Ask what to do when opening the app',
'Preguntar qué hacer al abrir la app',
),
style: Theme.of(context).textTheme.bodySmall,
),
value: settings.showQuickStartOnLaunch,
onChanged: (val) =>
onChanged(settings.copyWith(showQuickStartOnLaunch: val)),
),
const Padding(
padding: EdgeInsets.symmetric(horizontal: 16),
child: Divider(height: 1),
),
_SectionHeader(title: _t('Data', 'Datos')),

ListTile(
leading: const Icon(Icons.download_outlined),
title: Text(
_t('Export my data', 'Exportar mis datos'),
style: const TextStyle(fontWeight: FontWeight.w600),
),
subtitle: Text(_t('Coming soon', 'Próximamente')),
onTap: () => _showExportData(context),
),
ListTile(
leading: const Icon(
Icons.delete_forever_outlined,
color: Colors.redAccent,
),
title: Text(
_t('Reset App Data', 'Restablecer datos de la app'),
style: const TextStyle(
color: Colors.redAccent,
fontWeight: FontWeight.w600,
),
),
onTap: () => _confirmClearData(context),
),
ListTile(
leading: const Icon(Icons.logout_rounded, color: Colors.red),
title: Text(
_t('Sign Out', 'Cerrar sesión'),
style: const TextStyle(
color: Colors.red,
fontWeight: FontWeight.w600,
),
),
subtitle: Text(
_t(
'Sign out and return to the welcome screen.',
'Cerrar sesión y volver a la pantalla de bienvenida.',
),
),
onTap: () => _confirmSignOut(context),
),

ListTile(
leading: const Icon(Icons.tour_outlined, color: Colors.teal),
title: Text(
_t('Reset Onboarding Tour', 'Reiniciar Tour de Bienvenida'),
style: const TextStyle(
color: Colors.teal,
fontWeight: FontWeight.w600,
),
),
subtitle: Text(
_t(
'Show the guided tour again on next launch.',
'Mostrar el tour guiado en el próximo inicio.',
),
),
onTap: onResetQuickstart,
),
ListTile(
leading: const Icon(
Icons.play_circle_outline_rounded,
color: Colors.blue,
),
title: Text(
_t('Run Guided Tour Now', 'Ver Tour Guiado Ahora'),
style: const TextStyle(
color: Colors.blue,
fontWeight: FontWeight.w600,
),
),
subtitle: Text(
_t(
'Immediately launch the Surf Dashboard tour.',
'Lanzar el tour de Surf Dashboard ahora.',
),
),
trailing: const Icon(Icons.chevron_right, size: 20),
onTap: onRunTour,
),
const Padding(
padding: EdgeInsets.symmetric(horizontal: 16),
child: Divider(height: 1),
),
_SectionHeader(title: _t('Coach Pro', 'Coach Pro')),
ListTile(
leading: const Icon(Icons.star_border_rounded, color: Colors.amber),
title: Text(
_t('Coach Pro', 'Coach Pro'),
style: const TextStyle(fontWeight: FontWeight.w600),
),
subtitle: Text(
_t(
'Exclusive features for coaches (Coming Soon) - ${SubscriptionConfig.coachMonthlyStr}/mo',
'Funciones exclusivas para coaches (Próximamente) - ${SubscriptionConfig.coachMonthlyStr}/mes',
),
),
trailing: Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
decoration: BoxDecoration(
color: settings.isCoachPro
? Colors.green.withOpacity(0.15)
: Colors.grey.withOpacity(0.15),
borderRadius: BorderRadius.circular(12),
),
child: Text(
settings.isCoachPro
? _t('Active', 'Activo')
: _t('Not Active', 'No Activo'),
style: TextStyle(
color: settings.isCoachPro ? Colors.green : Colors.grey,
fontWeight: FontWeight.bold,
fontSize: 12,
),
),
),
onTap: () => showCoachProModal(context, isSpanish),
),
const Padding(
padding: EdgeInsets.symmetric(horizontal: 16),
child: Divider(height: 1),
),
_SectionHeader(title: _t('About', 'Acerca de')),
ListTile(
leading: const Icon(Icons.info_outline_rounded),
title: const Text(
'Smart Surf',
style: TextStyle(fontWeight: FontWeight.w600),
),
subtitle: Text(
_t(
'This app helps surfers log sessions, reflect on their surfing, track progress over time, and build their personal Surf Passport. Surfer Pro adds AI-powered reflections and deeper insight after each session.',
'Esta aplicación ayuda a los surfistas a registrar sesiones, reflexionar sobre su surf, seguir su progreso en el tiempo y construir su Pasaporte de Surf. Surfer Pro añade reflexiones con IA e información profunda después de cada sesión.',
),
),
),
const Padding(
padding: EdgeInsets.symmetric(horizontal: 16),
child: Divider(height: 1),
),
_SectionHeader(title: _t('Legal', 'Legal')),
ListTile(
leading: const Icon(Icons.privacy_tip_outlined),
title: Text(
_t('Privacy Policy', 'Política de Privacidad'),
style: const TextStyle(fontWeight: FontWeight.w600),
),
trailing: const Icon(Icons.chevron_right, size: 20),
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
PrivacyPolicyPage(isSpanish: settings.isSpanish),
),
),
),
ListTile(
leading: const Icon(Icons.description_outlined),
title: Text(
_t('Terms of Use', 'Términos de Uso'),
style: const TextStyle(fontWeight: FontWeight.w600),
),
trailing: const Icon(Icons.chevron_right, size: 20),
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
TermsOfUsePage(isSpanish: settings.isSpanish),
),
),
),
ListTile(
leading: const Icon(Icons.help_outline_rounded),
title: Text(
_t('Support', 'Soporte'),
style: const TextStyle(fontWeight: FontWeight.w600),
),
subtitle: const Text('smartsurfapp.help@gmail.com'),
trailing: const Icon(Icons.chevron_right, size: 20),
onTap: () async {
final Uri emailLaunchUri = Uri(
scheme: 'mailto',
path: 'smartsurfapp.help@gmail.com',
);
if (await canLaunchUrl(emailLaunchUri)) {
await launchUrl(emailLaunchUri);
}
},
),
const SizedBox(height: 24),
GestureDetector(
onLongPress: () {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
_t(
'Developer Mode: Full Reset available.',
'Modo Desarrollador: Reinicio completo disponible.',
),
),
duration: const Duration(seconds: 2),
),
);
_confirmClearData(context);
},
child: Center(
child: Text(
'v${settings.appVersion} (${settings.appEnvId})',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: AppTheme.textMuted.withOpacity(0.5),
),
),
),
),
const SizedBox(height: 48),
],
),
);
}
}

class _SectionHeader extends StatelessWidget {
final String title;

const _SectionHeader({required this.title});

@override
Widget build(BuildContext context) {
return Padding(
padding: const EdgeInsets.fromLTRB(20, 32, 16, 12),
child: Text(
title.toUpperCase(),
style: Theme.of(context).textTheme.bodySmall?.copyWith(
fontWeight: FontWeight.w900,
color: Theme.of(context).colorScheme.primary,
letterSpacing: 1.5,
),
),
);
}
}
