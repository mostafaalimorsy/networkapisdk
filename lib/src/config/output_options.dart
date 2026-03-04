enum BytesJsonMode { saveToFile, base64 }

class OutputOptions {
  final bool jsonOnly;
  final bool tryParseJsonText;
  final BytesJsonMode bytesMode;

  const OutputOptions({
    required this.jsonOnly,
    required this.tryParseJsonText,
    required this.bytesMode,
  });

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