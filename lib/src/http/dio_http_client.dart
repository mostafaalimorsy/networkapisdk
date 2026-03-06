import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../models/request_body.dart';
import 'http_client.dart';

class DioHttpClient implements HttpClient {
  final Dio _dio;

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
  Future<HttpResponse> send(HttpRequest request) async {
    final options = Options(
      method: request.method,
      headers: request.headers,
      responseType: _mapResponseType(request.responseType),
    );

    final data = await _mapBody(request.body);

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
      // Dio لوحده بيظبطها غالباً لو content-type اتحدد
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