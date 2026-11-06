import 'package:ai_chatbot/src/core/constants/app_constants.dart';
import 'package:ai_chatbot/src/features/chat/data/openrouter_request.dart';
import 'package:ai_chatbot/src/features/chat/domain/chat_message.dart';
import 'package:ai_chatbot/src/features/chat/domain/message_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<ChatMessage> history() => [
    ChatMessage(
      id: '1',
      role: MessageRole.user,
      text: 'hi',
      createdAt: DateTime(2026, 3, 1),
    ),
  ];

  Map<String, dynamic> build({String model = 'a/b:free'}) =>
      OpenRouterRequest.build(
        history: history(),
        model: model,
        systemPrompt: 'Be brief.',
      );

  group('fallback chain', () {
    test('puts the chosen model first so it is always preferred', () {
      final models = build(model: 'my/pick:free')['models'] as List;
      expect(models.first, 'my/pick:free');
    });

    test('never exceeds the three entries OpenRouter allows', () {
      expect((build()['models'] as List).length, lessThanOrEqualTo(3));
    });

    test('does not repeat the chosen model inside the fallbacks', () {
      final chosen = AppConstants.openRouterFallbackChain.first;
      final models = (build(model: chosen)['models'] as List).cast<String>();
      expect(models.where((m) => m == chosen), hasLength(1));
    });

    test('falls back only to vetted chat models', () {
      final models = (build()['models'] as List).cast<String>();
      for (final id in models.skip(1)) {
        expect(AppConstants.openRouterFallbackChain, contains(id));
      }
    });
  });

  group('vetted model list', () {
    test('excludes the content-safety classifier', () {
      // This model answers every prompt with "User Safety: safe", which is
      // what made `openrouter/free` unusable as a default.
      for (final id in AppConstants.fallbackFreeModels) {
        expect(id, isNot(contains('content-safety')));
      }
      expect(
        AppConstants.defaultOpenRouterModel,
        isNot(contains('content-safety')),
      );
    });

    test('default is a concrete model, not the random free router', () {
      expect(AppConstants.defaultOpenRouterModel, isNot('openrouter/free'));
      expect(AppConstants.defaultOpenRouterModel, contains('/'));
    });

    test('the default is itself a vetted model', () {
      expect(
        AppConstants.fallbackFreeModels,
        contains(AppConstants.defaultOpenRouterModel),
      );
    });
  });
}
