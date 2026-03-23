import 'dart:convert';
import 'dart:io';

import 'cache_store.dart';

/// File-backed [CacheStore] implementation.
///
/// Values are stored as a single JSON map in [_file]. Missing, invalid, or
/// unreadable files are treated as an empty cache.
class FileCacheStore implements CacheStore {
  final File _file;

  /// Creates a cache store backed by [_file].
  FileCacheStore(this._file);

  @override

  /// Saves [value] under [key] and rewrites the backing file.
  Future<void> put(String key, Object? value) async {
    final map = await _readAll();
    map[key] = value;
    await _writeAll(map);
  }

  @override

  /// Reads the cached value for [key].
  Future<Object?> get(String key) async {
    final map = await _readAll();
    return map[key];
  }

  @override

  /// Removes [key] from the cache file.
  Future<void> remove(String key) async {
    final map = await _readAll();
    map.remove(key);
    await _writeAll(map);
  }

  @override

  /// Clears the cache file.
  Future<void> clear() async {
    await _writeAll(<String, dynamic>{});
  }

  Future<Map<String, dynamic>> _readAll() async {
    try {
      if (!await _file.exists()) return <String, dynamic>{};
      final raw = await _file.readAsString();
      if (raw.trim().isEmpty) return <String, dynamic>{};

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, dynamic>{};

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _writeAll(Map<String, dynamic> map) async {
    try {
      final dir = _file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await _file.writeAsString(jsonEncode(map), flush: true);
    } catch (_) {}
  }
}
