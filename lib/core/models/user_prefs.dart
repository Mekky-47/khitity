class UserPrefs {
  final int dailyAvailableMinutes;
  final String language; // 'ar' or 'en'
  final String timezone;

  const UserPrefs({
    required this.dailyAvailableMinutes,
    required this.language,
    required this.timezone,
  });

  // Factory constructor for creating from database
  factory UserPrefs.fromMap(Map<String, dynamic> map) {
    return UserPrefs(
      dailyAvailableMinutes: map['dailyAvailableMinutes'] as int,
      language: map['language'] as String,
      timezone: map['timezone'] as String,
    );
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'dailyAvailableMinutes': dailyAvailableMinutes,
      'language': language,
      'timezone': timezone,
    };
  }

  // Copy with method for updates
  UserPrefs copyWith({
    int? dailyAvailableMinutes,
    String? language,
    String? timezone,
  }) {
    return UserPrefs(
      dailyAvailableMinutes: dailyAvailableMinutes ?? this.dailyAvailableMinutes,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
    );
  }

  // Default preferences
  static const UserPrefs defaultPrefs = UserPrefs(
    dailyAvailableMinutes: 120, // 2 hours default
    language: 'ar', // Arabic default
    timezone: 'UTC',
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPrefs &&
        other.dailyAvailableMinutes == dailyAvailableMinutes &&
        other.language == language &&
        other.timezone == timezone;
  }

  @override
  int get hashCode => dailyAvailableMinutes.hashCode ^
      language.hashCode ^
      timezone.hashCode;

  @override
  String toString() {
    return 'UserPrefs(dailyAvailableMinutes: $dailyAvailableMinutes, language: $language, timezone: $timezone)';
  }
}
