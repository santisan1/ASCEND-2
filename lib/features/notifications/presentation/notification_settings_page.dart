import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/notification_preferences_provider.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationPreferencesProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Notificaciones ASCEND'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Configurá recordatorios por módulo',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Sin Cloud Functions: funciona con recordatorios locales en tu dispositivo.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 20),
          ...provider.reminders.map(
            (reminder) => _ReminderTile(reminder: reminder),
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final ModuleReminder reminder;

  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationPreferencesProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reminder.module,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
              Switch(
                value: reminder.enabled,
                onChanged: (value) {
                  provider.updateReminder(
                    reminder.module,
                    reminder.copyWith(enabled: value),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')} · ${reminder.message}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: reminder.hour,
                      minute: reminder.minute,
                    ),
                  );
                  if (picked == null) return;
                  provider.updateReminder(
                    reminder.module,
                    reminder.copyWith(
                      hour: picked.hour,
                      minute: picked.minute,
                    ),
                  );
                },
                icon: const Icon(Icons.schedule, size: 16),
                label: const Text('Hora'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => provider.testNotification(reminder.module),
                icon: const Icon(Icons.notifications_active, size: 16),
                label: const Text('Probar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
