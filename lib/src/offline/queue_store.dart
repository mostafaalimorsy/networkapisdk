import '../http/http_client.dart';
import 'sync_queue_store.dart';

/// Wraps an [HttpRequest] for offline queue persistence.
class QueuedRequest {
  /// The queued transport request.
  final HttpRequest request;

  /// Creates a queued request wrapper.
  const QueuedRequest(this.request);
}

/// Persists write requests that should be flushed later.
abstract class QueueStore {
  /// Adds [r] to the end of the queue.
  Future<void> enqueue(QueuedRequest r);

  /// Returns the current queued requests without removing them.
  Future<List<QueuedRequest>> peekAll();

  /// Removes the queued item at [index].
  Future<void> removeAt(int index);

  /// Clears the queue.
  Future<void> clear();
}

/// In-memory [QueueStore] implementation.
///
/// This store keeps queued requests only for the lifetime of the current
/// process.
class MemoryQueueStore implements QueueStore, SyncQueueStore {
  final _q = <QueuedRequest>[];

  @override

  /// Adds a request to the in-memory queue.
  Future<void> enqueue(QueuedRequest r) {
    _q.add(r);
    return Future.value();
  }

  @override

  /// Returns an immutable snapshot of the queue.
  Future<List<QueuedRequest>> peekAll() => Future.value(List.unmodifiable(_q));

  @override

  /// Returns an immutable snapshot of the queue synchronously.
  List<QueuedRequest> peekAllSync() => List.unmodifiable(_q);

  @override

  /// Removes the item at [index].
  Future<void> removeAt(int index) {
    _q.removeAt(index);
    return Future.value();
  }

  @override

  /// Clears the queue.
  Future<void> clear() {
    _q.clear();
    return Future.value();
  }
}
