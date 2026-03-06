class SdkProfile {
  final bool offlineEnabled;
  final bool queueWritesWhenOffline;
  final bool autoFlushQueue;
  final Duration? flushInterval;

  @Deprecated('Use autoFlushQueue + flushInterval instead.')
  final bool autoFlushOnInit;

  const SdkProfile({
    required this.offlineEnabled,
    required this.queueWritesWhenOffline,
    this.autoFlushQueue = false,
    this.flushInterval,
    @Deprecated('Use autoFlushQueue + flushInterval instead.')
    this.autoFlushOnInit = false,
  });

  bool get shouldFlushOnceOnInit =>
      // ignore: deprecated_member_use_from_same_package
      autoFlushOnInit || (autoFlushQueue && flushInterval == null);

  factory SdkProfile.defaultSecure() => const SdkProfile(
    offlineEnabled: false,
    queueWritesWhenOffline: false,
    autoFlushQueue: false,
    flushInterval: null,
  );

  factory SdkProfile.offlineFirstSecure() => const SdkProfile(
    offlineEnabled: true,
    queueWritesWhenOffline: true,
    autoFlushQueue: true,
    flushInterval: null,
  );
}