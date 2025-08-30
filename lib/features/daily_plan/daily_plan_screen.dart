import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:giyas_ai/core/providers/providers.dart';
import 'package:giyas_ai/core/models/study_task.dart';
import 'package:giyas_ai/l10n/l10n.dart';

class DailyPlanScreen extends ConsumerWidget {
  const DailyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final todayTasksAsync = ref.watch(todayPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dailyPlan),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with greeting and progress
            _buildHeader(context, l10n),

            const SizedBox(height: 24),

            // Today's tasks
            Expanded(
              child: todayTasksAsync.when(
                data: (tasks) => _buildTasksList(context, ref, tasks, l10n),
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

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateFormat('EEEE, MMMM d').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.greeting,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          today,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 16),
        _buildProgressRing(context, l10n),
      ],
    );
  }

  Widget _buildProgressRing(BuildContext context, AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, child) {
        final todayTasksAsync = ref.watch(todayPlanProvider);

        return todayTasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return _buildEmptyState(context, l10n);
            }

            final completedTasks = tasks.where((task) => task.done).length;
            final totalTasks = tasks.length;
            final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

            return Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Center(
                        child: Text(
                          '${(progress * 100).round()}%',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.progress,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedTasks of $totalTasks tasks completed',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.task_alt,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noTasksToday,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.allCaughtUp,
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

  Widget _buildTasksList(BuildContext context, WidgetRef ref,
      List<StudyTask> tasks, AppLocalizations l10n) {
    if (tasks.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(context, ref, task, l10n);
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, StudyTask task,
      AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: task.done,
          onChanged: (value) async {
            if (value != null) {
              final dbService = ref.read(databaseServiceProvider);
              await dbService.toggleStudyTaskDone(task.id, value);
              // Refresh the provider
              ref.invalidate(todayPlanProvider);
            }
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.done ? TextDecoration.lineThrough : null,
            color: task.done
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                : null,
          ),
        ),
        subtitle: Text(
          '${task.estimatedMinutes} ${l10n.minutes}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        trailing: Container(
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
            'Error loading tasks',
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
