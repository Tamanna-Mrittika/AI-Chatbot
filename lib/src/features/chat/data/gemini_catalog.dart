import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../domain/ai_model.dart';
import '../domain/ai_provider.dart';

/// Fetches the Gemini model list from Google's own catalogue endpoint.
///
/// Unlike OpenRouter's, this endpoint requires the API key, so the catalogue
/// is only available once one is configured — callers fall back to
/// [AppConstants.geminiModels] when it is not.
///
/// Fetching beats hard-coding here: Google retires models for *new* keys while
/// still listing them for old ones, so a baked-in list silently rots. That is
/// exactly how `gemini-2.5-flash` ended up returning 404.
abstract final class GeminiCatalog {
  /// Model ids that are aliases rather than pinned versions.
  ///
  /// These track whatever Google currently considers current, so they never
  /// go stale, and are surfaced first in the picker.
  static const Set<String> _aliases = {
    'gemini-flash-latest',
    'gemini-flash-lite-latest',
    'gemini-pro-latest',
  };

  /// Substrings marking models that cannot serve an ordinary chat turn.
  ///
  /// Two groups: modalities this UI cannot render (speech, images,
  /// embeddings), and specialised agent endpoints that expect their own
  /// request shape rather than a plain conversation.
  ///
  /// Note this cannot filter *retired* models: Google keeps listing ids
  /// like `gemini-2.5-flash-lite` that answer 404 for newer keys, so the
  /// catalogue alone cannot tell us what a given key may call. That case is
  /// handled at request time, where the API explains itself clearly.
  static const List<String> _excluded = [
    'tts',
    'image',
    'embedding',
    'aqa',
    'music',
    'veo',
    'imagen',
    'learnlm',
    'computer-use',
    'deep-research',
    'antigravity',
    'transcribe',
  ];

  static Future<List<AiModel>> fetch(http.Client client, String apiKey) async {
    if (apiKey.trim().isEmpty) return fallback();

    final http.Response response;
    try {
      response = await client
          .get(
            Uri.parse('${AppConstants.geminiBaseUrl}/models?pageSize=200'),
            headers: {'x-goog-api-key': apiKey.trim()},
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      return fallback();
    }

    if (response.statusCode != 200) return fallback();

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final models = (decoded['models'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where(_isChatCapable)
          .map(_toModel)
          .toList();

      // Aliases first, then everything else alphabetically.
      models.sort((a, b) {
        final aAlias = _aliases.contains(a.id);
        final bAlias = _aliases.contains(b.id);
        if (aAlias != bAlias) return aAlias ? -1 : 1;
        return a.id.compareTo(b.id);
      });

      return models.isEmpty ? fallback() : models;
    } on Object {
      return fallback();
    }
  }

  /// True when the model can answer a text prompt.
  static bool _isChatCapable(Map<String, dynamic> json) {
    final methods = (json['supportedGenerationMethods'] as List<dynamic>?)
        ?.cast<String>();
    // Streaming is a variant of generateContent; the API never lists
    // `streamGenerateContent` separately.
    if (methods == null || !methods.contains('generateContent')) return false;

    final id = (json['name'] as String? ?? '').toLowerCase();
    return !_excluded.any(id.contains);
  }

  static AiModel _toModel(Map<String, dynamic> json) {
    final id = (json['name'] as String).replaceFirst('models/', '');
    return AiModel(
      id: id,
      name: json['displayName'] as String? ?? id,
      provider: AiProvider.gemini,
      contextLength: (json['inputTokenLimit'] as num?)?.toInt(),
    );
  }

  static List<AiModel> fallback() => [
    for (final id in AppConstants.geminiModels)
      AiModel(id: id, name: id, provider: AiProvider.gemini),
  ];
}
