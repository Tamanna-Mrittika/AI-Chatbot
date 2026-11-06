// Printing is the point here: the timings show deltas arriving separately.
// ignore_for_file: avoid_print
@Tags(['live'])
library;

import 'package:ai_chatbot/src/core/constants/app_constants.dart';
import 'package:ai_chatbot/src/features/chat/data/openrouter_chat_repository.dart';
import 'package:ai_chatbot/src/features/chat/domain/chat_message.dart';
import 'package:ai_chatbot/src/features/chat/domain/message_role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Hits the real OpenRouter API. Run with:
///   flutter test --dart-define-from-file=env.json test/live_smoke_test.dart
void main() {
  test('streams a real reply from OpenRouter', () async {
    final key = AppConstants.buildTimeOpenRouterKey;
    expect(key, isNotEmpty, reason: 'no key injected');

    final client = http.Client();
    addTearDown(client.close);

    final repo = OpenRouterChatRepository(
      client: client,
      apiKeyReader: () => key,
    );

    final deltas = <String>[];
    final stopwatch = Stopwatch()..start();

    await for (final delta in repo.streamReply(
      history: [
        ChatMessage(
          id: '1',
          role: MessageRole.user,
          text: 'List the four seasons, one per line, with a short sentence each.',
          createdAt: DateTime.now(),
        ),
      ],
      model: AppConstants.defaultOpenRouterModel,
      systemPrompt: 'Be extremely brief.',
    )) {
      deltas.add(delta);
      if (deltas.length <= 10) {
        print(
          '[+${stopwatch.elapsedMilliseconds}ms] delta ${deltas.length}: '
          '${delta.replaceAll('\n', r'\n')}',
        );
      }
    }

    print(
      'TOTAL deltas: ${deltas.length} in ${stopwatch.elapsedMilliseconds}ms',
    );
    print('TEXT: ${deltas.join()}');
    expect(deltas, isNotEmpty);
  }, timeout: const Timeout(Duration(seconds: 90)));
}
