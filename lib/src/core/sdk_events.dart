import 'dart:async';

enum SdkEvent {
  sessionExpired,
  signedOut, // ✅ Step 4.5
}

class SdkEvents {
  final _controller = StreamController<SdkEvent>.broadcast(sync: true);

  Stream<SdkEvent> get stream => _controller.stream;

  void emit(SdkEvent e) => _controller.add(e);

  void dispose() => _controller.close();
}