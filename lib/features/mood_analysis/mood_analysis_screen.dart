import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giyas_ai/core/providers/providers.dart';
import 'package:giyas_ai/l10n/l10n.dart';

class MoodAnalysisScreen extends ConsumerStatefulWidget {
  const MoodAnalysisScreen({super.key});

  @override
  ConsumerState<MoodAnalysisScreen> createState() => _MoodAnalysisScreenState();
}

class _MoodAnalysisScreenState extends ConsumerState<MoodAnalysisScreen> {
  final _moodController = TextEditingController();
  final List<String> _quickMoods = [
    'Happy',
    'Excited',
    'Tired',
    'Stressed',
    'Bored',
    'Anxious',
    'Focused',
    'Relaxed',
  ];

  @override
  void dispose() {
    _moodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final moodAnalysisAsync = ref.watch(moodAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moodAnalysis),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(moodAnalysisProvider.notifier).clearAnalysis();
            },
            tooltip: 'Clear analysis',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, l10n),

            const SizedBox(height: 24),

            // Mood input section
            _buildMoodInput(context, l10n),

            const SizedBox(height: 24),

            // Quick mood buttons
            _buildQuickMoodButtons(context, l10n),

            const SizedBox(height: 32),

            // Analysis results
            Expanded(
              child: moodAnalysisAsync.when(
                data: (analysis) => analysis != null
                    ? _buildAnalysisResults(context, analysis, l10n)
                    : _buildEmptyState(context, l10n),
                loading: () => _buildLoadingState(context, l10n),
                error: (error, stackTrace) =>
                    _buildErrorState(context, error, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.howAreYouFeeling,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.moodDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildMoodInput(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.describeMood,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _moodController,
          decoration: InputDecoration(
            hintText: l10n.moodHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: IconButton(
              onPressed: _analyzeMood,
              icon: const Icon(Icons.psychology),
              tooltip: l10n.analyzeMood,
            ),
          ),
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _analyzeMood(),
        ),
      ],
    );
  }

  Widget _buildQuickMoodButtons(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickMoods,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickMoods
              .map((mood) => ActionChip(
                    label: Text(mood),
                    onPressed: () {
                      _moodController.text = mood;
                      _analyzeMood();
                    },
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.readyToAnalyze,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.moodInstructions,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n.analyzingMood),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults(
      BuildContext context, dynamic analysis, AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.aiRecommendation,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Recommended hours
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.recommendedStudyTime,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${analysis.recommendedHours.toStringAsFixed(1)} hours',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Explanation
                  Text(
                    l10n.whyThisDuration,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analysis.explanation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tips card
          if (analysis.tips.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.studyTips,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...analysis.tips.map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(moodAnalysisProvider.notifier).clearAnalysis();
                    _moodController.clear();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.tryDifferentMood),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Apply recommendation to study plan
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.recommendationApplied),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: Text(l10n.applyToPlan),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, Object error, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.errorAnalyzingMood,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _analyzeMood,
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  void _analyzeMood() {
    final mood = _moodController.text.trim();
    if (mood.isNotEmpty) {
      ref.read(moodAnalysisProvider.notifier).analyzeTextMood(mood);
    }
  }
}
