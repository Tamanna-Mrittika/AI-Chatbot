import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_router.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../settings/application/settings_controller.dart';
import '../application/chat_session_controller.dart';
import '../application/conversation_list_controller.dart';
import '../domain/conversation.dart';
import '../domain/conversation_export.dart';
import 'thread_scroll_controller.dart';
import 'widgets/jump_to_latest_button.dart';
import 'widgets/message_composer.dart';
import 'widgets/message_list.dart';
import 'widgets/missing_key_banner.dart';
import 'widgets/suggestion_chips.dart';

/// One conversation thread.
///
/// Set [isEmbedded] when the screen is rendered inside the two-pane layout: it
/// drops the back button so it reads as a panel rather than a page.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.isEmbedded = false,
  });

  final String conversationId;
  final bool isEmbedded;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scroll = ThreadScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  ChatSessionController get _session =>
      ref.read(chatSessionControllerProvider(widget.conversationId).notifier);

  Future<void> _send(String text) async {
    await _session.send(text);
    _scroll.animateToLatest();
  }

  Future<void> _copyConversation(Conversation conversation) async {
    await Clipboard.setData(
      ClipboardData(text: ConversationExport.toPlainText(conversation)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Chat copied')));
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(conversationProvider(widget.conversationId));
    final session = ref.watch(
      chatSessionControllerProvider(widget.conversationId),
    );
    final isConfigured = ref.watch(
      settingsControllerProvider.select((settings) => settings.isConfigured),
    );

    _listenForKeyErrors();
    _followStreamedText();

    if (conversation == null) {
      return Scaffold(
        appBar: widget.isEmbedded ? null : AppBar(),
        body: const AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'Chat not found',
          message: 'This conversation was deleted.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (ConversationExport.hasContent(conversation))
            IconButton(
              tooltip: 'Copy whole chat',
              onPressed: () => _copyConversation(conversation),
              icon: const Icon(Icons.copy_all_rounded),
            ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => AppRoutes.openSettings(context),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isConfigured) const MissingKeyBanner(),
          Expanded(
            child: conversation.isEmpty
                ? EmptyThread(suggestions: SuggestionChips(onSelected: _send))
                : Stack(
                    children: [
                      MessageList(
                        messages: conversation.messages,
                        controller: _scroll.scrollController,
                        onRetry: _session.retry,
                      ),
                      JumpToLatestButton(
                        isVisible: _scroll.isScrolledUp,
                        onPressed: _scroll.animateToLatest,
                      ),
                    ],
                  ),
          ),
          MessageComposer(
            isStreaming: session.isStreaming,
            enabled: isConfigured,
            hintText: isConfigured
                ? 'Message…'
                : 'Add an API key in Settings to start',
            onSend: _send,
            onStop: _session.stop,
          ),
        ],
      ),
    );
  }

  /// Surfaces stream failures that are not already attached to a bubble.
  void _listenForKeyErrors() {
    ref.listen(
      chatSessionControllerProvider(widget.conversationId)
          .select((state) => state.error),
      (_, error) {
        if (error is AuthException) _showKeyPrompt(error);
      },
    );
  }

  /// Re-pins the viewport to the newest line whenever the reply grows.
  void _followStreamedText() {
    ref.listen(
      conversationProvider(widget.conversationId)
          .select((c) => c?.messages.lastOrNull?.text.length ?? 0),
      (previous, next) {
        if (next > (previous ?? 0)) _scroll.followStreamAfterFrame();
      },
    );
  }

  void _showKeyPrompt(AuthException error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => AppRoutes.openSettings(context),
          ),
        ),
      );
  }
}
