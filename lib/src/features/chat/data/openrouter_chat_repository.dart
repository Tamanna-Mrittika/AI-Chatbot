import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/sse_transformer.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import 'openrouter_request.dart';
import 'openrouter_response.dart';

/// [ChatRepository] backed by OpenRouter's OpenAI-compatible streaming API.
///
/// OpenRouter keeps long-running connections alive by sending SSE *comment*
/// lines (`: OPENROUTER PROCESSING`); the shared decoder drops those, so no
/// special handling is needed here.
class OpenRouterChatRepository implements ChatRepository {
  OpenRouterChatRepository({
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
        'No OpenRouter API key configured. Open Settings and paste a free key '
        'from openrouter.ai/keys.',
      );
    }

    final request =
        http.Request(
            'POST',
            Uri.parse('${AppConstants.openRouterBaseUrl}/chat/completions'),
          )
          ..headers.addAll(<String, String>{
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
            'Authorization': 'Bearer $apiKey',
            // Optional attribution headers OpenRouter uses for its rankings page.
            'HTTP-Referer': AppConstants.appSiteUrl,
            'X-Title': AppConstants.appName,
          })
          ..body = jsonEncode(
            OpenRouterRequest.build(
              history: history,
              model: model,
              systemPrompt: systemPrompt,
            ),
          );

    final http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } on Exception catch (error) {
      throw NetworkException(cause: error);
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw OpenRouterResponse.errorFor(response.statusCode, body);
    }

    yield* _decode(response.stream);
  }

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

      final chunk = OpenRouterResponse.parseChunk(json);
      if (chunk.text.isNotEmpty) yield chunk.text;

      if (chunk.isBlocked) {
        throw const ContentBlockedException('content filter');
      }
      if (chunk.finishReason != null) return;
    }
  }
}
