import 'package:ascend/features/habits/domain/habit_model.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HabitsTimelineView extends StatelessWidget {
  final List<Habit> habits;
  final Function(String habitId) onComplete;
  final Function(String habitId) onUndo;
  final Function(Habit habit) onTap;

  const HabitsTimelineView({
    super.key,
    required this.habits,
    required this.onComplete,
    required this.onUndo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Obtener hábitos del día actual
    final todayHabits = habits.where((habit) => habit.isDueToday).toList();

    // Separar hábitos completados y pendientes
    final completedHabits = todayHabits
        .where((h) => h.isFullyCompletedToday)
        .toList();
    final pendingHabits = todayHabits
        .where((h) => !h.isFullyCompletedToday)
        .toList();

    // Calcular tiempo total del día
    final totalTime = todayHabits.fold(
      0,
      (sum, h) => sum + (h.estimatedDuration * h.dailyRepetitions),
    );

    final completedTime = todayHabits.fold(
      0,
      (sum, h) => sum + (h.estimatedDuration * h.completionsToday),
    );

    // Agrupar hábitos pendientes por momento del día
    final groupedPendingHabits = _groupHabitsByTrigger(pendingHabits);
    // Agrupar hábitos completados por momento del día
    final groupedCompletedHabits = _groupHabitsByTrigger(completedHabits);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen del día
          _buildDaySummary(
            totalTime,
            completedTime,
            completedHabits.length,
            pendingHabits.length,
          ),

          const SizedBox(height: 24),

          // Sección de hábitos pendientes
          if (pendingHabits.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Hábitos Pendientes',
              subtitle: '${pendingHabits.length} por completar',
              icon: Icons.access_time,
              color: AppColors.warning,
            ),

            const SizedBox(height: 16),

            // Timeline por momento del día para pendientes
            ..._buildAllTimeSections(groupedPendingHabits, isCompleted: false),

            const SizedBox(height: 32),
          ],

          // Sección de hábitos completados
          if (completedHabits.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Hábitos Completados',
              subtitle: '${completedHabits.length} terminados',
              icon: Icons.check_circle,
              color: AppColors.accentGreen,
            ),

            const SizedBox(height: 16),

            // Timeline por momento del día para completados
            ..._buildAllTimeSections(groupedCompletedHabits, isCompleted: true),

            const SizedBox(height: 32),
          ],

          // Mensaje si no hay hábitos para hoy
          if (todayHabits.isEmpty) ...[_buildEmptyState()],
        ],
      ),
    );
  }

  Map<HabitTrigger, List<Habit>> _groupHabitsByTrigger(List<Habit> habitList) {
    final grouped = <HabitTrigger, List<Habit>>{};

    for (final trigger in HabitTrigger.values) {
      grouped[trigger] = habitList.where((h) => h.trigger == trigger).toList();
    }

    return grouped;
  }

  Widget _buildDaySummary(
    int totalTime,
    int completedTime,
    int completedCount,
    int pendingCount,
  ) {
    final progress = totalTime > 0 ? completedTime / totalTime : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tu día en minutos',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 14, color: AppColors.accentGreen),
                    const SizedBox(width: 4),
                    Text(
                      '$completedCount/$completedCount${pendingCount > 0 ? '+$pendingCount' : ''}',
                      style: TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeStat('Total', '$totalTime min', Icons.timer_outlined),
              Container(width: 1, height: 40, color: AppColors.borderDark),
              _buildTimeStat(
                'Completado',
                '$completedTime min',
                Icons.check_circle_outline,
              ),
              Container(width: 1, height: 40, color: AppColors.borderDark),
              _buildTimeStat(
                'Restante',
                '${totalTime - completedTime} min',
                Icons.pending_outlined,
              ),
            ],
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariantDark,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? AppColors.accentGreen : AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso del día',
                style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: progress == 1.0
                      ? AppColors.accentGreen
                      : AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4.copyWith(color: color)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textTertiaryDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAllTimeSections(
    Map<HabitTrigger, List<Habit>> groupedHabits, {
    required bool isCompleted,
  }) {
    final sections = <Widget>[];

    // Definir colores para cada momento del día
    final triggerColors = {
      HabitTrigger.morning: AppColors.warning,
      HabitTrigger.noon: AppColors.accent,
      HabitTrigger.afternoon: AppColors.secondary,
      HabitTrigger.evening: AppColors.info,
      HabitTrigger.anytime: AppColors.primary,
    };

    for (final trigger in HabitTrigger.values) {
      final habits = groupedHabits[trigger] ?? [];
      if (habits.isNotEmpty) {
        sections.add(
          _buildTimeSection(
            title: trigger.displayName,
            timeRange: trigger.timeRange,
            icon: _getTriggerIcon(trigger),
            color: triggerColors[trigger]!,
            habits: habits,
            isCompleted: isCompleted,
          ),
        );
        sections.add(const SizedBox(height: 16));
      }
    }

    return sections;
  }

  Widget _buildTimeSection({
    required String title,
    required String timeRange,
    required IconData icon,
    required Color color,
    required List<Habit> habits,
    required bool isCompleted,
  }) {
    final totalMinutes = habits.fold(
      0,
      (sum, h) => sum + (h.estimatedDuration * h.dailyRepetitions),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    timeRange,
                    style: TextStyle(
                      color: AppColors.textTertiaryDark,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$totalMinutes min',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Lista de hábitos
        ...habits.asMap().entries.map((entry) {
          final index = entry.key;
          final habit = entry.value;
          final isLast = index == habits.length - 1;

          return _buildTimelineHabitItem(
            habit,
            color,
            isLast,
            isCompleted: isCompleted,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTimelineHabitItem(
    Habit habit,
    Color sectionColor,
    bool isLast, {
    required bool isCompleted,
  }) {
    final hasPartial =
        habit.completionsToday > 0 && !habit.isFullyCompletedToday;
    final displayColor = isCompleted ? AppColors.accentGreen : sectionColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Línea timeline
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 2,
                height: 12,
                color: isCompleted ? displayColor : AppColors.borderDark,
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || hasPartial
                      ? displayColor
                      : Colors.transparent,
                  border: Border.all(
                    color: isCompleted || hasPartial
                        ? displayColor
                        : AppColors.borderDark,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : hasPartial
                    ? const Icon(
                        Icons.hourglass_bottom,
                        size: 10,
                        color: Colors.white,
                      )
                    : null,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 80,
                  color: isCompleted
                      ? displayColor.withOpacity(0.3)
                      : AppColors.borderDark,
                ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Card del hábito
        Expanded(
          child: InkWell(
            onTap: () => onTap(habit),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted
                    ? displayColor.withOpacity(0.1)
                    : AppColors.surfaceVariantDark.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted
                      ? displayColor.withOpacity(0.3)
                      : AppColors.borderDark,
                  width: isCompleted ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.check_circle
                            : (habit.category?.icon ?? Icons.track_changes),
                        size: 18,
                        color: isCompleted
                            ? displayColor
                            : (habit.category != null
                                  ? Color(habit.category!.color)
                                  : sectionColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.name,
                              style: TextStyle(
                                color: AppColors.textPrimaryDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Completado ${habit.completionsToday}/${habit.dailyRepetitions} veces',
                                style: TextStyle(
                                  color: AppColors.accentGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (habit.dailyRepetitions > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? displayColor.withOpacity(0.2)
                                : sectionColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${habit.completionsToday}/${habit.dailyRepetitions}',
                            style: TextStyle(
                              color: isCompleted ? displayColor : sectionColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.textTertiaryDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.estimatedDuration} min',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: habit.currentStreak > 0
                            ? AppColors.warning
                            : AppColors.textTertiaryDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.currentStreak} días',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),

                      const Spacer(),

                      // Botones de acción
                      if (!isCompleted)
                        InkWell(
                          onTap: () => onComplete(habit.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: sectionColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: sectionColor),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 14,
                                  color: sectionColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Completar',
                                  style: TextStyle(
                                    color: sectionColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (habit.completionsToday > 0)
                        InkWell(
                          onTap: () => onUndo(habit.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.undo,
                                  size: 14,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Deshacer',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondaryDark, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today,
            size: 48,
            color: AppColors.textTertiaryDark,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay hábitos para hoy',
            style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los hábitos programados para hoy aparecerán aquí',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 14),
          ),
        ],
      ),
    );
  }

  IconData _getTriggerIcon(HabitTrigger trigger) {
    switch (trigger) {
      case HabitTrigger.morning:
        return Icons.wb_sunny;
      case HabitTrigger.noon:
        return Icons.light_mode;
      case HabitTrigger.afternoon:
        return Icons.wb_twilight;
      case HabitTrigger.evening:
        return Icons.nightlight;
      case HabitTrigger.anytime:
        return Icons.all_inclusive;
    }
  }
}
