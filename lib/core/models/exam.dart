import 'package:intl/intl.dart';

class Exam {
  final int id;
  final int subjectId;
  final DateTime date;
  final double weightInTotal; // 0.0 to 1.0
  final String? syllabusRange;

  const Exam({
    required this.id,
    required this.subjectId,
    required this.date,
    required this.weightInTotal,
    this.syllabusRange,
  });

  // Factory constructor for creating from database
  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as int,
      subjectId: map['subjectId'] as int,
      date: DateTime.parse(map['date'] as String),
      weightInTotal: (map['weightInTotal'] as num).toDouble(),
      syllabusRange: map['syllabusRange'] as String?,
    );
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'weightInTotal': weightInTotal,
      'syllabusRange': syllabusRange,
    };
  }

  // Copy with method for updates
  Exam copyWith({
    int? id,
    int? subjectId,
    DateTime? date,
    double? weightInTotal,
    String? syllabusRange,
  }) {
    return Exam(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      weightInTotal: weightInTotal ?? this.weightInTotal,
      syllabusRange: syllabusRange ?? this.syllabusRange,
    );
  }

  // Get days until exam
  int get daysUntilExam {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final examDate = DateTime(date.year, date.month, date.day);
    return examDate.difference(today).inDays;
  }

  // Check if exam is today
  bool get isToday => daysUntilExam == 0;

  // Check if exam is tomorrow
  bool get isTomorrow => daysUntilExam == 1;

  // Check if exam is this week
  bool get isThisWeek => daysUntilExam >= 0 && daysUntilExam <= 6;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exam &&
        other.id == id &&
        other.subjectId == subjectId &&
        other.date == date &&
        other.weightInTotal == weightInTotal &&
        other.syllabusRange == syllabusRange;
  }

  @override
  int get hashCode => id.hashCode ^
      subjectId.hashCode ^
      date.hashCode ^
      weightInTotal.hashCode ^
      syllabusRange.hashCode;

  @override
  String toString() {
    return 'Exam(id: $id, subjectId: $subjectId, date: $date, weightInTotal: $weightInTotal, syllabusRange: $syllabusRange)';
  }
}
