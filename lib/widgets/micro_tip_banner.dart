import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7F9), // Light Seafoam tint
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _dismiss,
            child: Text(
              widget.dismissLabel ?? 'Got it',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
