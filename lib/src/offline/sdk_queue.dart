import 'queue_store.dart';
import '../core/sdk.dart';

class SdkQueue {
  final Sdk _sdk;
  final QueueStore _store;

  SdkQueue._(this._sdk, this._store);

  factory SdkQueue.internal(Sdk sdk, QueueStore store) => SdkQueue._(sdk, store);

  QueueStore get store => _store;

  /// Flush queued requests to the network.
  /// Returns how many requests were successfully sent and removed from the queue.
  Future<int> flush() async {
    var flushed = 0;

    while (true) {
      final items = await _store.peekAll();
      if (items.isEmpty) break;

      final next = items.first;

      try {
        // Use the SDK http client to send the queued request.
        final res = await _sdk.http.send(next.request);

        // Consider 2xx as success; remove it from the queue.
        final code = res.statusCode ?? 0;
        if (code >= 200 && code < 300) {
          await _store.removeAt(0);
          flushed++;
          continue;
        }

        // Non-2xx: stop flushing to preserve order.
        break;
      } catch (_) {
        // Network/other failure: stop flushing to retry later.
        break;
      }
    }

    return flushed;
  }
}