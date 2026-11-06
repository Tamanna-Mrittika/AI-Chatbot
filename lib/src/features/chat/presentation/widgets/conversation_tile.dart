import 'package:flutter/material.dart';

import '../../../../core/utils/timestamp_formatter.dart';
import '../../domain/conversation.dart';

/// One row in the conversation list.
///
/// Swipe-to-delete is provided by the caller's [Dismissible]; this widget only
/// renders, which keeps it trivially testable.
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.isSelected = false,
  });

  final Conversation conversation;
  final VoidCallback onTap;

  /// Highlighted in the two-pane layout to show which thread is open.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.secondaryContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: const Icon(Icons.forum_outlined, size: 20),
      ),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          conversation.preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      trailing: Text(
        TimestampFormatter.relative(conversation.updatedAt),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
