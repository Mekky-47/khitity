class MoodAnalysis {
  final double recommendedHours;
  final String explanation;
  final List<String> tips;
  final DateTime? timestamp;

  const MoodAnalysis({
    required this.recommendedHours,
    required this.explanation,
    required this.tips,
    this.timestamp,
  });

  factory MoodAnalysis.fromJson(Map<String, dynamic> json) {
    return MoodAnalysis(
      recommendedHours: (json['recommendedHours'] as num).toDouble(),
      explanation: json['explanation'] as String,
      tips: List<String>.from(json['tips']),
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendedHours': recommendedHours,
      'explanation': explanation,
      'tips': tips,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  MoodAnalysis copyWith({
    double? recommendedHours,
    String? explanation,
    List<String>? tips,
    DateTime? timestamp,
  }) {
    return MoodAnalysis(
      recommendedHours: recommendedHours ?? this.recommendedHours,
      explanation: explanation ?? this.explanation,
      tips: tips ?? this.tips,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'MoodAnalysis(recommendedHours: $recommendedHours, explanation: $explanation, tips: $tips, timestamp: $timestamp)';
  }
}
