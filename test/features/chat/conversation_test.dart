import 'package:ai_chatbot/src/features/chat/domain/chat_message.dart';
import 'package:ai_chatbot/src/features/chat/domain/conversation.dart';
import 'package:ai_chatbot/src/features/chat/domain/message_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ChatMessage message(
    String text, {
    MessageRole role = MessageRole.user,
    MessageStatus status = MessageStatus.sent,
  }) => ChatMessage(
    id: text,
    role: role,
    text: text,
    createdAt: DateTime(2026, 3, 1, 10),
    status: status,
  );

  Conversation withMessages(List<ChatMessage> messages) => Conversation.empty(
    'c1',
    now: DateTime(2026, 3, 1),
  ).copyWith(messages: messages);

  group('titleFromFirstMessage', () {
    test('uses the first user message verbatim when short', () {
      final conversation = withMessages([message('What is SSE?')]);
      expect(conversation.titleFromFirstMessage(), 'What is SSE?');
    });

    test('truncates at a word boundary with an ellipsis', () {
      final conversation = withMessages([
        message(
          'Explain the difference between server sent events and websockets',
        ),
      ]);

      final title = conversation.titleFromFirstMessage();
      expect(title.length, lessThanOrEqualTo(43));
      expect(title, endsWith('…'));
      expect(title, isNot(contains('  ')));
    });

    test('collapses whitespace and newlines', () {
      final conversation = withMessages([message('hello\n\n   world')]);
      expect(conversation.titleFromFirstMessage(), 'hello world');
    });

    test('skips a leading assistant message', () {
      final conversation = withMessages([
        message('Greeting', role: MessageRole.assistant),
        message('My question'),
      ]);
      expect(conversation.titleFromFirstMessage(), 'My question');
    });

    test('falls back to the placeholder for an empty thread', () {
      expect(
        withMessages(const []).titleFromFirstMessage(),
        Conversation.untitled,
      );
    });
  });

  group('preview', () {
    test('prefixes the user\'s own last message', () {
      expect(withMessages([message('hi')]).preview, 'You: hi');
    });

    test('shows the assistant reply unprefixed', () {
      final conversation = withMessages([
        message('reply', role: MessageRole.assistant),
      ]);
      expect(conversation.preview, 'reply');
    });

    test('shows a typing hint for an empty streaming placeholder', () {
      final conversation = withMessages([
        message(
          '',
          role: MessageRole.assistant,
          status: MessageStatus.streaming,
        ),
      ]);
      expect(conversation.preview, 'Typing…');
    });
  });

  group('serialisation', () {
    test('round-trips through JSON', () {
      final original = withMessages([
        message('question'),
        message('answer', role: MessageRole.assistant),
      ]).copyWith(title: 'My chat');

      final restored = Conversation.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, 'My chat');
      expect(restored.messages.map((m) => m.text), ['question', 'answer']);
      expect(restored.messages.last.role, MessageRole.assistant);
    });

    test('persists an interrupted stream as failed, never as streaming', () {
      final interrupted = withMessages([
        message(
          'half',
          role: MessageRole.assistant,
          status: MessageStatus.streaming,
        ),
      ]);

      final restored = Conversation.fromJson(interrupted.toJson());
      expect(restored.messages.single.status, MessageStatus.failed);
    });

    test('tolerates missing optional fields', () {
      final restored = Conversation.fromJson({'id': 'c9'});
      expect(restored.title, Conversation.untitled);
      expect(restored.messages, isEmpty);
    });
  });
}
