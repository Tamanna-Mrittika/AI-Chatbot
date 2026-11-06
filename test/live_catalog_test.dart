// ignore_for_file: avoid_print
@Tags(['live'])
library;

import 'package:ai_chatbot/src/core/constants/app_constants.dart';
import 'package:ai_chatbot/src/features/chat/data/gemini_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Proves the model picker shows Google's *current* catalogue rather than a
/// hardcoded list that silently rots.
void main() {
  test('fetches the live Gemini catalogue', () async {
    final client = http.Client();
    addTearDown(client.close);

    final models = await GeminiCatalog.fetch(
      client,
      AppConstants.buildTimeGeminiKey,
    );
    final ids = models.map((m) => m.id).toList();

    print('models offered in the picker: ${models.length}');
    for (final m in models.take(6)) {
      print('  ${m.id}  (${m.name})  ${m.contextLabel ?? ""}');
    }

    expect(models, isNotEmpty);

    // The default must be offered, or the picker and the default disagree.
    expect(
      ids,
      contains(AppConstants.defaultGeminiModel),
      reason: 'default Gemini model missing from the live catalogue',
    );

    // `-latest` aliases sort first so the safe choices are easiest to reach.
    expect(ids.first, endsWith('-latest'));

    // Non-chat modalities and specialised agent endpoints are filtered out.
    for (final banned in [
      'tts',
      'embedding',
      'imagen',
      'computer-use',
      'deep-research',
      'antigravity',
    ]) {
      expect(
        ids.where((id) => id.contains(banned)),
        isEmpty,
        reason: '"$banned" models should not be offered as chat models',
      );
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}
