class TokenPair {
  final String accessToken;
  final String refreshToken;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
  });
}

abstract class TokenStore {
  Future<void> save(TokenPair tokens, {required bool rememberMe});
  Future<TokenPair?> read();
  Future<void> clear();
}