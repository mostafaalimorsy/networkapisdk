/// Controls the SDK's built-in offline cache and request queue behavior.
///
/// The current implementation uses [offlineEnabled] and
/// [queueWritesWhenOffline] during request execution. Auto-flush settings are
/// currently limited to a single queue flush during SDK initialization.
class SdkProfile {
  /// Enables offline cache lookup for failed `GET` requests.
  final bool offlineEnabled;

  /// Queues non-`GET` requests when a network failure occurs.
  final bool queueWritesWhenOffline;

  /// Requests automatic queue flushing behavior.
  ///
  /// In the current implementation, this only triggers a single flush during
  /// SDK startup when [flushInterval] is `null`.
  final bool autoFlushQueue;

  /// Optional interval for future auto-flush scheduling.
  ///
  /// The built-in SDK does not currently schedule a periodic timer for this
  /// value.
  final Duration? flushInterval;

  /// Whether the queue should be flushed once during initialization.
  @Deprecated('Use autoFlushQueue + flushInterval instead.')
  final bool autoFlushOnInit;

  /// Creates a runtime profile for offline and queueing behavior.
  const SdkProfile({
    required this.offlineEnabled,
    required this.queueWritesWhenOffline,
    this.autoFlushQueue = false,
    this.flushInterval,
    @Deprecated('Use autoFlushQueue + flushInterval instead.')
    this.autoFlushOnInit = false,
  });

  /// Whether startup should trigger a one-time queue flush.
  bool get shouldFlushOnceOnInit =>
      // ignore: deprecated_member_use_from_same_package
      autoFlushOnInit || (autoFlushQueue && flushInterval == null);

  /// Creates a profile with offline features disabled.
  factory SdkProfile.defaultSecure() => const SdkProfile(
        offlineEnabled: false,
        queueWritesWhenOffline: false,
        autoFlushQueue: false,
        flushInterval: null,
      );

  /// Creates a profile that enables offline caching and offline write queueing.
  ///
  /// Because [autoFlushQueue] is `true` and [flushInterval] is `null`, the
  /// current implementation flushes the queue once during initialization.
  factory SdkProfile.offlineFirstSecure() => const SdkProfile(
        offlineEnabled: true,
        queueWritesWhenOffline: true,
        autoFlushQueue: true,
        flushInterval: null,
      );
}
