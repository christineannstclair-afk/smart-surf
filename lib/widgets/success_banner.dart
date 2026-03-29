import 'package:flutter/material.dart';
import '../ui_system/app_theme.dart';
import '../ui_system/spacing.dart';

class SessionLoggedBanner extends StatefulWidget {
  final VoidCallback onViewPassport;
  final VoidCallback onDismiss;
  final bool isSpanish;

  const SessionLoggedBanner({
    super.key,
    required this.onViewPassport,
    required this.onDismiss,
    required this.isSpanish,
  });

  @override
  State<SessionLoggedBanner> createState() => _SessionLoggedBannerState();

  static void show(BuildContext context, {required VoidCallback onViewPassport, required bool isSpanish}) {
    final overlay = Overlay.maybeOf(context) ?? 
                   (context is StatefulElement && context.state is NavigatorState 
                       ? (context.state as NavigatorState).overlay 
                       : Navigator.of(context, rootNavigator: true).overlay);
    
    if (overlay == null) return;
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 16,
        right: 16,
        child: SessionLoggedBanner(
          isSpanish: isSpanish,
          onViewPassport: () {
            entry.remove();
            onViewPassport();
          },
          onDismiss: () {
            entry.remove();
          },
        ),
      ),
    );

    overlay.insert(entry);
  }
}

class _SessionLoggedBannerState extends State<SessionLoggedBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = (String en, String es) => widget.isSpanish ? es : en;

    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! < -5) {
              _dismiss();
            }
          },
          onTap: _dismiss,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7F9), // Light Seafoam tint
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text("🌊", style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t(
                        "Session logged. Your surf passport just updated.",
                        "Sesión registrada. Tu pasaporte acaba de actualizarse."
                      ),
                      style: const TextStyle(
                        color: Color(0xFF0B4F57), // Deep Sea Teal
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: widget.onViewPassport,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 32),
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      t("View Passport", "Ver Pasaporte"),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
