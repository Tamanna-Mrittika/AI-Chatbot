import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/token_buffer.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/chat_message.dart';
import '../domain/message_role.dart';
import 'chat_providers.dart';
import 'chat_session_state.dart';
import 'conversation_list_controller.dart';
import 'turn_finaliser.dart';

/// Drives one conversation's request/stream lifecycle.
///
/// Responsibilities are deliberately narrow: append the user turn, open the
/// stream, and pipe deltas into the shared conversation state. Terminal
/// bookkeeping — making sure the assistant placeholder always ends up `sent`
/// or `failed` — lives in [TurnFinaliser].
///
/// Riverpod 3 passes family arguments through the constructor, so the
/// conversation id is a plain field rather than an `arg` getter.
class ChatSessionController extends Notifier<ChatSessionState> {
  ChatSessionController(this.conversationId);

  final String conversationId;

  StreamSubscription<String>? _subscription;
  TokenBuffer? _buffer;

  /// Releases the keep-alive link held for the duration of a turn.
  ///
  /// Riverpod 3 disposes providers once nothing is watching them, so without
  /// this a user who leaves the thread mid-reply would lose the response and
  /// come back to a bubble stuck on "typing". The link is released as soon as
  /// the turn reaches a terminal state, so idle sessions are still collected.
  void Function()? _releaseKeepAlive;

  ConversationListController get _conversations =>
      ref.read(conversationListControllerProvider.notifier);

  late final TurnFinaliser _finaliser = TurnFinaliser(
    conversations: _conversations,
    conversationId: conversationId,
  );

  @override
  ChatSessionState build() {
    ref.onDispose(_disposeStream);
    return const ChatSessionState();
  }

  /// Sends [text] and streams the reply.
  ///
  /// Ignored while a turn is already in flight — the composer disables its send
  /// button too, but guarding here keeps the invariant even if that changes.
  Future<void> send(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || state.isStreaming) return;

    final uuid = ref.read(uuidProvider);
    await _conversations.appendMessage(
      conversationId,
      ChatMessage(
        id: uuid.v4(),
        role: MessageRole.user,
        text: prompt,
        createdAt: DateTime.now(),
      ),
    );

    await _startTurn(uuid.v4());
  }

  /// Re-runs the last turn after a failure, discarding the failed placeholder.
  Future<void> retry() async {
    if (state.isStreaming) return;

    final last = _conversations.byId(conversationId)?.messages.lastOrNull;
    if (last != null && !last.isFromUser) {
      await _conversations.removeMessage(conversationId, last.id);
    }

    await _startTurn(ref.read(uuidProvider).v4());
  }

  /// Stops streaming and keeps whatever text has arrived so far.
  Future<void> stop() async {
    final messageId = state.streamingMessageId;
    _buffer?.flush();
    _disposeStream();

    if (messageId != null) {
      await _finaliser.markSent(messageId);
    }
    state = const ChatSessionState();
  }

  Future<void> _startTurn(String placeholderId) async {
    final conversation = _conversations.byId(conversationId);
    if (conversation == null) return;

    // The placeholder is UI-only until it completes, so it is not persisted.
    await _conversations.appendMessage(
      conversationId,
      ChatMessage(
        id: placeholderId,
        role: MessageRole.assistant,
        text: '',
        createdAt: DateTime.now(),
        status: MessageStatus.streaming,
      ),
      persist: false,
    );
    state = ChatSessionState(streamingMessageId: placeholderId);
    _releaseKeepAlive ??= ref.keepAlive().close;

    final settings = ref.read(settingsControllerProvider);
    _buffer = TokenBuffer(
      onFlush: (text) => unawaited(_finaliser.writeDelta(placeholderId, text)),
    );

    try {
      _subscription = ref
          .read(chatRepositoryProvider)
          .streamReply(
            history: conversation.messages,
            model: settings.activeModel,
            systemPrompt: settings.systemPrompt,
          )
          .listen(
            (delta) => _buffer?.add(delta),
            onDone: () => unawaited(_complete(placeholderId)),
            onError: (Object error) => unawaited(_fail(placeholderId, error)),
            cancelOnError: true,
          );
    } on Object catch (error) {
      // Thrown synchronously before the stream opened (e.g. missing API key).
      await _fail(placeholderId, error);
    }
  }

  Future<void> _complete(String messageId) async {
    _buffer?.flush();
    final text = _buffer?.text ?? '';
    _disposeStream();

    // An empty reply is a failure from the user's point of view.
    if (text.trim().isEmpty) {
      const empty = ApiException('The model returned an empty response.');
      await _finaliser.markFailed(messageId, empty.message);
      state = const ChatSessionState(error: empty);
      return;
    }

    await _finaliser.markSent(messageId);
    await _finaliser.generateTitleIfNeeded();
    state = const ChatSessionState();
  }

  Future<void> _fail(String messageId, Object error) async {
    _buffer?.flush();
    _disposeStream();

    final exception = error is AppException
        ? error
        : ApiException('Something went wrong.', cause: error);

    await _finaliser.markFailed(messageId, exception.message);
    state = ChatSessionState(error: exception);
  }

  void _disposeStream() {
    _subscription?.cancel();
    _subscription = null;
    _buffer?.dispose();
    _buffer = null;
    _releaseKeepAlive?.call();
    _releaseKeepAlive = null;
  }
}

/// One controller per conversation id.
final chatSessionControllerProvider =
    NotifierProvider.family<ChatSessionController, ChatSessionState, String>(
      ChatSessionController.new,
    );
