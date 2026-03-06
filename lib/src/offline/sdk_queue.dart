import 'queue_store.dart';
import 'sync_queue_store.dart';
import '../core/sdk.dart';

class SdkQueue {
  final Sdk _sdk;
  final QueueStore _store;

  SdkQueue._(this._sdk, this._store);

  factory SdkQueue.internal(Sdk sdk, QueueStore store) => SdkQueue._(sdk, store);

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