import '../../../core/constants/app_constants.dart';
import '../domain/chat_message.dart';
import '../domain/message_role.dart';

/// Builds the OpenAI-compatible body for `POST /chat/completions`.
abstract final class OpenRouterRequest {
  static Map<String, dynamic> build({
    required List<ChatMessage> history,
    required String model,
    required String systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) {
    return <String, dynamic>{
      'model': model,
      // OpenRouter tries these in order when the primary is unavailable,
      // which turns a provider-side 429 into a slightly different model
      // rather than a visible failure. The primary always wins when it is
      // healthy, so an explicitly chosen model is still honoured.
      'models': _fallbackChain(model),
      'stream': true,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'messages': <Map<String, String>>[
        if (systemPrompt.trim().isNotEmpty)
          {'role': 'system', 'content': systemPrompt.trim()},
        for (final message in _trim(history))
          {'role': _role(message), 'content': message.text},
      ],
    };
  }

  /// Builds the <=3 entry fallback list OpenRouter accepts.
  ///
  /// The chosen model goes first so it is always preferred; the rest are
  /// vetted free chat models used only if it is unavailable.
  static List<String> _fallbackChain(String model) {
    final chain = <String>[
      model,
      for (final id in AppConstants.openRouterFallbackChain)
        if (id != model) id,
    ];
    return chain.take(3).toList(growable: false);
  }

  /// OpenAI schema uses `assistant`, not Gemini's `model`.
  static String _role(ChatMessage message) =>
      message.role == MessageRole.user ? 'user' : 'assistant';

  /// Drops blank placeholders and caps the replayed context window.
  static List<ChatMessage> _trim(List<ChatMessage> history) {
    final nonEmpty = history
        .where((message) => message.text.trim().isNotEmpty)
        .toList(growable: false);

    return nonEmpty.length > AppConstants.historyWindow
        ? nonEmpty.sublist(nonEmpty.length - AppConstants.historyWindow)
        : nonEmpty;
  }
}
