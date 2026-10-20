class AppsPreferences {
  const AppsPreferences({
    this.hiddenAppIds = const {},
    this.customLabels = const {},
  });

  final Set<String> hiddenAppIds;
  final Map<String, String> customLabels;

  bool isHidden(String appId) => hiddenAppIds.contains(appId);

  String? customLabel(String appId) => customLabels[appId];

  AppsPreferences copyWith({
    Set<String>? hiddenAppIds,
    Map<String, String>? customLabels,
  }) {
    return AppsPreferences(
      hiddenAppIds: hiddenAppIds ?? this.hiddenAppIds,
      customLabels: customLabels ?? this.customLabels,
    );
  }

  factory AppsPreferences.fromJson(Map<String, dynamic> json) {
    final hidden = json['hidden'];
    final labels = json['labels'];
    return AppsPreferences(
      hiddenAppIds: hidden is List
          ? hidden.map((e) => e.toString()).toSet()
          : const {},
      customLabels: labels is Map
          ? labels.map((key, value) => MapEntry(key.toString(), value.toString()))
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'hidden': hiddenAppIds.toList(),
    'labels': customLabels,
  };
}
