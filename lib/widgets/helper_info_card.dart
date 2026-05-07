import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui_system/app_theme.dart';

/// A standardized helper/info card used across the app for onboarding and tips.
class HelperInfoCard extends StatefulWidget {
  final String? prefKey; 
  final String? message;
  final String? dismissLabel;
  final bool? visible;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;
  final bool showDismissButton;
  final EdgeInsets? margin;
  final Widget? child;

  const HelperInfoCard({
    super.key,
    this.prefKey,
    this.message,
    this.dismissLabel,
    this.visible,
    this.onDismiss,
    this.onTap,
    this.showDismissButton = true,
    this.margin,
    this.child,
  });

  @override
  State<HelperInfoCard> createState() => _HelperInfoCardState();
}

class _HelperInfoCardState extends State<HelperInfoCard> {
  bool _visible = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.visible != null) {
      _visible = widget.visible!;
      _loaded = true;
    } else if (widget.prefKey != null) {
      _checkPref();
    } else {
      _loaded = true;
    }
  }

  @override
  void didUpdateWidget(HelperInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != null) {
      _visible = widget.visible!;
    }
  }

  Future<void> _checkPref() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(widget.prefKey!) ?? false;
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
    } else if (widget.prefKey != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(widget.prefKey!, true);
      if (mounted) setState(() => _visible = false);
    } else {
      if (mounted) setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || !_visible) return const SizedBox.shrink();

    final content = Container(
      margin: widget.margin ?? const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F6F4), // Solid light seafoam/mint
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 22,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: widget.child ?? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.message != null)
                  Text(
                    widget.message!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (widget.showDismissButton && widget.onTap == null) ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _dismiss,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        backgroundColor: const Color(0xFFC7EBE6), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        widget.dismissLabel ?? 'Got it',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.onTap != null) ...[
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.chevron_right, color: AppTheme.primary, size: 20),
            ),
          ],
        ],
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: content,
      );
    }

    return content;
  }
}
