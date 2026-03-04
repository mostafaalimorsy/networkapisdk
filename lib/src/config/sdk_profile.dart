class SdkProfile {
  final bool offlineEnabled;
  final bool queueWritesWhenOffline;

  const SdkProfile({
    required this.offlineEnabled,
    required this.queueWritesWhenOffline,
  });

  factory SdkProfile.defaultSecure() =>
      const SdkProfile(offlineEnabled: false, queueWritesWhenOffline: false);

  factory SdkProfile.offlineFirstSecure() =>
      const SdkProfile(offlineEnabled: true, queueWritesWhenOffline: true);
}