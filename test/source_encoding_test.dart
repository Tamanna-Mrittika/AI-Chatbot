import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against UTF-8 double-encoding in the source tree.
///
/// Editing a file with a tool that reads UTF-8 bytes as Latin-1 and writes
/// them back turns `…` into `â€¦` and `—` into `â€”`. The code still compiles,
/// so nothing fails until the mangled string shows up on screen — which is
/// exactly how the composer once shipped a `Messageâ€¦` placeholder.
void main() {
  test('no Dart source contains double-encoded UTF-8', () {
    // Sequences that only appear when UTF-8 has been decoded as Latin-1.
    final mojibake = RegExp(r'Ã¢â‚¬|â€|Ã‚Â|Ã¢â€');

    final offenders = <String>[];
    for (final dir in ['lib', 'test']) {
      final directory = Directory(dir);
      if (!directory.existsSync()) continue;

      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        // Skip this file: it necessarily contains the patterns it looks for.
        if (entity.path.endsWith('source_encoding_test.dart')) continue;

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (mojibake.hasMatch(lines[i])) {
            offenders.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Mangled characters found — re-save these files as UTF-8:\n'
          '${offenders.join('\n')}',
    );
  });
}
