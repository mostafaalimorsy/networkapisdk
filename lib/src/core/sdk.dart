import 'dart:async';

import 'package:meta/meta.dart';

import '../auth/auth_manager.dart';
import '../auth/secure_token_store.dart';
import '../config/sdk_config.dart';
import '../http/dio_http_client.dart';
import '../http/http_client.dart';
import '../interceptors/interceptor_runner.dart';
import '../interceptors/built_in_logging_interceptor.dart';
import '../offline/cache_store.dart';
import '../offline/queue_store.dart';
import '../offline/sdk_queue.dart';
import 'sdk_auth.dart';
import 'sdk_call.dart';
import 'sdk_events.dart';

/// Global SDK entry point.
///
/// Initialize the singleton once with [init], then access modules such as
/// [call], [auth], [events], [cache], and [queue] through [instance].
///
/// ```dart
/// Sdk.init(
///   SdkConfig(
///     baseUrl: 'https://api.example.com',
///     profile: SdkProfile.defaultSecure(),
///     contract: SdkContract.auto(
///       data: 'data',
///       message: 'message',
///     ),
///     output: OutputOptions.jsonOnly(),
///   ),
/// );
/// ```
class Sdk {
  Sdk._(this.config);

  static Sdk? _instance;

  bool _sessionExpiredHandled = false;

  /// Resets the singleton for tests.
  ///
  /// This method is not intended for production app flows.
  @visibleForTesting
  static void resetForTest() {
    _instance?._dispose();
    _instance = null;
  }

  void _dispose() {
    events.dispose();
  }

  /// Initialization settings used to build the SDK modules.
  final SdkConfig config;

  /// HTTP client used by the SDK.
  late final HttpClient http;

  /// Request API for HTTP calls.
  late final SdkCall call;

  /// Authentication API for login, refresh, and sign-out flows.
  late final SdkAuth auth;

  /// Event hub for session lifecycle notifications.
  late final SdkEvents events;

  /// Token manager used internally by auth and retry flows.
  late final AuthManager authManager;

  /// Interceptor pipeline built from [SdkConfig.interceptors].
  late final InterceptorRunner interceptors;

  /// Queue store used for offline write persistence.
  late final QueueStore queueStore;

  /// Queue API used to flush queued requests.
  late final SdkQueue queue;

  /// Cache store used for offline `GET` fallbacks.
  late final CacheStore cache;

  /// Initializes or replaces the global SDK singleton.
  ///
  /// Calling this again disposes the current event stream and boots a new
  /// instance with [config]. If the selected profile requests a startup flush,
  /// the queue flush is started during initialization.
  static void init(SdkConfig config) {
    _instance = Sdk._(config);
    _instance!._boot();
  }

  /// Returns the initialized SDK singleton.
  ///
  /// Throws a [StateError] if [init] has not been called yet.
  static Sdk get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('Sdk is not initialized. Call Sdk.init(...) first.');
    }
    return i;
  }

  /// Clears persisted authentication state.
  ///
  /// When [emitEvent] is `true`, [SdkEvent.signedOut] is emitted after the
  /// token store is cleared.
  Future<void> signOut({bool emitEvent = true}) async {
    await authManager.clear();
    _sessionExpiredHandled = false;
    if (emitEvent) events.emit(SdkEvent.signedOut);
  }

  /// Handles a terminal session expiration exactly once until the session state
  /// is reset by a later successful auth flow.
  Future<void> handleSessionExpired({
    Future<void> Function()? onSessionExpired,
    bool emitEvent = true,
  }) async {
    if (_sessionExpiredHandled) return;
    _sessionExpiredHandled = true;

    await authManager.clear();

    if (emitEvent) {
      events.emit(SdkEvent.sessionExpired);
    }

    if (onSessionExpired != null) {
      await onSessionExpired();
    }
  }

  /// Allows future session-expiration handling after a successful login or
  /// refresh updates the active session.
  void resetSessionExpiredHandling() {
    _sessionExpiredHandled = false;
  }

  void _boot() {
    // Core utilities first (used by call/auth)
    events = SdkEvents();
    final mergedInterceptors = [...config.interceptors];

    if (config.logging.enabled) {
      mergedInterceptors.add(
        BuiltInLoggingInterceptor(config.logging),
      );
    }

    interceptors = InterceptorRunner(mergedInterceptors);

    authManager = AuthManager(
      config.tokenStoreOverride ?? const SecureTokenStore(),
    );

    // Offline stores
    cache = config.cacheStoreOverride ?? MemoryCacheStore();
    queueStore = config.queueStoreOverride ?? MemoryQueueStore();

    // HTTP + API surface
    http = config.httpOverride ?? DioHttpClient(baseUrl: config.baseUrl);
    call = SdkCall.internal(this);
    auth = SdkAuth.internal(this);
    _sessionExpiredHandled = false;

    // Queue last (depends on http/auth/events in practice)
    queue = SdkQueue.internal(this, queueStore);

    if (config.profile.shouldFlushOnceOnInit) {
      queue.flush();
    }
  }
}
