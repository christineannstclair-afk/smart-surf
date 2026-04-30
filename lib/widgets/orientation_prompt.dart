import 'package:flutter/material.dart';
import '../ui_system/app_theme.dart';
import '../ui_system/spacing.dart';

class OrientationPrompt extends StatelessWidget {
  final String title;
  final String message;
  final String? skipLabel;
  final VoidCallback onDismiss;
  final GlobalKey anchorKey;
  final bool isSpanish;

  const OrientationPrompt({
    super.key,
    required this.title,
    required this.message,
    required this.onDismiss,
    required this.anchorKey,
    this.isSpanish = false,
    this.skipLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onDismiss,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Semi-transparent background
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
            _PromptBox(
              anchorKey: anchorKey,
              title: title,
              message: message,
              skipLabel: skipLabel,
              isSpanish: isSpanish,
              onDismiss: onDismiss,
            ),
          ],
        ),
      ),
    );
  }

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onDismiss,
    required GlobalKey anchorKey,
    bool isSpanish = false,
    String? skipLabel,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) => OrientationPrompt(
        title: title,
        message: message,
        anchorKey: anchorKey,
        isSpanish: isSpanish,
        skipLabel: skipLabel,
        onDismiss: () {
          entry.remove();
          onDismiss();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _PromptBox extends StatelessWidget {
  final GlobalKey anchorKey;
  final String title;
  final String message;
  final String? skipLabel;
  final bool isSpanish;
  final VoidCallback onDismiss;

  const _PromptBox({
    required this.anchorKey,
    required this.title,
    required this.message,
    required this.onDismiss,
    required this.isSpanish,
    this.skipLabel,
  });

  @override
  Widget build(BuildContext context) {
    final renderBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    // Decide if we show above or below the anchor
    final showBelow = offset.dy < screenHeight * 0.5;

    return Positioned(
      left: 16,
      right: 16,
      top: showBelow ? offset.dy + size.height + 12 : null,
      bottom: !showBelow ? (screenHeight - offset.dy) + 12 : null,
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F7F9), // Light Seafoam tint
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: AppTheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                  ),
                ),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      skipLabel ?? (title.isEmpty ? (isSpanish ? "Entendido" : "Got it") : (isSpanish ? "Siguiente" : "Next")),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
