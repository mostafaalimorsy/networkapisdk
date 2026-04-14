import 'package:network_api_sdk/src/config/logging_options.dart';

import '../auth/token_store.dart';
import '../http/http_client.dart';
import '../interceptors/sdk_interceptor.dart';
import 'auth_options.dart';
import 'output_options.dart';
import 'sdk_contract.dart';
import 'sdk_profile.dart';
import '../offline/cache_store.dart';
import '../offline/queue_store.dart';

/// Configures SDK initialization.
///
/// This is the main package configuration object. It defines the base URL,
/// response contract, output normalization, authentication settings,
/// interceptors, and the concrete stores or transport implementations to use.
class SdkConfig {
  /// Base URL passed to the default [DioHttpClient].
  final String baseUrl;

  /// Runtime profile controlling offline cache and queue behavior.
  final SdkProfile profile;

  /// Contract used to evaluate backend success and extract response data.
  final SdkContract contract;

  /// Output normalization settings applied to transport responses.
  final OutputOptions output;

  /// Overrides the built-in HTTP client.
  ///
  /// When omitted, the SDK creates a [DioHttpClient] with [baseUrl].
  final HttpClient? httpOverride;

  /// Overrides the token store used by the built-in authentication manager.
  ///
  /// When omitted, the SDK uses [SecureTokenStore].
  final TokenStore? tokenStoreOverride;

  /// Enables the built-in login and refresh helpers when provided.
  final AuthOptions? auth;

  /// Interceptors executed in registration order.
  ///
  /// Request interceptors run after auth headers are attached. Response
  /// interceptors receive normalized transport responses.
  final List<SdkInterceptor> interceptors;

  /// Overrides the cache store used for offline `GET` fallbacks.
  ///
  /// When omitted, [Sdk] uses [MemoryCacheStore].
  final CacheStore? cacheStoreOverride;

  /// Overrides the queue store used for offline write persistence.
  ///
  /// When omitted, [Sdk] uses [MemoryQueueStore].
  final QueueStore? queueStoreOverride;

  /// Additional queue feature flag for consumers and custom integrations.
  ///
  /// The built-in request flow currently uses [SdkProfile.queueWritesWhenOffline]
  /// to decide whether offline writes are queued.
  final bool offlineQueueEnabled;

  /// to log the requests.
  final LoggingOptions logging;

  /// Returns the current language code for outgoing requests.
  final Future<String?> Function()? languageProvider;

  /// Callback triggered when the session expires and refresh fails.
  ///
  /// This allows the application to handle navigation (e.g., redirect to login)
  /// without coupling the SDK to any UI framework.
  final Future<void> Function()? onSessionExpired;

  /// Creates SDK initialization settings.
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
    this.logging = const LoggingOptions.disabled(),
    required this.languageProvider,
    this.onSessionExpired,
    this.offlineQueueEnabled = true,
  }) : interceptors = interceptors ?? const [];
}
