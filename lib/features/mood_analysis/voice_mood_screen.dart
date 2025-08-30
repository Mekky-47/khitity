import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giyas_ai/core/services/voice_service.dart';

class VoiceMoodScreen extends ConsumerStatefulWidget {
  const VoiceMoodScreen({super.key});

  @override
  ConsumerState<VoiceMoodScreen> createState() => _VoiceMoodScreenState();
}

class _VoiceMoodScreenState extends ConsumerState<VoiceMoodScreen> {
  final VoiceService _voiceService = VoiceService();
  final TextEditingController _textController = TextEditingController();

  bool _isRecording = false;
  bool _isAnalyzing = false;
  String? _recordingPath;
  Map<String, dynamic>? _analysisResult;

  @override
  void dispose() {
    _voiceService.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final success = await _voiceService.startRecording();
    if (success) {
      setState(() {
        _isRecording = true;
        _analysisResult = null;
      });
    } else {
      _showError(
          'Failed to start recording. Please check microphone permissions.');
    }
  }

  Future<void> _stopRecording() async {
    final path = await _voiceService.stopRecording();
    setState(() {
      _isRecording = false;
      _recordingPath = path;
    });

    if (path != null) {
      _analyzeVoiceMood(path);
    }
  }

  Future<void> _analyzeVoiceMood(String audioPath) async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _voiceService.analyzeVoiceMood(audioPath);

      setState(() {
        _isAnalyzing = false;
        _analysisResult = result.isSuccess ? result.aiAnalysis : null;
      });

      if (!result.isSuccess) {
        _showError(result.message ?? 'Failed to analyze voice mood');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showError('Error analyzing voice: $e');
    }
  }

  Future<void> _analyzeTextMood() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showError('Please enter your mood description');
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _voiceService.analyzeTextMood(text);

      setState(() {
        _isAnalyzing = false;
        _analysisResult = result.isSuccess ? result.aiAnalysis : null;
      });

      if (!result.isSuccess) {
        _showError(result.message ?? 'Failed to analyze text mood');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showError('Error analyzing text: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Mood Analysis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 32),

            // Voice Recording Section
            _buildVoiceRecordingSection(),
            const SizedBox(height: 32),

            // Text Input Section
            _buildTextInputSection(),
            const SizedBox(height: 32),

            // Analysis Results
            if (_analysisResult != null) _buildAnalysisResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Icon(
            Icons.mic,
            size: 64,
            color: Colors.blue[400],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Mood Analysis',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Record your voice or describe your mood to get personalized study recommendations',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVoiceRecordingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.mic, color: Colors.blue[600]),
                const SizedBox(width: 12),
                Text(
                  'Voice Recording',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tap the button below and speak about how you\'re feeling today. I\'ll analyze your voice to understand your mood and recommend the best study approach.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 120,
              height: 120,
              child: GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : Colors.blue)
                            .withOpacity(0.3),
                        spreadRadius: 4,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isRecording
                  ? 'Recording... Tap to stop'
                  : 'Tap to start recording',
              style: TextStyle(
                color: _isRecording ? Colors.red : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_recordingPath != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recording saved successfully',
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Colors.blue[600]),
                const SizedBox(width: 12),
                Text(
                  'Text Description',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Alternatively, describe your mood in text and I\'ll provide personalized study recommendations.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe how you\'re feeling today...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAnalyzing ? null : _analyzeTextMood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isAnalyzing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Analyze Mood',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResults() {
    final moodType = _analysisResult?['moodType'] as String? ?? 'unknown';
    final confidence = _analysisResult?['confidence'] as double? ?? 0.0;
    final recommendedHours =
        _analysisResult?['recommendedStudyHours'] as double? ?? 0.0;
    final explanation = _analysisResult?['explanation'] as String? ?? '';
    final studyTips = _analysisResult?['studyTips'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.blue[600]),
                const SizedBox(width: 12),
                Text(
                  'Analysis Results',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mood Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected Mood: ${moodType.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(color: Colors.blue[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recommended Study Time: ${recommendedHours.toStringAsFixed(1)} hours',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Explanation
            if (explanation.isNotEmpty) ...[
              Text(
                'Why this duration?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                explanation,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
            ],

            // Study Tips
            if (studyTips.isNotEmpty) ...[
              Text(
                'Personalized Study Tips:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...studyTips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip.toString(),
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
