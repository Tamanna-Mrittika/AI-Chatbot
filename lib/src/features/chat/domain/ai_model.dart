import 'ai_provider.dart';

/// A model the user can pick in Settings.
///
/// Gemini models are a hard-coded list (the API has no public catalogue
/// endpoint); OpenRouter models are fetched live and filtered down to the ones
/// that cost nothing to call.
class AiModel {
  const AiModel({
    required this.id,
    required this.name,
    required this.provider,
    this.contextLength,
    this.isFree = true,
  });

  /// Wire identifier, e.g. `deepseek/deepseek-chat-v3.1:free`.
  final String id;

  /// Human readable name, e.g. `DeepSeek V3.1 (free)`.
  final String name;

  final AiProvider provider;

  /// Context window in tokens, when the provider reports it.
  final int? contextLength;

  /// Whether calling this model costs nothing.
  final bool isFree;

  /// `128K`-style label for the model tile subtitle.
  String? get contextLabel {
    final tokens = contextLength;
    if (tokens == null || tokens <= 0) return null;
    if (tokens >= 1000000) {
      return '${(tokens / 1000000).toStringAsFixed(tokens % 1000000 == 0 ? 0 : 1)}M context';
    }
    if (tokens >= 1000) return '${(tokens / 1000).round()}K context';
    return '$tokens context';
  }

  factory AiModel.fromOpenRouterJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] as Map<String, dynamic>? ?? const {};
    return AiModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      provider: AiProvider.openRouter,
      contextLength: (json['context_length'] as num?)?.toInt(),
      isFree: _isZero(pricing['prompt']) && _isZero(pricing['completion']),
    );
  }

  /// Pricing arrives as a decimal *string* such as `"0"` or `"0.0000001"`.
  static bool _isZero(Object? price) {
    if (price == null) return false;
    return (double.tryParse(price.toString()) ?? 1) == 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AiModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
