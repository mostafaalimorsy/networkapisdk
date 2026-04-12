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
  bool _rememberMe = false;

  /// Whether the current session should also be persisted across app restarts.
  bool get rememberMe => _rememberMe;

  /// Loads tokens from memory or storage.
  ///
  /// The first call reads from [TokenStore.read] and caches the result. Later
  /// calls reuse the cached value.
  Future<TokenPair?> load() {
    if (_cached != null) return Future.value(_cached);

    _loadFuture ??= _store.read().then((tokens) {
      _cached = tokens;
      _rememberMe = tokens != null;
      return tokens;
    });

    return _loadFuture!;
  }

  /// Saves tokens to memory for the current session and persists them only
  /// when [rememberMe] is `true`.
  Future<void> save(TokenPair tokens, {required bool rememberMe}) async {
    _cached = tokens;
    _rememberMe = rememberMe;
    _loadFuture = Future.value(tokens); // keep single-flight consistent

    if (rememberMe) {
      await _store.save(tokens, rememberMe: true);
    } else {
      await _store.clear();
    }
  }

  /// Clears the in-memory cache and the underlying [TokenStore].
  Future<void> clear() async {
    _cached = null;
    _rememberMe = false;
    _loadFuture = Future.value(null);
    await _store.clear();
  }

  /// Runs a refresh operation while ensuring only one refresh is in flight.
  ///
  /// Concurrent callers await the same refresh future. When [executor]
  /// succeeds, the new tokens keep the current session persistence mode.
  Future<TokenPair?> refreshSingleFlight(RefreshExecutor executor) {
    _refreshFuture ??= load().then((current) {
      if (current == null) return null;
      return executor(current);
    }).then((pair) async {
      if (pair != null) {
        await save(pair, rememberMe: _rememberMe);
      }
      return pair;
    }).whenComplete(() {
      _refreshFuture = null;
    });

    return _refreshFuture!;
  }
}
