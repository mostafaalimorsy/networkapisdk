/// Configures built-in SDK logging behavior.
class LoggingOptions {
  /// Whether built-in SDK logging is enabled.
  final bool enabled;

  /// Whether request and response headers should be logged.
  final bool logHeaders;

  /// Whether request and response bodies should be logged.
  final bool logBody;

  /// Whether sensitive values should be masked in logs.
  final bool maskSensitiveData;

  const LoggingOptions({
    this.enabled = false,
    this.logHeaders = true,
    this.logBody = true,
    this.maskSensitiveData = true,
  });

  const LoggingOptions.disabled()
      : enabled = false,
        logHeaders = false,
        logBody = false,
        maskSensitiveData = true;

  const LoggingOptions.enabledSafe()
      : enabled = true,
        logHeaders = true,
        logBody = true,
        maskSensitiveData = true;
}
