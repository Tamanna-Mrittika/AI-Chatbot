import 'package:flutter/material.dart';

import '../../../../core/utils/timestamp_formatter.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/chat_message.dart';
import '../../domain/message_role.dart';
import 'markdown_message.dart';
import 'message_actions.dart';
import 'message_skeleton.dart';

/// One message in the thread.
///
/// Follows the asymmetric layout used by ChatGPT and Gemini: the user's turn is
/// a compact right-aligned bubble, while the assistant's answer runs full width
/// with no bubble at all, so long Markdown — headings, lists, code blocks — has
/// room to breathe and reads as a document rather than a chat balloon.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final ChatMessage message;

  /// Re-runs the turn; used by both the failure retry and regenerate actions.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: message.isFromUser
          ? _UserMessage(message: message)
          : _AssistantMessage(message: message, onRetry: onRetry),
    );
  }
}

class _UserMessage extends StatelessWidget {
  const _UserMessage({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  const _AssistantMessage({required this.message, required this.onRetry});

  final ChatMessage message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = message.status == MessageStatus.failed;
    final isStreaming = message.status == MessageStatus.streaming;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: AppAvatar.icon(Icons.auto_awesome_rounded, size: 30),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Before the first token arrives there is nothing to render, so
              // a shimmering skeleton stands in for the paragraph to come.
              if (message.isAwaitingFirstToken)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: MessageSkeleton(),
                )
              else
                MarkdownMessage(text: message.text, isStreaming: isStreaming),
              if (failed) _FailureNotice(message: message, onRetry: onRetry),
              if (!isStreaming && !failed && message.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      MessageActions(text: message.text, onRegenerate: onRetry),
                      const SizedBox(width: 4),
                      Text(
                        TimestampFormatter.clock(message.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Inline error strip with a retry affordance, shown in place of the actions.
class _FailureNotice extends StatelessWidget {
  const _FailureNotice({required this.message, required this.onRetry});

  final ChatMessage message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.errorMessage ?? 'Something went wrong.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: scheme.onErrorContainer,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
