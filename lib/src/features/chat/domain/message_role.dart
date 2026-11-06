/// Who authored a message.
///
/// The [wireName] is what the Gemini `contents[].role` field expects; the enum
/// name is what we persist, so renaming one never silently breaks the other.
enum MessageRole {
  user('user'),
  assistant('model');

  const MessageRole(this.wireName);

  /// Role string sent to / received from the Gemini API.
  final String wireName;

  static MessageRole fromName(String? value) => switch (value) {
    'assistant' || 'model' => MessageRole.assistant,
    _ => MessageRole.user,
  };
}

/// Delivery state of a message, used to drive the bubble's trailing indicator.
enum MessageStatus {
  /// User message persisted locally, request not yet acknowledged.
  sending,

  /// Assistant message currently receiving streamed tokens.
  streaming,

  /// Complete and persisted.
  sent,

  /// The request failed; the bubble offers a retry affordance.
  failed;

  bool get isInFlight =>
      this == MessageStatus.sending || this == MessageStatus.streaming;

  static MessageStatus fromName(String? value) => switch (value) {
    'sending' => MessageStatus.sending,
    'streaming' => MessageStatus.streaming,
    'failed' => MessageStatus.failed,
    _ => MessageStatus.sent,
  };
}
