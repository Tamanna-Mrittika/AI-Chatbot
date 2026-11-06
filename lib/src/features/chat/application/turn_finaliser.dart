import '../domain/chat_message.dart';
import '../domain/message_role.dart' show MessageStatus;
import 'conversation_list_controller.dart';

/// Writes a turn's message mutations into the shared conversation state.
///
/// Split out of `ChatSessionController` so the controller reads as a pure
/// state machine (open stream → deltas → terminal state) and the persistence
/// details live in one place.
class TurnFinaliser {
  const TurnFinaliser({
    required ConversationListController conversations,
    required this.conversationId,
    // Named parameters cannot be private initialising formals.
    // ignore: prefer_initializing_formals
  }) : _conversations = conversations;

  final ConversationListController _conversations;
  final String conversationId;

  /// Updates the streaming placeholder with the text received so far.
  ///
  /// Deliberately not persisted: writing to disk on every flush would mean
  /// dozens of serialisations per reply for no benefit.
  Future<void> writeDelta(String messageId, String text) async {
    final message = _messageById(messageId);
    if (message == null) return;

    await _conversations.replaceMessage(
      conversationId,
      message.copyWith(text: text, status: MessageStatus.streaming),
      persist: false,
    );
  }

  /// Marks the placeholder complete and flushes the conversation to disk.
  Future<void> markSent(String messageId) async {
    final message = _messageById(messageId);
    if (message == null) return;

    await _conversations.replaceMessage(
      conversationId,
      message.copyWith(status: MessageStatus.sent, clearError: true),
    );
  }

  /// Marks the placeholder failed, attaching [error] for the bubble to show.
  Future<void> markFailed(String messageId, String error) async {
    final message = _messageById(messageId);
    if (message == null) return;

    await _conversations.replaceMessage(
      conversationId,
      message.copyWith(status: MessageStatus.failed, errorMessage: error),
    );
  }

  /// Names the thread after its first user message once a reply lands.
  Future<void> generateTitleIfNeeded() async {
    final conversation = _conversations.byId(conversationId);
    if (conversation == null || conversation.hasGeneratedTitle) return;

    await _conversations.rename(
      conversationId,
      conversation.titleFromFirstMessage(),
    );
  }

  ChatMessage? _messageById(String messageId) {
    final messages = _conversations.byId(conversationId)?.messages;
    if (messages == null) return null;
    for (final message in messages) {
      if (message.id == messageId) return message;
    }
    return null;
  }
}
