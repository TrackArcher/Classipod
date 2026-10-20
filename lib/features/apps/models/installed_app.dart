class InstalledApp {
  const InstalledApp({
    required this.systemLabel,
    required this.packageName,
    required this.userSerial,
    this.customLabel,
  });

  final String systemLabel;
  final String packageName;
  final int userSerial;
  final String? customLabel;

  String get label => customLabel ?? systemLabel;

  String get id => '$packageName:$userSerial';

  InstalledApp withCustomLabel(String? label) {
    return InstalledApp(
      systemLabel: systemLabel,
      packageName: packageName,
      userSerial: userSerial,
      customLabel: label,
    );
  }

  factory InstalledApp.fromPlatformMap(Map<Object?, Object?> map) {
    return InstalledApp(
      systemLabel: map['label']! as String,
      packageName: map['packageName']! as String,
      userSerial: (map['userSerial'] as num).toInt(),
    );
  }
}
