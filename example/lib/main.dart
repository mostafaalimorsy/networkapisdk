import 'package:flutter/material.dart';
import 'package:network_api_sdk/network_api_sdk.dart';

void main() {
  Sdk.init(
    SdkConfig(
      baseUrl: "http://BASE_URL/api",
      auth: const AuthOptions(
        loginEndpoint: "/Login/login",
        refreshEndpoint: "/Login/refresh",
        accessTokenPath: "accessToken",
        refreshTokenPath: "refreshToken",
      ),
      profile: SdkProfile.defaultSecure(),
      contract: SdkContract.auto(
        data: "data",
        message: "message",
        successFlag: "isSuccess",
        errorCode: "code",
      ),
      output: OutputOptions.jsonOnly(),
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loading = false;
  String _result = "Not logged in";

  Future<void> login() async {
    setState(() {
      _loading = true;
      _result = "Logging in...";
    });

    try {
      final response = await Sdk.instance.auth.login(
        body: {
          "username": "username",
          "password": "password",
        },
        // rememberMe: false
      );
      print("ok = ${response.ok}");

      if (response.ok) {
        final data = response.data;

        final displayName =
            data?["displayName"] ??
                "${data?["firstName"] ?? ""} ${data?["lastName"] ?? ""}".trim();

        setState(() {
          _result =
          "Login success\nWelcome ${displayName.isEmpty ? "User" : displayName}";
        });

        debugPrint("Login success");
        debugPrint("data: ${response.data}");
      } else {
        setState(() {
          _result = response.error?.message ?? "Login failed";
        });

        debugPrint("Login failed: ${response.error?.message}");
      }
    } catch (e) {
      setState(() {
        _result = "Unexpected error: $e";
      });

      debugPrint("Unexpected error: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  Future<void> signOut() async {
    try {
      await Sdk.instance.auth.signOut();

      setState(() {
        _result = "Signed out";
      });

      debugPrint("User signed out");
    } catch (e) {
      debugPrint("Sign out failed: $e");

      setState(() {
        _result = "Sign out failed";
      });
    }
  }
  Future<void> fetchContinents() async {
    setState(() {
      _loading = true;
      _result = "Loading continents...";
    });

    try {
      final response = await Sdk.instance.call.get("/continent");

      print("continents ok = ${response.ok}");

      if (response.ok) {
        final data = response.data;
        final continents = data?["data"] as List? ?? [];

        setState(() {
          _result = "Loaded ${continents.length} continents";
        });

        debugPrint("Continents response: ${response.data}");

        for (final continent in continents) {
          debugPrint("Continent name: ${continent["name"]}");
        }
      } else {
        setState(() {
          _result = response.error?.message ?? "Failed to load continents";
        });

        debugPrint("Load continents failed: ${response.error?.message}");
      }
    } catch (e) {
      setState(() {
        _result = "Unexpected error: $e";
      });

      debugPrint("Unexpected error: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _incrementCounter() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _loading ? null : login,
                child: Text(_loading ? "Logging in..." : "Login"),
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _loading ? null : fetchContinents,
                child: const Text("Load Continents"),
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text("Sign Out"),
              ),

              const SizedBox(height: 16),
              Text(
                _result,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}