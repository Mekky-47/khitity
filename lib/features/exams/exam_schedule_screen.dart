import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:giyas_ai/core/providers/providers.dart';
import 'package:giyas_ai/core/models/exam.dart';
import 'package:giyas_ai/core/models/subject.dart';
import 'package:giyas_ai/l10n/l10n.dart';

class ExamScheduleScreen extends ConsumerWidget {
  const ExamScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final examsAsync = ref.watch(examsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.examSchedule),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExamDialog(context, ref, l10n),
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

            // Exams list
            Expanded(
              child: _buildExamsList(
                  context, ref, examsAsync, subjectsAsync, l10n),
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
          l10n.examSchedule,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your exam schedule and track upcoming tests',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildExamsList(BuildContext context, WidgetRef ref, List<Exam> exams,
      List<Subject> subjects, AppLocalizations l10n) {
    if (exams.isEmpty) {
      return _buildEmptyState(context, ref, l10n);
    }

    // Sort exams by date
    final sortedExams = List<Exam>.from(exams)
      ..sort((a, b) => a.date.compareTo(b.date));

    return ListView.builder(
      itemCount: sortedExams.length,
      itemBuilder: (context, index) {
        final exam = sortedExams[index];
        final subject = subjects.firstWhere((s) => s.id == exam.subjectId);
        return _buildExamCard(context, ref, exam, subject, l10n);
      },
    );
  }

  Widget _buildExamCard(BuildContext context, WidgetRef ref, Exam exam,
      Subject subject, AppLocalizations l10n) {
    final now = DateTime.now();
    final examDate = DateTime(exam.date.year, exam.date.month, exam.date.day);
    final today = DateTime(now.year, now.month, now.day);
    final daysUntil = examDate.difference(today).inDays;

    String statusText;
    Color statusColor;

    if (daysUntil < 0) {
      statusText = 'Completed';
      statusColor = Colors.grey;
    } else if (daysUntil == 0) {
      statusText = 'Today';
      statusColor = Colors.red;
    } else if (daysUntil == 1) {
      statusText = 'Tomorrow';
      statusColor = Colors.orange;
    } else if (daysUntil <= 7) {
      statusText = 'This week';
      statusColor = Colors.amber;
    } else {
      statusText = 'Upcoming';
      statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(exam.date),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.weight}: ${(exam.weightInTotal * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (exam.syllabusRange != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.syllabusRange}: ${exam.syllabusRange}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (daysUntil >= 0) ...[
                  Text(
                    daysUntil == 0 ? 'Today' : '$daysUntil days',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showEditExamDialog(context, ref, exam, subject, l10n),
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.edit),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteExam(context, ref, exam, l10n),
                    icon: const Icon(Icons.delete),
                    label: Text(l10n.delete),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No exams scheduled',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first exam to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddExamDialog(context, ref, l10n),
            icon: const Icon(Icons.add),
            label: Text(l10n.addExam),
          ),
        ],
      ),
    );
  }

  void _showAddExamDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => const AddExamDialog(),
    );
  }

  void _showEditExamDialog(BuildContext context, WidgetRef ref, Exam exam,
      Subject subject, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => EditExamDialog(exam: exam, subject: subject),
    );
  }

  Future<void> _deleteExam(BuildContext context, WidgetRef ref, Exam exam,
      AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content:
            Text('Are you sure you want to delete the ${exam.subjectId} exam?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dbService = ref.read(databaseServiceProvider);
      await dbService.deleteExam(exam.id);
      // Refresh the provider
      ref.invalidate(examsProvider);
    }
  }
}

class AddExamDialog extends ConsumerStatefulWidget {
  const AddExamDialog({super.key});

  @override
  ConsumerState<AddExamDialog> createState() => _AddExamDialogState();
}

class _AddExamDialogState extends ConsumerState<AddExamDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedSubjectId;
  DateTime? _selectedDate;
  double _weight = 0.5;
  final _syllabusController = TextEditingController();

  @override
  void dispose() {
    _syllabusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subjectsAsync = ref.watch(subjectsProvider);

    return AlertDialog(
      title: Text(l10n.addExam),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subject dropdown
              DropdownButtonFormField<int>(
                value: _selectedSubjectId,
                decoration: InputDecoration(
                  labelText: l10n.subject,
                  border: const OutlineInputBorder(),
                ),
                items: subjectsAsync.map((subject) {
                  return DropdownMenuItem(
                    value: subject.id,
                    child: Text(subject.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubjectId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a subject';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Date picker
              ListTile(
                title: Text(l10n.date),
                subtitle: Text(
                  _selectedDate == null
                      ? 'Select a date'
                      : DateFormat('MMM d, yyyy').format(_selectedDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Weight slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.weight}: ${(_weight * 100).round()}%'),
                  Slider(
                    value: _weight,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (value) {
                      setState(() {
                        _weight = value;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Syllabus range (optional)
              TextFormField(
                controller: _syllabusController,
                decoration: InputDecoration(
                  labelText: l10n.syllabusRange,
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., Chapters 1-5 (optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _saveExam,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _saveExam() async {
    if (_formKey.currentState!.validate() &&
        _selectedSubjectId != null &&
        _selectedDate != null) {
      final exam = Exam(
        id: 0, // Will be set by database
        subjectId: _selectedSubjectId!,
        date: _selectedDate!,
        weightInTotal: _weight,
        syllabusRange: _syllabusController.text.trim().isEmpty
            ? null
            : _syllabusController.text.trim(),
      );

      final dbService = ref.read(databaseServiceProvider);
      await dbService.insertExam(exam);

      // Refresh the provider
      ref.invalidate(examsProvider);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class EditExamDialog extends ConsumerStatefulWidget {
  final Exam exam;
  final Subject subject;

  const EditExamDialog({
    super.key,
    required this.exam,
    required this.subject,
  });

  @override
  ConsumerState<EditExamDialog> createState() => _EditExamDialogState();
}

class _EditExamDialogState extends ConsumerState<EditExamDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _selectedSubjectId;
  late DateTime _selectedDate;
  late double _weight;
  late final TextEditingController _syllabusController;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.exam.subjectId;
    _selectedDate = widget.exam.date;
    _weight = widget.exam.weightInTotal;
    _syllabusController =
        TextEditingController(text: widget.exam.syllabusRange);
  }

  @override
  void dispose() {
    _syllabusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subjectsAsync = ref.watch(subjectsProvider);

    return AlertDialog(
      title: Text(l10n.edit),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subject dropdown
              DropdownButtonFormField<int>(
                value: _selectedSubjectId,
                decoration: InputDecoration(
                  labelText: l10n.subject,
                  border: const OutlineInputBorder(),
                ),
                items: subjectsAsync.map((subject) {
                  return DropdownMenuItem(
                    value: subject.id,
                    child: Text(subject.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubjectId = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Date picker
              ListTile(
                title: Text(l10n.date),
                subtitle: Text(
                  DateFormat('MMM d, yyyy').format(_selectedDate),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Weight slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.weight}: ${(_weight * 100).round()}%'),
                  Slider(
                    value: _weight,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (value) {
                      setState(() {
                        _weight = value;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Syllabus range
              TextFormField(
                controller: _syllabusController,
                decoration: InputDecoration(
                  labelText: l10n.syllabusRange,
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., Chapters 1-5 (optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _updateExam,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _updateExam() async {
    if (_formKey.currentState!.validate()) {
      final updatedExam = widget.exam.copyWith(
        subjectId: _selectedSubjectId,
        date: _selectedDate,
        weightInTotal: _weight,
        syllabusRange: _syllabusController.text.trim().isEmpty
            ? null
            : _syllabusController.text.trim(),
      );

      final dbService = ref.read(databaseServiceProvider);
      await dbService.updateExam(updatedExam);

      // Refresh the provider
      ref.invalidate(examsProvider);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
