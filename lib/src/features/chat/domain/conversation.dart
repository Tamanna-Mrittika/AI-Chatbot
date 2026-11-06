import 'chat_message.dart';
import 'message_role.dart';

/// A chat thread: an ordered list of messages plus list-screen metadata.
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const <ChatMessage>[],
  });

  /// Creates an empty conversation with a placeholder title.
  factory Conversation.empty(String id, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    return Conversation(
      id: id,
      title: untitled,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  static const String untitled = 'New chat';

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  bool get isEmpty => messages.isEmpty;

  bool get hasGeneratedTitle => title != untitled;

  /// One-line preview rendered under the title in the conversation list.
  String get preview {
    if (messages.isEmpty) return 'No messages yet';
    final last = messages.last;
    final text = last.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) {
      return last.status == MessageStatus.failed ? 'Failed to send' : 'Typing…';
    }
    return last.isFromUser ? 'You: $text' : text;
  }

  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  /// Derives a title from the first user message, truncated at a word boundary.
  ///
  /// Called once, the first time a conversation receives a reply, so the list
  /// screen shows something meaningful without an extra API round trip.
  String titleFromFirstMessage() {
    final first = messages.firstWhere(
      (message) => message.isFromUser && message.text.trim().isNotEmpty,
      orElse: () => messages.isEmpty
          ? ChatMessage(
              id: id,
              role: MessageRole.user,
              text: untitled,
              createdAt: createdAt,
            )
          : messages.first,
    );

    final normalised = first.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalised.isEmpty) return untitled;
    if (normalised.length <= 42) return normalised;

    final cut = normalised.substring(0, 42);
    final lastSpace = cut.lastIndexOf(' ');
    return '${lastSpace > 20 ? cut.substring(0, lastSpace) : cut}…';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(growable: false),
  };

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? const [];
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String? ?? untitled,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      messages: rawMessages
          .cast<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList(growable: false),
    );
  }
}
