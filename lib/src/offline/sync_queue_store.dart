import 'queue_store.dart';

abstract class SyncQueueStore {
  List<QueuedRequest> peekAllSync();
}