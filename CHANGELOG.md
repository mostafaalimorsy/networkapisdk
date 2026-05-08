## 0.1.3

- Added automatic session expiration handling.
- Added `onSessionExpired` callback support in `SdkConfig`.
- Added centralized session expiration lifecycle management.
- Added automatic redirect support after refresh token failure.
- Added login-state checking with `isLoggedIn()`.
- Improved refresh token retry flow and session recovery handling.
- Fixed potential race condition in token loading and refresh flow.
- Improved authentication lifecycle reliability for both persistent and in-memory sessions.
- Improved logging implementation using `dart:developer` instead of `print`.
- Updated README documentation and authentication flow diagrams.

## 0.1.2

- Improved documentation and README clarity
- Improved pub.dev score and package quality



## 0.1.1

- Improved documentation and README clarity
- Added DartDoc comments for public APIs
- Updated package metadata and license
- Improved pub.dev score and package quality

## 0.1.0

- Initial public release.
- Added standardized API communication.
- Added authentication support with login and refresh token flow.
- Added request/response/error interceptors.
- Added offline cache support for GET requests.
- Added offline write queue with persistence.
- Added manual and automatic queue flushing.
- Added example application and package documentation.
