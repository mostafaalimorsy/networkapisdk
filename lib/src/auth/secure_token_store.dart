import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_store.dart';

class SecureTokenStore implements TokenStore {
  static const _kAccess = 'sdk_access_token';
  static const _kRefresh = 'sdk_refresh_token';
  static const _kRemember = 'sdk_remember_me';

  final FlutterSecureStorage _storage;

  const SecureTokenStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  @override
  Future<void> save(TokenPair tokens, {required bool rememberMe}) async {
    // access token: لو rememberMe=false ممكن نخليه برضه يتخزن (بس الأفضل نخزن الاتنين)
    await _storage.write(key: _kAccess, value: tokens.accessToken);
    await _storage.write(key: _kRefresh, value: tokens.refreshToken);
    await _storage.write(key: _kRemember, value: rememberMe ? '1' : '0');
  }

  @override
  Future<TokenPair?> read() async {
    final access = await _storage.read(key: _kAccess);
    final refresh = await _storage.read(key: _kRefresh);
    if (access == null || refresh == null) return null;
    return TokenPair(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kRemember);
  }
}