import 'dart:convert';
import 'dart:typed_data';

/// Normalizes raw transport payloads into JSON-friendly values.
///
/// This is used internally before contract evaluation.
class JsonNormalizer {
  /// Creates a normalizer.
  const JsonNormalizer();

  /// Normalizes [raw] into a value that is safe to expose through SDK
  /// responses.
  ///
  /// Maps, lists, numbers, and booleans are returned as-is. Strings may be
  /// decoded as JSON when [tryParseJsonText] is `true`; otherwise they are
  /// wrapped in `{type: text, value: ...}`. Byte arrays are wrapped in a base64
  /// map.
  dynamic normalize(dynamic raw, {bool tryParseJsonText = true}) {
    if (raw == null) return null;

    if (raw is Map<String, dynamic> || raw is List) return raw;
    if (raw is num || raw is bool) return raw;

    if (raw is String) {
      if (tryParseJsonText) {
        final t = raw.trim();
        final looksJson = (t.startsWith('{') && t.endsWith('}')) ||
            (t.startsWith('[') && t.endsWith(']'));
        if (looksJson) {
          try {
            return jsonDecode(t);
          } catch (_) {}
        }
      }
      return {"type": "text", "value": raw};
    }

    if (raw is Uint8List) {
      return {"type": "bytes", "base64": base64Encode(raw)};
    }

    return {"type": "unknown", "value": raw.toString()};
  }
}
