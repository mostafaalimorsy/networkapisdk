/// Configures the SDK's built-in authentication endpoints and token mapping.
///
/// Provide this to `SdkConfig.auth` when you want to use `Sdk.instance.auth`
/// for login and refresh flows. Token paths are resolved against the
/// successful response payload returned by the configured contract.
class AuthOptions {
  /// The endpoint used by the built-in login helper.
  final String loginEndpoint;

  /// The endpoint used by the built-in refresh helper.
  final String refreshEndpoint;

  /// Dot-separated path to the access token inside successful response data.
  final String accessTokenPath;

  /// Dot-separated path to the refresh token inside successful response data.
  final String refreshTokenPath;

  /// The request body key used when sending the refresh token.
  ///
  /// Defaults to `refreshToken`.
  final String refreshRequestKey;

  /// Creates authentication settings for login and refresh.
  const AuthOptions({
    required this.loginEndpoint,
    required this.refreshEndpoint,
    required this.accessTokenPath,
    required this.refreshTokenPath,
    this.refreshRequestKey = 'refreshToken',
  });
}
