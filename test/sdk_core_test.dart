import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdk_core/sdk_core.dart';
import 'package:sdk_core/src/http/http_client.dart';


class MockHttpClient extends Mock implements HttpClient {}
HttpRequest _captureRequest(Invocation inv) {
  return inv.positionalArguments.first as HttpRequest;
}

class FakeTokenStore implements TokenStore {
  TokenPair? saved;
  @override
  Future<void> save(TokenPair tokens, {required bool rememberMe}) async {
    saved = tokens;
  }

  @override
  Future<TokenPair?> read() async => saved;

  @override
  Future<void> clear() async {
    saved = null;
  }
}
class AddHeaderInterceptor implements SdkInterceptor {
  @override
  Future<HttpRequest> onRequest(HttpRequest req) async {
    final h = <String, String>{...?(req.headers as Map?)?.cast<String, String>()};
    h['X-From-Interceptor'] = 'YES';
    return req.copyWith(headers: h);
  }

  @override
  Future<HttpResponse> onResponse(HttpRequest req, HttpResponse res) async => res;

  @override
  Future<SdkError> onError(HttpRequest req, SdkError error) async => error;
}


class PatchResponseInterceptor implements SdkInterceptor {
  @override
  Future<HttpRequest> onRequest(HttpRequest req) async => req;

  @override
  Future<HttpResponse> onResponse(HttpRequest req, HttpResponse res) async {
    final root = Map<String, dynamic>.from(res.data as Map);

    final resultAny = root['result'];
    if (resultAny is Map) {
      final result = Map<String, dynamic>.from(resultAny);
      result['patched'] = true;
      root['result'] = result;
    } else {
      // If there is no map result, fall back to patching the root
      root['patched'] = true;
    }

    return res.copyWith(data: root);
  }

  @override
  Future<SdkError> onError(HttpRequest req, SdkError error) async => error;
}

class PatchErrorInterceptor implements SdkInterceptor {
  @override
  Future<HttpRequest> onRequest(HttpRequest req) async => req;

  @override
  Future<HttpResponse> onResponse(HttpRequest req, HttpResponse res) async => res;

  @override
  Future<SdkError> onError(HttpRequest req, SdkError error) async {
    // Make sure we can patch the message in a deterministic way for tests
    return SdkError(
      type: error.type,
      message: 'Friendly: ${req.endpoint}',
    );
  }
}
void main() {
  setUpAll(() {
    registerFallbackValue(
      const HttpRequest(
        endpoint: '/__dummy__',
        method: 'GET',
        body: RequestBody.none(),
        responseType: ResponseTypeHint.json,
      ),
    );
  });

  group('Step 1 - SDK skeleton', () {
    setUp(() {
      // Reset singleton before each test (requires resetForTest in Sdk)
      Sdk.resetForTest();
    });

    test('Sdk.instance throws before init', () {
      expect(() => Sdk.instance, throwsA(isA<StateError>()));
    });

    test('Sdk.init initializes singleton and core modules', () {
      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          profile: SdkProfile.offlineFirstSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
          tokenStoreOverride: FakeTokenStore(),
        ),
      );

      final sdk = Sdk.instance;

      // Config is present
      expect(sdk.config.baseUrl, 'https://api.example.com');
      expect(sdk.config.profile.offlineEnabled, isTrue);
      expect(sdk.config.profile.queueWritesWhenOffline, isTrue);

      // Core modules are wired
      expect(sdk.call, isNotNull);
      expect(sdk.auth, isNotNull);
      expect(sdk.events, isNotNull);
    });
  });

  group('Step 2 - HTTP layer wiring', () {
    setUp(() {
      Sdk.resetForTest();
    });

    test('Sdk.init initializes http client', () {
      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
          ),
          output: OutputOptions.jsonOnly(),
          tokenStoreOverride: FakeTokenStore(),
        ),
      );

      final sdk = Sdk.instance;

      // HTTP client should be initialized
      expect(sdk.http, isNotNull);
    });
  });

  group('Step 3 - Sdk.call.get contract + normalization', () {
    setUp(() => Sdk.resetForTest());

    test('GET returns ok=true and extracts data via contract', () async {
      final mockHttp = MockHttpClient();

      when(() => mockHttp.send(any())).thenAnswer((invocation) async {
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: {
            "succeeded": true,
            "errorCode": 0,
            "message": "OK",
            "result": {"id": 1, "name": "Mostafa"},
          },
        );
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: FakeTokenStore(),
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.call.get('/me');

      expect(res.ok, isTrue);
      expect(res.data, isA<Map>());
      expect(res.data['name'], 'Mostafa');
      verify(() => mockHttp.send(any())).called(1);
    });

    test('GET returns ok=false when contract fails even with 200', () async {
      final mockHttp = MockHttpClient();

      when(() => mockHttp.send(any())).thenAnswer((_) async {
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: {
            "succeeded": false,
            "errorCode": 123,
            "message": "Business error",
            "result": null,
          },
        );
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: FakeTokenStore(),
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.call.get('/me');

      expect(res.ok, isFalse);
      expect(res.error, isNotNull);
      expect(res.error!.message, contains('Business'));
    });

    test('GET normalizes text response into JSON wrapper', () async {
      final mockHttp = MockHttpClient();

      when(() => mockHttp.send(any())).thenAnswer((_) async {
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: "plain text",
        );
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: FakeTokenStore(),
          profile: SdkProfile.defaultSecure(),
          // هنا contract success by status فقط (body مش Map)
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
          ),
          output: OutputOptions.jsonOnly(tryParseJsonText: false),
        ),
      );

      final res = await Sdk.instance.call.get('/ping', responseType: ResponseTypeHint.text);

      expect(res.ok, isTrue);
      expect(res.data, isA<Map>());
      expect(res.data['type'], 'text');
      expect(res.data['value'], 'plain text');
    });
  });
  group('Step 3.3 - Methods + Body types', () {
    setUp(() => Sdk.resetForTest());

    test('POST sends JSON body', () async {
      final mockHttp = MockHttpClient();

      late HttpRequest captured;

      when(() => mockHttp.send(any())).thenAnswer((inv) async {
        captured = _captureRequest(inv);
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: {"succeeded": true, "errorCode": 0, "message": "OK", "result": true},
        );
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: FakeTokenStore(),
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.call.post(
        '/login',
        body: RequestBody.json({"u": "x", "p": "y"}),
      );

      expect(res.ok, isTrue);
      expect(captured.method, 'POST');
      expect(captured.body.type, BodyType.json);
      expect(captured.body.value, isA<Map>());
    });

    test('PUT sends formUrlEncoded body', () async {
      final mockHttp = MockHttpClient();
      late HttpRequest captured;

      when(() => mockHttp.send(any())).thenAnswer((inv) async {
        captured = _captureRequest(inv);
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: {"succeeded": true, "errorCode": 0, "message": "OK", "result": true},
        );
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: FakeTokenStore(),
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.call.put(
        '/profile',
        body: RequestBody.formUrlEncoded({"name": "Mostafa"}),
      );

      expect(res.ok, isTrue);
      expect(captured.method, 'PUT');
      expect(captured.body.type, BodyType.formUrlEncoded);
    });

    test('DELETE sends no body by default', () async {
      final mockHttp = MockHttpClient();
      late HttpRequest captured;

      when(() => mockHttp.send(any())).thenAnswer((inv) async {
        captured = _captureRequest(inv);
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: {"succeeded": true, "errorCode": 0, "message": "OK", "result": true},
        );
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: FakeTokenStore(),
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.call.delete('/session');

      expect(res.ok, isTrue);
      expect(captured.method, 'DELETE');
      expect(captured.body.type, BodyType.none);
    });
  });
  group('Step 4.2 - Auth login', () {
    setUp(() => Sdk.resetForTest());

    test('login saves tokens from response', () async {
      final mockHttp = MockHttpClient();
      final tokenStore = FakeTokenStore();

      when(() => mockHttp.send(any())).thenAnswer((_) async {
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: {
            "succeeded": true,
            "errorCode": 0,
            "message": "OK",
            "result": {
              "accessToken": "ACCESS",
              "refreshToken": "REFRESH",
            }
          },
        );
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: tokenStore,
          auth: const AuthOptions(
            loginEndpoint: '/auth/login',
            refreshEndpoint: '/auth/refresh',
            accessTokenPath: 'accessToken',
            refreshTokenPath: 'refreshToken',
          ),
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.auth.login(
        body: {"u": "x", "p": "y"},
        rememberMe: true,
      );

      expect(res.ok, isTrue);
      expect(tokenStore.saved, isNotNull);
      expect(tokenStore.saved!.accessToken, 'ACCESS');
      expect(tokenStore.saved!.refreshToken, 'REFRESH');
    });
  });
  group('Step 4.3-A - Auto attach token', () {
    setUp(() => Sdk.resetForTest());

    test('attaches Authorization header when token exists', () async {
      final mockHttp = MockHttpClient();
      final tokenStore = FakeTokenStore();

      // save tokens first
      await tokenStore.save(
        const TokenPair(accessToken: 'ACCESS_123', refreshToken: 'REFRESH_123'),
        rememberMe: true,
      );

      late HttpRequest captured;

      when(() => mockHttp.send(any())).thenAnswer((inv) async {
        captured = inv.positionalArguments.first as HttpRequest;
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: {
            "succeeded": true,
            "errorCode": 0,
            "message": "OK",
            "result": {"x": 1}
          },
        );
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: tokenStore,
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.call.get('/protected');

      expect(res.ok, isTrue);
      expect(captured.headers, isNotNull);
      expect(captured.headers!['Authorization'], 'Bearer ACCESS_123');
    });

    test('does NOT attach Authorization when attachAuth=false', () async {
      final mockHttp = MockHttpClient();
      final tokenStore = FakeTokenStore();

      await tokenStore.save(
        const TokenPair(accessToken: 'ACCESS_123', refreshToken: 'REFRESH_123'),
        rememberMe: true,
      );

      late HttpRequest captured;

      when(() => mockHttp.send(any())).thenAnswer((inv) async {
        captured = inv.positionalArguments.first as HttpRequest;
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: {
            "succeeded": true,
            "errorCode": 0,
            "message": "OK",
            "result": {"x": 1}
          },
        );
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: tokenStore,
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.call.get('/public', attachAuth: false);

      expect(res.ok, isTrue);
      expect(captured.headers?['Authorization'], isNull);
    });
  });
  group('Step 4.3-B - Refresh token + retry', () {
    setUp(() => Sdk.resetForTest());

    test('on 401 it refreshes then retries and succeeds', () async {
      final mockHttp = MockHttpClient();
      final tokenStore = FakeTokenStore();

      // start with OLD tokens
      await tokenStore.save(
        const TokenPair(accessToken: 'OLD_ACCESS', refreshToken: 'REFRESH_1'),
        rememberMe: true,
      );

      int protectedCalls = 0;

      when(() => mockHttp.send(any())).thenAnswer((inv) async {
        final req = inv.positionalArguments.first as HttpRequest;

        if (req.endpoint == '/protected') {
          protectedCalls++;
          // first time -> 401, second time -> 200
          if (protectedCalls == 1) {
            return const HttpResponse(statusCode: 401, headers: {}, data: {
              "succeeded": false,
              "errorCode": 401,
              "message": "Unauthorized",
              "result": null,
            });
          }
          return const HttpResponse(statusCode: 200, headers: {}, data: {
            "succeeded": true,
            "errorCode": 0,
            "message": "OK",
            "result": {"x": 1},
          });
        }

        if (req.endpoint == '/auth/refresh') {
          // refresh returns NEW tokens
          return const HttpResponse(statusCode: 200, headers: {}, data: {
            "succeeded": true,
            "errorCode": 0,
            "message": "OK",
            "result": {
              "accessToken": "NEW_ACCESS",
              "refreshToken": "NEW_REFRESH",
            }
          });
        }

        throw StateError('Unexpected endpoint: ${req.endpoint}');
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: tokenStore,
          auth: const AuthOptions(
            loginEndpoint: '/auth/login',
            refreshEndpoint: '/auth/refresh',
            accessTokenPath: 'accessToken',
            refreshTokenPath: 'refreshToken',
          ),
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.call.get('/protected');

      expect(res.ok, isTrue);
      expect(res.data['x'], 1);

      // tokens should be updated
      expect(tokenStore.saved!.accessToken, 'NEW_ACCESS');
      expect(tokenStore.saved!.refreshToken, 'NEW_REFRESH');
    });

    test('single-flight: multiple 401 triggers only one refresh call', () async {
      final mockHttp = MockHttpClient();
      final tokenStore = FakeTokenStore();

      await tokenStore.save(
        const TokenPair(accessToken: 'OLD_ACCESS', refreshToken: 'REFRESH_1'),
        rememberMe: true,
      );

      int refreshCalls = 0;

      when(() => mockHttp.send(any())).thenAnswer((inv) async {
        final req = inv.positionalArguments.first as HttpRequest;

        if (req.endpoint == '/protected') {
          // Always return 401 first time until refresh completes, then OK.
          final auth = req.headers?['Authorization'] ?? '';
          if (auth.contains('NEW_ACCESS')) {
            return const HttpResponse(statusCode: 200, headers: {}, data: {
              "succeeded": true,
              "errorCode": 0,
              "message": "OK",
              "result": {"ok": true},
            });
          }
          return const HttpResponse(statusCode: 401, headers: {}, data: {
            "succeeded": false,
            "errorCode": 401,
            "message": "Unauthorized",
            "result": null,
          });
        }

        if (req.endpoint == '/auth/refresh') {
          refreshCalls++;
          // simulate refresh success
          return const HttpResponse(statusCode: 200, headers: {}, data: {
            "succeeded": true,
            "errorCode": 0,
            "message": "OK",
            "result": {
              "accessToken": "NEW_ACCESS",
              "refreshToken": "NEW_REFRESH",
            }
          });
        }

        throw StateError('Unexpected endpoint: ${req.endpoint}');
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: tokenStore,
          auth: const AuthOptions(
            loginEndpoint: '/auth/login',
            refreshEndpoint: '/auth/refresh',
            accessTokenPath: 'accessToken',
            refreshTokenPath: 'refreshToken',
          ),
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      // fire 3 calls in parallel
      final results = await Future.wait([
        Sdk.instance.call.get('/protected'),
        Sdk.instance.call.get('/protected'),
        Sdk.instance.call.get('/protected'),
      ]);

      for (final r in results) {
        expect(r.ok, isTrue);
        expect(r.data['ok'], true);
      }

      expect(refreshCalls, 1); // ✅ single-flight تحقق
    });
  });
  group('Step 4.4 - Refresh failure + session expired event', () {
    setUp(() => Sdk.resetForTest());

    test('if refresh fails, it clears tokens, emits sessionExpired, and does not retry protected', () async {
      final mockHttp = MockHttpClient();
      final tokenStore = FakeTokenStore();

      await tokenStore.save(
        const TokenPair(accessToken: 'OLD_ACCESS', refreshToken: 'REFRESH_1'),
        rememberMe: true,
      );

      int protectedCalls = 0;
      int refreshCalls = 0;

      when(() => mockHttp.send(any())).thenAnswer((inv) async {
        final req = inv.positionalArguments.first as HttpRequest;

        if (req.endpoint == '/protected') {
          protectedCalls++;
          return const HttpResponse(statusCode: 401, headers: {}, data: {
            "succeeded": false,
            "errorCode": 401,
            "message": "Unauthorized",
            "result": null,
          });
        }

        if (req.endpoint == '/auth/refresh') {
          refreshCalls++;
          return const HttpResponse(statusCode: 401, headers: {}, data: {
            "succeeded": false,
            "errorCode": 401,
            "message": "Refresh unauthorized",
            "result": null,
          });
        }

        throw StateError('Unexpected endpoint: ${req.endpoint}');
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: tokenStore,
          auth: const AuthOptions(
            loginEndpoint: '/auth/login',
            refreshEndpoint: '/auth/refresh',
            accessTokenPath: 'accessToken',
            refreshTokenPath: 'refreshToken',
          ),
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final events = <SdkEvent>[];
      final sub = Sdk.instance.events.stream.listen(events.add);
      addTearDown(sub.cancel);

      final res = await Sdk.instance.call.get('/protected');

      expect(res.ok, isFalse);
      expect(refreshCalls, 1);
      expect(protectedCalls, 1); // no retry when refresh failed
      expect(tokenStore.saved, isNull); // cleared
      expect(events, contains(SdkEvent.sessionExpired)); // emitted
    });

    test('if refresh succeeds but retry is still 401, it clears tokens and emits sessionExpired', () async {
      final mockHttp = MockHttpClient();
      final tokenStore = FakeTokenStore();

      await tokenStore.save(
        const TokenPair(accessToken: 'OLD_ACCESS', refreshToken: 'REFRESH_1'),
        rememberMe: true,
      );

      int protectedCalls = 0;
      int refreshCalls = 0;

      when(() => mockHttp.send(any())).thenAnswer((inv) async {
        final req = inv.positionalArguments.first as HttpRequest;

        if (req.endpoint == '/protected') {
          protectedCalls++;
          return const HttpResponse(statusCode: 401, headers: {}, data: {
            "succeeded": false,
            "errorCode": 401,
            "message": "Unauthorized",
            "result": null,
          });
        }

        if (req.endpoint == '/auth/refresh') {
          refreshCalls++;
          return const HttpResponse(statusCode: 200, headers: {}, data: {
            "succeeded": true,
            "errorCode": 0,
            "message": "OK",
            "result": {
              "accessToken": "NEW_ACCESS",
              "refreshToken": "NEW_REFRESH",
            }
          });
        }

        throw StateError('Unexpected endpoint: ${req.endpoint}');
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: tokenStore,
          auth: const AuthOptions(
            loginEndpoint: '/auth/login',
            refreshEndpoint: '/auth/refresh',
            accessTokenPath: 'accessToken',
            refreshTokenPath: 'refreshToken',
          ),
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final events = <SdkEvent>[];
      final sub = Sdk.instance.events.stream.listen(events.add);
      addTearDown(sub.cancel);

      final res = await Sdk.instance.call.get('/protected');

      expect(res.ok, isFalse);
      expect(refreshCalls, 1);
      expect(protectedCalls, 2); // retried once
      expect(tokenStore.saved, isNull); // cleared after retry still 401
      expect(events, contains(SdkEvent.sessionExpired)); // emitted
    });
  });
  group('Step 4.5 - Sign out', () {
    setUp(() => Sdk.resetForTest());

    test('signOut clears tokens and emits signedOut', () async {
      final tokenStore = FakeTokenStore();

      await tokenStore.save(
        const TokenPair(accessToken: 'ACCESS_1', refreshToken: 'REFRESH_1'),
        rememberMe: true,
      );

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          tokenStoreOverride: tokenStore,
          auth: const AuthOptions(
            loginEndpoint: '/auth/login',
            refreshEndpoint: '/auth/refresh',
            accessTokenPath: 'accessToken',
            refreshTokenPath: 'refreshToken',
          ),
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final events = <SdkEvent>[];
      final sub = Sdk.instance.events.stream.listen(events.add);
      addTearDown(sub.cancel);

      await Sdk.instance.auth.signOut();

      expect(tokenStore.saved, isNull);
      expect(events, contains(SdkEvent.signedOut));
    });
  });
  group('Step 4.6 - Token persistence on init', () {
    setUp(() => Sdk.resetForTest());

    test('after init, protected call attaches token loaded from TokenStore', () async {
      final mockHttp = MockHttpClient();
      final tokenStore = FakeTokenStore();

      // simulate previously saved tokens BEFORE init
      await tokenStore.save(
        const TokenPair(accessToken: 'PERSISTED_ACCESS', refreshToken: 'PERSISTED_REFRESH'),
        rememberMe: true,
      );

      late HttpRequest captured;

      when(() => mockHttp.send(any())).thenAnswer((inv) async {
        captured = inv.positionalArguments.first as HttpRequest;
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: {"succeeded": true, "errorCode": 0, "message": "OK", "result": {"ok": true}},
        );
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: tokenStore,
          profile: SdkProfile.defaultSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.call.get('/protected');

      expect(res.ok, isTrue);
      expect(captured.headers?['Authorization'], 'Bearer PERSISTED_ACCESS');
    });
  });
  group('Step 5.1 - Interceptors', () {
    setUp(() => Sdk.resetForTest());

    test('onRequest can add headers', () async {
      final mockHttp = MockHttpClient();
      late HttpRequest captured;

      when(() => mockHttp.send(any())).thenAnswer((inv) async {
        captured = inv.positionalArguments.first as HttpRequest;
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: {"succeeded": true, "errorCode": 0, "message": "OK", "result": {"x": 1}},
        );
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: FakeTokenStore(),
          profile: SdkProfile.defaultSecure(),
          interceptors: [
            AddHeaderInterceptor(),
          ],
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.call.get('/any');

      expect(res.ok, isTrue);
      expect(captured.headers?['X-From-Interceptor'], 'YES');
    });

    test('onResponse can patch normalized output', () async {
      final mockHttp = MockHttpClient();

      when(() => mockHttp.send(any())).thenAnswer((_) async {
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: {"succeeded": true, "errorCode": 0, "message": "OK", "result": {"x": 1}},
        );
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: FakeTokenStore(),
          profile: SdkProfile.defaultSecure(),
          interceptors: [
            PatchResponseInterceptor(),
          ],
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.call.get('/any');

      expect(res.ok, isTrue);
      // لأن interceptor عدّل الـ HttpResponse قبل normalization
      // فهتلاقي patched وصلت للي تحت
      expect(res.data, isA<Map>());
      expect((res.data as Map)['patched'], true);
    });
  });

  group('Step 5.2 - Interceptors onError', () {
    setUp(() => Sdk.resetForTest());

    test('onError can patch error message when http client throws', () async {
      final mockHttp = MockHttpClient();

      when(() => mockHttp.send(any())).thenThrow(Exception('boom'));

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: FakeTokenStore(),
          profile: SdkProfile.defaultSecure(),
          interceptors: [
            PatchErrorInterceptor(),
          ],
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.call.get('/any');

      expect(res.ok, isFalse);
      expect(res.error, isNotNull);
      expect(res.error!.message, 'Friendly: /any');
      verify(() => mockHttp.send(any())).called(1);
    });
  });
  group('Step 6.1 - Offline GET uses cache', () {
    setUp(() => Sdk.resetForTest());

    test('when offline, GET returns cached response if exists', () async {
      final mockHttp = MockHttpClient();

      // First call online -> success
      when(() => mockHttp.send(any())).thenAnswer((_) async {
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: {
            "succeeded": true,
            "errorCode": 0,
            "message": "OK",
            "result": {"x": 1}
          },
        );
      });

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: FakeTokenStore(),
          profile: SdkProfile.offlineFirstSecure(), // ✅ offline enabled
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      // Online first (cache it)
      final r1 = await Sdk.instance.call.get('/me');
      expect(r1.ok, isTrue);
      expect(r1.data['x'], 1);

      // Now simulate offline (throw)
      when(() => mockHttp.send(any())).thenThrow(Exception('offline'));

      // Offline should return cached
      final r2 = await Sdk.instance.call.get('/me');
      expect(r2.ok, isTrue);
      expect(r2.data['x'], 1);
    });
  });

  group('Step 6.2 - Offline write queues request', () {
    setUp(() => Sdk.resetForTest());

    test('when offline, POST is queued if queueWritesWhenOffline=true', () async {
      final mockHttp = MockHttpClient();

      when(() => mockHttp.send(any())).thenThrow(Exception('offline'));

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: FakeTokenStore(),
          profile: SdkProfile.offlineFirstSecure(), // ✅ queueWritesWhenOffline=true
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      final res = await Sdk.instance.call.post(
        '/tasks',
        body: RequestBody.json({"a": 1}),
      );

      // queued but not failed
      expect(res.ok, isTrue);
      expect(res.data, isA<Map>());
      expect(res.data['queued'], true);
    });
  });

  group('Step 6.3 - Flush queue sends queued writes', () {
    setUp(() => Sdk.resetForTest());

    test('flush sends queued requests in order and clears queue on success', () async {
      final mockHttp = MockHttpClient();

      // Start offline
      when(() => mockHttp.send(any())).thenThrow(Exception('offline'));

      Sdk.init(
        SdkConfig(
          baseUrl: 'https://api.example.com',
          httpOverride: mockHttp,
          tokenStoreOverride: FakeTokenStore(),
          profile: SdkProfile.offlineFirstSecure(),
          contract: SdkContract.auto(
            data: 'result',
            message: 'message',
            successFlag: 'succeeded',
            errorCode: 'errorCode',
          ),
          output: OutputOptions.jsonOnly(),
        ),
      );

      // Queue 2 writes
      final r1 = await Sdk.instance.call.post('/a', body: RequestBody.json({"x": 1}));
      final r2 = await Sdk.instance.call.put('/b', body: RequestBody.json({"y": 2}));

      expect(r1.ok, isTrue);
      expect((r1.data as Map)['queued'], true);
      expect(r2.ok, isTrue);
      expect((r2.data as Map)['queued'], true);

      // Now go online: return OK for any queued request
      int calls = 0;
      when(() => mockHttp.send(any())).thenAnswer((inv) async {
        calls++;
        return const HttpResponse(
          statusCode: 200,
          headers: {},
          data: {"succeeded": true, "errorCode": 0, "message": "OK", "result": true},
        );
      });

      final flushed = await Sdk.instance.queue.flush();
      expect(flushed, 2);
      expect(calls, 2);

      // Flush again should do nothing
      final flushed2 = await Sdk.instance.queue.flush();
      expect(flushed2, 0);
    });
  });
}
