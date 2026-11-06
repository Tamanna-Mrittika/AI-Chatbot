import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../application/conversation_list_controller.dart';
import '../domain/conversation.dart';
import 'chat_screen.dart';
import 'widgets/conversation_list_view.dart';
import 'widgets/user_menu_button.dart';

/// Home screen: the list of chats.
///
/// On a compact window it is a single list that pushes the thread screen. On
/// medium and expanded windows it becomes a master/detail layout, with the
/// thread rendered inline beside the list.
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  String? _selectedId;

  Future<void> _createChat() async {
    final conversation = await ref
        .read(conversationListControllerProvider.notifier)
        .create();
    if (mounted) _open(conversation);
  }

  void _open(Conversation conversation) {
    if (context.windowSize.isTwoPane) {
      setState(() => _selectedId = conversation.id);
    } else {
      AppRoutes.openChat(context, conversation.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTwoPane = context.windowSize.isTwoPane;

    final list = ConversationListView(
      selectedId: isTwoPane ? _selectedId : null,
      onOpen: _open,
      onCreate: _createChat,
      bottomPadding: isTwoPane ? 12 : 96,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: const [UserMenuButton(), SizedBox(width: 4)],
      ),
      // In two-pane mode the thread's composer owns the bottom-right corner,
      // so the new-chat action moves into the list pane instead of floating
      // over it.
      floatingActionButton: isTwoPane
          ? null
          : FloatingActionButton.extended(
              onPressed: _createChat,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New chat'),
            ),
      body: isTwoPane
          ? Row(
              children: [
                SizedBox(
                  width: 340,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: FilledButton.icon(
                          onPressed: _createChat,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('New chat'),
                        ),
                      ),
                      Expanded(child: list),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _DetailPane(conversationId: _selectedId)),
              ],
            )
          : list,
    );
  }
}

/// Right-hand pane of the two-pane layout.
class _DetailPane extends StatelessWidget {
  const _DetailPane({this.conversationId});

  final String? conversationId;

  @override
  Widget build(BuildContext context) {
    if (conversationId == null) {
      return const AppEmptyState(
        icon: Icons.auto_awesome_rounded,
        title: 'Pick a chat',
        message: 'Select a conversation on the left, or start a new one.',
      );
    }

    return ChatScreen(
      // Keying by id tears down the old thread's scroll position and state
      // when the selection changes.
      key: ValueKey(conversationId),
      conversationId: conversationId!,
      isEmbedded: true,
    );
  }
}
