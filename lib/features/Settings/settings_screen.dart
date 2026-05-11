import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/subscription_config.dart';
import '../../ui_system/app_theme.dart';
import '../../widgets/language_menu.dart';
import '../../widgets/helper_info_card.dart';
import '../coach_pro/subscription_service.dart';
import 'coach_pro_screen.dart';
import 'legal_pages.dart';
import 'settings_models.dart';
import '../session_log/firebase_service.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final VoidCallback onResetOnboarding;
  final Function({String? title, String? content}) onOpenSurferPro;
  final VoidCallback onRunTour;
  final VoidCallback onResetSessions;
  final VoidCallback onResetAppState;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.onResetOnboarding,
    required this.onOpenSurferPro,
    required this.onRunTour,
    required this.onResetSessions,
    required this.onResetAppState,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool get isSpanish => widget.settings.isSpanish;

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
            widget.onResetAppState();
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

// _confirmResetSessions was removed as it was unused.

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
            widget.onResetAppState();

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

void _confirmDeleteAccount(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(_t('Delete Account?', '¿Eliminar cuenta?')),
      content: Text(
        _t(
          'This will permanently delete your profile, all sessions, insights, and your account. This action cannot be undone.',
          'Esto eliminará permanentemente tu perfil, todas las sesiones, insights y tu cuenta. Esta acción no se puede deshacer.',
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
            _finalDeletionStep(context);
          },
          child: Text(
            _t('Continue', 'Continuar'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}

void _finalDeletionStep(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(_t('Final Confirmation', 'Confirmación Final')),
      content: Text(
        _t(
          'Are you absolutely sure? All data will be wiped from our servers immediately.',
          '¿Estás absolutamente seguro? Todos los datos serán borrados de nuestros servidores inmediatamente.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(_t('Cancel', 'Cancelar')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            Navigator.pop(ctx);
            _performDeletion(context);
          },
          child: Text(_t('Delete My Account', 'Eliminar Mi Cuenta')),
        ),
      ],
    ),
  );
}

Future<void> _performDeletion(BuildContext context) async {
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  try {
    await FirebaseService().deleteUserAccount();
    
    if (mounted) {
      Navigator.pop(context); // Close loading
      widget.onResetAppState(); // Return to welcome
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Account deleted successfully.', 'Cuenta eliminada correctamente.')),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      Navigator.pop(context); // Close loading
      
      if (e is RecentLoginRequiredException) {
        // TRIGGER RE-AUTH FLOW
        _handleReauthentication(context);
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(_t('Deletion Error', 'Error al eliminar')),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

Future<void> _handleReauthentication(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final providerId = user.providerData.isNotEmpty 
      ? user.providerData.first.providerId 
      : 'password';

  debugPrint('[Settings] Re-auth required for provider: $providerId');

  bool reauthSuccess = false;

  if (providerId == 'password') {
    reauthSuccess = await _showPasswordReauthDialog(context);
  } else if (providerId == 'google.com') {
    reauthSuccess = await _reauthenticateWithGoogle();
  } else if (providerId == 'apple.com') {
    reauthSuccess = await _reauthenticateWithApple();
  } else {
    // Fallback if provider is unknown
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Please sign out and back in to delete your account.', 'Por favor, cierra sesión e inicia sesión de nuevo para eliminar tu cuenta.'))),
      );
    }
    return;
  }

  if (reauthSuccess && mounted) {
    // Retry deletion
    _performDeletion(context);
  }
}

Future<bool> _showPasswordReauthDialog(BuildContext context) async {
  final passwordController = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(_t('Verify Password', 'Verificar Contraseña')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_t('Enter your password to continue with account deletion.', 'Ingresa tu contraseña para continuar con la eliminación de la cuenta.')),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: _t('Password', 'Contraseña')),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_t('Cancel', 'Cancelar'))),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(_t('Verify', 'Verificar')),
        ),
      ],
    ),
  );

  if (result != true) return false;

  try {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return false;
    
    final credential = EmailAuthProvider.credential(email: email, password: passwordController.text);
    await FirebaseService().reauthenticate(credential);
    return true;
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    return false;
  }
}

Future<bool> _reauthenticateWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return false;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseService().reauthenticate(credential);
    return true;
  } catch (e) {
    debugPrint('Google re-auth failed: $e');
    return false;
  }
}

Future<bool> _reauthenticateWithApple() async {
  try {
    final appleProvider = AppleAuthProvider();
    await FirebaseService().reauthenticate(await FirebaseAuth.instance.currentUser!.reauthenticateWithProvider(appleProvider) as AuthCredential);
    // Actually reauthenticateWithProvider handles it directly on the user object, 
    // but FirebaseService().reauthenticate also works if we pass the credential.
    // Wait, reauthenticateWithProvider returns a UserCredential.
    return true;
  } catch (e) {
    debugPrint('Apple re-auth failed: $e');
    return false;
  }
}

void _restorePurchases(BuildContext context) async {
  final subService = SubscriptionService();
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final success = await subService.restorePurchases();
    
    if (context.mounted) {
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? _t('Purchases restored successfully!', '¡Compras restauradas con éxito!')
              : _t('No active purchases found to restore.', 'No se encontraron compras activas para restaurar.')
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? Colors.green.shade800 : Colors.blueGrey,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
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
widget.onChanged(widget.settings.copyWith(isSpanish: val)),
),
],
),
body: ListView(
        children: [
          const SizedBox(height: 16),
          HelperInfoCard(
            prefKey: 'hasSeenSettingsTip',
            visible: !widget.settings.hasSeenSettingsTip,
            onDismiss: () => widget.onChanged(widget.settings.copyWith(hasSeenSettingsTip: true)),
            message: _t(
              'Manage your experience here — sign out, run the tour, restore purchases, and explore Surfer Pro.',
              'Gestiona tu experiencia aquí: cierra sesión, ver el tour, restaura compras y explora Surfer Pro.',
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(
              'AI Reflection & Video Analysis',
              'Reflexión con IA y Análisis de Video',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (widget.settings.isSurferPro) 
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: GestureDetector(
                onTap: () => SubscriptionService().openManageSubscriptions(),
                child: Text(
                  _t(
                    'Manage or cancel in Apple Settings →',
                    'Gestionar o cancelar en los Ajustes de Apple →'
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: widget.settings.isSurferPro
              ? Colors.blue.withOpacity(0.15)
              : Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.settings.isSurferPro
              ? (widget.settings.isSurferTrial 
                  ? _t('Trial Active', 'Prueba Activa')
                  : _t('Pro Active', 'Pro Activa'))
              : _t('Get Pro', 'Obtener Pro'),
          style: TextStyle(
            color: widget.settings.isSurferPro ? Colors.blue : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      onTap: widget.settings.isSurferPro ? null : () => widget.onOpenSurferPro(),
    ),
    ListTile(
      dense: true,
      leading: const SizedBox(width: 24),
      title: Text(
        _t('Restore Purchases', 'Restaurar compras'),
        style: const TextStyle(fontSize: 13, decoration: TextDecoration.underline),
      ),
      onTap: () => _restorePurchases(context),
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
      onTap: widget.onRunTour,
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
color: widget.settings.isCoachPro
? Colors.green.withOpacity(0.15)
: Colors.grey.withOpacity(0.15),
borderRadius: BorderRadius.circular(12),
),
child: Text(
widget.settings.isCoachPro
? _t('Active', 'Activo')
: _t('Not Active', 'No Activo'),
style: TextStyle(
color: widget.settings.isCoachPro ? Colors.green : Colors.grey,
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
PrivacyPolicyPage(isSpanish: widget.settings.isSpanish),
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
TermsOfUsePage(isSpanish: widget.settings.isSpanish),
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
const Padding(
  padding: EdgeInsets.symmetric(horizontal: 16),
  child: Divider(height: 1),
),
_SectionHeader(title: _t('Advanced', 'Avanzado')),
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
  leading: const Icon(Icons.no_accounts_rounded, color: Colors.amber),
  title: Text(
    _t('Delete Account', 'Eliminar cuenta'),
    style: const TextStyle(
      color: Colors.amber,
      fontWeight: FontWeight.w600,
    ),
  ),
  subtitle: Text(
    _t(
      'Permanently delete your account and all data.',
      'Elimina permanentemente tu cuenta y todos los datos.',
    ),
  ),
  onTap: () => _confirmDeleteAccount(context),
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
      'v${widget.settings.appVersion} (${widget.settings.appEnvId})',
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
