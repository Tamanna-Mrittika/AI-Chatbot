import '../../../core/errors/app_exception.dart';

/// Transient UI state for one open conversation.
///
/// The messages themselves live in `ConversationListController`; this holds
/// only what is true *while* a turn is in flight, so navigating away and back
/// never leaves a stale spinner behind.
class ChatSessionState {
  const ChatSessionState({this.streamingMessageId, this.error});

  /// Id of the assistant message currently receiving tokens, if any.
  final String? streamingMessageId;

  /// Last failure, cleared as soon as the next turn starts.
  final AppException? error;

  bool get isStreaming => streamingMessageId != null;

  /// Whether the composer should accept a new message.
  bool get canSend => !isStreaming;

  ChatSessionState copyWith({
    String? streamingMessageId,
    AppException? error,
    bool clearStreaming = false,
    bool clearError = false,
  }) {
    return ChatSessionState(
      streamingMessageId: clearStreaming
          ? null
          : (streamingMessageId ?? this.streamingMessageId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
