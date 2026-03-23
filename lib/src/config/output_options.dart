/// Controls how the SDK normalizes transport responses.
///
/// The current built-in pipeline already returns JSON-friendly values. Only
/// `tryParseJsonText` is actively read by the built-in request flow.
enum BytesJsonMode {
  /// Indicates a preference for file-based byte handling.
  saveToFile,

  /// Indicates a preference for base64-encoded byte output.
  base64,
}

/// Creates output normalization settings for the SDK.
class OutputOptions {
  /// Whether responses should be constrained to JSON-friendly values.
  ///
  /// This flag is currently informational in the built-in implementation,
  /// which already normalizes all responses into JSON-friendly values.
  final bool jsonOnly;

  /// Whether string responses that look like JSON should be decoded.
  final bool tryParseJsonText;

  /// Preferred handling for byte responses.
  ///
  /// This value is not currently consumed by the built-in normalizer, which
  /// encodes bytes as base64 data.
  final BytesJsonMode bytesMode;

  /// Creates a new set of output options.
  const OutputOptions({
    required this.jsonOnly,
    required this.tryParseJsonText,
    required this.bytesMode,
  });

  /// Creates the package's standard JSON-friendly output configuration.
  factory OutputOptions.jsonOnly({
    bool tryParseJsonText = true,
    BytesJsonMode bytesMode = BytesJsonMode.saveToFile,
  }) =>
      OutputOptions(
        jsonOnly: true,
        tryParseJsonText: tryParseJsonText,
        bytesMode: bytesMode,
      );
}
