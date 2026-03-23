import '../auth/token_store.dart';
import '../models/request_body.dart';
import '../models/sdk_response.dart';
import '../core/sdk_events.dart';
import 'sdk.dart';

/// Provides authentication helpers for the initialized [Sdk].
///
/// Access this API through [Sdk.instance.auth].
class SdkAuth {
  final Sdk _sdk;

  /// Internal constructor used by [Sdk].
  SdkAuth.internal(this._sdk);

  /// Logs in with [body] and stores the returned tokens.
  ///
  /// This sends a `POST` request to the configured login endpoint with
  /// [RequestBody.json] and `attachAuth: false`. On success, tokens are
  /// extracted from the successful response data using
  /// the configured token paths.
  ///
  /// Throws a [StateError] if authentication is not configured on the SDK.
  ///
  /// ```dart
  /// final result = await Sdk.instance.auth.login(
  ///   body: {
  ///     'email': 'dev@example.com',
  ///     'password': 'secret',
  ///   },
  /// );
  /// ```
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

    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
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

  /// Refreshes the current session using the stored refresh token.
  ///
  /// Returns the new [TokenPair] when refresh succeeds, or `null` when auth is
  /// not configured, no refresh token exists, the refresh call fails, or token
  /// extraction fails. Successful refreshes are persisted with
  /// `rememberMe: true`.
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

    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      return null;
    }

    final pair = TokenPair(accessToken: access, refreshToken: refresh);
    await _sdk.authManager.save(pair, rememberMe: true);
    return pair;
  }

  /// Saves tokens directly to the configured [TokenStore].
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

  /// Restores any previously saved session.
  Future<TokenPair?> restoreSession() => _sdk.authManager.load();

  /// Clears saved tokens without emitting an SDK event.
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

  /// Clears the current session and optionally emits [SdkEvent.signedOut].
  Future<void> signOut({bool emitEvent = true}) async {
    await _sdk.authManager.clear();
    if (emitEvent) {
      _sdk.events.emit(SdkEvent.signedOut);
    }
  }

  /// Alias for [signOut].
  Future<void> clearSession({bool emitEvent = true}) =>
      signOut(emitEvent: emitEvent);
}
