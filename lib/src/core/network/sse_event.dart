/// A single decoded Server-Sent Event.
///
/// Only the fields the Gemini streaming endpoint actually emits are modelled;
/// `id` and `retry` are parsed but unused so the decoder stays spec-correct.
class SseEvent {
  const SseEvent({required this.data, this.event, this.id});

  /// Concatenated `data:` lines, newline separated, without the field prefix.
  final String data;

  /// Optional `event:` field. Gemini never sets it, but the spec allows it.
  final String? event;

  /// Optional `id:` field.
  final String? id;

  /// Whether this event carries the conventional end-of-stream sentinel.
  bool get isDone => data == '[DONE]';

  @override
  String toString() => 'SseEvent(event: $event, data: $data)';
}
