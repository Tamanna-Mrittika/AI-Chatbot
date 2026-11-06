import '../../../core/errors/app_exception.dart';

/// One decoded chunk of a `streamGenerateContent` response.
class GeminiChunk {
  const GeminiChunk({required this.text, this.finishReason});

  /// Concatenated visible text of this chunk; empty for metadata-only chunks.
  final String text;

  /// `STOP`, `MAX_TOKENS`, `SAFETY`, `RECITATION`… when the turn ended here.
  final String? finishReason;

  bool get isBlocked =>
      finishReason == 'SAFETY' || finishReason == 'RECITATION';
}

/// Parses Gemini streaming payloads.
abstract final class GeminiResponse {
  /// Converts one decoded SSE `data:` object into a [GeminiChunk].
  ///
  /// Throws [ContentBlockedException] when the prompt itself was rejected, and
  /// [ApiException] when the payload carries an `error` object (the API sends
  /// these inline rather than closing the stream).
  static GeminiChunk parseChunk(Map<String, dynamic> json) {
    final error = json['error'];
    if (error is Map<String, dynamic>) {
      throw ApiException(
        error['message'] as String? ?? 'Gemini returned an error.',
        statusCode: error['code'] as int?,
      );
    }

    final promptFeedback = json['promptFeedback'];
    if (promptFeedback is Map<String, dynamic>) {
      final blockReason = promptFeedback['blockReason'] as String?;
      if (blockReason != null) throw ContentBlockedException(blockReason);
    }

    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return const GeminiChunk(text: '');
    }

    final candidate = candidates.first as Map<String, dynamic>;
    return GeminiChunk(
      text: _textOf(candidate['content']),
      finishReason: candidate['finishReason'] as String?,
    );
  }

  /// Extracts user-visible text from a `content` object.
  ///
  /// Parts flagged `thought: true` are the model's internal reasoning summary
  /// and are deliberately skipped — rendering them would leak scratch work into
  /// the conversation.
  static String _textOf(Object? content) {
    if (content is! Map<String, dynamic>) return '';
    final parts = content['parts'];
    if (parts is! List) return '';

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is! Map<String, dynamic>) continue;
      if (part['thought'] == true) continue;
      final text = part['text'];
      if (text is String) buffer.write(text);
    }
    return buffer.toString();
  }

  /// Turns a non-200 response body into the most specific exception available.
  static AppException errorFor(int statusCode, String body) {
    final message = _messageFrom(body);
    return switch (statusCode) {
      400 when message.toLowerCase().contains('api key') =>
        const AuthException(),
      401 || 403 => const AuthException(),
      429 => const RateLimitException(),
      _ => ApiException(
        message.isEmpty
            ? 'Gemini request failed with status $statusCode.'
            : message,
        statusCode: statusCode,
      ),
    };
  }

  static String _messageFrom(String body) {
    // The body is JSON in practice, but never trust that on an error path.
    final match = RegExp(r'"message"\s*:\s*"((?:[^"\\]|\\.)*)"')
        .firstMatch(body);
    return match?.group(1)?.replaceAll(r'\"', '"') ?? '';
  }
}
