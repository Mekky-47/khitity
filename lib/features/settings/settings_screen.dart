import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giyas_ai/core/providers/providers.dart';
import 'package:giyas_ai/core/models/user_prefs.dart';
import 'package:giyas_ai/l10n/l10n.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late int _dailyAvailableMinutes;
  late String _language;
  late String _timezone;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = ref.read(userPrefsProvider);
    setState(() {
      _dailyAvailableMinutes = prefs.dailyAvailableMinutes;
      _language = prefs.language;
      _timezone = prefs.timezone;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily available minutes setting
            _buildDailyMinutesSetting(context, l10n),

            const SizedBox(height: 24),

            // Language setting
            _buildLanguageSetting(context, l10n),

            const SizedBox(height: 24),

            // Timezone setting
            _buildTimezoneSetting(context, l10n),

            const SizedBox(height: 32),

            // Save button
            _buildSaveButton(context, l10n),

            const Spacer(),

            // App info
            _buildAppInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyMinutesSetting(
      BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.availableMinutes,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set how many minutes you want to study each day',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _dailyAvailableMinutes.toDouble(),
                    min: 30.0,
                    max: 480.0, // 8 hours max
                    divisions: 45,
                    onChanged: (value) {
                      setState(() {
                        _dailyAvailableMinutes = value.round();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_dailyAvailableMinutes}m',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '30m',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                Text(
                  '8h',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSetting(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.language,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your preferred language',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildLanguageOption(
                    context,
                    'ar',
                    'العربية',
                    'Arabic',
                    Icons.translate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLanguageOption(
                    context,
                    'en',
                    'English',
                    'English',
                    Icons.language,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String code,
      String nativeName, String englishName, IconData icon) {
    final isSelected = _language == code;

    return GestureDetector(
      onTap: () {
        setState(() {
          _language = code;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              nativeName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
            ),
            Text(
              englishName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimezoneSetting(BuildContext context, AppLocalizations l10n) {
    final timezones = [
      'UTC',
      'UTC+1',
      'UTC+2',
      'UTC+3',
      'UTC+4',
      'UTC+5',
      'UTC+6',
      'UTC+7',
      'UTC+8',
      'UTC+9',
      'UTC+10',
      'UTC+11',
      'UTC+12',
      'UTC-1',
      'UTC-2',
      'UTC-3',
      'UTC-4',
      'UTC-5',
      'UTC-6',
      'UTC-7',
      'UTC-8',
      'UTC-9',
      'UTC-10',
      'UTC-11',
      'UTC-12',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.timezone,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your timezone for accurate scheduling',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _timezone,
              decoration: InputDecoration(
                labelText: l10n.timezone,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.access_time),
              ),
              items: timezones.map((tz) {
                return DropdownMenuItem(
                  value: tz,
                  child: Text(tz),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _timezone = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.save),
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Version', '1.0.0'),
            _buildInfoRow('Build', '1'),
            _buildInfoRow('Flutter', '3.0.0+'),
            _buildInfoRow('Dart', '2.17.0+'),
            const SizedBox(height: 16),
            Text(
              'Giyas.AI - AI-powered study planner for students',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedPrefs = UserPrefs(
        dailyAvailableMinutes: _dailyAvailableMinutes,
        language: _language,
        timezone: _timezone,
      );

      final dbService = ref.read(databaseServiceProvider);
      await dbService.updateUserPrefs(updatedPrefs);

      // Refresh the provider
      ref.invalidate(userPrefsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings saved successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
