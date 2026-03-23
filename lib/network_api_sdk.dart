/// Public entry point for the `network_api_sdk` package.
///
/// Import this library to access the supported package surface, including
/// [Sdk], [SdkConfig], authentication helpers, interceptors, request models,
/// and offline extension points.
library;

export 'src/core/sdk.dart';

// Configuration
export 'src/config/sdk_config.dart';
export 'src/config/sdk_profile.dart';
export 'src/config/sdk_contract.dart';
export 'src/config/output_options.dart';
export 'src/config/auth_options.dart';

// Models
export 'src/models/request_body.dart';
export 'src/models/sdk_response.dart';
export 'src/models/sdk_error.dart';
export 'src/models/enums.dart';

// Auth
export 'src/auth/token_store.dart';
export 'src/auth/auth_manager.dart';
export 'src/auth/secure_token_store.dart';

// Events
export 'src/core/sdk_events.dart' show SdkEvents, SdkEvent;

// Interceptors
export 'src/interceptors/sdk_interceptor.dart';

// HTTP extension points
export 'src/http/http_client.dart';
export 'src/http/dio_http_client.dart';

// Offline extension points
export 'src/offline/cache_store.dart';
export 'src/offline/file_cache_store.dart';
export 'src/offline/queue_store.dart';
export 'src/offline/file_queue_store.dart';
