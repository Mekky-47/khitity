import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

export 'package:flutter_localizations/flutter_localizations.dart';

@immutable
class AppLocalizations {
  const AppLocalizations();

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static AppLocalizations? maybeOf(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // These will be generated from ARB files
  String get appTitle => 'Giyas.AI';
  String get addExam => 'Add Exam';
  String get generatePlan => 'Generate Plan';
  String get regeneratePlan => 'Regenerate Plan';
  String get dailyPlan => 'Daily Plan';
  String get weeklyPlan => 'Weekly Plan';
  String get examSchedule => 'Exam Schedule';
  String get chat => 'Chat';
  String get settings => 'Settings';
  String get subject => 'Subject';
  String get date => 'Date';
  String get weight => 'Weight';
  String get availableMinutes => 'Available Minutes';
  String get language => 'Language';
  String get timezone => 'Timezone';
  String get save => 'Save';
  String get cancel => 'Cancel';
  String get delete => 'Delete';
  String get edit => 'Edit';
  String get applySuggestion => 'Apply Suggestion';
  String get send => 'Send';
  String get typeMessage => 'Type your message...';
  String get noExamsYet => 'No exams yet';
  String get addYourFirstExam => 'Add your first exam to get started';
  String get noPlanYet => 'No study plan yet';
  String get generateYourFirstPlan => 'Generate your first study plan';
  String get noTasksToday => 'No tasks for today';
  String get allCaughtUp => 'All caught up!';
  String get greeting => 'Hello';
  String get today => 'Today';
  String get progress => 'Progress';
  String get minutes => 'minutes';
  String get difficulty => 'Difficulty';
  String get syllabusRange => 'Syllabus Range';
  String get moodAnalysis => 'Mood Analysis';
  String get howAreYouFeeling => 'How are you feeling today?';
  String get moodDescription =>
      'Tell us about your mood and we\'ll recommend the perfect study session length for you';
  String get describeMood => 'Describe your mood:';
  String get moodHint => 'e.g., I feel tired but motivated to study...';
  String get quickMoods => 'Quick moods:';
  String get analyzeMood => 'Analyze Mood';
  String get readyToAnalyze => 'Ready to analyze your mood?';
  String get moodInstructions =>
      'Describe how you\'re feeling or select a quick mood to get personalized study recommendations';
  String get analyzingMood => 'Analyzing your mood...';
  String get aiRecommendation => 'AI Recommendation';
  String get recommendedStudyTime => 'Recommended Study Time';
  String get whyThisDuration => 'Why this duration?';
  String get studyTips => 'Study Tips';
  String get tryDifferentMood => 'Try Different Mood';
  String get applyToPlan => 'Apply to Plan';
  String get recommendationApplied => 'Recommendation applied to study plan!';
  String get errorAnalyzingMood => 'Error analyzing mood';
  String get tryAgain => 'Try Again';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ar', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return const AppLocalizations();
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
