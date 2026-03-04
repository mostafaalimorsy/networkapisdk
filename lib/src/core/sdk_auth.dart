import '../auth/token_store.dart';
import '../models/request_body.dart';
import '../models/sdk_response.dart';
import 'sdk.dart';
import '../core/sdk_events.dart';

class SdkAuth {
  final Sdk _sdk;
  SdkAuth.internal(this._sdk);

  Future<SdkResponse> login({
    required Map<String, dynamic> body,
    bool rememberMe = true,
    Map<String, String>? headers,
  }) async {
    final opts = _sdk.config.auth;
    if (opts == null) {
      throw StateError('AuthOptions is not configured in SdkConfig.auth');
    }

    final res = await _sdk.call.post(
      opts.loginEndpoint,
      headers: headers,
      body: RequestBody.json(body),
      attachAuth: false,
    );

    if (!res.ok) return res;

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      return SdkResponse(
        ok: false,
        statusCode: res.statusCode,
        source: res.source,
        message: res.message,
        data: null,
        error: res.error,
        meta: {
          ...res.meta,
          "auth": "Token extraction failed: data is not a Map",
        },
      );
    }

    final access = _readPath(data, opts.accessTokenPath)?.toString();
    final refresh = _readPath(data, opts.refreshTokenPath)?.toString();

    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      return SdkResponse(
        ok: false,
        statusCode: res.statusCode,
        source: res.source,
        message: res.message,
        data: null,
        error: res.error,
        meta: {
          ...res.meta,
          "auth": "Token extraction failed: missing access/refresh token",
        },
      );
    }

    await _sdk.authManager.save(
      TokenPair(accessToken: access, refreshToken: refresh),
      rememberMe: rememberMe,
    );

    return res;
  }

  Future<TokenPair?> refresh() async {
    final opts = _sdk.config.auth;
    if (opts == null) return null;

    final current = await _sdk.authManager.load();
    final refreshToken = current?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final res = await _sdk.call.post(
      opts.refreshEndpoint,
      attachAuth: false,
      body: RequestBody.json({opts.refreshRequestKey: refreshToken}),
    );

    if (!res.ok) return null;

    final data = res.data;
    if (data is! Map<String, dynamic>) return null;

    final access = _readPath(data, opts.accessTokenPath)?.toString();
    final refresh = _readPath(data, opts.refreshTokenPath)?.toString();

    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      return null;
    }

    final pair = TokenPair(accessToken: access, refreshToken: refresh);
    await _sdk.authManager.save(pair, rememberMe: true);
    return pair;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool rememberMe = true,
  }) async {
    await _sdk.authManager.save(
      TokenPair(accessToken: accessToken, refreshToken: refreshToken),
      rememberMe: rememberMe,
    );
  }

  Future<TokenPair?> restoreSession() => _sdk.authManager.load();
  Future<void> logout() => _sdk.authManager.clear();

  dynamic _readPath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return null;
    final parts = path.split('.');
    dynamic cur = json;
    for (final p in parts) {
      if (cur is Map<String, dynamic> && cur.containsKey(p)) {
        cur = cur[p];
      } else {
        return null;
      }
    }
    return cur;
  }

  Future<void> signOut({bool emitEvent = true}) async {
    await _sdk.authManager.clear();
    if (emitEvent) {
      _sdk.events.emit(SdkEvent.signedOut);
    }
  }

  // لو عايزها alias
  Future<void> clearSession({bool emitEvent = true}) => signOut(emitEvent: emitEvent);
}