import '../../../core/constants/app_constants.dart';
import '../domain/app_settings.dart';

/// Repairs settings that were saved by an older build.
///
/// Preferences outlive the code that wrote them, so a bad default does not
/// stop being a problem the moment it is fixed: anyone who already ran the app
/// has the old value on disk and would keep using it forever.
abstract final class SettingsMigration {
  /// Model ids that must not be used as a chat model, with the reason.
  ///
  /// `openrouter/free` dispatches to a random zero-cost model, and that pool
  /// includes a content-safety classifier which answers every prompt with
  /// "User Safety: safe / Response Safety: safe", plus music generators.
  static const Set<String> retiredOpenRouterModels = {
    'openrouter/free',
    'nvidia/nemotron-3.5-content-safety:free',
    'deepseek/deepseek-chat-v3.1:free',
    'deepseek/deepseek-r1:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'qwen/qwen3-coder:free',
    'mistralai/mistral-small-3.2-24b-instruct:free',
  };

  /// Gemini ids Google has retired for newer API keys.
  static const Set<String> retiredGeminiModels = {
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.5-pro',
  };

  /// Returns [settings] with any unusable model replaced by the current
  /// default, leaving every other preference untouched.
  static AppSettings apply(AppSettings settings) {
    var migrated = settings;

    if (retiredOpenRouterModels.contains(settings.openRouterModel)) {
      migrated = migrated.copyWith(
        openRouterModel: AppConstants.defaultOpenRouterModel,
      );
    }

    if (retiredGeminiModels.contains(settings.geminiModel)) {
      migrated = migrated.copyWith(
        geminiModel: AppConstants.defaultGeminiModel,
      );
    }

    return migrated;
  }

  /// Whether [apply] would change anything, so the caller can skip a write.
  static bool isNeeded(AppSettings settings) =>
      retiredOpenRouterModels.contains(settings.openRouterModel) ||
      retiredGeminiModels.contains(settings.geminiModel);
}
