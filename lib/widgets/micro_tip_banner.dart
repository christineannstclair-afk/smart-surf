import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A one-time dismissible tip banner.
/// Shows itself only the first time until [prefKey] is set to true.
class MicroTipBanner extends StatefulWidget {
  final String prefKey;
  final String message;
  final String? dismissLabel;

  const MicroTipBanner({
    super.key,
    required this.prefKey,
    required this.message,
    this.dismissLabel,
  });

  @override
  State<MicroTipBanner> createState() => _MicroTipBannerState();
}

class _MicroTipBannerState extends State<MicroTipBanner> {
  bool _visible = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _checkPref();
  }

  Future<void> _checkPref() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(widget.prefKey) ?? false;
    if (mounted) {
      setState(() {
        _visible = !seen;
        _loaded = true;
      });
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefKey, true);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || !_visible) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _visible
          ? Container(
              key: const ValueKey('visible'),
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onPrimaryContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Text(
                      widget.dismissLabel ?? 'Dismiss',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }
}
