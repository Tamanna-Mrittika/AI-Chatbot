import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../chat/domain/ai_provider.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  ref.keepAlive();
  return SettingsRepository(ref.watch(keyValueStoreProvider));
});

/// Holds [AppSettings] and writes every change straight through to disk.
///
/// State is synchronous: preferences are read during bootstrap, so no screen
/// ever has to render a spinner for them.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    ref.keepAlive();
    return ref.watch(settingsRepositoryProvider).read();
  }

  Future<void> setProvider(AiProvider provider) =>
      _update(state.copyWith(provider: provider));

  /// Sets the API key for the currently selected provider.
  Future<void> setApiKey(String key) =>
      _update(state.withActiveKey(key.trim()));

  /// Sets the model for the currently selected provider.
  Future<void> setModel(String modelId) =>
      _update(state.withActiveModel(modelId));

  Future<void> setSystemPrompt(String prompt) =>
      _update(state.copyWith(systemPrompt: prompt));

  Future<void> setThemeMode(AppThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  /// Applies [next] optimistically, then persists it.
  ///
  /// A failed write rolls the in-memory state back so the UI never claims to
  /// have saved something it did not.
  Future<void> _update(AppSettings next) async {
    final previous = state;
    state = next;
    try {
      await ref.read(settingsRepositoryProvider).write(next);
    } on Object {
      state = previous;
      rethrow;
    }
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
