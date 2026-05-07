import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui_system/app_theme.dart';

/// A one-time dismissible tip banner.
/// Shows itself only the first time until [prefKey] is set to true.
class MicroTipBanner extends StatefulWidget {
  final String prefKey;
  final String message;
  final String? dismissLabel;
  final bool? visible;
  final VoidCallback? onDismiss;

  const MicroTipBanner({
    super.key,
    required this.prefKey,
    required this.message,
    this.dismissLabel,
    this.visible,
    this.onDismiss,
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
    if (widget.visible == null) {
      _checkPref();
    } else {
      _visible = widget.visible!;
      _loaded = true;
    }
  }

  @override
  void didUpdateWidget(MicroTipBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != null) {
      _visible = widget.visible!;
      _loaded = true;
    }
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
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(widget.prefKey, true);
      if (mounted) setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || !_visible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 20,
              color: AppTheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _dismiss,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      backgroundColor: colorScheme.primary.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      widget.dismissLabel ?? 'Got it',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
