/// Stores cached response payloads for offline `GET` fallbacks.
abstract class CacheStore {
  /// Saves [value] under [key].
  Future<void> put(String key, Object? value);

  /// Retrieves a previously cached value for [key].
  Future<Object?> get(String key);

  /// Removes the cached value for [key].
  Future<void> remove(String key);

  /// Removes all cached values.
  Future<void> clear();
}

/// In-memory [CacheStore] implementation.
///
/// This store is process-local and is cleared when the app restarts.
class MemoryCacheStore implements CacheStore {
  final Map<String, Object?> _mem = {};

  @override

  /// Saves [value] under [key] in memory.
  Future<void> put(String key, Object? value) async {
    _mem[key] = value;
  }

  @override

  /// Reads a value from memory.
  Future<Object?> get(String key) async => _mem[key];

  @override

  /// Removes a value from memory.
  Future<void> remove(String key) async {
    _mem.remove(key);
  }

  @override

  /// Clears all in-memory values.
  Future<void> clear() async {
    _mem.clear();
  }
}
