class StudyTask {
  final int id;
  final int subjectId;
  final String title;
  final int estimatedMinutes;
  final int dayOfWeek; // 0-6 (Monday = 0, Sunday = 6)
  final bool done;

  const StudyTask({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.estimatedMinutes,
    required this.dayOfWeek,
    this.done = false,
  });

  // Factory constructor for creating from database
  factory StudyTask.fromMap(Map<String, dynamic> map) {
    return StudyTask(
      id: map['id'] as int,
      subjectId: map['subjectId'] as int,
      title: map['title'] as String,
      estimatedMinutes: map['estimatedMinutes'] as int,
      dayOfWeek: map['dayOfWeek'] as int,
      done: (map['done'] as int) == 1, // SQLite stores bool as int
    );
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'title': title,
      'estimatedMinutes': estimatedMinutes,
      'dayOfWeek': dayOfWeek,
      'done': done ? 1 : 0, // Convert bool to int for SQLite
    };
  }

  // Copy with method for updates
  StudyTask copyWith({
    int? id,
    int? subjectId,
    String? title,
    int? estimatedMinutes,
    int? dayOfWeek,
    bool? done,
  }) {
    return StudyTask(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      done: done ?? this.done,
    );
  }

  // Get day name
  String get dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[dayOfWeek];
  }

  // Get short day name
  String get shortDayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayOfWeek];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudyTask &&
        other.id == id &&
        other.subjectId == subjectId &&
        other.title == title &&
        other.estimatedMinutes == estimatedMinutes &&
        other.dayOfWeek == dayOfWeek &&
        other.done == done;
  }

  @override
  int get hashCode => id.hashCode ^
      subjectId.hashCode ^
      title.hashCode ^
      estimatedMinutes.hashCode ^
      dayOfWeek.hashCode ^
      done.hashCode;

  @override
  String toString() {
    return 'StudyTask(id: $id, subjectId: $subjectId, title: $title, estimatedMinutes: $estimatedMinutes, dayOfWeek: $dayOfWeek, done: $done)';
  }
}
