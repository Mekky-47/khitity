class MoodSession {
  final String id;
  final String userId;
  final String moodType;
  final String? moodDescription;
  final String? voiceFileUrl;
  final Map<String, dynamic> aiAnalysis;
  final double recommendedStudyHours;
  final double? confidence;
  final List<String> studyTips;
  final bool appliedToPlan;
  final DateTime sessionDate;

  const MoodSession({
    required this.id,
    required this.userId,
    required this.moodType,
    this.moodDescription,
    this.voiceFileUrl,
    required this.aiAnalysis,
    required this.recommendedStudyHours,
    this.confidence,
    required this.studyTips,
    required this.appliedToPlan,
    required this.sessionDate,
  });

  factory MoodSession.fromJson(Map<String, dynamic> json) {
    return MoodSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      moodType: json['mood_type'] as String,
      moodDescription: json['mood_description'] as String?,
      voiceFileUrl: json['voice_file_url'] as String?,
      aiAnalysis: Map<String, dynamic>.from(json['ai_analysis'] ?? {}),
      recommendedStudyHours:
          (json['recommended_study_hours'] as num).toDouble(),
      confidence: json['confidence'] != null
          ? (json['confidence'] as num).toDouble()
          : null,
      studyTips: List<String>.from(json['study_tips'] ?? []),
      appliedToPlan: json['applied_to_plan'] as bool? ?? false,
      sessionDate: DateTime.parse(json['session_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mood_type': moodType,
      'mood_description': moodDescription,
      'voice_file_url': voiceFileUrl,
      'ai_analysis': aiAnalysis,
      'recommended_study_hours': recommendedStudyHours,
      'confidence': confidence,
      'study_tips': studyTips,
      'applied_to_plan': appliedToPlan,
      'session_date': sessionDate.toIso8601String(),
    };
  }

  MoodSession copyWith({
    String? id,
    String? userId,
    String? moodType,
    String? moodDescription,
    String? voiceFileUrl,
    Map<String, dynamic>? aiAnalysis,
    double? recommendedStudyHours,
    double? confidence,
    List<String>? studyTips,
    bool? appliedToPlan,
    DateTime? sessionDate,
  }) {
    return MoodSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moodType: moodType ?? this.moodType,
      moodDescription: moodDescription ?? this.moodDescription,
      voiceFileUrl: voiceFileUrl ?? this.voiceFileUrl,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      recommendedStudyHours:
          recommendedStudyHours ?? this.recommendedStudyHours,
      confidence: confidence ?? this.confidence,
      studyTips: studyTips ?? this.studyTips,
      appliedToPlan: appliedToPlan ?? this.appliedToPlan,
      sessionDate: sessionDate ?? this.sessionDate,
    );
  }

  // Helper getters for AI analysis data
  String get detectedMood => aiAnalysis['moodType'] as String? ?? moodType;
  double get aiConfidence =>
      (aiAnalysis['confidence'] as num?)?.toDouble() ?? 0.0;
  String get explanation => aiAnalysis['explanation'] as String? ?? '';
  List<String> get aiStudyTips =>
      List<String>.from(aiAnalysis['studyTips'] ?? studyTips);
  Map<String, dynamic> get moodContext =>
      Map<String, dynamic>.from(aiAnalysis['moodContext'] ?? {});

  @override
  String toString() {
    return 'MoodSession(id: $id, moodType: $moodType, confidence: $confidence, recommendedHours: $recommendedStudyHours)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

