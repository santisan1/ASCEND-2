// Crea un nuevo archivo: habit_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:ascend/features/habits/domain/habit_model.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HabitDetailScreen extends StatelessWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalles del Hábito',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimaryDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono y nombre
            _buildHabitHeader(),

            const SizedBox(height: 24),

            // Estadísticas principales
            _buildMainStats(),

            const SizedBox(height: 24),

            // Información detallada
            _buildDetailedInfo(),

            const SizedBox(height: 24),

            // Historial de completaciones
            _buildCompletionHistory(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: habit.category != null
            ? Color(habit.category!.color).withOpacity(0.1)
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: habit.category != null
              ? Color(habit.category!.color).withOpacity(0.3)
              : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: habit.category != null
                  ? Color(habit.category!.color).withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              habit.category?.icon ?? Icons.track_changes,
              size: 30,
              color: habit.category != null
                  ? Color(habit.category!.color)
                  : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                if (habit.description.isNotEmpty)
                  Text(
                    habit.description,
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Racha Actual',
                '${habit.currentStreak} días',
                Icons.local_fire_department,
                AppColors.warning,
              ),
              _buildStatItem(
                'Mejor Racha',
                '${habit.longestStreak} días',
                Icons.leaderboard,
                AppColors.accent,
              ),
              _buildStatItem(
                'Consistencia',
                '${(habit.completionRate * 100).toInt()}%',
                Icons.trending_up,
                AppColors.accentGreen,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Dificultad',
                '${habit.difficulty}/5',
                Icons.fitness_center,
                AppColors.error,
              ),
              _buildStatItem(
                'Impacto',
                '${habit.impact}/5',
                Icons.bolt,
                AppColors.accent,
              ),
              _buildStatItem(
                'Completados',
                '${habit.totalCompletions}',
                Icons.check_circle,
                AppColors.accentGreen,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creado',
                      style: TextStyle(
                        color: AppColors.textTertiaryDark,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      dateFormat.format(habit.createdAt),
                      style: TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (habit.lastCompleted != null) ...[
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Último Completado',
                        style: TextStyle(
                          color: AppColors.textTertiaryDark,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        dateFormat.format(habit.lastCompleted!),
                        style: TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
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
          style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildDetailedInfo() {
    final daysOfWeek = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información del Hábito',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: 16),

          // Días de la semana
          _buildInfoRow(
            'Días:',
            Row(
              children: daysOfWeek.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                final isSelected = habit.frequency.contains(index + 1);
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.borderDark,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Momento del día
          if (habit.trigger != null)
            _buildInfoRow(
              'Momento:',
              Text(
                habit.trigger!.displayName,
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Duración estimada
          _buildInfoRow(
            'Duración:',
            Text(
              '${habit.estimatedDuration} minutos',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Repeticiones diarias
          if (habit.dailyRepetitions > 1)
            _buildInfoRow(
              'Repeticiones:',
              Text(
                '${habit.dailyRepetitions} veces al día',
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Recordatorio
          if (habit.reminderTime != null)
            _buildInfoRow(
              'Recordatorio:',
              Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    habit.reminderTime!,
                    style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Meta
          _buildInfoRow(
            'Meta:',
            Text(
              '${habit.targetDays} días',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Categoría
          if (habit.category != null)
            _buildInfoRow(
              'Categoría:',
              Row(
                children: [
                  Icon(
                    habit.category!.icon,
                    size: 16,
                    color: Color(habit.category!.color),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    habit.category!.displayName,
                    style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Tags
          if (habit.tags != null && habit.tags!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Etiquetas:',
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: habit.tags!.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
          ),
        ),
        Expanded(child: value),
      ],
    );
  }

  Widget _buildCompletionHistory() {
    final dateFormat = DateFormat('dd/MM');

    if (habit.completionDates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariantDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 40, color: AppColors.textTertiaryDark),
            const SizedBox(height: 12),
            Text(
              'Aún no hay historial',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los registros de completación aparecerán aquí',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Tomar los últimos 30 días
    final last30Days = habit.completionDates
        .where(
          (date) =>
              date.isAfter(DateTime.now().subtract(const Duration(days: 30))),
        )
        .toList();

    if (last30Days.isEmpty) {
      return Container();
    }

    // Ordenar por fecha (más reciente primero)
    last30Days.sort((a, b) => b.compareTo(a));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial Reciente',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: 16),

          // Heatmap simple (últimos 30 días)
          _buildHeatmap(last30Days),

          const SizedBox(height: 20),

          // Lista de fechas
          Column(
            children: last30Days.take(10).map((date) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormat.format(date),
                            style: TextStyle(
                              color: AppColors.textPrimaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getDayName(date.weekday),
                            style: TextStyle(
                              color: AppColors.textTertiaryDark,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(date),
                      style: TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          if (last30Days.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '+${last30Days.length - 10} completaciones más',
                style: TextStyle(
                  color: AppColors.textTertiaryDark,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(List<DateTime> completions) {
    final today = DateTime.now();
    final days = List.generate(30, (index) {
      return today.subtract(Duration(days: 29 - index));
    });

    return Column(
      children: [
        // Encabezado de días de la semana
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((day) {
            return SizedBox(
              width: 30,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textTertiaryDark,
                  fontSize: 10,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Cuadrícula de 30 días (4 semanas + 2 días)
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: days.asMap().entries.map((entry) {
            final index = entry.key;
            final date = entry.value;

            final isCompleted = completions.any((completion) {
              return completion.year == date.year &&
                  completion.month == date.month &&
                  completion.day == date.day;
            });

            return Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.accentGreen.withOpacity(0.8)
                    : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.accentGreen.withOpacity(0.3)
                      : AppColors.borderDark,
                ),
              ),
              child: Center(
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    color: isCompleted
                        ? Colors.white
                        : AppColors.textTertiaryDark,
                    fontSize: 8,
                    fontWeight: isCompleted
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
  }
}
