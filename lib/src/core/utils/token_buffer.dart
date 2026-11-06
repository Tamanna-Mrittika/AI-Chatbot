import 'dart:async';

/// Coalesces high-frequency stream deltas into periodic flushes.
///
/// A fast model emits tokens far quicker than the display can refresh.
/// Rebuilding the widget tree on every single one wastes frames, so deltas are
/// accumulated and handed to [onFlush] at most once per [interval] — plus an
/// immediate final flush when the stream ends.
class TokenBuffer {
  TokenBuffer({
    required this.onFlush,
    this.interval = const Duration(milliseconds: 50),
  });

  /// Receives the full accumulated text so far.
  final void Function(String text) onFlush;

  final Duration interval;

  final StringBuffer _buffer = StringBuffer();
  Timer? _timer;
  bool _isDisposed = false;

  /// Text accumulated so far, including deltas not yet flushed.
  String get text => _buffer.toString();

  /// Adds a delta and schedules a flush if one is not already pending.
  void add(String delta) {
    if (_isDisposed) return;
    _buffer.write(delta);
    _timer ??= Timer(interval, () {
      _timer = null;
      if (!_isDisposed) onFlush(text);
    });
  }

  /// Emits everything immediately and cancels any pending flush.
  void flush() {
    _timer?.cancel();
    _timer = null;
    if (!_isDisposed) onFlush(text);
  }

  /// Stops all further callbacks; safe to call more than once.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _isDisposed = true;
  }
}
