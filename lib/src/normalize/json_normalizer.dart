import 'dart:convert';
import 'dart:typed_data';

class JsonNormalizer {
  const JsonNormalizer();

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