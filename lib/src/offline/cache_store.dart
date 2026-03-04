abstract class CacheStore {
  Future<void> put(String key, Object? value);
  Future<Object?> get(String key);
  Future<void> clear();
}

class MemoryCacheStore implements CacheStore {
  final _m = <String, Object?>{};
  @override
  Future<void> put(String key, Object? value) async => _m[key] = value;
  @override
  Future<Object?> get(String key) async => _m[key];
  @override
  Future<void> clear() async => _m.clear();
}