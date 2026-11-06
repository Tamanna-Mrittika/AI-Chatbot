import 'package:flutter/material.dart';

import '../../../../core/widgets/shimmer.dart';

/// Shimmering placeholder shown between sending a prompt and the first token
/// arriving, in the style of Gemini's loading state.
///
/// Three bars of decreasing width read as "a paragraph is coming" without
/// implying how long the answer will be.
class MessageSkeleton extends StatelessWidget {
  const MessageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Generating a response',
      child: const Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShimmerBar(widthFactor: 0.92),
            SizedBox(height: 8),
            ShimmerBar(widthFactor: 0.78),
            SizedBox(height: 8),
            ShimmerBar(widthFactor: 0.45),
          ],
        ),
      ),
    );
  }
}

/// Shimmering stand-in for the conversation list while it loads from disk.
class ConversationListSkeleton extends StatelessWidget {
  const ConversationListSkeleton({super.key, this.itemCount = 7});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: itemCount,
        itemBuilder: (context, index) => const _TileSkeleton(),
      ),
    );
  }
}

class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBar(widthFactor: 0.5, height: 13),
                SizedBox(height: 8),
                ShimmerBar(widthFactor: 0.85, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
