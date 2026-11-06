import 'package:ai_chatbot/src/features/chat/application/conversation_list_controller.dart';
import 'package:ai_chatbot/src/features/chat/domain/conversation.dart';
import 'package:ai_chatbot/src/features/chat/domain/message_role.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/chat_session_harness.dart';

void main() {
  group('send', () {
    test(
      'appends the user turn then streams the reply into one bubble',
      () async {
        final h = ChatSessionHarness(ScriptedRepository(['Hel', 'lo!']));
        final id = await h.seed();

        await h.sendAndSettle(id, 'Hi there');

        final messages = h.messagesOf(id);
        expect(messages, hasLength(2));
        expect(messages.first.role, MessageRole.user);
        expect(messages.first.text, 'Hi there');
        expect(messages.last.role, MessageRole.assistant);
        expect(messages.last.text, 'Hello!');
        expect(messages.last.status, MessageStatus.sent);
      },
    );

    test('clears the streaming flag once the turn ends', () async {
      final h = ChatSessionHarness(ScriptedRepository(['ok']));
      final id = await h.seed();

      await h.sendAndSettle(id, 'x');

      expect(h.notifier(id).state.isStreaming, isFalse);
    });

    test('ignores an empty prompt', () async {
      final h = ChatSessionHarness(ScriptedRepository(['ok']));
      final id = await h.seed();

      await h.sendAndSettle(id, '   ');

      expect(h.messagesOf(id), isEmpty);
    });

    test('sends prior history, excluding the placeholder', () async {
      final repository = ScriptedRepository(['ok']);
      final h = ChatSessionHarness(repository);
      final id = await h.seed();

      await h.sendAndSettle(id, 'Question');

      expect(repository.lastHistory!.map((m) => m.text), ['Question']);
    });

    test('titles the conversation from the first user message', () async {
      final h = ChatSessionHarness(ScriptedRepository(['ok']));
      final id = await h.seed();

      expect(
        h.container.read(conversationProvider(id))!.title,
        Conversation.untitled,
      );

      await h.sendAndSettle(id, 'How does SSE work?');

      expect(
        h.container.read(conversationProvider(id))!.title,
        'How does SSE work?',
      );
    });
  });
}
