import '../auth/token_store.dart';
import '../http/http_client.dart';
import 'auth_options.dart';
import 'output_options.dart';
import 'sdk_contract.dart';
import 'sdk_profile.dart';
import '../interceptors/sdk_interceptor.dart';

import '../offline/queue_store.dart';
import '../offline/cache_store.dart';
class SdkConfig {
  final String baseUrl;
  final SdkProfile profile;
  final SdkContract contract;
  final OutputOptions output;

  // ✅ Step 2: allow overriding http client in tests
  final HttpClient? httpOverride;

  // ✅ Step 4: allow overriding token store in tests
  final TokenStore? tokenStoreOverride;

  // ✅ Step 4.2: auth options (login endpoint + token paths)
  final AuthOptions? auth;

  // ✅ Step 5: interceptors
  final List<SdkInterceptor> interceptors;


  // ✅ Step 6: caching
  final CacheStore? cacheStoreOverride;
  final QueueStore? queueStoreOverride;

  const SdkConfig({
    required this.baseUrl,
    required this.profile,
    required this.contract,
    required this.output,
    this.httpOverride,
    this.tokenStoreOverride,
    this.auth,
    this.cacheStoreOverride,
    this.queueStoreOverride,
    List<SdkInterceptor>? interceptors,
  }) : interceptors = interceptors ?? const [];
}