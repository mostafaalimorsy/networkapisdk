import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_store.dart';

/// Stores SDK tokens in `flutter_secure_storage`.
///
/// The current implementation writes access and refresh tokens regardless of
/// the `rememberMe` value, and also stores that flag as a separate marker.
class SecureTokenStore implements TokenStore {
  static const _kAccess = 'sdk_access_token';
  static const _kRefresh = 'sdk_refresh_token';
  static const _kRemember = 'sdk_remember_me';

  final FlutterSecureStorage _storage;

  /// Creates a secure token store.
  ///
  /// Pass a custom [storage] to integrate with existing secure-storage setup or
  /// tests.
  const SecureTokenStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  @override

  /// Persists both tokens and records the `rememberMe` flag.
  Future<void> save(TokenPair tokens, {required bool rememberMe}) async {
    await _storage.write(key: _kAccess, value: tokens.accessToken);
    await _storage.write(key: _kRefresh, value: tokens.refreshToken);
    await _storage.write(key: _kRemember, value: rememberMe ? '1' : '0');
  }

  @override

  /// Reads tokens from secure storage.
  Future<TokenPair?> read() async {
    final access = await _storage.read(key: _kAccess);
    final refresh = await _storage.read(key: _kRefresh);
    if (access == null || refresh == null) return null;
    return TokenPair(accessToken: access, refreshToken: refresh);
  }

  @override

  /// Removes all SDK token keys from secure storage.
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kRemember);
  }
}
