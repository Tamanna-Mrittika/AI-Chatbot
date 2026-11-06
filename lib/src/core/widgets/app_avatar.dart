import 'package:flutter/material.dart';

/// Circular avatar showing either initials or an icon.
///
/// Used for the signed-in user in the app bar and for the assistant next to
/// each message bubble.
class AppAvatar extends StatelessWidget {
  const AppAvatar.initials(
    this.initials, {
    super.key,
    this.size = 40,
    this.background,
    this.foreground,
  }) : icon = null;

  const AppAvatar.icon(
    this.icon, {
    super.key,
    this.size = 40,
    this.background,
    this.foreground,
  }) : initials = null;

  final String? initials;
  final IconData? icon;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = background ?? scheme.primaryContainer;
    final fg = foreground ?? scheme.onPrimaryContainer;

    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: icon != null
          ? Icon(icon, size: size * 0.52, color: fg)
          : Text(
              initials!,
              style: TextStyle(
                color: fg,
                fontSize: size * 0.36,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
    );
  }
}
