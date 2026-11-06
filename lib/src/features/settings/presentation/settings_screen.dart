import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/domain/ai_provider.dart';
import '../application/settings_controller.dart';
import '../domain/app_settings.dart';
import 'widgets/api_key_field.dart';
import 'widgets/model_picker_sheet.dart';
import 'widgets/settings_section.dart';
import 'widgets/system_prompt_tile.dart';

/// Provider, model, key, persona and appearance preferences.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          SettingsSection(
            title: 'Provider',
            description:
                'OpenRouter offers a catalogue of models that are free to '
                'call. Gemini uses Google AI Studio\'s free tier.',
            children: [
              SegmentedButton<AiProvider>(
                segments: [
                  for (final provider in AiProvider.values)
                    ButtonSegment(value: provider, label: Text(provider.label)),
                ],
                selected: {settings.provider},
                onSelectionChanged: (selection) =>
                    controller.setProvider(selection.first),
              ),
            ],
          ),
          SettingsSection(
            title: 'API key',
            children: [
              ApiKeyField(
                // Rebuild the field when the provider changes so it shows the
                // right stored key.
                key: ValueKey(settings.provider),
                provider: settings.provider,
                initialValue: settings.storedKey,
                usesBuildTimeKey: settings.usesBuildTimeKey,
                onChanged: controller.setApiKey,
              ),
            ],
          ),
          SettingsSection(
            title: 'Model',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.memory_rounded),
                title: const Text('Active model'),
                subtitle: Text(
                  settings.activeModel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _pickModel(context, ref, settings),
              ),
            ],
          ),
          SettingsSection(
            title: 'Assistant persona',
            children: [
              SystemPromptTile(
                value: settings.systemPrompt,
                onChanged: controller.setSystemPrompt,
              ),
            ],
          ),
          SettingsSection(
            title: 'Appearance',
            children: [
              RadioGroup<AppThemeMode>(
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) controller.setThemeMode(value);
                },
                child: Column(
                  children: [
                    for (final mode in AppThemeMode.values)
                      RadioListTile<AppThemeMode>(
                        contentPadding: EdgeInsets.zero,
                        value: mode,
                        title: Text(switch (mode) {
                          AppThemeMode.system => 'Follow system',
                          AppThemeMode.light => 'Light',
                          AppThemeMode.dark => 'Dark',
                        }),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickModel(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final chosen = await ModelPickerSheet.show(context, settings.activeModel);
    if (chosen != null) {
      await ref.read(settingsControllerProvider.notifier).setModel(chosen);
    }
  }
}
