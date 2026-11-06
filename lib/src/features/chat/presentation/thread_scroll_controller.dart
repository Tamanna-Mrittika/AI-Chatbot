import 'package:flutter/material.dart';

/// Owns the thread's scroll behaviour: follow-the-stream and jump-to-latest.
///
/// The message list is reversed, so **offset zero is the bottom**. That makes
/// "stick to the newest line" a matter of holding the offset at zero rather
/// than chasing `maxScrollExtent`, which would race the list as it grows.
///
/// Extracted from `ChatScreen` so the screen stays layout-only and this
/// behaviour can be reasoned about (and tested) on its own.
class ThreadScrollController {
  ThreadScrollController() {
    scrollController.addListener(_onScroll);
  }

  final ScrollController scrollController = ScrollController();

  /// True once the user has scrolled up far enough to be reading history.
  ///
  /// Exposed as a listenable so only the floating button repaints on scroll,
  /// never the message list.
  final ValueNotifier<bool> isScrolledUp = ValueNotifier<bool>(false);

  /// How far from the newest message counts as "reading history".
  static const double _followThreshold = 160;

  void _onScroll() {
    if (!scrollController.hasClients) return;
    isScrolledUp.value = scrollController.offset > _followThreshold;
  }

  /// Animates back to the newest message.
  void animateToLatest() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Keeps the newest line in view as tokens arrive.
  ///
  /// Called after each batch of streamed text. It deliberately does nothing
  /// while [isScrolledUp] is true: yanking the viewport back down while
  /// someone is reading earlier messages is worse than letting them fall
  /// behind, which is what the jump-to-latest button is for.
  void followStream() {
    if (isScrolledUp.value || !scrollController.hasClients) return;
    if (scrollController.offset <= 0) return;
    scrollController.jumpTo(0);
  }

  /// Schedules [followStream] for after the frame that renders the new text,
  /// so the list has already been laid out at its new height.
  void followStreamAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => followStream());
  }

  void dispose() {
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    isScrolledUp.dispose();
  }
}
