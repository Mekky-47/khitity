import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giyas_ai/core/providers/providers.dart';
import 'package:giyas_ai/core/models/study_task.dart';
import 'package:giyas_ai/l10n/l10n.dart';

class WeeklyPlannerScreen extends ConsumerWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final weeklyPlanAsync = ref.watch(weeklyPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weeklyPlan),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Invalidate the weekly plan to regenerate
              ref.invalidate(weeklyPlanProvider);
            },
            tooltip: l10n.regeneratePlan,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Regenerate plan button
            _buildRegenerateButton(context, ref, l10n),

            const SizedBox(height: 24),

            // Weekly plan
            Expanded(
              child: weeklyPlanAsync.when(
                data: (weeklyPlan) =>
                    _buildWeeklyPlan(context, weeklyPlan, l10n),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    _buildErrorState(context, error, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegenerateButton(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Clear existing tasks and regenerate plan
          _regeneratePlan(ref);
        },
        icon: const Icon(Icons.refresh),
        label: Text(l10n.regeneratePlan),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Future<void> _regeneratePlan(WidgetRef ref) async {
    final dbService = ref.read(databaseServiceProvider);

    // Clear existing study tasks
    await dbService.clearAllStudyTasks();

    // Invalidate providers to trigger regeneration
    ref.invalidate(weeklyPlanProvider);
    ref.invalidate(todayPlanProvider);
  }

  Widget _buildWeeklyPlan(BuildContext context,
      Map<int, List<StudyTask>> weeklyPlan, AppLocalizations l10n) {
    if (weeklyPlan.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        final dayOfWeek = index;
        final tasks = weeklyPlan[dayOfWeek] ?? [];
        return _buildDayCard(context, dayOfWeek, tasks, l10n);
      },
    );
  }

  Widget _buildDayCard(BuildContext context, int dayOfWeek,
      List<StudyTask> tasks, AppLocalizations l10n) {
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final shortDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    final isToday = today.weekday - 1 == dayOfWeek;

    final totalMinutes =
        tasks.fold<int>(0, (sum, task) => sum + task.estimatedMinutes);
    final completedTasks = tasks.where((task) => task.done).length;
    final progress = tasks.isNotEmpty ? completedTasks / tasks.length : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    shortDayNames[dayOfWeek],
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayNames[dayOfWeek],
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (isToday)
                        Text(
                          l10n.today,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalMinutes ${l10n.minutes}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Text(
                      '${tasks.length} tasks',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            if (tasks.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Tasks list
            if (tasks.isNotEmpty) ...[
              ...tasks.map((task) => _buildTaskItem(context, task, l10n)),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 20,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No tasks scheduled',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
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

  Widget _buildTaskItem(
      BuildContext context, StudyTask task, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: task.done
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            task.done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: task.done
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                decoration: task.done ? TextDecoration.lineThrough : null,
                color: task.done
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                    : null,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: task.done
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${task.estimatedMinutes}m',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: task.done
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_view_week,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noPlanYet,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.generateYourFirstPlan,
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
            'Error loading weekly plan',
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
        ],
      ),
    );
  }
}
