import 'message_role.dart';

/// A single immutable message inside a conversation.
///
/// Immutability matters here: the streaming controller replaces the trailing
/// assistant message on every token, and Riverpod/`ListView` rely on identity
/// changes to know what to repaint.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.errorMessage,
  });

  final String id;
  final MessageRole role;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;

  /// Populated only when [status] is [MessageStatus.failed].
  final String? errorMessage;

  bool get isFromUser => role == MessageRole.user;

  /// True for an assistant placeholder that has not received a token yet, so
  /// the UI can show a typing indicator instead of an empty bubble.
  bool get isAwaitingFirstToken =>
      status == MessageStatus.streaming && text.isEmpty;

  ChatMessage copyWith({
    String? text,
    MessageStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      createdAt: createdAt,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'role': role.name,
    'text': text,
    'createdAt': createdAt.toUtc().toIso8601String(),
    // In-flight states are never meaningful after a restart: a message that
    // was still streaming when the app died is persisted as failed.
    'status': status.isInFlight ? MessageStatus.failed.name : status.name,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    role: MessageRole.fromName(json['role'] as String?),
    text: json['text'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    status: MessageStatus.fromName(json['status'] as String?),
    errorMessage: json['errorMessage'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          other.id == id &&
          other.text == text &&
          other.status == status &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(id, text, status, errorMessage);
}
