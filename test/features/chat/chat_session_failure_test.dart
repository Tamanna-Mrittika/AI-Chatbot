import 'package:ai_chatbot/src/core/errors/app_exception.dart';
import 'package:ai_chatbot/src/features/chat/application/chat_session_controller.dart';
import 'package:ai_chatbot/src/features/chat/application/conversation_list_controller.dart';
import 'package:ai_chatbot/src/features/chat/domain/message_role.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/chat_session_harness.dart';

void main() {
  group('failures', () {
    test('marks the placeholder failed and exposes the error', () async {
      final h = ChatSessionHarness(
        ScriptedRepository(const [], error: const RateLimitException()),
      );
      final id = await h.seed();

      await h.sendAndSettle(id, 'x');

      final last = h.messagesOf(id).last;
      expect(last.status, MessageStatus.failed);
      expect(last.errorMessage, contains('Rate limit'));
      expect(
        h.container.read(chatSessionControllerProvider(id)).error,
        isA<RateLimitException>(),
      );
    });

    test('treats an empty reply as a failure', () async {
      final h = ChatSessionHarness(ScriptedRepository(const []));
      final id = await h.seed();

      await h.sendAndSettle(id, 'x');

      expect(h.messagesOf(id).last.status, MessageStatus.failed);
    });

    test('retry drops the failed bubble and produces a fresh reply', () async {
      final h = ChatSessionHarness(
        ScriptedRepository(const [], error: const NetworkException()),
      );
      final id = await h.seed();

      await h.sendAndSettle(id, 'x');
      expect(h.messagesOf(id), hasLength(2));

      h.useRepository(ScriptedRepository(['recovered']));
      await h.notifier(id).retry();
      await h.settle(id);

      final messages = h.messagesOf(id);
      expect(messages, hasLength(2));
      expect(messages.last.text, 'recovered');
      expect(messages.last.status, MessageStatus.sent);
    });
  });

  group('persistence', () {
    test('does not write to disk for every streamed token', () async {
      final h = ChatSessionHarness(
        ScriptedRepository(List.generate(50, (i) => 'tok$i ')),
      );
      final id = await h.seed();
      final before = h.store.writeCount;

      await h.sendAndSettle(id, 'x');

      // User turn + terminal status + title rename: far fewer than 50.
      expect(h.store.writeCount - before, lessThan(10));
    });

    test('a completed reply survives a reload from storage', () async {
      final h = ChatSessionHarness(ScriptedRepository(['persisted']));
      final id = await h.seed();

      await h.sendAndSettle(id, 'x');

      final reloaded = ChatSessionHarness.reopen(h.store);
      final conversations = await reloaded.read(
        conversationListControllerProvider.future,
      );
      expect(conversations.single.messages.last.text, 'persisted');
    });
  });
}
