
# Network API SDK

A reusable Flutter networking SDK that standardizes API communication, authentication, response normalization, interceptors, offline caching, offline queueing, persistence, and queue flushing across applications.

---

## 🤖 SDK AI Assistant

An official Custom GPT assistant is available to help developers integrate and troubleshoot the SDK.

Use it to:

- Learn SDK initialization
- Generate integration examples
- Understand authentication and refresh tokens
- Debug integration problems
- Understand offline queue behavior

Assistant:

https://chatgpt.com/g/g-69aa3c19d9e081918dafe44ed385559c-network-api-sdk-guide

---

# Table of Contents

1. [Overview](#1-overview)
2. [Public API Surface](#2-public-api-surface)
3. [Installation](#3-installation)
4. [Importing SDK](#4-importing-sdk)
5. [Architecture](#5-architecture)
6. [Quick Start](#6-quick-start)
7. [SDK Initialization](#7-sdk-initialization)
8. [SdkConfig Reference](#8-sdkconfig-reference)
9. [SdkProfile Reference](#9-sdkprofile-reference)
10. [SdkContract Reference](#10-sdkcontract-reference)
11. [OutputOptions Reference](#11-outputoptions-reference)
12. [AuthOptions Reference](#12-authoptions-reference)
13. [HTTP Calls](#13-http-calls)
14. [RequestBody Types](#14-requestbody-types)
15. [Authentication](#15-authentication)
16. [Interceptors](#16-interceptors)
17. [Response Model](#17-response-model)
18. [Error Model](#18-error-model)
19. [Events](#19-events)
20. [Offline Support](#20-offline-support)
21. [Persistence Stores](#21-persistence-stores)
22. [HTTP Extension Points](#22-http-extension-points)
23. [Example Project](#23-example-project)
24. [Advanced Initialization](#24-advanced-initialization)
25. [Flow Diagrams](#25-flow-diagrams)
26. [Troubleshooting](#26-troubleshooting)
27. [Project Status](#27-project-status)

---

# 1. Overview

Network API SDK is a standardized networking layer for Flutter applications.

It centralizes:

- request construction
- response normalization
- contract-based success/error evaluation
- authentication lifecycle
- interceptor execution
- offline caching
- offline request queue
- persistent request queue
- queue flushing

The goal is to make API integration consistent across applications.

---

# 2. Public API Surface

## Core

- `Sdk`
- `SdkEvents`
- `SdkEvent`

## Configuration

- `SdkConfig`
- `SdkProfile`
- `SdkContract`
- `OutputOptions`
- `AuthOptions`

## Models

- `RequestBody`
- `BodyFile`
- `BodyType`
- `ResponseTypeHint`
- `SdkResponse`
- `SdkError`
- `ResponseSource`
- `ErrorType`

## Authentication

- `AuthManager`
- `TokenStore`
- `SecureTokenStore`

## Interceptors

- `SdkInterceptor`

## HTTP Layer

- `HttpClient`
- `HttpRequest`
- `HttpResponse`
- `DioHttpClient`

## Offline Layer

- `CacheStore`
- `FileCacheStore`
- `QueueStore`
- `FileQueueStore`

---

# 3. Installation

### Local dependency

```yaml
dependencies:
  network_api_sdk:
    path: ../network_api_sdk
```

### Published dependency

```yaml
dependencies:
  network_api_sdk: ^1.0.0
```

Run:

```bash
flutter pub get
```

---

# 4. Importing SDK

```dart
import 'package:network_api_sdk/network_api_sdk.dart';
```

Always import from the package root.

Avoid importing from `src`.

---

# 5. Architecture

SDK architecture layers:

```text
Application Layer
        ↓
     SDK Core
        ↓
     HTTP Layer
        ↓
    Storage Layer
```

### SDK Core Responsibilities

- Request building
- Response normalization
- Authentication lifecycle
- Contract evaluation
- Interceptors
- Offline orchestration

---

# 6. Quick Start

Initialize the SDK:

```dart
Sdk.init(
  SdkConfig(
    baseUrl: 'https://api.example.com',
    profile: SdkProfile.defaultSecure(),
    contract: SdkContract.auto(
      data: 'data',
      message: 'message',
      successFlag: 'isSuccess',
      errorCode: 'code',
    ),
    output: OutputOptions.jsonOnly(),
  ),
);
```

Example usage:

```dart
final response = await Sdk.instance.call.get('/profile');
```

---

# 7. SDK Initialization

Initialize once:

```dart
Sdk.init(SdkConfig(...));
```

Access instance:

```dart
Sdk.instance
```

Available modules:

- `Sdk.instance.call`
- `Sdk.instance.auth`
- `Sdk.instance.events`
- `Sdk.instance.http`
- `Sdk.instance.cache`
- `Sdk.instance.queue`
- `Sdk.instance.config`

---

# 8. SdkConfig Reference

Primary SDK configuration.

Example:

```dart
SdkConfig(
  baseUrl: 'https://api.example.com',
  profile: SdkProfile.defaultSecure(),
  contract: SdkContract.auto(),
  output: OutputOptions.jsonOnly(),
)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `baseUrl` | `String` | Yes | API base URL |
| `httpOverride` | `HttpClient?` | No | Custom HTTP client |
| `auth` | `AuthOptions?` | No | Authentication configuration |
| `tokenStoreOverride` | `TokenStore?` | No | Custom token storage |
| `cacheStoreOverride` | `CacheStore?` | No | Custom cache store |
| `queueStoreOverride` | `QueueStore?` | No | Custom queue store |
| `profile` | `SdkProfile` | Yes | Offline configuration |
| `contract` | `SdkContract` | Yes | API contract |
| `output` | `OutputOptions` | Yes | Response normalization |
| `interceptors` | `List<SdkInterceptor>?` | No | SDK interceptors |

---

# 9. SdkProfile Reference

Controls offline behavior.

```dart
const SdkProfile(
  offlineEnabled: true,
  queueWritesWhenOffline: true,
  autoFlushQueue: true,
  flushInterval: null,
)
```

| Field | Type | Description |
|------|------|-------------|
| `offlineEnabled` | `bool` | Enable offline features |
| `queueWritesWhenOffline` | `bool` | Queue writes when offline |
| `autoFlushQueue` | `bool` | Auto flush queue |
| `flushInterval` | `Duration?` | Periodic flush interval |

Factories:

```dart
SdkProfile.defaultSecure();
SdkProfile.offlineFirstSecure();
```

---

# 10. SdkContract Reference

Defines backend response structure.

```dart
SdkContract.auto(
  data: 'data',
  message: 'message',
  successFlag: 'isSuccess',
  errorCode: 'code',
)
```

Fallback error path:

```text
errors[0].message
```

---

# 11. OutputOptions Reference

Controls SDK output format.

```dart
OutputOptions.jsonOnly();
```

Advanced:

```dart
OutputOptions.jsonOnly(
  tryParseJsonText: true,
  bytesMode: BytesJsonMode.base64,
);
```

---

# 12. AuthOptions Reference

```dart
AuthOptions(
  loginEndpoint: '/auth/login',
  refreshEndpoint: '/auth/refresh',
  accessTokenPath: 'accessToken',
  refreshTokenPath: 'refreshToken',
);
```

| Field | Type | Description |
|------|------|-------------|
| `loginEndpoint` | `String` | Login API |
| `refreshEndpoint` | `String` | Refresh API |
| `accessTokenPath` | `String` | Access token path |
| `refreshTokenPath` | `String` | Refresh token path |
| `refreshRequestKey` | `String?` | Optional refresh body key |

---

# 13. HTTP Calls

Main entry:

```dart
Sdk.instance.call
```

Methods:

- `get`
- `post`
- `put`
- `delete`
- `any`

Example:

```dart
final res = await Sdk.instance.call.get('/users');
```

### HTTP Call Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `endpoint` | `String` | Yes | API endpoint path |
| `query` | `Map<String, dynamic>?` | No | Query parameters |
| `headers` | `Map<String, String>?` | No | Request headers |
| `body` | `RequestBody?` | No | Request payload |
| `responseType` | `ResponseTypeHint?` | No | Expected response type |
| `attachAuth` | `bool` | No | Whether to attach bearer token |

---

# 14. RequestBody Types

Constructors:

```dart
RequestBody.none()
RequestBody.json()
RequestBody.text()
RequestBody.bytes()
RequestBody.formUrlEncoded()
RequestBody.multipart()
```

Example:

```dart
RequestBody.json({
  'email': 'a@b.com',
});
```

### BodyFile

Used in multipart uploads.

| Field | Type | Description |
|------|------|-------------|
| `filename` | `String` | File name |
| `bytes` | `Uint8List` | File data |
| `contentType` | `String?` | MIME type |

---

# 15. Authentication

Login example:

```dart
await Sdk.instance.auth.login(
  body: {
    'username': 'user',
    'password': 'password',
  },
  rememberMe: true,
);
```

### Login parameters

| Parameter | Type | Description |
|----------|------|-------------|
| `body` | `Map` | Login payload |
| `headers` | `Map?` | Extra headers |
| `rememberMe` | `bool` | Persist tokens |

### Sign Out

```dart
await Sdk.instance.auth.signOut();
```

---

# 16. Interceptors

Example:

```dart
class MyInterceptor implements SdkInterceptor {
  @override
  Future<HttpRequest?> onRequest(HttpRequest req) async => req;

  @override
  Future<HttpResponse?> onResponse(HttpRequest req, HttpResponse res) async => res;

  @override
  Future<SdkError?> onError(HttpRequest req, SdkError error) async => error;
}
```

Register:

```dart
interceptors: [
  MyInterceptor(),
]
```

---

# 17. Response Model

SDK responses return `SdkResponse`.

Example:

```dart
if (res.ok) {
  print(res.data);
}
```

| Field | Type |
|------|------|
| `ok` | `bool` |
| `data` | `dynamic` |
| `error` | `SdkError?` |
| `statusCode` | `int` |
| `message` | `String?` |
| `source` | `ResponseSource` |

### ResponseSource

- `network`
- `cache`
- `queued`

---

# 18. Error Model

SDK errors return `SdkError`.

| Field | Type |
|------|------|
| `type` | `ErrorType` |
| `message` | `String` |
| `statusCode` | `int?` |
| `raw` | `dynamic` |

### ErrorType

- `offline`
- `timeout`
- `unauthorized`
- `forbidden`
- `badRequest`
- `server`
- `contract`
- `parse`
- `unknown`

---

# 19. Events

Listen:

```dart
Sdk.instance.events.stream.listen((event) {
  // handle event
});
```

Events:

- `sessionExpired`
- `signedOut`

---

# 20. Offline Support

When enabled:

- GET → cache fallback
- WRITE → queued request

Manual queue flush:

```dart
await Sdk.instance.queue.flush();
```

---

# 21. Persistence Stores

Tokens

- `TokenStore`
- `SecureTokenStore`

Cache

- `CacheStore`
- `FileCacheStore`

Queue

- `QueueStore`
- `FileQueueStore`

---

# 22. HTTP Extension Points

Default client:

```dart
DioHttpClient
```

Constructor:

```dart
DioHttpClient(
  baseUrl: 'https://api.example.com',
  connectTimeout: Duration(seconds: 20),
  receiveTimeout: Duration(seconds: 30),
);
```

---

# 23. Example Project

Located in:

```text
/example
```

Run:

```bash
cd example
flutter pub get
flutter run
```

---

# 24. Advanced Initialization

Offline-first configuration:

```dart
Sdk.init(
  SdkConfig(
    baseUrl: 'https://api.example.com',
    profile: SdkProfile.offlineFirstSecure(),
    contract: SdkContract.auto(),
    output: OutputOptions.jsonOnly(),
  ),
);
```

---

# 25. Flow Diagrams

Authentication flow:

```text
Login
 ↓
Save Tokens
 ↓
Attach Bearer
 ↓
401
 ↓
Refresh
 ↓
Retry Request
```

Offline queue flow:

```text
Write Request
 ↓
No Internet
 ↓
Queue
 ↓
Persist
 ↓
Flush Later
```

---

# 26. Troubleshooting

SDK not initialized:

```dart
Sdk.init(
  SdkConfig(
    baseUrl: 'https://api.example.com',
    profile: SdkProfile.defaultSecure(),
    contract: SdkContract.auto(),
    output: OutputOptions.jsonOnly(),
  ),
);
```

Refresh token failing:

Check:

- `refreshEndpoint`
- `refreshTokenPath`
- `accessTokenPath`

---

# 27. Project Status

## Implemented

- SDK initialization
- contract parsing
- authentication login
- refresh token
- bearer token attach
- interceptors
- offline cache
- offline queue
- queue persistence
- manual queue flush
- auto flush on init
- SDK events

## Planned

- retry policies
- observability
- upload progress
- cache invalidation
- advanced queue policies
