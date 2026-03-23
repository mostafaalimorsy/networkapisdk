import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/request_body.dart';
import 'http_client.dart';

/// Default [HttpClient] implementation backed by `package:dio`.
class DioHttpClient implements HttpClient {
  final Dio _dio;

  /// Creates a Dio-backed client for [Sdk].
  DioHttpClient({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: connectTimeout,
            receiveTimeout: receiveTimeout,
            validateStatus: (_) => true,
          ),
        );

  @override

  /// Sends [request] through Dio and returns a flattened [HttpResponse].
  ///
  /// Non-2xx responses are returned normally. Transport exceptions without a
  /// response are rethrown to the caller.
  Future<HttpResponse> send(HttpRequest request) async {
    final options = Options(
      method: request.method,
      headers: request.headers,
      responseType: _mapResponseType(request.responseType),
      validateStatus: (_) => true,
    );

    final data = await _mapBody(request.body);

    try {
      final res = await _dio.request(
        request.endpoint,
        queryParameters: request.query,
        data: data,
        options: options,
      );

      return HttpResponse(
        statusCode: res.statusCode,
        headers: res.headers.map.map((k, v) => MapEntry(k, v.join(','))),
        data: res.data,
      );
    } on DioException catch (e) {
      final res = e.response;
      if (res != null) {
        return HttpResponse(
          statusCode: res.statusCode,
          headers: res.headers.map.map((k, v) => MapEntry(k, v.join(','))),
          data: res.data,
        );
      }
      rethrow;
    }
  }

  ResponseType _mapResponseType(ResponseTypeHint hint) {
    switch (hint) {
      case ResponseTypeHint.json:
        return ResponseType.json;
      case ResponseTypeHint.text:
        return ResponseType.plain;
      case ResponseTypeHint.bytes:
        return ResponseType.bytes;
    }
  }

  Future<dynamic> _mapBody(RequestBody body) async {
    switch (body.type) {
      case BodyType.none:
        return null;
      case BodyType.json:
        return body.value;
      case BodyType.text:
        return body.value as String;
      case BodyType.bytes:
        return body.value as Uint8List;
      case BodyType.formUrlEncoded:
        return body.value as Map<String, dynamic>;
      case BodyType.multipart:
        final formData = FormData();
        (body.fields ?? {}).forEach((k, v) {
          formData.fields.add(MapEntry(k, v.toString()));
        });
        (body.files ?? {}).forEach((k, f) {
          formData.files.add(
            MapEntry(
              k,
              MultipartFile.fromBytes(
                f.bytes,
                filename: f.filename,
                contentType: f.contentType != null
                    ? DioMediaType.parse(f.contentType!)
                    : null,
              ),
            ),
          );
        });
        return formData;
    }
  }
}
