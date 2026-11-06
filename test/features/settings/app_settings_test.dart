import 'package:ai_chatbot/src/core/constants/app_constants.dart';
import 'package:ai_chatbot/src/features/chat/domain/ai_provider.dart';
import 'package:ai_chatbot/src/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('activeKey', () {
    test('prefers a key entered in Settings over the build-time key', () {
      const settings = AppSettings(openRouterKey: 'sk-or-v1-from-settings');
      expect(settings.activeKey, 'sk-or-v1-from-settings');
    });

    test('falls back to the --dart-define key when Settings is empty', () {
      const settings = AppSettings();
      // Empty in a plain `flutter test` run; equal to the injected value when
      // the suite is run with --dart-define-from-file=env.json.
      expect(settings.activeKey, AppConstants.buildTimeOpenRouterKey);
    });

    test('reads the key belonging to the selected provider', () {
      const settings = AppSettings(
        provider: AiProvider.gemini,
        openRouterKey: 'sk-or-v1-ignored',
        geminiKey: 'AIza-used',
      );
      expect(settings.activeKey, 'AIza-used');
    });

    test('isConfigured is false when neither source supplies a key', () {
      const settings = AppSettings();
      expect(
        settings.isConfigured,
        AppConstants.buildTimeOpenRouterKey.trim().isNotEmpty,
      );
    });

    test('isConfigured is true once a key is present', () {
      const settings = AppSettings(openRouterKey: 'sk-or-v1-abc');
      expect(settings.isConfigured, isTrue);
    });
  });

  group('activeModel', () {
    test('tracks the selected provider', () {
      const settings = AppSettings(
        openRouterModel: 'deepseek/deepseek-chat-v3.1:free',
        geminiModel: 'gemini-2.5-pro',
      );

      expect(settings.activeModel, 'deepseek/deepseek-chat-v3.1:free');
      expect(
        settings.copyWith(provider: AiProvider.gemini).activeModel,
        'gemini-2.5-pro',
      );
    });

    test('withActiveModel only touches the current provider', () {
      const settings = AppSettings(provider: AiProvider.gemini);
      final updated = settings.withActiveModel('gemini-2.5-flash-lite');

      expect(updated.geminiModel, 'gemini-2.5-flash-lite');
      expect(updated.openRouterModel, settings.openRouterModel);
    });

    test('withActiveKey only touches the current provider', () {
      const settings = AppSettings(provider: AiProvider.openRouter);
      final updated = settings.withActiveKey('sk-or-v1-new');

      expect(updated.openRouterKey, 'sk-or-v1-new');
      expect(updated.geminiKey, '');
    });
  });

  group('storedKey / usesBuildTimeKey', () {
    test('storedKey is empty when nothing was typed into Settings', () {
      const settings = AppSettings();
      expect(settings.storedKey, isEmpty);
    });

    test('storedKey follows the selected provider', () {
      const settings = AppSettings(
        provider: AiProvider.gemini,
        openRouterKey: 'sk-or-v1-x',
        geminiKey: 'AIza-y',
      );
      expect(settings.storedKey, 'AIza-y');
    });

    test('usesBuildTimeKey is false once a key is typed in', () {
      const settings = AppSettings(openRouterKey: 'sk-or-v1-mine');
      expect(settings.usesBuildTimeKey, isFalse);
    });

    test('usesBuildTimeKey matches whether a build-time key exists', () {
      const settings = AppSettings();
      expect(
        settings.usesBuildTimeKey,
        AppConstants.buildTimeOpenRouterKey.trim().isNotEmpty,
      );
    });
  });

  test('settings round-trip through JSON', () {
    const original = AppSettings(
      provider: AiProvider.gemini,
      geminiKey: 'AIza-x',
      geminiModel: 'gemini-2.5-pro',
      themeMode: AppThemeMode.dark,
    );

    final restored = AppSettings.fromJson(original.toJson());

    expect(restored.provider, AiProvider.gemini);
    expect(restored.geminiKey, 'AIza-x');
    expect(restored.geminiModel, 'gemini-2.5-pro');
    expect(restored.themeMode, AppThemeMode.dark);
  });
}
