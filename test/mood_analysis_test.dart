import 'package:flutter_test/flutter_test.dart';
import 'package:giyas_ai/core/models/mood_analysis.dart';

void main() {
  group('MoodAnalysis Model Tests', () {
    test('should create MoodAnalysis from JSON', () {
      final json = {
        'recommendedHours': 4.5,
        'explanation': 'Test explanation',
        'tips': ['Tip 1', 'Tip 2', 'Tip 3'],
      };

      final moodAnalysis = MoodAnalysis.fromJson(json);

      expect(moodAnalysis.recommendedHours, 4.5);
      expect(moodAnalysis.explanation, 'Test explanation');
      expect(moodAnalysis.tips, ['Tip 1', 'Tip 2', 'Tip 3']);
      expect(moodAnalysis.timestamp, isA<DateTime>());
    });

    test('should convert MoodAnalysis to JSON', () {
      final moodAnalysis = MoodAnalysis(
        recommendedHours: 3.0,
        explanation: 'Test explanation',
        tips: ['Tip 1', 'Tip 2'],
        timestamp: DateTime(2024, 1, 1),
      );

      final json = moodAnalysis.toJson();

      expect(json['recommendedHours'], 3.0);
      expect(json['explanation'], 'Test explanation');
      expect(json['tips'], ['Tip 1', 'Tip 2']);
      expect(json['timestamp'], '2024-01-01T00:00:00.000');
    });

    test('should create copy with updated values', () {
      final original = MoodAnalysis(
        recommendedHours: 2.0,
        explanation: 'Original explanation',
        tips: ['Original tip'],
        timestamp: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        recommendedHours: 4.0,
        explanation: 'Updated explanation',
      );

      expect(updated.recommendedHours, 4.0);
      expect(updated.explanation, 'Updated explanation');
      expect(updated.tips, ['Original tip']); // Unchanged
      expect(updated.timestamp, DateTime(2024, 1, 1)); // Unchanged
    });

    test('should handle decimal hours correctly', () {
      final json = {
        'recommendedHours': 1.5,
        'explanation': 'Test',
        'tips': ['Tip'],
      };

      final moodAnalysis = MoodAnalysis.fromJson(json);
      expect(moodAnalysis.recommendedHours, 1.5);
    });

    test('should handle integer hours correctly', () {
      final json = {
        'recommendedHours': 6,
        'explanation': 'Test',
        'tips': ['Tip'],
      };

      final moodAnalysis = MoodAnalysis.fromJson(json);
      expect(moodAnalysis.recommendedHours, 6.0);
    });
  });
}
