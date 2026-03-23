import '../models/request_body.dart';

/// Raw transport response returned by an [HttpClient].
class HttpResponse {
  /// HTTP status code returned by the transport.
  final int? statusCode;

  /// Response headers flattened into a string map.
  final Map<String, String> headers;

  /// Raw response payload before SDK contract evaluation.
  final dynamic data;

  /// Creates a transport response.
  const HttpResponse({
    required this.statusCode,
    required this.headers,
    required this.data,
  });

  /// Returns a copy of this response with selected fields replaced.
  ///
  /// Passing `null` for [data] preserves the current value.
  HttpResponse copyWith({
    int? statusCode,
    Map<String, String>? headers,
    Object? data,
  }) {
    return HttpResponse(
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      data: data ?? this.data,
    );
  }
}

/// Raw transport request sent through an [HttpClient].
class HttpRequest {
  /// Endpoint path relative to the configured base URL.
  final String endpoint;

  /// HTTP method, such as `GET` or `POST`.
  final String method;

  /// Query parameters appended to the request URL.
  final Map<String, dynamic>? query;

  /// Request headers.
  final Map<String, String>? headers;

  /// Request payload description.
  final RequestBody body;

  /// Response type hint for the underlying HTTP client.
  final ResponseTypeHint responseType;

  /// Creates a transport request.
  const HttpRequest({
    required this.endpoint,
    required this.method,
    this.query,
    this.headers,
    this.body = const RequestBody.none(),
    this.responseType = ResponseTypeHint.json,
  });

  /// Returns a copy of this request with selected fields replaced.
  ///
  /// Passing `null` for [query] or [headers] preserves the current value.
  HttpRequest copyWith({
    String? endpoint,
    String? method,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    RequestBody? body,
    ResponseTypeHint? responseType,
  }) {
    return HttpRequest(
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      query: query ?? this.query,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      responseType: responseType ?? this.responseType,
    );
  }
}

/// Transport abstraction used by the SDK.
abstract class HttpClient {
  /// Sends [request] and returns the raw transport response.
  Future<HttpResponse> send(HttpRequest request);
}
