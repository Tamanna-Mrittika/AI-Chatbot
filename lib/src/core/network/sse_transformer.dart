import 'dart:async';
import 'dart:convert';

import 'sse_event.dart';

/// Decodes a line-oriented Server-Sent Events stream into [SseEvent]s.
///
/// Implements the dispatch rules from the WHATWG SSE specification that matter
/// for a JSON streaming API:
///
/// * lines beginning with `:` are comments and are ignored (they are also used
///   as keep-alive pings by some proxies);
/// * `field: value` splits on the *first* colon, and a single leading space in
///   the value is stripped;
/// * consecutive `data:` lines are joined with `\n`;
/// * a blank line dispatches the buffered event.
///
/// Feed it a `Stream<String>` of complete lines — see [decodeSseBytes], which
/// wires up the UTF-8 and line splitting for you.
class SseTransformer extends StreamTransformerBase<String, SseEvent> {
  const SseTransformer();

  @override
  Stream<SseEvent> bind(Stream<String> stream) {
    final dataLines = <String>[];
    String? eventName;
    String? lastId;

    void reset() {
      dataLines.clear();
      eventName = null;
    }

    return Stream<SseEvent>.eventTransformed(
      stream,
      (EventSink<SseEvent> sink) => _SseSink(
        sink,
        onLine: (String line) {
          // A blank line terminates the current event.
          if (line.isEmpty) {
            if (dataLines.isNotEmpty) {
              sink.add(
                SseEvent(
                  data: dataLines.join('\n'),
                  event: eventName,
                  id: lastId,
                ),
              );
            }
            reset();
            return;
          }

          if (line.startsWith(':')) return; // comment / keep-alive

          final colon = line.indexOf(':');
          final String field;
          String value;
          if (colon == -1) {
            field = line;
            value = '';
          } else {
            field = line.substring(0, colon);
            value = line.substring(colon + 1);
            if (value.startsWith(' ')) value = value.substring(1);
          }

          switch (field) {
            case 'data':
              dataLines.add(value);
            case 'event':
              eventName = value;
            case 'id':
              lastId = value;
            case 'retry':
              break; // reconnection is handled by the caller, not here
          }
        },
        onFlush: () {
          // Some servers close without a trailing blank line.
          if (dataLines.isNotEmpty) {
            sink.add(
              SseEvent(
                data: dataLines.join('\n'),
                event: eventName,
                id: lastId,
              ),
            );
            reset();
          }
        },
      ),
    );
  }
}

class _SseSink implements EventSink<String> {
  _SseSink(this._out, {required this.onLine, required this.onFlush});

  final EventSink<SseEvent> _out;
  final void Function(String line) onLine;
  final void Function() onFlush;

  @override
  void add(String line) => onLine(line);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _out.addError(error, stackTrace);

  @override
  void close() {
    onFlush();
    _out.close();
  }
}

/// Convenience wrapper: raw response bytes in, [SseEvent]s out.
///
/// Uses `Converter.bind` rather than `Stream.transform` because the incoming
/// stream is typically `Stream<Uint8List>`, which does not satisfy
/// `StreamTransformer<List<int>, String>`.
Stream<SseEvent> decodeSseBytes(Stream<List<int>> bytes) =>
    const Utf8Decoder(allowMalformed: true)
        .bind(bytes)
        .transform(const LineSplitter())
        .transform(const SseTransformer());
