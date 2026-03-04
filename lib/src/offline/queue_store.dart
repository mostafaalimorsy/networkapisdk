import '../http/http_client.dart';

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

class MemoryQueueStore implements QueueStore {
  final _q = <QueuedRequest>[];
  @override
  Future<void> enqueue(QueuedRequest r) async => _q.add(r);
  @override
  Future<List<QueuedRequest>> peekAll() async => List.unmodifiable(_q);
  @override
  Future<void> removeAt(int index) async => _q.removeAt(index);
  @override
  Future<void> clear() async => _q.clear();
}