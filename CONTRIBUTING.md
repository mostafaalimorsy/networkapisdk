

# Contributing to network_api_sdk

Thank you for your interest in contributing to **network_api_sdk**.  
We welcome contributions from the community and aim to maintain high-quality standards across the project.

---

## 🚀 Getting Started

### 1. Fork the repository
Click the "Fork" button on GitHub and clone your fork:

```bash
git clone https://github.com/mostafaalimorsy/networkapisdk.git
cd network_api_sdk
```

### 2. Install dependencies

```bash
flutter pub get
cd example
flutter pub get
cd ..
```

---

## 🧪 Running Checks

Before submitting any changes, make sure everything passes:

```bash
flutter analyze
flutter test
```

---

## 🧱 Project Structure

```
lib/
 ├── network_api_sdk.dart   # Public API
 └── src/                   # Internal implementation (DO NOT import externally)
example/                    # Usage examples
test/                       # Unit tests
```

⚠️ Important:
- Only expose APIs through `network_api_sdk.dart`
- Never import from `src/` in external usage

---

## 🧾 Code Style Guidelines

- Follow Dart & Flutter best practices
- Use `snake_case` for file names
- Keep classes and methods small and focused
- Prefer composition over inheritance
- Follow SOLID principles where applicable

---

## 📚 Documentation Rules

- All public APIs must include DartDoc comments
- Keep documentation clear, concise, and example-driven
- Ensure README examples match actual implementation

Example:

```dart
/// Sends a network request using the configured SDK.
/// 
/// Returns a [SdkResponse] containing the result.
Future<SdkResponse> call(HttpRequest request);
```

---

## 🔄 Making Changes

### Branch naming

- `feature/your-feature-name`
- `fix/bug-description`
- `refactor/module-name`

---

## 📦 Pull Request Guidelines

Before submitting a PR, ensure:

- [ ] Code compiles successfully
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Public APIs are documented
- [ ] README updated (if needed)
- [ ] CHANGELOG updated (if applicable)
- [ ] No unnecessary files included

---

## 🐛 Reporting Bugs

When reporting a bug, include:

- Steps to reproduce
- Expected behavior
- Actual behavior
- Flutter & Dart versions
- Package version

---

## 💡 Suggesting Features

For feature requests:

- Clearly describe the problem
- Explain your proposed solution
- Mention any alternatives considered

---

## ⚠️ Breaking Changes

Breaking changes must:

- Be clearly documented
- Be discussed before implementation (open an issue)
- Include migration instructions

---

## 🔐 Security Issues

If you discover a security vulnerability, please do **not** open a public issue.  
Instead, contact the maintainer privately.

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the same license as this project.

---

## ❤️ Thank You

Your contributions help make this SDK better for everyone.