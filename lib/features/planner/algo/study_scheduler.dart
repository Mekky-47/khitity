import 'dart:math';
import 'package:giyas_ai/core/models/exam.dart';
import 'package:giyas_ai/core/models/subject.dart';
import 'package:giyas_ai/core/models/study_task.dart';

/// Study Scheduler Algorithm
///
/// This class implements the core scheduling algorithm for generating weekly and daily study plans.
/// The algorithm uses a priority-based approach that considers:
/// - Exam proximity (urgency)
/// - Subject difficulty
/// - Lateness penalty for pending tasks
/// - Exam weight in total grade
///
/// The algorithm is designed to be:
/// - Deterministic (same inputs always produce same output)
/// - Configurable (constants can be tuned)
/// - Testable (pure functions)
/// - Efficient (O(n log n) complexity)
class StudyScheduler {
  // Configuration constants - these can be tuned based on user feedback
  static const double _proximityWeight = 0.5; // How much exam proximity matters
  static const double _difficultyWeight =
      0.25; // How much subject difficulty matters
  static const double _latenessWeight = 0.15; // Penalty for pending tasks
  static const double _examWeight = 0.10; // How much exam weight matters

  // Scheduling constraints
  static const int _maxTasksPerDay = 5; // Maximum number of tasks per day
  static const int _minTaskMinutes = 25; // Minimum task duration
  static const int _maxTaskMinutes = 50; // Maximum task duration
  // static const int _breakMinutes = 5; // Break between tasks

  /// Generates a weekly study plan based on exams, subjects, and user preferences
  ///
  /// [exams] - List of upcoming exams
  /// [subjects] - List of available subjects
  /// [dailyAvailableMinutes] - Minutes available per day for studying
  /// [today] - Reference date for calculations (defaults to current date)
  ///
  /// Returns a map of day of week (0-6) to list of study tasks
  static Map<int, List<StudyTask>> generateWeeklyPlan({
    required List<Exam> exams,
    required List<Subject> subjects,
    required int dailyAvailableMinutes,
    DateTime? today,
  }) {
    if (exams.isEmpty || subjects.isEmpty) {
      return {};
    }

    final referenceDate = today ?? DateTime.now();
    final weeklyPlan = <int, List<StudyTask>>{};

    // Generate tasks for each day of the week (Monday = 0, Sunday = 6)
    for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
      final dayTasks = _generateDayTasks(
        dayOfWeek: dayOfWeek,
        exams: exams,
        subjects: subjects,
        dailyAvailableMinutes: dailyAvailableMinutes,
        referenceDate: referenceDate,
      );

      weeklyPlan[dayOfWeek] = dayTasks;
    }

    return weeklyPlan;
  }

  /// Generates a daily study plan for a specific day
  ///
  /// [dayOfWeek] - Day of week (0-6, Monday = 0)
  /// [exams] - List of upcoming exams
  /// [subjects] - List of available subjects
  /// [dailyAvailableMinutes] - Minutes available for the day
  /// [today] - Reference date for calculations
  ///
  /// Returns a list of study tasks for the specified day
  static List<StudyTask> generateTodayPlan({
    required List<Exam> exams,
    required List<Subject> subjects,
    required int dailyAvailableMinutes,
    DateTime? today,
  }) {
    if (exams.isEmpty || subjects.isEmpty) {
      return [];
    }

    final referenceDate = today ?? DateTime.now();
    final todayWeekday = referenceDate.weekday - 1; // Convert to 0-6 range

    return _generateDayTasks(
      dayOfWeek: todayWeekday,
      exams: exams,
      subjects: subjects,
      dailyAvailableMinutes: dailyAvailableMinutes,
      referenceDate: referenceDate,
    );
  }

  /// Internal method to generate tasks for a specific day
  static List<StudyTask> _generateDayTasks({
    required int dayOfWeek,
    required List<Exam> exams,
    required List<Subject> subjects,
    required int dailyAvailableMinutes,
    required DateTime referenceDate,
  }) {
    // Calculate subject priorities for this day
    final subjectPriorities = _calculateSubjectPriorities(
      exams: exams,
      subjects: subjects,
      referenceDate: referenceDate,
    );

    // Convert priorities to time allocation using softmax
    final timeAllocation = _allocateTime(
      priorities: subjectPriorities,
      totalMinutes: dailyAvailableMinutes,
    );

    // Generate tasks from time allocation
    return _createTasksFromAllocation(
      dayOfWeek: dayOfWeek,
      timeAllocation: timeAllocation,
      subjects: subjects,
    );
  }

  /// Calculates priority scores for each subject based on the scheduling algorithm
  static Map<int, double> _calculateSubjectPriorities({
    required List<Exam> exams,
    required List<Subject> subjects,
    required DateTime referenceDate,
  }) {
    final priorities = <int, double>{};

    for (final subject in subjects) {
      // Find exams for this subject
      final subjectExams =
          exams.where((e) => e.subjectId == subject.id).toList();

      if (subjectExams.isEmpty) {
        priorities[subject.id] = 0.0;
        continue;
      }

      // Calculate proximity score (urgency)
      final proximityScore =
          _calculateProximityScore(subjectExams, referenceDate);

      // Normalize difficulty (1-5 scale to 0-1)
      final normalizedDifficulty = (subject.perceivedDifficulty - 1) / 4.0;

      // Calculate lateness penalty (if there are pending tasks and exam is soon)
      final latenessPenalty =
          _calculateLatenessPenalty(subjectExams, referenceDate);

      // Calculate exam weight score (average of all exam weights for this subject)
      final examWeightScore =
          subjectExams.map((e) => e.weightInTotal).reduce((a, b) => a + b) /
              subjectExams.length;

      // Apply priority formula
      final priority = _proximityWeight * proximityScore +
          _difficultyWeight * normalizedDifficulty +
          _latenessWeight * latenessPenalty +
          _examWeight * examWeightScore;

      priorities[subject.id] = priority;
    }

    return priorities;
  }

  /// Calculates proximity score based on exam dates
  /// Higher score = more urgent (exam is closer)
  static double _calculateProximityScore(
      List<Exam> exams, DateTime referenceDate) {
    if (exams.isEmpty) return 0.0;

    // Find the closest exam
    final closestExam = exams.reduce((a, b) {
      final aDays = a.date.difference(referenceDate).inDays;
      final bDays = b.date.difference(referenceDate).inDays;
      return aDays < bDays ? a : b;
    });

    final daysUntil = closestExam.date.difference(referenceDate).inDays;

    // Proximity score: 1 / (days + 1) to avoid division by zero
    // This gives higher scores for closer exams
    return 1.0 / (daysUntil + 1);
  }

  /// Calculates lateness penalty for subjects with pending tasks
  /// Higher penalty = more urgent (tasks are overdue)
  static double _calculateLatenessPenalty(
      List<Exam> exams, DateTime referenceDate) {
    if (exams.isEmpty) return 0.0;

    // Find the closest exam
    final closestExam = exams.reduce((a, b) {
      final aDays = a.date.difference(referenceDate).inDays;
      final bDays = b.date.difference(referenceDate).inDays;
      return aDays < bDays ? a : b;
    });

    final daysUntil = closestExam.date.difference(referenceDate).inDays;

    // If exam is very close (within 3 days) and we have pending tasks, apply penalty
    if (daysUntil <= 3) {
      return 1.0 - (daysUntil / 3.0); // 1.0 for today, 0.0 for 3+ days
    }

    return 0.0;
  }

  /// Allocates time to subjects based on priorities using softmax
  static Map<int, int> _allocateTime({
    required Map<int, double> priorities,
    required int totalMinutes,
  }) {
    if (priorities.isEmpty) return {};

    // Apply softmax to convert priorities to probabilities
    final softmaxScores = _softmax(priorities.values.toList());

    // Allocate time proportionally
    final allocation = <int, int>{};
    final subjectIds = priorities.keys.toList();

    for (int i = 0; i < subjectIds.length; i++) {
      final subjectId = subjectIds[i];
      final proportion = softmaxScores[i];
      final allocatedMinutes = (totalMinutes * proportion).round();

      if (allocatedMinutes >= _minTaskMinutes) {
        allocation[subjectId] = allocatedMinutes;
      }
    }

    return allocation;
  }

  /// Applies softmax function to convert raw scores to probabilities
  static List<double> _softmax(List<double> scores) {
    if (scores.isEmpty) return [];

    // Find maximum score to prevent overflow
    final maxScore = scores.reduce((a, b) => a > b ? a : b);

    // Apply softmax formula: exp(score - maxScore) / sum(exp(score - maxScore))
    final expScores = scores.map((score) => exp(score - maxScore)).toList();
    final sumExpScores = expScores.reduce((a, b) => a + b);

    return expScores.map((expScore) => expScore / sumExpScores).toList();
  }

  /// Creates study tasks from time allocation
  static List<StudyTask> _createTasksFromAllocation({
    required int dayOfWeek,
    required Map<int, int> timeAllocation,
    required List<Subject> subjects,
  }) {
    final tasks = <StudyTask>[];
    int taskId = 1;

    for (final entry in timeAllocation.entries) {
      final subjectId = entry.key;
      final totalMinutes = entry.value;

      // Split into 25-50 minute blocks
      final blocks = _splitIntoBlocks(totalMinutes);

      for (final blockMinutes in blocks) {
        final subject = subjects.firstWhere((s) => s.id == subjectId);
        final task = StudyTask(
          id: taskId++,
          subjectId: subjectId,
          title: 'Study ${subject.name}',
          estimatedMinutes: blockMinutes,
          dayOfWeek: dayOfWeek,
        );

        tasks.add(task);
      }
    }

    // Limit to maximum tasks per day
    if (tasks.length > _maxTasksPerDay) {
      tasks.sort((a, b) => b.estimatedMinutes.compareTo(a.estimatedMinutes));
      return tasks.take(_maxTasksPerDay).toList();
    }

    return tasks;
  }

  /// Splits total minutes into appropriate block sizes
  static List<int> _splitIntoBlocks(int totalMinutes) {
    final blocks = <int>[];
    int remaining = totalMinutes;

    while (remaining > 0) {
      int blockSize;

      if (remaining >= _maxTaskMinutes) {
        blockSize = _maxTaskMinutes;
      } else if (remaining >= _minTaskMinutes) {
        blockSize = remaining;
      } else {
        // If remaining time is too small, add it to the last block or skip
        if (blocks.isNotEmpty) {
          blocks[blocks.length - 1] += remaining;
        }
        break;
      }

      blocks.add(blockSize);
      remaining -= blockSize;
    }

    return blocks;
  }
}
