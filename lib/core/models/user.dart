class User {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final UserPreferences preferences;
  final DateTime? lastLogin;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.preferences,
    this.lastLogin,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      preferences:
          UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'preferences': preferences.toJson(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isActive': isActive,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    UserPreferences? preferences,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      preferences: preferences ?? this.preferences,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, preferences: $preferences)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class UserPreferences {
  final String language;
  final String timezone;
  final int dailyAvailableMinutes;
  final bool notifications;

  const UserPreferences({
    this.language = 'en',
    this.timezone = 'UTC',
    this.dailyAvailableMinutes = 120,
    this.notifications = true,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      language: json['language'] as String? ?? 'en',
      timezone: json['timezone'] as String? ?? 'UTC',
      dailyAvailableMinutes: json['dailyAvailableMinutes'] as int? ?? 120,
      notifications: json['notifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'timezone': timezone,
      'dailyAvailableMinutes': dailyAvailableMinutes,
      'notifications': notifications,
    };
  }

  UserPreferences copyWith({
    String? language,
    String? timezone,
    int? dailyAvailableMinutes,
    bool? notifications,
  }) {
    return UserPreferences(
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      dailyAvailableMinutes:
          dailyAvailableMinutes ?? this.dailyAvailableMinutes,
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  String toString() {
    return 'UserPreferences(language: $language, timezone: $timezone, dailyAvailableMinutes: $dailyAvailableMinutes, notifications: $notifications)';
  }
}
