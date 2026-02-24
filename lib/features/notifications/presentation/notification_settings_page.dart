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
        actions: [
          IconButton(
            onPressed: () => context.read<NotificationPreferencesProvider>().pullFromCloud(),
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Recordatorios por módulo',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Se sincronizan con Firestore para usar ASCEND en varios dispositivos.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.lastSyncAt == null
                ? 'Última sync: pendiente'
                : 'Última sync: ${provider.lastSyncAt}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            provider.syncState == SyncState.synced
                ? 'Estado: sincronizado'
                : provider.syncState == SyncState.pending
                    ? 'Estado: cambios pendientes de sync'
                    : 'Estado: error de sync',
            style: AppTextStyles.bodySmall.copyWith(
              color: provider.syncState == SyncState.error
                  ? AppColors.error
                  : AppColors.textSecondaryDark,
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
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: reminder.frequency,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  dropdownColor: AppColors.surfaceDark,
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Diaria')),
                    DropdownMenuItem(value: 'weekdays', child: Text('Lun-Vie')),
                    DropdownMenuItem(value: 'weekend', child: Text('Finde')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    provider.updateReminder(
                      reminder.module,
                      reminder.copyWith(frequency: value),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final c = TextEditingController(text: reminder.message);
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Mensaje del recordatorio'),
                  content: TextField(controller: c, maxLines: 3),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
                  ],
                ),
              );
              if (ok == true) {
                provider.updateReminder(reminder.module, reminder.copyWith(message: c.text.trim().isEmpty ? reminder.message : c.text.trim()));
              }
            },
            icon: const Icon(Icons.edit_note, size: 16),
            label: const Text('Editar mensaje'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => provider.testNotification(reminder.module),
            icon: const Icon(Icons.notifications_active, size: 16),
            label: const Text('Probar notificación'),
          ),
        ],
      ),
    );
  }
}
