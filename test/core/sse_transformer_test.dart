import 'dart:convert';

import 'package:ai_chatbot/src/core/network/sse_transformer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Feeds [chunks] as raw byte chunks and collects the decoded event data.
  Future<List<String>> decode(List<String> chunks) async {
    final bytes = Stream.fromIterable(chunks.map(utf8.encode));
    return decodeSseBytes(bytes).map((event) => event.data).toList();
  }

  group('decodeSseBytes', () {
    test('decodes one event per blank-line-terminated block', () async {
      final events = await decode(['data: a\n\ndata: b\n\n']);
      expect(events, ['a', 'b']);
    });

    test('joins consecutive data lines with a newline', () async {
      final events = await decode(['data: line1\ndata: line2\n\n']);
      expect(events, ['line1\nline2']);
    });

    test('reassembles an event split across byte chunks', () async {
      // The JSON payload is cut mid-token, as a real socket would.
      final events = await decode(['data: {"te', 'xt":"hi"}\n', '\n']);
      expect(events, ['{"text":"hi"}']);
    });

    test('ignores comment keep-alive lines', () async {
      final events = await decode([
        ': OPENROUTER PROCESSING\n\n',
        'data: real\n\n',
      ]);
      expect(events, ['real']);
    });

    test('strips exactly one leading space from the value', () async {
      final events = await decode(['data:  padded\n\n']);
      expect(events, [' padded']);
    });

    test(
      'emits a trailing event when the stream closes without a blank line',
      () async {
        final events = await decode(['data: last\n']);
        expect(events, ['last']);
      },
    );

    test('flags the [DONE] sentinel', () async {
      final events = await decodeSseBytes(
        Stream.value(utf8.encode('data: [DONE]\n\n')),
      ).toList();
      expect(events.single.isDone, isTrue);
    });

    test('parses event and id fields alongside data', () async {
      final events = await decodeSseBytes(
        Stream.value(utf8.encode('id: 7\nevent: ping\ndata: x\n\n')),
      ).toList();
      expect(events.single.event, 'ping');
      expect(events.single.id, '7');
      expect(events.single.data, 'x');
    });

    test('does not emit an event for a data-less block', () async {
      final events = await decode(['event: ping\n\n', 'data: x\n\n']);
      expect(events, ['x']);
    });
  });
}
