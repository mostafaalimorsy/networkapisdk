import 'dart:typed_data';

enum BodyType { none, json, text, bytes, formUrlEncoded, multipart }

class BodyFile {
  final String filename;
  final Uint8List bytes;
  final String? contentType;

  const BodyFile({
    required this.filename,
    required this.bytes,
    this.contentType,
  });
}

class RequestBody {
  final BodyType type;
  final dynamic value;
  final Map<String, dynamic>? fields; // للمولتي بارت
  final Map<String, BodyFile>? files; // للمولتي بارت
  final String? contentType; // bytes/text override

  const RequestBody._({
    required this.type,
    this.value,
    this.fields,
    this.files,
    this.contentType,
  });

  const RequestBody.none() : this._(type: BodyType.none);

  factory RequestBody.json(dynamic json) =>
      RequestBody._(type: BodyType.json, value: json);

  factory RequestBody.text(String text, {String? contentType}) => RequestBody._(
    type: BodyType.text,
    value: text,
    contentType: contentType ?? 'text/plain; charset=utf-8',
  );

  factory RequestBody.bytes(
      Uint8List bytes, {
        String contentType = 'application/octet-stream',
      }) =>
      RequestBody._(
        type: BodyType.bytes,
        value: bytes,
        contentType: contentType,
      );

  factory RequestBody.formUrlEncoded(Map<String, dynamic> data) =>
      RequestBody._(type: BodyType.formUrlEncoded, value: data);

  factory RequestBody.multipart({
    Map<String, dynamic>? fields,
    Map<String, BodyFile>? files,
  }) =>
      RequestBody._(
        type: BodyType.multipart,
        fields: fields ?? const {},
        files: files ?? const {},
      );
}

enum ResponseTypeHint { json, text, bytes }