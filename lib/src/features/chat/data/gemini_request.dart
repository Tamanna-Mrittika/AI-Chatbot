import '../../../core/constants/app_constants.dart';
import '../domain/chat_message.dart';

/// Builds the JSON body for `models/*:streamGenerateContent`.
///
/// Kept separate from the HTTP client so the wire format can be unit-tested
/// without touching the network.
abstract final class GeminiRequest {
  /// Maps domain messages onto the `contents` array Gemini expects.
  ///
  /// Three rules are enforced:
  /// 1. only the last [AppConstants.historyWindow] messages are sent;
  /// 2. empty messages (a placeholder that never received a token) are dropped,
  ///    because the API rejects parts with blank text;
  /// 3. the history must start with a `user` turn, so any leading assistant
  ///    messages left over from trimming are discarded.
  static Map<String, dynamic> build({
    required List<ChatMessage> history,
    required String systemPrompt,
    double temperature = 0.7,
    int maxOutputTokens = 2048,
  }) {
    final trimmed = _trim(history);

    return <String, dynamic>{
      'contents': [
        for (final message in trimmed)
          {
            'role': message.role.wireName,
            'parts': [
              {'text': message.text},
            ],
          },
      ],
      if (systemPrompt.trim().isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt.trim()},
          ],
        },
      'generationConfig': <String, dynamic>{
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
      },
    };
  }

  static List<ChatMessage> _trim(List<ChatMessage> history) {
    final nonEmpty = history
        .where((message) => message.text.trim().isNotEmpty)
        .toList(growable: false);

    final windowed = nonEmpty.length > AppConstants.historyWindow
        ? nonEmpty.sublist(nonEmpty.length - AppConstants.historyWindow)
        : nonEmpty;

    final firstUser = windowed.indexWhere((message) => message.isFromUser);
    if (firstUser <= 0) return windowed;
    return windowed.sublist(firstUser);
  }
}
