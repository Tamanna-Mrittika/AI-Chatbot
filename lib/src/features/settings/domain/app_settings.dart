import '../../../core/constants/app_constants.dart';
import '../../chat/domain/ai_provider.dart';

/// User-configurable preferences, persisted as a single JSON blob.
class AppSettings {
  const AppSettings({
    this.provider = AiProvider.openRouter,
    this.openRouterKey = '',
    this.geminiKey = '',
    this.openRouterModel = AppConstants.defaultOpenRouterModel,
    this.geminiModel = AppConstants.defaultGeminiModel,
    this.systemPrompt = AppConstants.defaultSystemPrompt,
    this.themeMode = AppThemeMode.system,
  });

  final AiProvider provider;
  final String openRouterKey;
  final String geminiKey;
  final String openRouterModel;
  final String geminiModel;
  final String systemPrompt;
  final AppThemeMode themeMode;

  /// API key for the currently selected provider, falling back to the value
  /// injected with `--dart-define` when the user has not entered one.
  String get activeKey => switch (provider) {
    AiProvider.openRouter =>
      openRouterKey.isNotEmpty
          ? openRouterKey
          : AppConstants.buildTimeOpenRouterKey,
    AiProvider.gemini =>
      geminiKey.isNotEmpty ? geminiKey : AppConstants.buildTimeGeminiKey,
  };

  /// The key saved on this device for the selected provider.
  ///
  /// Empty when the user has never typed one in — which is the normal case for
  /// a build that already carries a key from `--dart-define`.
  String get storedKey => switch (provider) {
    AiProvider.openRouter => openRouterKey,
    AiProvider.gemini => geminiKey,
  };

  /// True when the active key came from the build rather than from Settings.
  ///
  /// The Settings field shows [storedKey], so without this the field looks
  /// empty even though the app is perfectly configured. The UI uses this to
  /// say so explicitly instead of implying nothing is set up.
  bool get usesBuildTimeKey =>
      storedKey.trim().isEmpty && activeKey.trim().isNotEmpty;

  /// Model id for the currently selected provider.
  String get activeModel => switch (provider) {
    AiProvider.openRouter => openRouterModel,
    AiProvider.gemini => geminiModel,
  };

  /// Whether the app is ready to send a message.
  bool get isConfigured => activeKey.trim().isNotEmpty;

  AppSettings copyWith({
    AiProvider? provider,
    String? openRouterKey,
    String? geminiKey,
    String? openRouterModel,
    String? geminiModel,
    String? systemPrompt,
    AppThemeMode? themeMode,
  }) {
    return AppSettings(
      provider: provider ?? this.provider,
      openRouterKey: openRouterKey ?? this.openRouterKey,
      geminiKey: geminiKey ?? this.geminiKey,
      openRouterModel: openRouterModel ?? this.openRouterModel,
      geminiModel: geminiModel ?? this.geminiModel,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  /// Sets the model for whichever provider is currently active.
  AppSettings withActiveModel(String modelId) => switch (provider) {
    AiProvider.openRouter => copyWith(openRouterModel: modelId),
    AiProvider.gemini => copyWith(geminiModel: modelId),
  };

  /// Sets the API key for whichever provider is currently active.
  AppSettings withActiveKey(String key) => switch (provider) {
    AiProvider.openRouter => copyWith(openRouterKey: key),
    AiProvider.gemini => copyWith(geminiKey: key),
  };

  Map<String, dynamic> toJson() => <String, dynamic>{
    'provider': provider.id,
    'openRouterKey': openRouterKey,
    'geminiKey': geminiKey,
    'openRouterModel': openRouterModel,
    'geminiModel': geminiModel,
    'systemPrompt': systemPrompt,
    'themeMode': themeMode.name,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    provider: AiProvider.fromId(json['provider'] as String?),
    openRouterKey: json['openRouterKey'] as String? ?? '',
    geminiKey: json['geminiKey'] as String? ?? '',
    openRouterModel:
        json['openRouterModel'] as String? ??
        AppConstants.defaultOpenRouterModel,
    geminiModel:
        json['geminiModel'] as String? ?? AppConstants.defaultGeminiModel,
    systemPrompt:
        json['systemPrompt'] as String? ?? AppConstants.defaultSystemPrompt,
    themeMode: AppThemeMode.fromName(json['themeMode'] as String?),
  );
}

/// Theme preference, mirrored onto Flutter's `ThemeMode`.
enum AppThemeMode {
  system,
  light,
  dark;

  static AppThemeMode fromName(String? value) => switch (value) {
    'light' => AppThemeMode.light,
    'dark' => AppThemeMode.dark,
    _ => AppThemeMode.system,
  };
}
