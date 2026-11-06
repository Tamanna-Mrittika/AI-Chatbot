import 'package:ai_chatbot/src/features/chat/domain/chat_message.dart';
import 'package:ai_chatbot/src/features/chat/domain/conversation.dart';
import 'package:ai_chatbot/src/features/chat/domain/conversation_export.dart';
import 'package:ai_chatbot/src/features/chat/domain/message_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ChatMessage msg(
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

  Conversation convo(List<ChatMessage> messages, {String title = 'My chat'}) =>
      Conversation.empty(
        'c1',
        now: DateTime(2026, 3, 1),
      ).copyWith(title: title, messages: messages);

  group('toPlainText', () {
    test('labels each turn and keeps order', () {
      final text = ConversationExport.toPlainText(
        convo([
          msg('What is SSE?'),
          msg('Server-Sent Events.', role: MessageRole.assistant),
        ]),
      );

      expect(text, contains('# My chat'));
      expect(text.indexOf('## You'), lessThan(text.indexOf('## Assistant')));
      expect(text, contains('What is SSE?'));
      expect(text, contains('Server-Sent Events.'));
    });

    test('skips failed turns', () {
      final text = ConversationExport.toPlainText(
        convo([
          msg('hello'),
          msg(
            'broken',
            role: MessageRole.assistant,
            status: MessageStatus.failed,
          ),
        ]),
      );

      expect(text, contains('hello'));
      expect(text, isNot(contains('broken')));
    });

    test('skips an empty streaming placeholder', () {
      final text = ConversationExport.toPlainText(
        convo([
          msg('hello'),
          msg('', role: MessageRole.assistant, status: MessageStatus.streaming),
        ]),
      );

      expect(text, contains('hello'));
      expect(text.trim(), endsWith('hello'));
    });

    test('has no trailing blank lines', () {
      final text = ConversationExport.toPlainText(convo([msg('hi')]));
      expect(text, equals(text.trimRight()));
    });

    test('an empty conversation yields just the title', () {
      final text = ConversationExport.toPlainText(convo(const []));
      expect(text.trim(), '# My chat');
    });
  });

  group('hasContent', () {
    test('false for an empty conversation', () {
      expect(ConversationExport.hasContent(convo(const [])), isFalse);
    });

    test('false when every turn failed', () {
      expect(
        ConversationExport.hasContent(
          convo([msg('x', status: MessageStatus.failed)]),
        ),
        isFalse,
      );
    });

    test('true once a real message exists', () {
      expect(ConversationExport.hasContent(convo([msg('hi')])), isTrue);
    });
  });
}
