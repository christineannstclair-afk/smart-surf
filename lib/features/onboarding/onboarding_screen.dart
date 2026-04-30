import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/permission_service.dart';
import '../../core/translation_service.dart';
import '../../core/legal_utils.dart';
import '../../ui_system/app_theme.dart';
import '../../ui_system/surf_constants.dart';
import '../../widgets/smart_surf_wordmark.dart';
import '../session_log/firebase_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/micro_tip_banner.dart';

class OnboardingScreen extends StatefulWidget {
final bool isSpanish;
final void Function(bool) onSetLanguage;
final void Function(
String? name,
String? profilePhotoPath,
String? comfortZone,
String? boardType,
) onFinish;

const OnboardingScreen({
super.key,
required this.isSpanish,
required this.onFinish,
required this.onSetLanguage,
});

@override
State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

String? _name;
String? _profilePhotoPath;
String? _comfortZone;
String? _boardType;

bool _isUploadingPhoto = false;
bool _isSigningIn = false;

String t(String keyOrEn, [String? es]) {
  if (es != null) {
    return widget.isSpanish ? es : keyOrEn;
  }
  return TranslationService().translate(keyOrEn, widget.isSpanish);
}
String _friendlyAuthMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'user-not-found':
      return 'No account found with that email.';
    case 'email-already-in-use':
      return 'That email is already being used.';
    case 'weak-password':
      return 'Your password is too weak. Please use at least 6 characters.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again in a few minutes.';
    case 'network-request-failed':
      return 'No internet connection. Please try again.';
    case 'missing-fields':
      return 'Email and password are required.';
    case 'credential-already-in-use':
      return 'This account is already linked to another user. Signing you in instead.';
    case 'email-already-in-use':
      return 'That email is already being used. Try signing in instead of creating a new account.';
    case 'account-exists-with-different-credential':
      return 'This email is already associated with another login method.';
    default:
      return e.message ?? 'Authentication failed.';
  }
}

Future<void> _pickImage() async {
  final picker = ImagePicker();

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(t("onboarding_choose_photo")),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(t("onboarding_take_photo")),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ],
      ),
    ),
  );

  if (source == null) return;

  // 1. Unified Permission Check
  final result = await PermissionService().handleImageSourcePermission(source);

  if (result == PermissionResult.granted || result == PermissionResult.limited) {
    if (result == PermissionResult.limited && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(
            "Photo library access is limited. You can manage permitted photos in iOS Settings.",
            "El acceso a la biblioteca está limitado. Puedes gestionar las fotos permitidas en los Ajustes de iOS."
          )),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // Proceed to picker
  } else {
     _showPermissionDeniedDialog(result, source);
     return;
  }

  // 2. Picker
  final picked = await picker.pickImage(
    source: source,
    maxWidth: 800,
  );

  if (picked == null) return;

  setState(() => _isUploadingPhoto = true);

  Uint8List? bytes;
  if (kIsWeb) {
    bytes = await picked.readAsBytes();
  }

  final fbResult = await FirebaseService().uploadMedia(
    localPath: picked.path,
    isProfile: true,
    isVideo: false,
    webBytes: bytes,
  );

  if (!mounted) return;

  if (fbResult != null && fbResult.success) {
    setState(() {
      _profilePhotoPath = fbResult.url;
      _isUploadingPhoto = false;
    });
  } else {
    setState(() => _isUploadingPhoto = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t('onboarding_upload_failed') +
          (fbResult?.errorMessage ?? t("onboarding_unknown_error")),
        ),
      ),
    );
  }
}

  void _showPermissionDeniedDialog(PermissionResult result, ImageSource source) {
  final isCamera = source == ImageSource.camera;
  
  String title = isCamera 
      ? t("Camera Permission", "Permiso de Cámara")
      : t("Photos Permission", "Permiso de Fotos");

  String message = "";
  if (result == PermissionResult.permanentlyDenied) {
    message = isCamera
        ? t(
            "Camera access is permanently disabled. Please enable it in Settings to take a profile photo.",
            "El acceso a la cámara está desactivado permanentemente. Por favor, actívalo en Ajustes para tomar una foto de perfil."
          )
        : t(
            "Photo library access is permanently disabled. Please enable it in Settings to choose a photo.",
            "El acceso a la biblioteca está desactivado permanentemente. Por favor, actívalo en Ajustes para elegir una foto."
          );
  } else {
    message = isCamera
        ? t(
            "Camera access is required to take a profile photo.",
            "Se requiere acceso a la cámara para tomar una foto de perfil."
          )
        : t(
            "Photo library access is required to choose a profile photo.",
            "Se requiere acceso a la biblioteca para elegir una foto de perfil."
          );
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
        if (result == PermissionResult.permanentlyDenied)
           TextButton(
             onPressed: () {
               Navigator.pop(ctx);
               openAppSettings();
             },
             child: Text(t("Settings", "Ajustes")),
           ),
      ],
    ),
  );
}

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isSigningIn = true);

      final googleSignIn = GoogleSignIn(
scopes: <String>['email'],
);

final googleUser = await googleSignIn.signIn();

if (googleUser == null) {
if (!mounted) return;
setState(() => _isSigningIn = false);
return;
}

final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      FirebaseService().logEvent('sign_in_google');

if (!mounted) return;
setState(() => _isSigningIn = false);
_completeOnboarding();
} catch (e) {
if (!mounted) return;
setState(() => _isSigningIn = false);
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Google sign-in failed: $e')),
);
}
}

  Future<void> _signInWithApple() async {
    try {
      setState(() => _isSigningIn = true);

      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      await FirebaseAuth.instance.signInWithProvider(appleProvider);
      FirebaseService().logEvent('sign_in_apple');

if (!mounted) return;
setState(() => _isSigningIn = false);
_completeOnboarding();
} on FirebaseAuthException catch (e) {
if (!mounted) return;
setState(() => _isSigningIn = false);

debugPrint('FIREBASE AUTH ERROR: ${e.code} | ${e.message}');
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Apple sign-in failed: ${e.code}')),
);
} catch (e) {
if (!mounted) return;
setState(() => _isSigningIn = false);

debugPrint('APPLE UNKNOWN ERROR: $e');
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Apple sign-in failed: $e')),
);
}
}

  Future<void> _signInWithEmail() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLogin = false;

  final shouldSubmit = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(isLogin ? 'Sign In' : 'Create Account'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        isLogin = !isLogin;
                      });
                    },
                    child: Text(
                      isLogin
                          ? 'Need an account? Create one'
                          : 'Already have an account? Sign in',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(isLogin ? 'Sign In' : 'Create Account'),
              ),
            ],
          );
        },
      );
    },
  );

  if (shouldSubmit != true) return;

  try {
    setState(() => _isSigningIn = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-fields',
        message: 'Email and password are required.',
      );
    }

      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      FirebaseService().logEvent('sign_in_email', parameters: {'is_new': !isLogin});

    if (!mounted) return;
    setState(() => _isSigningIn = false);
    _completeOnboarding();
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;
    setState(() => _isSigningIn = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_friendlyAuthMessage(e))),
    );
  } catch (e) {
    if (!mounted) return;
    setState(() => _isSigningIn = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Something went wrong. Please try again.'),
      ),
    );
  }
}

  void _completeOnboarding() {
    FocusScope.of(context).unfocus();
    widget.onFinish(null, null, null, null);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildStep2Login(),
    );
  }

  Widget _buildStep2Login() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SmartSurfWordmark(),
                    const Spacer(),
                    const SizedBox(height: 48),
                    Text(
                      t("Welcome to Smart Surf", "Bienvenido a Smart Surf"),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t("Log your surf sessions and track your progress.", "Registra tus sesiones de surf y sigue tu progreso."),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    _buildLoginButton(
                      Icons.apple,
                      t("onboarding_continue_apple"),
                      _signInWithApple,
                    ),
                    const SizedBox(height: 16),
                    _buildLoginButton(
                      Icons.g_mobiledata,
                      t("onboarding_continue_google"),
                      _signInWithGoogle,
                    ),
                    const SizedBox(height: 16),
                    _buildLoginButton(
                      Icons.email_outlined,
                      t("onboarding_continue_email"),
                      _signInWithEmail,
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    LegalUtils.buildLegalFooter(
                      context: context, 
                      isSpanish: widget.isSpanish,
                      fontSize: 12,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginButton(
    IconData icon,
    String text,
    Future<void> Function() onTap,
  ) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isSigningIn
            ? null
            : () async {
                await onTap();
                if (FirebaseAuth.instance.currentUser != null) {
                  _completeOnboarding();
                }
              },
        icon: Icon(
          icon,
          size: 24,
          color: AppTheme.textPrimary,
        ),
        label: _isSigningIn
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
