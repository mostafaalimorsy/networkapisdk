class AuthOptions {
  final String loginEndpoint;

  /// ✅ refresh endpoint
  final String refreshEndpoint;

  /// Where to find tokens in successful response JSON (dot paths)
  final String accessTokenPath;
  final String refreshTokenPath;

  /// ✅ key name sent in refresh body (default: refreshToken)
  final String refreshRequestKey;

  const AuthOptions({
    required this.loginEndpoint,
    required this.refreshEndpoint,
    required this.accessTokenPath,
    required this.refreshTokenPath,
    this.refreshRequestKey = 'refreshToken',
  });
}