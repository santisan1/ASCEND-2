import 'package:ascend/features/habits/domain/habit_model.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback onCompleted;
  final VoidCallback onPressed;
  final VoidCallback? onUndo; // NUEVO

  const HabitTile({
    super.key,
    required this.habit,
    required this.onCompleted,
    required this.onPressed,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    // Swipe para completar/deshacer
    return Dismissible(
      key: Key('habit_${habit.id}_${habit.completionsToday}'),
      direction: habit.isFullyCompletedToday
          ? DismissDirection
                .endToStart // Solo swipe izquierda para deshacer
          : DismissDirection.horizontal, // Ambos lados para completar
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe derecha = completar
          if (!habit.isFullyCompletedToday) {
            onCompleted();
          }
        } else {
          // Swipe izquierda = deshacer
          if (habit.completionsToday > 0 && onUndo != null) {
            onUndo!();
          }
        }
        return false; // No eliminar el tile
      },
      background: _buildSwipeBackground(true), // Completar
      secondaryBackground: _buildSwipeBackground(false), // Deshacer
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariantDark.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: habit.isFullyCompletedToday
                ? AppColors.primary
                : habit.completionsToday > 0
                ? AppColors.accent.withOpacity(0.5)
                : AppColors.borderDark,
            width: habit.isFullyCompletedToday ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icono
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: habit.category != null
                          ? Color(habit.category!.color).withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      habit.category?.icon ?? Icons.track_changes,
                      color: habit.category != null
                          ? Color(habit.category!.color)
                          : AppColors.primary,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                habit.name,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textPrimaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Indicador de repeticiones
                            if (habit.dailyRepetitions > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: habit.isFullyCompletedToday
                                      ? AppColors.accentGreen.withOpacity(0.2)
                                      : AppColors.accent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${habit.completionsToday}/${habit.dailyRepetitions}',
                                  style: TextStyle(
                                    color: habit.isFullyCompletedToday
                                        ? AppColors.accentGreen
                                        : AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Streak
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

                            const SizedBox(width: 12),

                            // Duración estimada
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

                            // Badge HOY
                            if (habit.isDueToday &&
                                !habit.isFullyCompletedToday)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'HOY',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                            const Spacer(),

                            // Completion rate
                            Text(
                              '${(habit.completionRate * 100).toInt()}%',
                              style: TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Botón de completar/estado
                  _buildActionButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (habit.isFullyCompletedToday) {
      // Completado todas las repeticiones
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 20),
      );
    } else if (habit.completionsToday > 0) {
      // Completó algunas pero no todas
      return InkWell(
        onTap: onCompleted,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: const Icon(Icons.add, color: AppColors.accent, size: 20),
        ),
      );
    } else {
      // No completado
      return InkWell(
        onTap: onCompleted,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariantDark,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderDark, width: 2),
          ),
          child: const Icon(
            Icons.circle_outlined,
            color: AppColors.textTertiaryDark,
            size: 20,
          ),
        ),
      );
    }
  }

  Widget _buildSwipeBackground(bool isComplete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.accentGreen.withOpacity(0.2)
            : AppColors.error.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: isComplete ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.undo,
            color: isComplete ? AppColors.accentGreen : AppColors.error,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            isComplete ? 'Completar' : 'Deshacer',
            style: TextStyle(
              color: isComplete ? AppColors.accentGreen : AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
