import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/ai_model.dart';
import '../domain/ai_provider.dart';
import 'gemini_catalog.dart';

/// Supplies the list of models the user can choose between.
///
/// OpenRouter's catalogue is public — no API key required — so the model
/// picker works before the user has pasted a key.
class ModelCatalogService {
  const ModelCatalogService(this._client, this._geminiKeyReader);

  final http.Client _client;

  /// Read lazily: the Gemini catalogue needs the key, and it can change in
  /// Settings between one picker opening and the next.
  final String Function() _geminiKeyReader;

  /// Models available for [provider], free ones first.
  Future<List<AiModel>> fetch(AiProvider provider) async {
    return switch (provider) {
      AiProvider.gemini => GeminiCatalog.fetch(_client, _geminiKeyReader()),
      AiProvider.openRouter => _openRouterCatalog(),
    };
  }

  Future<List<AiModel>> _openRouterCatalog() async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('${AppConstants.openRouterBaseUrl}/models'))
          .timeout(const Duration(seconds: 15));
    } on Exception {
      return _openRouterFallback();
    }

    if (response.statusCode != 200) return _openRouterFallback();

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as List<dynamic>;

      final models =
          data
              .cast<Map<String, dynamic>>()
              .map(AiModel.fromOpenRouterJson)
              .where((model) => model.isFree && _isChatModel(model.id))
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      return models.isEmpty ? _openRouterFallback() : models;
    } on Object catch (error) {
      // A catalogue we cannot parse must not block the chat: degrade to the
      // hard-coded list rather than surfacing an error.
      assert(() {
        // ignore: avoid_print
        print('Model catalogue parse failed: ${ParseException(cause: error)}');
        return true;
      }());
      return _openRouterFallback();
    }
  }

  /// Excludes models that cannot hold a conversation.
  ///
  /// The free pool is not curated: it contains a content-safety classifier
  /// (which answers every prompt with "User Safety: safe") and music
  /// generators. Offering those as chat models produces replies that look
  /// like the app is broken.
  static bool _isChatModel(String id) {
    const banned = [
      'content-safety',
      'guard',
      'moderation',
      'lyria',
      'tts',
      'whisper',
      'embed',
      'rerank',
    ];
    final lower = id.toLowerCase();
    return !banned.any(lower.contains);
  }

  List<AiModel> _openRouterFallback() => [
    for (final id in AppConstants.fallbackFreeModels)
      AiModel(id: id, name: _prettify(id), provider: AiProvider.openRouter),
  ];

  /// `meta-llama/llama-3.3-70b-instruct:free` → `Llama 3.3 70b instruct (free)`
  static String _prettify(String id) {
    final withoutVendor = id.split('/').last;
    final isFree = withoutVendor.endsWith(':free');
    final base = withoutVendor.replaceAll(':free', '').replaceAll('-', ' ');
    final capitalised = base.isEmpty
        ? base
        : base[0].toUpperCase() + base.substring(1);
    return isFree ? '$capitalised (free)' : capitalised;
  }
}
