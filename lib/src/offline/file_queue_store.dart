import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../http/http_client.dart';
import '../models/request_body.dart';
import 'queue_store.dart';
import 'sync_queue_store.dart';

class FileQueueStore implements QueueStore, SyncQueueStore {
  final File file;
  final List<QueuedRequest> _q = [];

  FileQueueStore(this.file) {
    _loadSync();
  }

  void _loadSync() {
    try {
      if (!file.existsSync()) return;

      final txt = file.readAsStringSync();
      if (txt.trim().isEmpty) return;

      final decoded = jsonDecode(txt);
      if (decoded is! List) return;

      _q
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .map((m) => QueuedRequest(_requestFromJson(m))),
        );
    } catch (_) {
      _q.clear();
    }
  }

  Future<void> _persist() async {
    try {
      final list = _q.map((qr) => _requestToJson(qr.request)).toList();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(list), flush: true);
    } catch (_) {
      // don't crash
    }
  }

  @override
  List<QueuedRequest> peekAllSync() => List.unmodifiable(_q);

  @override
  Future<void> enqueue(QueuedRequest r) async {
    _q.add(r);
    await _persist();
  }

  @override
  Future<List<QueuedRequest>> peekAll() async => List.unmodifiable(_q);

  @override
  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _q.length) return;
    _q.removeAt(index);
    await _persist();
  }

  @override
  Future<void> clear() async {
    _q.clear();
    await _persist();
  }

  Map<String, dynamic> _requestToJson(HttpRequest r) {
    return <String, dynamic>{
      'endpoint': r.endpoint,
      'method': r.method,
      'query': r.query,
      'headers': r.headers,
      'responseType': r.responseType.name,
      'body': _bodyToJson(r.body),
    };
  }

  HttpRequest _requestFromJson(Map<String, dynamic> j) {
    final endpoint = (j['endpoint'] ?? '').toString();
    final method = (j['method'] ?? 'GET').toString();

    final queryRaw = j['query'];
    final query =
    queryRaw is Map ? Map<String, dynamic>.from(queryRaw) : null;

    final headersRaw = j['headers'];
    final headers = headersRaw is Map
        ? Map<String, String>.from(
      headersRaw.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
      ),
    )
        : null;

    final rtName =
    (j['responseType'] ?? ResponseTypeHint.json.name).toString();
    final responseType = ResponseTypeHint.values.firstWhere(
          (e) => e.name == rtName,
      orElse: () => ResponseTypeHint.json,
    );

    final bodyRaw = j['body'];
    final body = bodyRaw is Map
        ? _bodyFromJson(Map<String, dynamic>.from(bodyRaw))
        : const RequestBody.none();

    return HttpRequest(
      endpoint: endpoint,
      method: method,
      query: query,
      headers: headers,
      body: body,
      responseType: responseType,
    );
  }

  Map<String, dynamic> _bodyToJson(RequestBody b) {
    switch (b.type) {
      case BodyType.none:
        return <String, dynamic>{
          'type': BodyType.none.name,
        };

      case BodyType.json:
        return <String, dynamic>{
          'type': BodyType.json.name,
          'value': b.value,
        };

      case BodyType.text:
        return <String, dynamic>{
          'type': BodyType.text.name,
          'value': b.value,
          'contentType': b.contentType,
        };

      case BodyType.bytes:
        String? b64;
        if (b.value is Uint8List) {
          b64 = base64Encode(b.value as Uint8List);
        } else if (b.value is List<int>) {
          b64 = base64Encode(Uint8List.fromList(b.value as List<int>));
        }

        return <String, dynamic>{
          'type': BodyType.bytes.name,
          'bytesB64': b64,
          'contentType': b.contentType,
        };

      case BodyType.formUrlEncoded:
        return <String, dynamic>{
          'type': BodyType.formUrlEncoded.name,
          'value': b.value,
        };

      case BodyType.multipart:
        return <String, dynamic>{
          'type': BodyType.multipart.name,
          'fields': b.fields,
          'files': b.files?.map(
                (key, file) => MapEntry(
              key,
              <String, dynamic>{
                'filename': file.filename,
                'bytesB64': base64Encode(file.bytes),
                'contentType': file.contentType,
              },
            ),
          ),
        };
    }
  }

  RequestBody _bodyFromJson(Map<String, dynamic> j) {
    final typeName = (j['type'] ?? BodyType.none.name).toString();
    final type = BodyType.values.firstWhere(
          (e) => e.name == typeName,
      orElse: () => BodyType.none,
    );

    switch (type) {
      case BodyType.none:
        return const RequestBody.none();

      case BodyType.json:
        return RequestBody.json(j['value']);

      case BodyType.text:
        return RequestBody.text(
          (j['value'] ?? '').toString(),
          contentType: j['contentType']?.toString(),
        );

      case BodyType.bytes:
        final b64 = j['bytesB64']?.toString();
        final bytes = (b64 == null || b64.isEmpty)
            ? Uint8List(0)
            : Uint8List.fromList(base64Decode(b64));

        return RequestBody.bytes(
          bytes,
          contentType:
          j['contentType']?.toString() ?? 'application/octet-stream',
        );

      case BodyType.formUrlEncoded:
        return RequestBody.formUrlEncoded(
          j['value'] is Map
              ? Map<String, dynamic>.from(j['value'] as Map)
              : <String, dynamic>{},
        );

      case BodyType.multipart:
        final rawFields = j['fields'];
        final fields = rawFields is Map
            ? Map<String, dynamic>.from(rawFields)
            : <String, dynamic>{};

        final rawFiles = j['files'];
        final files = <String, BodyFile>{};

        if (rawFiles is Map) {
          for (final entry in rawFiles.entries) {
            final v = entry.value;
            if (v is Map) {
              final map = Map<String, dynamic>.from(v);
              final b64 = map['bytesB64']?.toString() ?? '';
              files[entry.key.toString()] = BodyFile(
                filename: map['filename']?.toString() ?? 'file',
                bytes: b64.isEmpty
                    ? Uint8List(0)
                    : Uint8List.fromList(base64Decode(b64)),
                contentType: map['contentType']?.toString(),
              );
            }
          }
        }

        return RequestBody.multipart(
          fields: fields,
          files: files,
        );
    }
  }
}