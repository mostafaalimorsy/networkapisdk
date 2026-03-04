import 'token_store.dart';

typedef RefreshExecutor = Future<TokenPair?> Function(TokenPair current);

class AuthManager {
  AuthManager(this._store);

  final TokenStore _store;

  TokenPair? _cached;
  Future<TokenPair?>? _loadFuture;
  Future<TokenPair?>? _refreshFuture;

  /// Reads from storage once and caches.
  Future<TokenPair?> load() {
    if (_cached != null) return Future.value(_cached);

    _loadFuture ??= _store.read().then((t) {
      _cached = t;
      return t;
    });

    return _loadFuture!;
  }

  Future<void> save(TokenPair tokens, {required bool rememberMe}) async {
    _cached = tokens;
    _loadFuture = Future.value(tokens); // keep single-flight consistent
    await _store.save(tokens, rememberMe: rememberMe);
  }

  Future<void> clear() async {
    _cached = null;
    _loadFuture = Future.value(null);
    await _store.clear();
  }

  /// Ensures only one refresh runs at a time. Others await the same future.
  Future<TokenPair?> refreshSingleFlight(RefreshExecutor executor) {
    _refreshFuture ??= load()
        .then((current) {
      if (current == null) return null;
      return executor(current);
    })
        .then((pair) async {
      if (pair != null) {
        await save(pair, rememberMe: true);
      }
      return pair;
    })
        .whenComplete(() {
      _refreshFuture = null;
    });

    return _refreshFuture!;
  }
}