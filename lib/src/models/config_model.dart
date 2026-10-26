class ConfigModel {
  final String theme; // 'light', 'dark', 'system'
  final bool showWelcome;

  ConfigModel({
    this.theme = 'system',
    this.showWelcome = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'show_welcome': showWelcome ? 1 : 0,
    };
  }

  factory ConfigModel.fromMap(Map<String, dynamic> map) {
    return ConfigModel(
      theme: map['theme'] as String? ?? 'system',
      showWelcome: (map['show_welcome'] as int?) == 1 || map['show_welcome'] == null,
    );
  }

  ConfigModel copyWith({
    String? theme,
    bool? showWelcome,
  }) {
    return ConfigModel(
      theme: theme ?? this.theme,
      showWelcome: showWelcome ?? this.showWelcome,
    );
  }
}
