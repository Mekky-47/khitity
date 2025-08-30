class Subject {
  final int id;
  final String name;
  final int perceivedDifficulty; // 1-5 scale

  const Subject({
    required this.id,
    required this.name,
    required this.perceivedDifficulty,
  });

  // Factory constructor for creating from database
  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int,
      name: map['name'] as String,
      perceivedDifficulty: map['perceivedDifficulty'] as int,
    );
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'perceivedDifficulty': perceivedDifficulty,
    };
  }

  // Copy with method for updates
  Subject copyWith({
    int? id,
    String? name,
    int? perceivedDifficulty,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      perceivedDifficulty: perceivedDifficulty ?? this.perceivedDifficulty,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subject &&
        other.id == id &&
        other.name == name &&
        other.perceivedDifficulty == perceivedDifficulty;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ perceivedDifficulty.hashCode;

  @override
  String toString() {
    return 'Subject(id: $id, name: $name, perceivedDifficulty: $perceivedDifficulty)';
  }
}
