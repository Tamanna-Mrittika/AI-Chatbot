import 'package:flutter/widgets.dart';

/// Layout breakpoints, following the Material 3 window size classes.
///
/// The chat feature uses these to switch between a stacked navigation flow on
/// phones and a two-pane master/detail layout on tablets and desktops.
enum WindowSize {
  compact,
  medium,
  expanded;

  /// True when the conversation list and the thread can sit side by side.
  bool get isTwoPane => this != WindowSize.compact;
}

extension WindowSizeX on BuildContext {
  /// Current window size class derived from the shortest usable width.
  WindowSize get windowSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width < 600) return WindowSize.compact;
    if (width < 1000) return WindowSize.medium;
    return WindowSize.expanded;
  }

  /// Maximum width a text column should occupy, so message bubbles do not
  /// stretch into unreadable lines on a desktop window.
  double get readableWidth =>
      MediaQuery.sizeOf(this).width.clamp(0, 760).toDouble();
}
