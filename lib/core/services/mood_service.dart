import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mood_session.dart';
import 'auth_service.dart';

class MoodService {
  static const String _baseUrl = 'http://localhost:3000/api';

  // Analyze mood from voice recording (placeholder for now)
  Future<Map<String, dynamic>> analyzeVoiceMood() async {
    try {
      // For now, we'll simulate voice analysis with a placeholder
      // TODO: Implement actual voice recording and file upload

      return {
        'success': false,
        'error': 'Voice recording not yet implemented',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Analyze mood from text description
  Future<Map<String, dynamic>> analyzeTextMood(String moodDescription) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.post(
        Uri.parse('$_baseUrl/mood/analyze-text'),
        headers: headers,
        body: jsonEncode({
          'moodDescription': moodDescription,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final moodSession = MoodSession.fromJson(data['moodSession']);
        return {
          'success': true,
          'moodSession': moodSession,
          'aiAnalysis': data['aiAnalysis'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Text analysis failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Get mood history
  Future<Map<String, dynamic>> getMoodHistory({
    int page = 1,
    int limit = 10,
    String? moodType,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (moodType != null) {
        queryParams['moodType'] = moodType;
      }

      final uri = Uri.parse('$_baseUrl/mood/history')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final moodSessions = (data['moodSessions'] as List)
            .map((json) => MoodSession.fromJson(json))
            .toList();

        return {
          'success': true,
          'moodSessions': moodSessions,
          'pagination': data['pagination'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to fetch mood history',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Get specific mood session
  Future<Map<String, dynamic>> getMoodSession(String sessionId) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/mood/session/$sessionId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final moodSession = MoodSession.fromJson(data['moodSession']);
        return {
          'success': true,
          'moodSession': moodSession,
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to fetch mood session',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Update mood session
  Future<Map<String, dynamic>> updateMoodSession(
    String sessionId, {
    bool? appliedToPlan,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final body = <String, dynamic>{};
      if (appliedToPlan != null) body['appliedToPlan'] = appliedToPlan;

      final response = await http.put(
        Uri.parse('$_baseUrl/mood/session/$sessionId'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final moodSession = MoodSession.fromJson(data['moodSession']);
        return {
          'success': true,
          'moodSession': moodSession,
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to update mood session',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Get mood analytics
  Future<Map<String, dynamic>> getMoodAnalytics({int days = 30}) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/mood/analytics?days=$days'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'analytics': data['analytics'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to fetch mood analytics',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Legacy mood analysis (for backward compatibility)
  Future<Map<String, dynamic>> analyzeMoodLegacy(String mood) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-mood'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mood': mood}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'recommendedHours': data['recommendedHours'],
          'explanation': data['explanation'],
          'tips': data['tips'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Mood analysis failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}
