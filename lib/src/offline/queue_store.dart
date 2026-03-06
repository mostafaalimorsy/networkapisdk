import '../http/http_client.dart';
import 'sync_queue_store.dart';

class QueuedRequest {
  final HttpRequest request;
  const QueuedRequest(this.request);
}

abstract class QueueStore {
  Future<void> enqueue(QueuedRequest r);
  Future<List<QueuedRequest>> peekAll();
  Future<void> removeAt(int index);
  Future<void> clear();
}

class MemoryQueueStore implements QueueStore, SyncQueueStore {
  final _q = <QueuedRequest>[];

  @override
  Future<void> enqueue(QueuedRequest r) {
    _q.add(r);
    return Future.value();
  }

  @override
  Future<List<QueuedRequest>> peekAll() => Future.value(List.unmodifiable(_q));

  @override
  List<QueuedRequest> peekAllSync() => List.unmodifiable(_q);

  @override
  Future<void> removeAt(int index) {
    _q.removeAt(index);
    return Future.value();
  }

  @override
  Future<void> clear() {
    _q.clear();
    return Future.value();
  }
}