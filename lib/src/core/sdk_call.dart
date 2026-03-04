import '../contract/contract_evaluator.dart';
import '../http/http_client.dart';
import '../models/enums.dart';
import '../models/request_body.dart';
import '../models/sdk_error.dart';
import '../models/sdk_response.dart';
import '../normalize/json_normalizer.dart';
import 'sdk.dart';
import 'sdk_events.dart';
import '../offline/queue_store.dart';

class SdkCall {
  final Sdk _sdk;
  final JsonNormalizer _normalizer = const JsonNormalizer();

  SdkCall.internal(this._sdk);
  Future<Map<String, String>> _buildHeaders(
    Map<String, String> baseHeaders, {
    required bool attachAuth,
  }) async {
    final h = <String, String>{};
    h.addAll(baseHeaders);

    if (attachAuth) {
      final pair = await _sdk.authManager.load();
      final access = pair?.accessToken;
      if (access != null && access.isNotEmpty) {
        h['Authorization'] = 'Bearer $access';
      }
    }

    return h;
  }

  String _cacheKey(HttpRequest req) {
    final q = req.query ?? const <String, dynamic>{};
    final queryStr = q.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '${req.method}:${req.endpoint}?$queryStr';
  }

  Future<SdkResponse> get(
      String endpoint, {
        Map<String, dynamic>? query,
        Map<String, String>? headers,
        ResponseTypeHint responseType = ResponseTypeHint.json,
        bool attachAuth = true,
      }) =>
      _send(
        endpoint: endpoint,
        method: 'GET',
        query: query,
        headers: headers,
        body: const RequestBody.none(),
        responseType: responseType,
        attachAuth: attachAuth,
      );

  Future<SdkResponse> post(
      String endpoint, {
        Map<String, dynamic>? query,
        Map<String, String>? headers,
        RequestBody body = const RequestBody.none(),
        ResponseTypeHint responseType = ResponseTypeHint.json,
        bool attachAuth = true,
      }) =>
      _send(
        endpoint: endpoint,
        method: 'POST',
        query: query,
        headers: headers,
        body: body,
        responseType: responseType,
        attachAuth: attachAuth,
      );

  Future<SdkResponse> put(
      String endpoint, {
        Map<String, dynamic>? query,
        Map<String, String>? headers,
        RequestBody body = const RequestBody.none(),
        ResponseTypeHint responseType = ResponseTypeHint.json,
        bool attachAuth = true,
      }) =>
      _send(
        endpoint: endpoint,
        method: 'PUT',
        query: query,
        headers: headers,
        body: body,
        responseType: responseType,
        attachAuth: attachAuth,
      );

  Future<SdkResponse> delete(
      String endpoint, {
        Map<String, dynamic>? query,
        Map<String, String>? headers,
        RequestBody body = const RequestBody.none(),
        ResponseTypeHint responseType = ResponseTypeHint.json,
        bool attachAuth = true,
      }) =>
      _send(
        endpoint: endpoint,
        method: 'DELETE',
        query: query,
        headers: headers,
        body: body,
        responseType: responseType,
        attachAuth: attachAuth,
      );

  Future<SdkResponse> any(
      String endpoint, {
        required String method,
        Map<String, dynamic>? query,
        Map<String, String>? headers,
        RequestBody body = const RequestBody.none(),
        ResponseTypeHint responseType = ResponseTypeHint.json,
        bool attachAuth = true,
      }) =>
      _send(
        endpoint: endpoint,
        method: method.toUpperCase(),
        query: query,
        headers: headers,
        body: body,
        responseType: responseType,
        attachAuth: attachAuth,
      );

  Future<SdkResponse> _send({
    required String endpoint,
    required String method,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required RequestBody body,
    required ResponseTypeHint responseType,
    bool attachAuth = true, // ✅ default
    bool isRetry = false,
  }) async {
    // Always have a request instance available (even if an error occurs early)
    // so error interceptors can run safely.
    HttpRequest req = HttpRequest(
      endpoint: endpoint,
      method: method,
      query: query,
      headers: Map<String, String>.from(headers ?? const <String, String>{}),
      body: body,
      responseType: responseType,
    );

    try {
      // Build headers (including auth if enabled) based on the request's current headers.
      final finalHeaders = Map<String, String>.from(
        await _buildHeaders(req.headers ?? const <String, String>{}, attachAuth: attachAuth),
      );

      // Rebuild request with merged headers, then allow request interceptors to mutate it.
      req = HttpRequest(
        endpoint: endpoint,
        method: method,
        query: query,
        headers: finalHeaders,
        body: body,
        responseType: responseType,
      );

      // Request interceptors
      req = await _sdk.interceptors.runRequest(req);

      // Send
      var httpRes = await _sdk.http.send(req);

      // Normalize
      final normalized = _normalizer.normalize(
        httpRes.data,
        tryParseJsonText: _sdk.config.output.tryParseJsonText,
      );

      // Put normalized data back, then allow response interceptors to patch it
      httpRes = httpRes.copyWith(data: normalized);

      // Response interceptors (after normalize)
      httpRes = await _sdk.interceptors.runResponse(req, httpRes);

      // ✅ Retry-on-401 (single retry)
      if (attachAuth && httpRes.statusCode == 401) {
        if (!isRetry) {
          final refreshed = await _sdk.authManager.refreshSingleFlight(
            (current) async => _sdk.auth.refresh(),
          );

          if (refreshed != null) {
            return _send(
              endpoint: endpoint,
              method: method,
              query: query,
              headers: headers,
              body: body,
              responseType: responseType,
              attachAuth: attachAuth,
              isRetry: true,
            );
          }
        }

        // Refresh failed OR retry still 401 => session expired
        await _sdk.authManager.clear();
        _sdk.events.emit(SdkEvent.sessionExpired);

        return SdkResponse(
          ok: false,
          statusCode: 401,
          source: ResponseSource.network,
          message: 'Session expired',
          data: null,
          error: const SdkError(
            type: ErrorType.unknown,
            message: 'Unauthorized (session expired)',
          ),
        );
      }

      // Contract evaluate
      final evaluator = ContractEvaluator(_sdk.config.contract);
      final sdkRes = evaluator.evaluate(
        statusCode: httpRes.statusCode,
        rawJson: httpRes.data,
        source: ResponseSource.network,
      );

      // Offline cache write for successful GET
      if (_sdk.config.profile.offlineEnabled && req.method == 'GET' && sdkRes.ok) {
        await _sdk.cache.put(_cacheKey(req), sdkRes.data);
      }

      return sdkRes;
    } catch (e) {
      // ---- Offline fallbacks (best effort) ----
      final offlineEnabled = _sdk.config.profile.offlineEnabled;
      final queueWrites = _sdk.config.profile.queueWritesWhenOffline;

      // GET -> return cache if exists
      if (offlineEnabled && req.method == 'GET') {
        final cached = await _sdk.cache.get(_cacheKey(req));
        if (cached != null) {
          return SdkResponse(
            ok: true,
            statusCode: 200,
            source: ResponseSource.cache,
            message: 'OK (cache)',
            data: cached,
            error: null,
          );
        }
      }

      // write -> queue
      final isWrite = req.method != 'GET';
      if (offlineEnabled && queueWrites && isWrite) {
        await _sdk.queueStore.enqueue(QueuedRequest(req));
        return SdkResponse(
          ok: true,
          statusCode: 202,
          source: ResponseSource.network,
          message: 'Queued',
          data: const <String, dynamic>{'queued': true},
          error: null,
        );
      }

      // else normal error + error interceptors
      var sdkError = SdkError(
        type: ErrorType.unknown,
        message: e.toString(),
      );

      sdkError = await _sdk.interceptors.runError(req, sdkError);

      return SdkResponse(
        ok: false,
        statusCode: 0,
        source: ResponseSource.network,
        message: sdkError.message,
        data: null,
        error: sdkError,
      );
    }
  }
}