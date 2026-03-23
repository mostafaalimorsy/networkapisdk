import 'dart:typed_data';

/// Declares how a [RequestBody] should be encoded by an HTTP client.
enum BodyType {
  /// No request body.
  none,

  /// A JSON body.
  json,

  /// A plain-text body.
  text,

  /// A raw byte body.
  bytes,

  /// A form URL encoded body.
  formUrlEncoded,

  /// A multipart body containing fields and optional files.
  multipart,
}

/// Represents one multipart file field.
class BodyFile {
  /// File name sent to the server.
  final String filename;

  /// Raw file contents.
  final Uint8List bytes;

  /// Optional MIME type for multipart uploads.
  final String? contentType;

  /// Creates a multipart file payload.
  const BodyFile({
    required this.filename,
    required this.bytes,
    this.contentType,
  });
}

/// Represents a request payload sent through the SDK call API.
///
/// Use the named constructors to describe the payload shape expected by the
/// underlying HTTP client.
///
/// ```dart
/// final body = RequestBody.multipart(
///   fields: {'name': 'avatar'},
///   files: {
///     'file': BodyFile(
///       filename: 'avatar.png',
///       bytes: bytes,
///       contentType: 'image/png',
///     ),
///   },
/// );
/// ```
class RequestBody {
  /// The body encoding requested by the caller.
  final BodyType type;

  /// The primary body value for non-multipart requests.
  final dynamic value;

  /// Form fields used for multipart requests.
  final Map<String, dynamic>? fields;

  /// Multipart files keyed by field name.
  final Map<String, BodyFile>? files;

  /// Optional content type metadata for text or byte payloads.
  ///
  /// The built-in Dio client currently carries this value on the object
  /// but does not turn it into a request header for text or byte bodies.
  final String? contentType;

  const RequestBody._({
    required this.type,
    this.value,
    this.fields,
    this.files,
    this.contentType,
  });

  /// Creates an empty request body.
  const RequestBody.none() : this._(type: BodyType.none);

  /// Creates a JSON body.
  factory RequestBody.json(dynamic json) =>
      RequestBody._(type: BodyType.json, value: json);

  /// Creates a plain-text body.
  factory RequestBody.text(String text, {String? contentType}) => RequestBody._(
        type: BodyType.text,
        value: text,
        contentType: contentType ?? 'text/plain; charset=utf-8',
      );

  /// Creates a raw byte body.
  factory RequestBody.bytes(
    Uint8List bytes, {
    String contentType = 'application/octet-stream',
  }) =>
      RequestBody._(
        type: BodyType.bytes,
        value: bytes,
        contentType: contentType,
      );

  /// Creates an `application/x-www-form-urlencoded` style body description.
  factory RequestBody.formUrlEncoded(Map<String, dynamic> data) =>
      RequestBody._(type: BodyType.formUrlEncoded, value: data);

  /// Creates a multipart body with optional fields and files.
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

/// Hints how the HTTP client should request the response payload.
enum ResponseTypeHint {
  /// Expect a JSON response.
  json,

  /// Expect a text response.
  text,

  /// Expect a byte response.
  bytes,
}
