import 'package:flutter/material.dart';

import '../../../../core/utils/timestamp_formatter.dart';
import '../../domain/chat_message.dart';
import 'message_bubble.dart';

/// Scrollable message history with day separators.
///
/// The list is reversed so new messages appear at the bottom without any
/// scroll maths — the viewport is anchored to the newest item, which also
/// means streaming tokens push older content upward while the newest line
/// stays in view.
class MessageList extends StatelessWidget {
  const MessageList({
    super.key,
    required this.messages,
    required this.onRetry,
    this.controller,
  });

  final List<ChatMessage> messages;
  final VoidCallback onRetry;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    // Reversed view of the history, newest first.
    final items = messages.reversed.toList(growable: false);

    // A single SelectionArea over the whole list lets one drag select across
    // several messages, the way ChatGPT and Claude behave. Individual bubbles
    // therefore render plain Text: a SelectableText per bubble would trap each
    // selection inside its own message.
    return SelectionArea(
      child: ListView.builder(
        controller: controller,
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final message = items[index];
          // `index + 1` is the chronologically *previous* message.
          final previous = index + 1 < items.length ? items[index + 1] : null;

          return Column(
            children: [
              if (_startsNewDay(previous, message))
                _DaySeparator(timestamp: message.createdAt),
              MessageBubble(message: message, onRetry: onRetry),
            ],
          );
        },
      ),
    );
  }

  static bool _startsNewDay(ChatMessage? previous, ChatMessage current) {
    if (previous == null) return true;
    final a = previous.createdAt;
    final b = current.createdAt;
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.timestamp});

  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(indent: 16, endIndent: 12)),
          Text(
            TimestampFormatter.daySeparator(timestamp),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Expanded(child: Divider(indent: 12, endIndent: 16)),
        ],
      ),
    );
  }
}
