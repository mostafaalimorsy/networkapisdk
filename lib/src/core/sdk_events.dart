import 'dart:async';

/// SDK lifecycle events emitted through [SdkEvents].
enum SdkEvent {
  /// Emitted after a protected request cannot recover from a `401` response.
  sessionExpired,

  /// Emitted after the session is explicitly cleared through a sign-out call.
  signedOut,
}

/// Broadcasts SDK lifecycle events to listeners.
class SdkEvents {
  final _controller = StreamController<SdkEvent>.broadcast(sync: true);

  /// A broadcast stream of [SdkEvent] values.
  Stream<SdkEvent> get stream => _controller.stream;

  /// Emits [e] to current listeners.
  void emit(SdkEvent e) => _controller.add(e);

  /// Closes the underlying stream controller.
  void dispose() => _controller.close();
}
