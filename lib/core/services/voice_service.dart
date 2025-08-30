import 'dart:io';
import 'dart:convert';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:giyas_ai/core/services/auth_service.dart';

class VoiceService {
  static const String _baseUrl = 'http://localhost:3000/api';
  final Record _recorder = Record();

  bool _isRecording = false;
  String? _currentRecordingPath;

  // Check and request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await Permission.microphone.isGranted;
  }

  // Start recording audio
  Future<bool> startRecording() async {
    try {
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) return false;
      }

      if (_isRecording) return false;

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/mood_recording_$timestamp.wav';

      await _recorder.start(
        path: _currentRecordingPath!,
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        samplingRate: 44100,
      );

      _isRecording = true;
      return true;
    } catch (e) {
      // Log error for debugging
      return false;
    }
  }

  // Stop recording audio
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      await _recorder.stop();
      _isRecording = false;

      return _currentRecordingPath;
    } catch (e) {
      // Log error for debugging
      return null;
    }
  }

  // Check if currently recording
  bool get isRecording => _isRecording;

  // Analyze voice for mood detection
  Future<VoiceAnalysisResult> analyzeVoiceMood(String audioFilePath) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return VoiceAnalysisResult.failure(message: 'No authentication token');
      }

      final audioFile = File(audioFilePath);
      if (!await audioFile.exists()) {
        return VoiceAnalysisResult.failure(message: 'Audio file not found');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/mood/analyze-voice'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioFilePath),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final moodSession = data['moodSession'];
        final aiAnalysis = data['aiAnalysis'];

        return VoiceAnalysisResult.success(
          moodSession: moodSession,
          aiAnalysis: aiAnalysis,
          audioFile: data['audioFile'] as String?,
        );
      } else {
        final error = jsonDecode(responseBody);
        return VoiceAnalysisResult.failure(
            message: error['error'] ?? 'Failed to analyze voice mood');
      }
    } catch (e) {
      return VoiceAnalysisResult.failure(message: 'Network error: $e');
    }
  }

  // Analyze text mood (fallback)
  Future<VoiceAnalysisResult> analyzeTextMood(String moodDescription) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return VoiceAnalysisResult.failure(message: 'No authentication token');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/mood/analyze-text'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'moodDescription': moodDescription,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final moodSession = data['moodSession'];
        final aiAnalysis = data['aiAnalysis'];

        return VoiceAnalysisResult.success(
          moodSession: moodSession,
          aiAnalysis: aiAnalysis,
        );
      } else {
        final error = jsonDecode(response.body);
        return VoiceAnalysisResult.failure(
            message: error['error'] ?? 'Failed to analyze text mood');
      }
    } catch (e) {
      return VoiceAnalysisResult.failure(message: 'Network error: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _recorder.dispose();
  }
}

class VoiceAnalysisResult {
  final bool isSuccess;
  final Map<String, dynamic>? moodSession;
  final Map<String, dynamic>? aiAnalysis;
  final String? audioFile;
  final String? message;

  const VoiceAnalysisResult._({
    required this.isSuccess,
    this.moodSession,
    this.aiAnalysis,
    this.audioFile,
    this.message,
  });

  factory VoiceAnalysisResult.success({
    Map<String, dynamic>? moodSession,
    Map<String, dynamic>? aiAnalysis,
    String? audioFile,
  }) {
    return VoiceAnalysisResult._(
      isSuccess: true,
      moodSession: moodSession,
      aiAnalysis: aiAnalysis,
      audioFile: audioFile,
    );
  }

  factory VoiceAnalysisResult.failure({String? message}) {
    return VoiceAnalysisResult._(
      isSuccess: false,
      message: message,
    );
  }
}
