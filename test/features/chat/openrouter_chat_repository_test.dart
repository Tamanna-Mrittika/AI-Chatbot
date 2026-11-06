import 'package:ai_chatbot/src/core/errors/app_exception.dart';
import 'package:ai_chatbot/src/features/chat/data/openrouter_chat_repository.dart';
import 'package:ai_chatbot/src/features/chat/domain/chat_message.dart';
import 'package:ai_chatbot/src/features/chat/domain/message_role.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_sse_client.dart';

void main() {
  ChatMessage userMessage(String text) => ChatMessage(
    id: 'm1',
    role: MessageRole.user,
    text: text,
    createdAt: DateTime(2026, 3, 1, 10),
  );

  OpenRouterChatRepository build(
    FakeSseClient client, {
    String key = 'sk-test',
  }) => OpenRouterChatRepository(client: client, apiKeyReader: () => key);

  Stream<String> reply(OpenRouterChatRepository repository) =>
      repository.streamReply(
        history: [userMessage('Hi')],
        model: 'deepseek/deepseek-chat-v3.1:free',
        systemPrompt: 'Be brief.',
      );

  String delta(String text) =>
      '{"choices":[{"delta":{"content":"$text"},"finish_reason":null}]}';

  group('streamReply', () {
    test('emits each content delta in order', () async {
      final client = FakeSseClient(
        chunks: sseFrames([delta('Hel'), delta('lo'), '[DONE]']),
      );

      expect(await reply(build(client)).toList(), ['Hel', 'lo']);
    });

    test('sends the system prompt and history in OpenAI format', () async {
      final client = FakeSseClient(chunks: sseFrames([delta('ok'), '[DONE]']));
      await reply(build(client)).drain<void>();

      expect(client.lastBody!['stream'], isTrue);
      expect(client.lastBody!['model'], 'deepseek/deepseek-chat-v3.1:free');
      expect(client.lastBody!['messages'], [
        {'role': 'system', 'content': 'Be brief.'},
        {'role': 'user', 'content': 'Hi'},
      ]);
    });

    test('authenticates with a bearer token', () async {
      final client = FakeSseClient(chunks: sseFrames(['[DONE]']));
      await reply(build(client, key: 'sk-or-v1-abc')).drain<void>();

      expect(client.lastHeaders['Authorization'], 'Bearer sk-or-v1-abc');
    });

    test('stops at finish_reason without waiting for [DONE]', () async {
      final client = FakeSseClient(
        chunks: sseFrames([
          delta('done'),
          '{"choices":[{"delta":{},"finish_reason":"stop"}]}',
          delta('should not arrive'),
        ]),
      );

      expect(await reply(build(client)).toList(), ['done']);
    });

    test('throws AuthException without a key, before any request', () async {
      final client = FakeSseClient(chunks: const []);

      await expectLater(
        reply(build(client, key: '  ')),
        emitsError(isA<AuthException>()),
      );
      expect(client.lastBody, isNull);
    });

    test('maps 401 to AuthException', () {
      final client = FakeSseClient(
        statusCode: 401,
        chunks: const [],
        errorBody: '{"error":{"message":"No auth credentials found"}}',
      );

      expect(reply(build(client)), emitsError(isA<AuthException>()));
    });

    test('maps 429 to RateLimitException', () {
      final client = FakeSseClient(
        statusCode: 429,
        chunks: const [],
        errorBody: '{"error":{"message":"rate limited"}}',
      );

      expect(reply(build(client)), emitsError(isA<RateLimitException>()));
    });

    test('maps 402 to a credits-required ApiException', () {
      final client = FakeSseClient(
        statusCode: 402,
        chunks: const [],
        errorBody: '{"error":{"message":"insufficient credits"}}',
      );

      expect(
        reply(build(client)),
        emitsError(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('free'),
          ),
        ),
      );
    });

    test('surfaces an inline error object mid-stream', () {
      final client = FakeSseClient(
        chunks: sseFrames([
          delta('partial'),
          '{"error":{"code":500,"message":"upstream exploded"}}',
        ]),
      );

      expect(
        reply(build(client)),
        emitsInOrder(['partial', emitsError(isA<ApiException>())]),
      );
    });

    test('throws ParseException on a malformed frame', () {
      final client = FakeSseClient(chunks: sseFrames(['not json']));

      expect(reply(build(client)), emitsError(isA<ParseException>()));
    });

    test('cancelling the subscription aborts the request', () async {
      final client = FakeSseClient(
        chunks: sseFrames([delta('a'), delta('b'), delta('c')]),
        chunkDelay: const Duration(milliseconds: 20),
      );

      final subscription = reply(build(client)).listen(null);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await subscription.cancel();

      expect(client.wasCancelled, isTrue);
    });
  });
}
