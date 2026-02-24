import 'package:ascend/features/auth/domain/auth_provider.dart';
import 'package:ascend/features/habits/domain/habit_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/habit_templates.dart';
import '../domain/habits_provider.dart';

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final templates = HabitTemplates.templates;
    final categories = HabitCategory.values;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Templates de Hábitos'),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final categoryTemplates = templates
              .where((t) => t.category == category)
              .toList();

          if (categoryTemplates.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(category.icon, color: Color(category.color), size: 24),
                    const SizedBox(width: 12),
                    Text(
                      category.displayName,
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              ...categoryTemplates.map(
                (template) => _buildTemplateCard(context, template),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, Habit template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTemplateDetails(context, template),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(template.category!.color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        template.category!.icon,
                        color: Color(template.category!.color),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textPrimaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            template.description,
                            style: TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildChip(
                      template.trigger.displayName,
                      Icons.access_time,
                      AppColors.accent,
                    ),
                    _buildChip(
                      template.priority.displayName,
                      Icons.flag,
                      _getPriorityColor(template.priority),
                    ),
                    _buildChip(
                      '${template.frequency.length} días/sem',
                      Icons.calendar_today,
                      AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Color _getPriorityColor(HabitPriority priority) {
    switch (priority) {
      case HabitPriority.critical:
        return AppColors.error;
      case HabitPriority.high:
        return AppColors.warning;
      case HabitPriority.medium:
        return AppColors.info;
      case HabitPriority.low:
        return AppColors.textTertiaryDark;
    }
  }

  void _showTemplateDetails(BuildContext context, Habit template) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              template.name,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              template.description,
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Momento', template.trigger.timeRange),
            _buildDetailRow('Prioridad', template.priority.displayName),
            _buildDetailRow('Dificultad', '${template.difficulty}/5'),
            _buildDetailRow('Impacto', '${template.impact}/5'),
            _buildDetailRow(
              'Frecuencia',
              '${template.frequency.length} días/semana',
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Usar este Template',
              onPressed: () async {
                Navigator.pop(context);
                await _createFromTemplate(context, template);
              },
              type: ButtonType.gradient,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondaryDark)),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createFromTemplate(BuildContext context, Habit template) async {
    final habitsProvider = context.read<HabitsProvider>();
    final userId = context.read<AuthProvider>().user?.uid;

    if (userId == null) return;

    final habit = HabitTemplates.createFromTemplate(template, userId);

    try {
      await habitsProvider.createHabit(habit);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Hábito "${habit.name}" creado'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
