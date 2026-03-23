/// Holds the access and refresh tokens for an authenticated session.
class TokenPair {
  /// Token attached to authenticated requests.
  final String accessToken;

  /// Token used to obtain a new access token.
  final String refreshToken;

  /// Creates a token pair.
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
  });
}

/// Persists authentication tokens for the SDK.
///
/// Implement this interface to control how login and refresh tokens are stored.
/// The SDK calls [save], [read], and [clear] through [AuthManager].
abstract class TokenStore {
  /// Persists [tokens].
  ///
  /// The meaning of [rememberMe] is implementation-defined.
  Future<void> save(TokenPair tokens, {required bool rememberMe});

  /// Loads the last saved token pair, or `null` if none exists.
  Future<TokenPair?> read();

  /// Removes any stored session data.
  Future<void> clear();
}
