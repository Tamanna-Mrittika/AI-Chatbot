import 'dart:convert';

import 'package:ai_chatbot/src/core/constants/app_constants.dart';
import 'package:ai_chatbot/src/features/chat/domain/ai_provider.dart';
import 'package:ai_chatbot/src/features/settings/data/settings_repository.dart';
import 'package:ai_chatbot/src/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_key_value_store.dart';

void main() {
  /// Writes [settings] the way an older build would have, bypassing migration.
  FakeKeyValueStore storeWith(AppSettings settings) =>
      FakeKeyValueStore({'app.settings': jsonEncode(settings.toJson())});

  group('migration on read', () {
    test('replaces the random free router with a concrete model', () {
      // The old default dispatched to any zero-cost model, including a
      // content-safety classifier that replied "User Safety: safe".
      final store = storeWith(
        const AppSettings(openRouterModel: 'openrouter/free'),
      );

      final settings = SettingsRepository(store).read();

      expect(settings.openRouterModel, AppConstants.defaultOpenRouterModel);
      expect(settings.openRouterModel, isNot('openrouter/free'));
    });

    test('replaces the content-safety classifier if it was selected', () {
      final store = storeWith(
        const AppSettings(
          openRouterModel: 'nvidia/nemotron-3.5-content-safety:free',
        ),
      );

      expect(
        SettingsRepository(store).read().openRouterModel,
        AppConstants.defaultOpenRouterModel,
      );
    });

    test('replaces Gemini ids Google retired for new keys', () {
      final store = storeWith(
        const AppSettings(geminiModel: 'gemini-2.5-flash'),
      );

      expect(
        SettingsRepository(store).read().geminiModel,
        AppConstants.defaultGeminiModel,
      );
    });

    test('leaves a healthy model choice alone', () {
      const chosen = 'cohere/north-mini-code:free';
      final store = storeWith(const AppSettings(openRouterModel: chosen));

      expect(SettingsRepository(store).read().openRouterModel, chosen);
    });

    test('preserves every other preference', () {
      final store = storeWith(
        const AppSettings(
          provider: AiProvider.gemini,
          openRouterModel: 'openrouter/free',
          openRouterKey: 'sk-or-v1-keep-me',
          systemPrompt: 'Custom persona.',
          themeMode: AppThemeMode.dark,
        ),
      );

      final settings = SettingsRepository(store).read();

      expect(settings.provider, AiProvider.gemini);
      expect(settings.openRouterKey, 'sk-or-v1-keep-me');
      expect(settings.systemPrompt, 'Custom persona.');
      expect(settings.themeMode, AppThemeMode.dark);
      // ...while still repairing the broken model.
      expect(settings.openRouterModel, AppConstants.defaultOpenRouterModel);
    });
  });
}
