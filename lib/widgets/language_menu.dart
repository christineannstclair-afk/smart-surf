import 'package:flutter/material.dart';

class LanguageMenu extends StatelessWidget {
  final bool isSpanish;
  final void Function(bool spanish) onSetLanguage;
  final bool isInverse;

  const LanguageMenu({
    super.key,
    required this.isSpanish,
    required this.onSetLanguage,
    this.isInverse = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentLabel = isSpanish ? "Español" : "English";
    final currentFlag = isSpanish ? "🇪🇸" : "🇺🇸";

    return PopupMenuButton<bool>(
      tooltip: isSpanish ? "Idioma" : "Language",
      onSelected: onSetLanguage,
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (ctx) => [
        PopupMenuItem<bool>(
          value: false,
          child: Row(
            children: [
              const Text("🇺🇸", style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(
                "English",
                style: TextStyle(
                  fontWeight: !isSpanish ? FontWeight.bold : FontWeight.normal,
                  color: !isSpanish ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              if (!isSpanish) ...[
                const Spacer(),
                Icon(Icons.check, size: 16, color: colorScheme.primary),
              ],
            ],
          ),
        ),
        PopupMenuItem<bool>(
          value: true,
          child: Row(
            children: [
              const Text("🇪🇸", style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(
                "Español",
                style: TextStyle(
                  fontWeight: isSpanish ? FontWeight.bold : FontWeight.normal,
                  color: isSpanish ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              if (isSpanish) ...[
                const Spacer(),
                Icon(Icons.check, size: 16, color: colorScheme.primary),
              ],
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentFlag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              currentLabel,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
