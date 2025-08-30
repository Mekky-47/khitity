import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/study_task.dart';
import '../models/subject.dart';
import '../models/exam.dart';
import '../models/user_prefs.dart';
import '../models/mood_session.dart';
import '../services/mood_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'chat_provider.dart';

// Legacy providers for backward compatibility
final studyTasksProvider =
    StateNotifierProvider<StudyTasksNotifier, List<StudyTask>>(
  (ref) => StudyTasksNotifier(),
);

final subjectsProvider = StateNotifierProvider<SubjectsNotifier, List<Subject>>(
  (ref) => SubjectsNotifier(),
);

final examsProvider = StateNotifierProvider<ExamsNotifier, List<Exam>>(
  (ref) => ExamsNotifier(),
);

final userPrefsProvider = StateNotifierProvider<UserPrefsNotifier, UserPrefs>(
  (ref) => UserPrefsNotifier(),
);

// Re-export the new providers with different names to avoid conflicts
final chatProviderState = chatProvider;
final moodAnalysisProvider =
    StateNotifierProvider<MoodAnalysisNotifier, AsyncValue<MoodSession?>>(
  (ref) => MoodAnalysisNotifier(ref.read(moodServiceProvider)),
);

// Legacy notifiers
class StudyTasksNotifier extends StateNotifier<List<StudyTask>> {
  StudyTasksNotifier() : super([]);

  void addTask(StudyTask task) {
    state = [...state, task];
  }

  void removeTask(int id) {
    state = state.where((task) => task.id != id).toList();
  }

  void updateTask(StudyTask updatedTask) {
    state = state
        .map((task) => task.id == updatedTask.id ? updatedTask : task)
        .toList();
  }
}

class SubjectsNotifier extends StateNotifier<List<Subject>> {
  SubjectsNotifier() : super([]);

  void addSubject(Subject subject) {
    state = [...state, subject];
  }

  void removeSubject(int id) {
    state = state.where((subject) => subject.id != id).toList();
  }

  void updateSubject(Subject updatedSubject) {
    state = state
        .map((subject) =>
            subject.id == updatedSubject.id ? updatedSubject : subject)
        .toList();
  }
}

class ExamsNotifier extends StateNotifier<List<Exam>> {
  ExamsNotifier() : super([]);

  void addExam(Exam exam) {
    state = [...state, exam];
  }

  void removeExam(int id) {
    state = state.where((exam) => exam.id != id).toList();
  }

  void updateExam(Exam updatedExam) {
    state = state
        .map((exam) => exam.id == updatedExam.id ? updatedExam : exam)
        .toList();
  }
}

class UserPrefsNotifier extends StateNotifier<UserPrefs> {
  UserPrefsNotifier()
      : super(const UserPrefs(
          dailyAvailableMinutes: 480,
          language: 'en',
          timezone: 'UTC',
        ));

  void updatePrefs(UserPrefs prefs) {
    state = prefs;
  }
}

// Service providers
final moodServiceProvider = Provider<MoodService>(
  (ref) => MoodService(),
);

final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(),
);

// Mock weekly plan provider for development
final weeklyPlanProvider =
    FutureProvider<Map<int, List<StudyTask>>>((ref) async {
  return {
    0: [
      // Monday
      const StudyTask(
        id: 1,
        subjectId: 1,
        title: 'Mathematics Review',
        estimatedMinutes: 60,
        dayOfWeek: 0,
        done: false,
      ),
    ],
    1: [
      // Tuesday
      const StudyTask(
        id: 2,
        subjectId: 2,
        title: 'Physics Practice',
        estimatedMinutes: 45,
        dayOfWeek: 1,
        done: false,
      ),
    ],
  };
});

// Mock today plan provider for development
final todayPlanProvider = FutureProvider<List<StudyTask>>((ref) async {
  return [
    const StudyTask(
      id: 1,
      subjectId: 1,
      title: 'Mathematics Review',
      estimatedMinutes: 60,
      dayOfWeek: 0,
      done: false,
    ),
  ];
});

// Mock database service provider for development
final databaseServiceProvider = Provider<dynamic>((ref) => null);

// Mood Analysis Notifier
class MoodAnalysisNotifier extends StateNotifier<AsyncValue<MoodSession?>> {
  final MoodService _moodService;

  MoodAnalysisNotifier(this._moodService) : super(const AsyncValue.data(null));

  Future<void> analyzeTextMood(String moodDescription) async {
    state = const AsyncValue.loading();
    try {
      await _moodService.analyzeTextMood(moodDescription);
      // Handle the result based on the actual return type
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> analyzeVoiceMood() async {
    state = const AsyncValue.loading();
    try {
      await _moodService.analyzeVoiceMood();
      // Handle the result based on the actual return type
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void clearAnalysis() {
    state = const AsyncValue.data(null);
  }
}
