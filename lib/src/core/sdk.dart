import 'package:meta/meta.dart';

import '../auth/auth_manager.dart';
import '../auth/secure_token_store.dart';
import '../config/sdk_config.dart';
import '../http/dio_http_client.dart';
import '../http/http_client.dart';
import '../interceptors/interceptor_runner.dart';
import 'sdk_auth.dart';
import 'sdk_call.dart';
import 'sdk_events.dart';
import '../offline/sdk_queue.dart';
import '../offline/queue_store.dart';
import '../offline/cache_store.dart';
class Sdk {
  Sdk._(this.config);

  static Sdk? _instance;

  @visibleForTesting
  static void resetForTest() {
    _instance?._dispose();
    _instance = null;
  }

  void _dispose() {
    events.dispose();
  }

  final SdkConfig config;

  late final HttpClient http;
  late final SdkCall call;
  late final SdkAuth auth;
  late final SdkEvents events;

  late final AuthManager authManager;

  late final InterceptorRunner interceptors;
  late final QueueStore queueStore;
  late final SdkQueue queue;
  late final CacheStore cache;

  static void init(SdkConfig config) {
    _instance = Sdk._(config);
    _instance!._boot();
  }

  static Sdk get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('Sdk is not initialized. Call Sdk.init(...) first.');
    }
    return i;
  }

  Future<void> signOut({bool emitEvent = true}) async {
    await authManager.clear();
    if (emitEvent) events.emit(SdkEvent.signedOut);
  }

  void _boot() {
    // Core utilities first (used by call/auth)
    events = SdkEvents();
    interceptors = InterceptorRunner(config.interceptors);
    authManager = AuthManager(
      config.tokenStoreOverride ?? const SecureTokenStore(),
    );

    // HTTP + API surface
    http = config.httpOverride ?? DioHttpClient(baseUrl: config.baseUrl);
    call = SdkCall.internal(this);
    auth = SdkAuth.internal(this);
    cache = config.cacheStoreOverride ?? MemoryCacheStore();

    queueStore = config.queueStoreOverride ?? MemoryQueueStore();

    queue = SdkQueue.internal(this, queueStore);
  }
}