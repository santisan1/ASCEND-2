import 'package:ascend/features/habits/domain/habit_model.dart';
import 'package:ascend/features/habits/domain/habits_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class AddHabitDialog extends StatefulWidget {
  const AddHabitDialog({super.key});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  HabitCategory? _selectedCategory;
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];
  int _difficulty = 3;
  int _impact = 3;

  HabitPriority _priority = HabitPriority.medium;
  HabitTrigger _trigger = HabitTrigger.anytime;
  HabitCadence _cadence = HabitCadence.daily;
  TimeOfDay? _reminderTime;
  int _targetDays = 30;
  String _selectedIcon = 'fitness_center';

  // NUEVOS CAMPOS
  int _estimatedDuration = 15; // minutos
  int _dailyRepetitions = 1; // veces por día

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_cadence == HabitCadence.daily && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un día'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final habit = Habit(
      id: '',
      userId: '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      icon: _selectedIcon,
      category: _selectedCategory,
      frequency: _cadence == HabitCadence.daily ? _selectedDays : [1, 2, 3, 4, 5, 6, 7],
      difficulty: _difficulty,
      impact: _impact,
      priority: _priority,
      trigger: _trigger,
      cadence: _cadence,
      reminderTime: _reminderTime != null
          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
          : null,
      targetDays: _targetDays,
      estimatedDuration: _estimatedDuration,
      dailyRepetitions: _dailyRepetitions,
      createdAt: DateTime.now(),
    );

    try {
      await context.read<HabitsProvider>().createHabit(habit);

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡Hábito "${habit.name}" creado!',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header fijo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderDark)),
              ),
              child: Row(
                children: [
                  Text(
                    'Nuevo Hábito',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // NOMBRE
                      AppTextField(
                        controller: _nameController,
                        labelText: 'Nombre del hábito',
                        hintText: 'Ej: Meditar 10 minutos',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa un nombre';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // DESCRIPCIÓN
                      AppTextField(
                        controller: _descriptionController,
                        labelText: 'Descripción (opcional)',
                        hintText: 'Describe tu hábito',
                        maxLines: 2,
                      ),

                      const SizedBox(height: 24),

                      // CATEGORÍA
                      _buildSectionTitle('Categoría'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: HabitCategory.values.map((category) {
                          final isSelected = _selectedCategory == category;
                          return InkWell(
                            onTap: () =>
                                setState(() => _selectedCategory = category),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.2)
                                    : AppColors.surfaceVariantDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.borderDark,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    category.icon,
                                    size: 14,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondaryDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    category.displayName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondaryDark,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      _buildSectionTitle('Frecuencia objetivo'),
                      const SizedBox(height: 12),
                      Row(
                        children: HabitCadence.values.map((cadence) {
                          final selected = _cadence == cadence;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () => setState(() => _cadence = cadence),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary.withOpacity(0.2)
                                        : AppColors.surfaceVariantDark,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected ? AppColors.primary : AppColors.borderDark,
                                    ),
                                  ),
                                  child: Text(
                                    cadence.displayName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textSecondaryDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // DURACIÓN Y REPETICIONES
                      _buildSectionTitle('Tiempo y frecuencia'),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(child: _buildDurationSelector()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildRepetitionsSelector()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // PRIORIDAD
                      _buildSectionTitle('Prioridad'),
                      const SizedBox(height: 12),
                      Row(
                        children: HabitPriority.values.map((priority) {
                          final isSelected = _priority == priority;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _priority = priority),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _getPriorityColor(
                                            priority,
                                          ).withOpacity(0.2)
                                        : AppColors.surfaceVariantDark,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? _getPriorityColor(priority)
                                          : AppColors.borderDark,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        _getPriorityIcon(priority),
                                        color: isSelected
                                            ? _getPriorityColor(priority)
                                            : AppColors.textSecondaryDark,
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        priority.displayName,
                                        style: TextStyle(
                                          color: isSelected
                                              ? _getPriorityColor(priority)
                                              : AppColors.textSecondaryDark,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // MOMENTO DEL DÍA
                      _buildSectionTitle('¿Cuándo prefieres hacerlo?'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: HabitTrigger.values.map((trigger) {
                          final isSelected = _trigger == trigger;
                          return InkWell(
                            onTap: () => setState(() => _trigger = trigger),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent.withOpacity(0.2)
                                    : AppColors.surfaceVariantDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.borderDark,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    trigger.displayName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.accent
                                          : AppColors.textSecondaryDark,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    trigger.timeRange,
                                    style: TextStyle(
                                      color: AppColors.textTertiaryDark,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // RECORDATORIO
                      _buildSectionTitle('Recordatorio'),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectReminderTime,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariantDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _reminderTime != null
                                  ? AppColors.primary
                                  : AppColors.borderDark,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications_active,
                                color: _reminderTime != null
                                    ? AppColors.primary
                                    : AppColors.textSecondaryDark,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _reminderTime != null
                                      ? 'Recordar a las ${_reminderTime!.format(context)}'
                                      : 'Sin recordatorio',
                                  style: TextStyle(
                                    color: _reminderTime != null
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textSecondaryDark,
                                  ),
                                ),
                              ),
                              if (_reminderTime != null)
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _reminderTime = null),
                                  icon: const Icon(Icons.close, size: 18),
                                  color: AppColors.textTertiaryDark,
                                )
                              else
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppColors.textTertiaryDark,
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // DÍAS DE LA SEMANA
                      _buildSectionTitle('Días de la semana'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (int i = 1; i <= 7; i++)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (_selectedDays.contains(i)) {
                                    _selectedDays.remove(i);
                                  } else {
                                    _selectedDays.add(i);
                                  }
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _selectedDays.contains(i)
                                      ? AppColors.primary.withOpacity(0.2)
                                      : AppColors.surfaceVariantDark,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedDays.contains(i)
                                        ? AppColors.primary
                                        : AppColors.borderDark,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _getDayLabel(i),
                                    style: TextStyle(
                                      color: _selectedDays.contains(i)
                                          ? AppColors.primary
                                          : AppColors.textSecondaryDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // META DE DÍAS
                      _buildSectionTitle('Meta de consistencia (días)'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariantDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Meta: $_targetDays días seguidos',
                                  style: TextStyle(
                                    color: AppColors.textPrimaryDark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_targetDays',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Slider(
                              value: _targetDays.toDouble(),
                              min: 7,
                              max: 365,
                              divisions: 51,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.borderDark,
                              onChanged: (value) {
                                setState(() {
                                  _targetDays = value.toInt();
                                });
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '7 días',
                                  style: TextStyle(
                                    color: AppColors.textTertiaryDark,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  '365 días',
                                  style: TextStyle(
                                    color: AppColors.textTertiaryDark,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Footer con botón
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderDark)),
              ),
              child: PrimaryButton(
                text: 'Crear Hábito',
                onPressed: _submit,
                type: ButtonType.gradient,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Icon(Icons.schedule, color: AppColors.accent, size: 20),
          const SizedBox(height: 8),
          Text(
            'Duración',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _estimatedDuration = (_estimatedDuration - 5).clamp(5, 180);
                  });
                },
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: AppColors.textSecondaryDark,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_estimatedDuration min',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _estimatedDuration = (_estimatedDuration + 5).clamp(5, 180);
                  });
                },
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: AppColors.textSecondaryDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepetitionsSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Icon(Icons.repeat, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            'Veces al día',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _dailyRepetitions = (_dailyRepetitions - 1).clamp(1, 10);
                  });
                },
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: AppColors.textSecondaryDark,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_dailyRepetitions${_dailyRepetitions == 1 ? " vez" : " veces"}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _dailyRepetitions = (_dailyRepetitions + 1).clamp(1, 10);
                  });
                },
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: AppColors.textSecondaryDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.labelLarge.copyWith(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Color _getPriorityColor(HabitPriority priority) {
    switch (priority) {
      case HabitPriority.low:
        return AppColors.info;
      case HabitPriority.medium:
        return AppColors.warning;
      case HabitPriority.high:
        return AppColors.error;
      case HabitPriority.critical:
        return AppColors.error;
    }
  }

  IconData _getPriorityIcon(HabitPriority priority) {
    switch (priority) {
      case HabitPriority.low:
        return Icons.low_priority;
      case HabitPriority.medium:
        return Icons.remove;
      case HabitPriority.high:
        return Icons.priority_high;
      case HabitPriority.critical:
        return Icons.warning;
    }
  }

  String _getDayLabel(int day) {
    switch (day) {
      case 1:
        return 'L';
      case 2:
        return 'M';
      case 3:
        return 'X';
      case 4:
        return 'J';
      case 5:
        return 'V';
      case 6:
        return 'S';
      case 7:
        return 'D';
      default:
        return '';
    }
  }
}
