import 'token_store.dart';

/// Executes a token refresh using the current stored [TokenPair].
typedef RefreshExecutor = Future<TokenPair?> Function(TokenPair current);

/// Manages token caching, persistence, and single-flight refreshes.
///
/// This class backs the higher-level auth API and the automatic 401 retry flow
/// used by the SDK request layer.
class AuthManager {
  /// Creates an authentication manager backed by [_store].
  AuthManager(this._store);

  final TokenStore _store;

  TokenPair? _cached;
  Future<TokenPair?>? _loadFuture;
  Future<TokenPair?>? _refreshFuture;

  /// Loads tokens from memory or storage.
  ///
  /// The first call reads from [TokenStore.read] and caches the result. Later
  /// calls reuse the cached value.
  Future<TokenPair?> load() {
    if (_cached != null) return Future.value(_cached);

    _loadFuture ??= _store.read().then((t) {
      _cached = t;
      return t;
    });

    return _loadFuture!;
  }

  /// Saves tokens to memory and persistent storage.
  Future<void> save(TokenPair tokens, {required bool rememberMe}) async {
    _cached = tokens;
    _loadFuture = Future.value(tokens); // keep single-flight consistent
    await _store.save(tokens, rememberMe: rememberMe);
  }

  /// Clears the in-memory cache and the underlying [TokenStore].
  Future<void> clear() async {
    _cached = null;
    _loadFuture = Future.value(null);
    await _store.clear();
  }

  /// Runs a refresh operation while ensuring only one refresh is in flight.
  ///
  /// Concurrent callers await the same refresh future. When [executor]
  /// succeeds, the new tokens are saved with `rememberMe: true`.
  Future<TokenPair?> refreshSingleFlight(RefreshExecutor executor) {
    _refreshFuture ??= load().then((current) {
      if (current == null) return null;
      return executor(current);
    }).then((pair) async {
      if (pair != null) {
        await save(pair, rememberMe: true);
      }
      return pair;
    }).whenComplete(() {
      _refreshFuture = null;
    });

    return _refreshFuture!;
  }
}
