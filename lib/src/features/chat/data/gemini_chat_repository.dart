import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/sse_transformer.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import 'gemini_request.dart';
import 'gemini_response.dart';

/// [ChatRepository] talking to the Google Generative Language REST API over
/// Server-Sent Events (`?alt=sse`).
///
/// The API key is supplied lazily through [apiKeyReader] rather than captured
/// at construction, so changing it in Settings takes effect on the next message
/// without rebuilding the repository.
class GeminiChatRepository implements ChatRepository {
  GeminiChatRepository({
    required http.Client client,
    required String Function() apiKeyReader,
    // Named parameters cannot be private initialising formals, hence the
    // explicit assignment.
    // ignore: prefer_initializing_formals
  }) : _client = client,
       _apiKey = apiKeyReader;

  final http.Client _client;
  final String Function() _apiKey;

  @override
  Stream<String> streamReply({
    required List<ChatMessage> history,
    required String model,
    required String systemPrompt,
  }) async* {
    final apiKey = _apiKey().trim();
    if (apiKey.isEmpty) {
      throw const AuthException(
        'No Gemini API key configured. Open Settings and paste a key from '
        'aistudio.google.com/apikey.',
      );
    }

    final request =
        http.Request(
            'POST',
            Uri.parse(
              '${AppConstants.geminiBaseUrl}/models/$model:streamGenerateContent'
              '?alt=sse',
            ),
          )
          ..headers.addAll(<String, String>{
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
            // Passing the key as a header rather than a query parameter keeps it
            // out of proxy and server access logs.
            'x-goog-api-key': apiKey,
          })
          ..body = jsonEncode(
            GeminiRequest.build(history: history, systemPrompt: systemPrompt),
          );

    final http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } on http.ClientException catch (error) {
      throw NetworkException(cause: error);
    } on Exception catch (error) {
      throw NetworkException(cause: error);
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw GeminiResponse.errorFor(response.statusCode, body);
    }

    yield* _decode(response.stream);
  }

  /// Decodes the SSE body into text deltas, aborting if the server stalls.
  Stream<String> _decode(Stream<List<int>> body) async* {
    final events = decodeSseBytes(body).timeout(
      AppConstants.streamIdleTimeout,
      onTimeout: (sink) => sink.addError(const NetworkException()),
    );

    await for (final event in events) {
      if (event.isDone) return;

      final Map<String, dynamic> json;
      try {
        json = jsonDecode(event.data) as Map<String, dynamic>;
      } on FormatException catch (error) {
        throw ParseException(cause: error);
      } on TypeError catch (error) {
        throw ParseException(cause: error);
      }

      final chunk = GeminiResponse.parseChunk(json);
      if (chunk.text.isNotEmpty) yield chunk.text;

      if (chunk.isBlocked) {
        throw ContentBlockedException(chunk.finishReason!);
      }
      if (chunk.finishReason != null) return;
    }
  }
}
