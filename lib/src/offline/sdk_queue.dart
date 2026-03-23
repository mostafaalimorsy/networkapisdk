import 'queue_store.dart';
import 'sync_queue_store.dart';
import '../core/sdk.dart';

/// Flushes queued requests stored for offline delivery.
///
/// Access this API through [Sdk.instance.queue].
class SdkQueue {
  final Sdk _sdk;
  final QueueStore _store;

  SdkQueue._(this._sdk, this._store);

  /// Internal factory used by [Sdk].
  factory SdkQueue.internal(Sdk sdk, QueueStore store) =>
      SdkQueue._(sdk, store);

  /// Sends queued requests in FIFO order until one fails.
  ///
  /// This method uses [Sdk.http] directly, so it does not re-run the higher
  /// level [SdkCall] pipeline for auth attachment, contract evaluation,
  /// interceptors, caching, or re-queueing. Only requests that receive a `2xx`
  /// status are removed. The returned value is the number of flushed items.
  ///
  /// ```dart
  /// final flushed = await Sdk.instance.queue.flush();
  /// ```
  Future<int> flush() async {
    var flushed = 0;

    while (true) {
      final items = _store is SyncQueueStore
          ? (_store as SyncQueueStore).peekAllSync()
          : await _store.peekAll();

      if (items.isEmpty) break;

      final qr = items.first;

      try {
        final res = await _sdk.http.send(qr.request);
        final status = res.statusCode ?? 0;

        if (status >= 200 && status < 300) {
          await _store.removeAt(0);
          flushed++;
          continue;
        }

        break;
      } catch (_) {
        break;
      }
    }

    return flushed;
  }
}
