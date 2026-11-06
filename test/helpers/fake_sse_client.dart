import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// An [http.Client] that replays a canned SSE body.
///
/// Using a real `StreamedResponse` (rather than mocking the repository) keeps
/// the SSE decoding, status handling and cancellation paths under test.
class FakeSseClient extends http.BaseClient {
  FakeSseClient({
    required this.chunks,
    this.statusCode = 200,
    this.errorBody = '',
    this.chunkDelay = Duration.zero,
  });

  /// Raw SSE text chunks, delivered in order.
  final List<String> chunks;
  final int statusCode;
  final String errorBody;
  final Duration chunkDelay;

  /// The last request body sent, decoded, so tests can assert the wire format.
  Map<String, dynamic>? lastBody;

  /// Headers of the last request.
  Map<String, String> lastHeaders = const {};

  /// Set when the caller cancels the response subscription.
  bool wasCancelled = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastHeaders = Map.of(request.headers);
    if (request is http.Request && request.body.isNotEmpty) {
      lastBody = jsonDecode(request.body) as Map<String, dynamic>;
    }

    if (statusCode != 200) {
      return http.StreamedResponse(
        Stream.value(utf8.encode(errorBody)),
        statusCode,
      );
    }

    final controller = StreamController<List<int>>();
    controller.onCancel = () => wasCancelled = true;
    controller.onListen = () async {
      for (final chunk in chunks) {
        if (controller.isClosed) return;
        if (chunkDelay > Duration.zero) await Future<void>.delayed(chunkDelay);
        if (controller.isClosed) return;
        controller.add(utf8.encode(chunk));
      }
      await controller.close();
    };

    return http.StreamedResponse(controller.stream, 200);
  }
}

/// Wraps [payloads] as `data:` frames terminated by a blank line.
List<String> sseFrames(List<String> payloads) => [
  for (final payload in payloads) 'data: $payload\n\n',
];
