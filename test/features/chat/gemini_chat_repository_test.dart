import 'package:ai_chatbot/src/core/errors/app_exception.dart';
import 'package:ai_chatbot/src/features/chat/data/gemini_chat_repository.dart';
import 'package:ai_chatbot/src/features/chat/domain/chat_message.dart';
import 'package:ai_chatbot/src/features/chat/domain/message_role.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_sse_client.dart';

void main() {
  ChatMessage message(String text, MessageRole role) => ChatMessage(
    id: text,
    role: role,
    text: text,
    createdAt: DateTime(2026, 3, 1, 10),
  );

  GeminiChatRepository build(
    FakeSseClient client, {
    String key = 'AIza-test',
  }) => GeminiChatRepository(client: client, apiKeyReader: () => key);

  Stream<String> reply(
    GeminiChatRepository repository, {
    List<ChatMessage>? history,
  }) => repository.streamReply(
    history: history ?? [message('Hi', MessageRole.user)],
    model: 'gemini-2.5-flash',
    systemPrompt: 'Be brief.',
  );

  String part(String text) =>
      '{"candidates":[{"content":{"parts":[{"text":"$text"}],"role":"model"}}]}';

  group('streamReply', () {
    test('emits each text part in order', () async {
      final client = FakeSseClient(
        chunks: sseFrames([part('Hel'), part('lo')]),
      );

      expect(await reply(build(client)).toList(), ['Hel', 'lo']);
    });

    test('sends the key as a header, never in the query string', () async {
      final client = FakeSseClient(chunks: sseFrames([part('ok')]));
      await reply(build(client, key: 'AIza-secret')).drain<void>();

      expect(client.lastHeaders['x-goog-api-key'], 'AIza-secret');
    });

    test('maps history onto Gemini roles and a systemInstruction', () async {
      final client = FakeSseClient(chunks: sseFrames([part('ok')]));
      await reply(
        build(client),
        history: [
          message('Q1', MessageRole.user),
          message('A1', MessageRole.assistant),
          message('Q2', MessageRole.user),
        ],
      ).drain<void>();

      expect(client.lastBody!['contents'], [
        {
          'role': 'user',
          'parts': [
            {'text': 'Q1'},
          ],
        },
        {
          'role': 'model',
          'parts': [
            {'text': 'A1'},
          ],
        },
        {
          'role': 'user',
          'parts': [
            {'text': 'Q2'},
          ],
        },
      ]);
      expect((client.lastBody!['systemInstruction'] as Map)['parts'], [
        {'text': 'Be brief.'},
      ]);
    });

    test('drops empty placeholder messages from the payload', () async {
      final client = FakeSseClient(chunks: sseFrames([part('ok')]));
      await reply(
        build(client),
        history: [
          message('Q1', MessageRole.user),
          message('', MessageRole.assistant),
        ],
      ).drain<void>();

      expect(client.lastBody!['contents'] as List, hasLength(1));
    });

    test('skips thought parts so reasoning never reaches the UI', () async {
      final client = FakeSseClient(
        chunks: sseFrames([
          '{"candidates":[{"content":{"parts":['
              '{"text":"scratch","thought":true},{"text":"answer"}]}}]}',
        ]),
      );

      expect(await reply(build(client)).toList(), ['answer']);
    });

    test('throws ContentBlockedException when the prompt is blocked', () {
      final client = FakeSseClient(
        chunks: sseFrames(['{"promptFeedback":{"blockReason":"SAFETY"}}']),
      );

      expect(reply(build(client)), emitsError(isA<ContentBlockedException>()));
    });

    test('throws ContentBlockedException on a SAFETY finish reason', () {
      final client = FakeSseClient(
        chunks: sseFrames([
          '{"candidates":[{"content":{"parts":[]},"finishReason":"SAFETY"}]}',
        ]),
      );

      expect(reply(build(client)), emitsError(isA<ContentBlockedException>()));
    });

    test('maps an API-key error body to AuthException', () {
      final client = FakeSseClient(
        statusCode: 400,
        chunks: const [],
        errorBody: '{"error":{"message":"API key not valid"}}',
      );

      expect(reply(build(client)), emitsError(isA<AuthException>()));
    });

    test('throws AuthException when no key is configured', () {
      expect(
        reply(build(FakeSseClient(chunks: const []), key: '')),
        emitsError(isA<AuthException>()),
      );
    });
  });
}
