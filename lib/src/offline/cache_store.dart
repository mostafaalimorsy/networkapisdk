abstract class CacheStore {
  Future<void> put(String key, Object? value);
  Future<Object?> get(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

class MemoryCacheStore implements CacheStore {
  final Map<String, Object?> _mem = {};

  @override
  Future<void> put(String key, Object? value) async {
    _mem[key] = value;
  }

  @override
  Future<Object?> get(String key) async => _mem[key];

  @override
  Future<void> remove(String key) async {
    _mem.remove(key);
  }

  @override
  Future<void> clear() async {
    _mem.clear();
  }
}