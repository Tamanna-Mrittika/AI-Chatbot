import '../../../core/errors/app_exception.dart';

/// One decoded chunk of an OpenRouter `chat.completion.chunk` stream.
class OpenRouterChunk {
  const OpenRouterChunk({required this.text, this.finishReason});

  final String text;

  /// `stop`, `length`, `content_filter`… when the turn ended on this chunk.
  final String? finishReason;

  bool get isBlocked => finishReason == 'content_filter';
}

/// Parses OpenRouter streaming payloads.
abstract final class OpenRouterResponse {
  static OpenRouterChunk parseChunk(Map<String, dynamic> json) {
    final error = json['error'];
    if (error is Map<String, dynamic>) {
      throw _exceptionFor(
        (error['code'] as num?)?.toInt(),
        error['message'] as String? ?? 'OpenRouter returned an error.',
      );
    }

    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) {
      return const OpenRouterChunk(text: '');
    }

    final choice = choices.first as Map<String, dynamic>;
    final delta = choice['delta'] as Map<String, dynamic>? ?? const {};

    // `content` is null on the first chunk (which only carries the role) and on
    // the final chunk (which only carries finish_reason).
    final content = delta['content'];
    return OpenRouterChunk(
      text: content is String ? content : '',
      finishReason: choice['finish_reason'] as String?,
    );
  }

  /// Turns a non-200 response body into the most specific exception available.
  static AppException errorFor(int statusCode, String body) =>
      _exceptionFor(statusCode, _messageFrom(body));

  static AppException _exceptionFor(int? code, String message) {
    return switch (code) {
      401 || 403 => const AuthException(
        'Your OpenRouter API key was rejected. Open Settings and paste a '
        'valid key from openrouter.ai/keys.',
      ),
      402 => const ApiException(
        'This model needs credits. Pick a model tagged "free" in Settings.',
        statusCode: 402,
      ),
      429 => const RateLimitException(),
      _ => ApiException(
        message.isEmpty
            ? 'OpenRouter request failed with status $code.'
            : message,
        statusCode: code,
      ),
    };
  }

  static String _messageFrom(String body) {
    final match = RegExp(r'"message"\s*:\s*"((?:[^"\\]|\\.)*)"')
        .firstMatch(body);
    return match?.group(1)?.replaceAll(r'\"', '"') ?? '';
  }
}
