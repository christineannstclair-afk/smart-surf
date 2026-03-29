import 'package:flutter/material.dart';
import 'spacing.dart';

class AppCard extends StatelessWidget {
  final Color? color;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? headerTitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.headerTitle,
    this.leadingIcon,
    this.trailing,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (headerTitle != null || leadingIcon != null || trailing != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
              ],
              if (headerTitle != null)
                Expanded(
                  child: Text(
                    headerTitle!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              else
                const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          if (headerTitle != null || leadingIcon != null || trailing != null)
            const SizedBox(height: AppSpacing.sm),
          child,
        ],
      );
    }

    final card = Card(
      clipBehavior: Clip.antiAlias,
      color: color,
      shape: borderRadius != null ? RoundedRectangleBorder(borderRadius: borderRadius!) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: content,
        ),
      ),
    );

    return card;
  }
}
