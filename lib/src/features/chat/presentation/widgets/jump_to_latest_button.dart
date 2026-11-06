import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Floating "scroll to newest" pill, shown only once the user has scrolled up.
///
/// Driven by a [ValueListenable] rather than the screen's own state so that
/// scrolling repaints this button alone, never the message list behind it.
class JumpToLatestButton extends StatelessWidget {
  const JumpToLatestButton({
    super.key,
    required this.isVisible,
    required this.onPressed,
  });

  final ValueListenable<bool> isVisible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: ValueListenableBuilder<bool>(
        valueListenable: isVisible,
        builder: (context, visible, child) => AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: IgnorePointer(ignoring: !visible, child: child),
        ),
        child: Center(
          child: Material(
            elevation: 3,
            shape: const CircleBorder(),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: IconButton(
              onPressed: onPressed,
              tooltip: 'Jump to latest',
              icon: const Icon(Icons.arrow_downward_rounded, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
