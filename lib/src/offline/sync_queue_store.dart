import 'queue_store.dart';

/// Optional synchronous queue access used by queue flushing.
///
/// Implement this when the queue can be inspected without awaiting I/O.
abstract class SyncQueueStore {
  /// Returns a synchronous snapshot of the queued requests.
  List<QueuedRequest> peekAllSync();
}
