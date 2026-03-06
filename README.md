# Network API SDK

A production‑ready networking SDK designed to standardize API communication in Flutter applications.  
The SDK provides authentication management, request/response normalization, offline support, caching, queue persistence, interceptors, and a unified API layer.

This package helps teams avoid rewriting networking logic across projects and provides a reliable, extensible integration layer between applications and backend APIs.

---

# 🤖 SDK AI Assistant

An official Custom GPT assistant is available to help developers integrate and troubleshoot the SDK.

Use it to:

• Learn how to initialize and configure the SDK
• Generate integration examples
• Understand authentication, offline mode, and queue behavior
• Debug common integration issues

Open the assistant here:

https://chatgpt.com/g/g-69aa3c19d9e081918dafe44ed385559c-network-api-sdk-guide

The assistant is trained using the SDK documentation, architecture notes, and implementation progress.

---

# Table of Contents

1. Overview
2. Features
3. Installation
4. Quick Start
5. SDK Initialization
6. Making API Calls
7. Request Bodies
8. Authentication
9. Interceptors
10. Offline Mode
11. Queue & Flush
12. Caching
13. Configuration Profiles
14. Error Handling
15. Example Usage
16. Project Status

---

# 1. Overview

Network API SDK is a reusable networking layer that sits between your application and backend APIs.

Instead of writing HTTP logic repeatedly in every project, the SDK provides:

• Standard request structure  
• Unified response format  
• Authentication lifecycle management  
• Offline support  
• Queue persistence  
• Extensible interceptor pipeline

The SDK is designed for **Flutter mobile applications**, but the architecture is portable to other platforms.

---

# 2. Features

• HTTP abstraction layer  
• Unified request builder  
• Response normalization  
• Contract-based backend validation  
• Authentication login + token refresh  
• Automatic Authorization header injection  
• Request/Response/Error interceptors  
• Offline caching for GET requests  
• Offline queue for write operations  
• Persistent cache and queue storage  
• Automatic queue flush

---

# 3. Installation

Add the SDK to your project:

```yaml
dependencies:
  network_api_sdk:
    path: ../network_api_sdk
```

or if published:

```yaml
dependencies:
  network_api_sdk: ^1.0.0
```

Then run:

```
flutter pub get
```

---

# 4. Quick Start

Initialize the SDK once when your application starts.

```dart
Sdk.init(
  SdkConfig(
    baseUrl: "https://api.example.com",

    profile: SdkProfile.offlineFirstSecure(),

    contract: SdkContract.auto(
      data: "result",
      message: "message",
      successFlag: "succeeded",
      errorCode: "errorCode",
    ),

    output: OutputOptions.jsonOnly(),
  ),
);
```

Access the SDK instance:

```dart
final sdk = Sdk.instance;
```

---

# 5. SDK Initialization

The SDK must be initialized once.

```dart
Sdk.init(
  SdkConfig(
    baseUrl: "https://api.example.com",
    profile: SdkProfile.defaultSecure(),
    contract: SdkContract.auto(),
    output: OutputOptions.jsonOnly(),
  ),
);
```

Attempting to access `Sdk.instance` before initialization will throw an error.

---

# 5.1 Advanced SDK Configuration

The SDK supports advanced configuration through `SdkConfig`. These options allow you to fully control networking behavior.

Example with **all available options**:

```dart
Sdk.init(
  SdkConfig(

    // Base API URL
    baseUrl: "https://api.example.com",

    // Optional custom HTTP implementation
    httpOverride: DioHttpClient(
      baseUrl: "https://api.example.com",
    ),

    // Authentication configuration
    auth: const AuthOptions(
      loginEndpoint: "/auth/login",
      refreshEndpoint: "/auth/refresh",
      accessTokenPath: "accessToken",
      refreshTokenPath: "refreshToken",
    ),

    // Token storage override (optional)
    tokenStoreOverride: SecureTokenStore(),

    // Cache storage override
    cacheStoreOverride: FileCacheStore(
      File("cache.json"),
    ),

    // Queue persistence storage override
    queueStoreOverride: FileQueueStore(
      File("queue.json"),
    ),

    // SDK behavior profile
    profile: const SdkProfile(
      offlineEnabled: true,
      queueWritesWhenOffline: true,
      autoFlushQueue: true,
      flushInterval: Duration(seconds: 30),
    ),

    // API response contract configuration
    contract: SdkContract.auto(
      data: "result",
      message: "message",
      successFlag: "succeeded",
      errorCode: "errorCode",
    ),

    // Output behavior
    output: OutputOptions.jsonOnly(),

    // Optional interceptors
    interceptors: [
      AddHeaderInterceptor(),
    ],
  ),
);
```

---

## SdkConfig Fields

| Option | Description |
|------|-------------|
| baseUrl | Base URL for all API requests |
| httpOverride | Custom HTTP client implementation |
| auth | Authentication configuration (login + refresh endpoints) |
| tokenStoreOverride | Custom token storage implementation |
| cacheStoreOverride | Custom cache storage provider |
| queueStoreOverride | Custom request queue storage |
| profile | Controls offline + queue behavior |
| contract | Defines how API responses are interpreted |
| output | Controls response normalization behavior |
| interceptors | List of request/response interceptors |

---

## Advanced Profile Options

The SDK behavior is controlled by `SdkProfile`.

```dart
const SdkProfile(
  offlineEnabled: true,
  queueWritesWhenOffline: true,
  autoFlushQueue: true,
  flushInterval: Duration(seconds: 30),
)
```

### Options

| Option | Description |
|------|-------------|
| offlineEnabled | Enables offline cache + queue features |
| queueWritesWhenOffline | Allows write requests to be queued when offline |
| autoFlushQueue | Automatically flush queued requests |
| flushInterval | Optional periodic flush interval |

---
---

# 6. Making API Calls

GET request:

```dart
final res = await Sdk.instance.call.get("/users");
```

POST request:

```dart
final res = await Sdk.instance.call.post(
  "/login",
  body: RequestBody.json({"email": "a@b.com", "password": "123"}),
);
```

PUT request:

```dart
await Sdk.instance.call.put("/profile", body: RequestBody.json(data));
```

DELETE request:

```dart
await Sdk.instance.call.delete("/session");
```

---

# 7. Request Bodies

Supported body types:

JSON

```dart
RequestBody.json({...})
```

Text

```dart
RequestBody.text("hello")
```

Binary

```dart
RequestBody.bytes(data)
```

Form URL encoded

```dart
RequestBody.formUrlEncoded({"a":1})
```

Multipart

```dart
RequestBody.multipart(
  fields: {"name": "file"},
  files: {
    "file": BodyFile(
      filename: "image.jpg",
      bytes: imageBytes,
    )
  }
)
```

---

# 8. Authentication

Login example:

```dart
final res = await Sdk.instance.auth.login(
  body: {
    "username": "user",
    "password": "123"
  },
);
```

After login the SDK automatically:

• Saves tokens
• Attaches Authorization headers
• Refreshes expired tokens

Logout:

```dart
await Sdk.instance.auth.signOut();
```

---

# 9. Interceptors

Interceptors allow modifying requests and responses.

Example:

```dart
class AddHeaderInterceptor implements SdkInterceptor {

  @override
  Future<HttpRequest?> onRequest(HttpRequest req) async {
    return req.copyWith(
      headers: {...?req.headers, "X-App": "mobile"},
    );
  }

  @override
  Future<HttpResponse?> onResponse(HttpRequest req, HttpResponse res) async {
    return res;
  }

  @override
  Future<SdkError?> onError(HttpRequest req, SdkError error) async {
    return error;
  }
}
```

Register interceptors in config:

```dart
interceptors: [
  AddHeaderInterceptor(),
]
```

---

# 10. Offline Mode

When offline the SDK can:

• Return cached GET responses  
• Queue write requests

Offline mode is enabled via profile:

```dart
profile: SdkProfile.offlineFirstSecure()
```

---

# 11. Queue & Flush

Write operations performed while offline are queued.

Flush manually:

```dart
await Sdk.instance.queue.flush();
```

Flush also happens automatically depending on SDK profile configuration.

---

# 12. Caching

Successful GET responses can be cached.

Cached responses are used when:

• Network fails  
• Device is offline

Custom cache stores can also be implemented.

---

# 13. Configuration Profiles

Profiles control SDK behavior.

Example:

```dart
SdkProfile.offlineFirstSecure()
```

Configuration options include:

• offlineEnabled  
• queueWritesWhenOffline  
• autoFlushQueue  
• flushInterval

---

# 14. Error Handling

Responses are normalized into a unified structure.

Example:

```dart
if (response.ok) {
  print(response.data);
} else {
  print(response.error?.message);
}
```

Error types include:

• Network errors  
• Contract errors  
• Backend errors

---

# 15. Example Usage

Typical flow:

```dart
await Sdk.instance.auth.login(body: credentials);

final profile = await Sdk.instance.call.get("/profile");

await Sdk.instance.call.post(
  "/orders",
  body: RequestBody.json(orderData),
);
```

---

# 16. Project Status

Current implementation progress:

Completed

• SDK core architecture  
• HTTP abstraction  
• Request normalization  
• Authentication lifecycle  
• Interceptor system  
• Offline caching  
• Offline queue  
• Disk persistence

Planned improvements

• Retry policies  
• Backoff strategies  
• Observability and metrics  
• Upload/download progress  
• Advanced cache strategies

---

# License

Internal / proprietary SDK unless published publicly.
