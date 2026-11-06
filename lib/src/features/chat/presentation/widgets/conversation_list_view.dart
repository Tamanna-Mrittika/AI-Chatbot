import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../application/conversation_list_controller.dart';
import '../../domain/conversation.dart';
import 'conversation_tile.dart';
import 'message_skeleton.dart';

/// Renders the conversation list, including its loading, error and empty
/// states. Extracted from the screen so the screen stays pure layout.
class ConversationListView extends ConsumerWidget {
  const ConversationListView({
    super.key,
    required this.onOpen,
    required this.onCreate,
    this.selectedId,
    this.bottomPadding = 96,
  });

  final void Function(Conversation conversation) onOpen;
  final VoidCallback onCreate;
  final String? selectedId;

  /// Space reserved under the last row so a floating action button cannot
  /// cover it. Set to a small value when there is no FAB.
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationListControllerProvider);

    return conversations.when(
      loading: () => const ConversationListSkeleton(),
      error: (error, _) => AppEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load your chats',
        message: '$error',
        action: FilledButton.tonal(
          onPressed: () => ref.invalidate(conversationListControllerProvider),
          child: const Text('Retry'),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return AppEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No chats yet',
            message:
                'Start a conversation and replies will stream in token by '
                'token.',
            action: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New chat'),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.only(bottom: bottomPadding, top: 4),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(indent: 72, endIndent: 16),
          itemBuilder: (context, index) {
            final conversation = items[index];
            return Dismissible(
              key: ValueKey(conversation.id),
              direction: DismissDirection.endToStart,
              background: const _DeleteBackground(),
              confirmDismiss: (_) => _confirmDelete(context, conversation),
              onDismissed: (_) => ref
                  .read(conversationListControllerProvider.notifier)
                  .delete(conversation.id),
              child: ConversationTile(
                conversation: conversation,
                isSelected: conversation.id == selectedId,
                onTap: () => onOpen(conversation),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    Conversation conversation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete chat?'),
        content: Text(
          '"${conversation.title}" and its messages will be permanently '
          'removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      color: scheme.errorContainer,
      child: Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
    );
  }
}
