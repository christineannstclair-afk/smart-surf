import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/translation_service.dart';
import '../../ui_system/app_theme.dart';
import '../../ui_system/surf_constants.dart';
import '../../widgets/smart_surf_wordmark.dart';
import '../session_log/firebase_service.dart';

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
final PageController _pageController = PageController();

String? _name;
String? _profilePhotoPath;
String? _comfortZone;
String? _boardType;

bool _isUploadingPhoto = false;
bool _isSigningIn = false;

String t(String key) => TranslationService().translate(key, widget.isSpanish);
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

if (!mounted) return;
setState(() => _isSigningIn = false);
await _nextPage();
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

if (!mounted) return;
setState(() => _isSigningIn = false);
await _nextPage();
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

    if (!mounted) return;
    setState(() => _isSigningIn = false);
    await _nextPage();
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

Future<void> _nextPage() async {
FocusScope.of(context).unfocus();
await _pageController.nextPage(
duration: const Duration(milliseconds: 300),
curve: Curves.easeInOut,
);
}

void _skipOnboarding() {
FocusScope.of(context).unfocus();
widget.onFinish(null, null, null, null);
}

void _completeOnboarding() {
FocusScope.of(context).unfocus();
widget.onFinish(_name, _profilePhotoPath, _comfortZone, _boardType);
}

@override
void dispose() {
_pageController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.white,
body: PageView(
controller: _pageController,
physics: const NeverScrollableScrollPhysics(),
children: [
_buildStep2Login(),
_buildStep3Name(),
_buildStep4Basics(),
],
),
);
}

Widget _buildStep2Login() {
return SafeArea(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
child: Column(
children: [
const SmartSurfWordmark(),
const Spacer(),
Text(
"Welcome to Smart Surf",
style: Theme.of(context).textTheme.headlineMedium?.copyWith(
fontWeight: FontWeight.w900,
color: AppTheme.textPrimary,
fontSize: 28,
),
textAlign: TextAlign.center,
),
const SizedBox(height: 12),
Text(
"Log your sessions and get insights after every surf.",
style: Theme.of(context).textTheme.bodyLarge?.copyWith(
color: AppTheme.textMuted,
fontWeight: FontWeight.w500,
),
textAlign: TextAlign.center,
),
const SizedBox(height: 48),
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
TextButton(
onPressed: _isSigningIn ? null : _skipOnboarding,
child: Text(
t("onboarding_skip_now"),
style: TextStyle(
color: Theme.of(context).colorScheme.onSurfaceVariant,
fontWeight: FontWeight.bold,
),
),
),
],
),
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

Widget _buildStep3Name() {
return SafeArea(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SmartSurfWordmark(),
const SizedBox(height: 48),
Text(
t("onboarding_name_prompt"),
style: Theme.of(context).textTheme.headlineMedium?.copyWith(
fontWeight: FontWeight.bold,
color: AppTheme.textPrimary,
),
),
const SizedBox(height: 40),
Center(
child: GestureDetector(
onTap: _isUploadingPhoto ? null : _pickImage,
child: Container(
width: 120,
height: 120,
decoration: BoxDecoration(
color: Colors.grey.shade100,
shape: BoxShape.circle,
border: Border.all(color: Colors.grey.shade300, width: 2),
image: _profilePhotoPath != null
? DecorationImage(
image: NetworkImage(_profilePhotoPath!),
fit: BoxFit.cover,
)
: null,
),
child: Center(
child: _isUploadingPhoto
? const CircularProgressIndicator()
: _profilePhotoPath == null
? Icon(
Icons.add_a_photo,
size: 40,
color: Colors.grey.shade400,
)
: null,
),
),
),
),
const SizedBox(height: 12),
Center(
child: Text(
t("onboarding_add_photo_optional"),
style: TextStyle(
color: Theme.of(context).colorScheme.onSurfaceVariant,
),
),
),
const SizedBox(height: 40),
TextField(
decoration: InputDecoration(
labelText: t("onboarding_your_name_label"),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: AppTheme.surface,
),
onChanged: (val) => setState(() => _name = val),
),
const Spacer(),
SizedBox(
height: 56,
width: double.infinity,
child: ElevatedButton(
onPressed: _nextPage,
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.primary,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
elevation: 0,
),
child: Text(
t("onboarding_continue"),
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
),
),
],
),
),
);
}

Widget _buildStep4Basics() {
return SafeArea(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SmartSurfWordmark(),
const SizedBox(height: 48),
Text(
t("onboarding_basics_title"),
style: Theme.of(context).textTheme.headlineMedium?.copyWith(
fontWeight: FontWeight.bold,
color: AppTheme.textPrimary,
),
),
const SizedBox(height: 16),
Text(
t("onboarding_basics_subtitle"),
style: Theme.of(context).textTheme.bodyLarge?.copyWith(
color: Theme.of(context).colorScheme.onSurfaceVariant,
),
),
const SizedBox(height: 40),
Text(
t("onboarding_comfort_zone_label"),
style: TextStyle(
fontWeight: FontWeight.bold,
color: Theme.of(context).colorScheme.onSurfaceVariant,
),
),
const SizedBox(height: 8),
DropdownButtonFormField<String>(
value: _comfortZone,
decoration: InputDecoration(
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: AppTheme.surface,
),
hint: Text(t("onboarding_select_wave_height")),
items: SurfConstants.waveHeightOptions.map((opt) {
return DropdownMenuItem(
value: opt["en"],
child: Text(widget.isSpanish ? opt["es"]! : opt["en"]!),
);
}).toList(),
onChanged: (v) => setState(() => _comfortZone = v),
),
const SizedBox(height: 32),
Text(
t("onboarding_board_type_label"),
style: TextStyle(
fontWeight: FontWeight.bold,
color: Theme.of(context).colorScheme.onSurfaceVariant,
),
),
const SizedBox(height: 8),
DropdownButtonFormField<String>(
value: _boardType,
decoration: InputDecoration(
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: AppTheme.surface,
),
hint: Text(t("onboarding_select_board")),
items: SurfConstants.boardOptions.map((opt) {
return DropdownMenuItem(
value: opt["en"],
child: Text(widget.isSpanish ? opt["es"]! : opt["en"]!),
);
}).toList(),
onChanged: (v) => setState(() => _boardType = v),
),
const Spacer(),
SizedBox(
height: 56,
width: double.infinity,
child: ElevatedButton(
onPressed: _completeOnboarding,
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.primary,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
elevation: 0,
),
child: Text(
t("onboarding_finish_setup"),
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
),
),
],
),
),
);
}
}