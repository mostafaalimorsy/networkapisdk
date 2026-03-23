/// Describes where a response was produced from.
enum ResponseSource {
  /// The response came from a live network call.
  network,

  /// The response came from the offline cache.
  cache,

  /// The request was accepted into the offline queue instead of being sent.
  queued,
}

/// Categorizes SDK errors.
///
/// The built-in implementation currently produces [contract] and [unknown] for
/// its own failures. Other values remain available for custom transports,
/// stores, or interceptors that want to classify errors more precisely.
enum ErrorType {
  /// The request failed because the device was offline.
  offline,

  /// The request failed because it timed out.
  timeout,

  /// The request was rejected as unauthorized.
  unauthorized,

  /// The request was rejected as forbidden.
  forbidden,

  /// The request body or parameters were invalid.
  badRequest,

  /// The server returned a server-side failure.
  server,

  /// The response did not satisfy the configured contract.
  contract,

  /// The response could not be parsed as expected.
  parse,

  /// The error could not be classified more precisely.
  unknown,
}
