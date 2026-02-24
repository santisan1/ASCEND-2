import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'package:ascend/features/habits/domain/habit_model.dart';

// ============================================================================
// CALENDARIO GENERAL - Vista de todos los hábitos
// ============================================================================

class HabitsProgressCalendar extends StatefulWidget {
  final List<Habit> habits;

  const HabitsProgressCalendar({super.key, required this.habits});

  @override
  State<HabitsProgressCalendar> createState() => _HabitsProgressCalendarState();
}

class _HabitsProgressCalendarState extends State<HabitsProgressCalendar> {
  DateTime _selectedMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  Map<DateTime, int> _getCompletionsForMonth() {
    final completions = <DateTime, int>{};

    for (final habit in widget.habits) {
      for (final completion in habit.completionHistory) {
        try {
          final date = DateTime.parse(completion);
          final dateKey = DateTime(date.year, date.month, date.day);

          if (dateKey.year == _selectedMonth.year &&
              dateKey.month == _selectedMonth.month) {
            completions[dateKey] = (completions[dateKey] ?? 0) + 1;
          }
        } catch (e) {
          // Ignorar fechas inválidas
        }
      }
    }

    return completions;
  }

  @override
  Widget build(BuildContext context) {
    final completions = _getCompletionsForMonth();
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );

    final firstWeekday = firstDayOfMonth.weekday;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          // Header con mes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.textPrimaryDark,
              ),
              Text(
                _getMonthName(_selectedMonth.month),
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.textPrimaryDark,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Días de la semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((day) {
              return SizedBox(
                width: 36,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Grid de días
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: firstWeekday - 1 + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }

              final day = index - firstWeekday + 2;
              final date = DateTime(
                _selectedMonth.year,
                _selectedMonth.month,
                day,
              );
              final completionCount = completions[date] ?? 0;
              final isToday = _isToday(date);
              final isFuture = date.isAfter(DateTime.now());

              return _buildDayCell(day, completionCount, isToday, isFuture);
            },
          ),

          const SizedBox(height: 20),

          // Leyenda
          Wrap(
            spacing: 16,
            children: [
              _buildLegendItem('Sin datos', AppColors.surfaceVariantDark),
              _buildLegendItem(
                '1-2 hábitos',
                AppColors.primary.withOpacity(0.3),
              ),
              _buildLegendItem(
                '3-4 hábitos',
                AppColors.primary.withOpacity(0.6),
              ),
              _buildLegendItem('5+ hábitos', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(int day, int completions, bool isToday, bool isFuture) {
    Color backgroundColor;

    if (isFuture) {
      backgroundColor = AppColors.surfaceVariantDark.withOpacity(0.2);
    } else if (completions == 0) {
      backgroundColor = AppColors.surfaceVariantDark;
    } else if (completions <= 2) {
      backgroundColor = AppColors.primary.withOpacity(0.3);
    } else if (completions <= 4) {
      backgroundColor = AppColors.primary.withOpacity(0.6);
    } else {
      backgroundColor = AppColors.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday ? AppColors.accent : Colors.transparent,
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: completions > 0 || isToday
                    ? AppColors.textPrimaryDark
                    : AppColors.textTertiaryDark,
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (completions > 0 && !isFuture)
              Text(
                '$completions',
                style: TextStyle(
                  color: AppColors.textPrimaryDark.withOpacity(0.7),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }
}

// ============================================================================
// CALENDARIO INDIVIDUAL - Vista de un hábito específico
// ============================================================================

class IndividualHabitCalendar extends StatefulWidget {
  final Habit habit;

  const IndividualHabitCalendar({super.key, required this.habit});

  @override
  State<IndividualHabitCalendar> createState() =>
      _IndividualHabitCalendarState();
}

class _IndividualHabitCalendarState extends State<IndividualHabitCalendar> {
  DateTime _selectedMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  Set<DateTime> _getCompletedDates() {
    final completedDates = <DateTime>{};

    for (final completion in widget.habit.completionHistory) {
      try {
        final date = DateTime.parse(completion);
        completedDates.add(DateTime(date.year, date.month, date.day));
      } catch (e) {
        // Ignorar fechas inválidas
      }
    }

    return completedDates;
  }

  @override
  Widget build(BuildContext context) {
    final completedDates = _getCompletedDates();
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );

    final firstWeekday = firstDayOfMonth.weekday;

    // Calcular estadísticas del mes
    final completedThisMonth = completedDates.where((date) {
      return date.year == _selectedMonth.year &&
          date.month == _selectedMonth.month;
    }).length;

    final today = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == today.year &&
        _selectedMonth.month == today.month;
    final daysElapsed = isCurrentMonth ? today.day : daysInMonth;
    final completionRate = daysElapsed > 0
        ? (completedThisMonth / daysElapsed * 100).toInt()
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Stats del mes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.accent.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Completados', '$completedThisMonth'),
                _buildStat('Tasa', '$completionRate%'),
                _buildStat('Streak', '${widget.habit.currentStreak}'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Header del calendario
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.textPrimaryDark,
              ),
              Column(
                children: [
                  Text(
                    _getMonthName(_selectedMonth.month),
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  Text(
                    '${_selectedMonth.year}',
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.textPrimaryDark,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Días de la semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((day) {
              return SizedBox(
                width: 40,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Grid de días
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: firstWeekday - 1 + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }

              final day = index - firstWeekday + 2;
              final date = DateTime(
                _selectedMonth.year,
                _selectedMonth.month,
                day,
              );
              final isCompleted = completedDates.contains(date);
              final isToday = _isToday(date);
              final isFuture = date.isAfter(DateTime.now());
              final isDueDay = widget.habit.frequency.contains(date.weekday);

              return _buildIndividualDayCell(
                day,
                isCompleted,
                isToday,
                isFuture,
                isDueDay,
              );
            },
          ),

          const SizedBox(height: 20),

          // Leyenda
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(
                'Completado',
                AppColors.accentGreen,
                Icons.check_circle,
              ),
              _buildLegendItem(
                'Omitido',
                AppColors.error.withOpacity(0.5),
                Icons.cancel,
              ),
              _buildLegendItem(
                'No aplica',
                AppColors.surfaceVariantDark,
                Icons.remove_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualDayCell(
    int day,
    bool isCompleted,
    bool isToday,
    bool isFuture,
    bool isDueDay,
  ) {
    Color backgroundColor;
    Color borderColor = Colors.transparent;
    IconData? icon;
    Color? iconColor;

    if (isFuture) {
      backgroundColor = AppColors.surfaceVariantDark.withOpacity(0.2);
    } else if (!isDueDay) {
      backgroundColor = AppColors.surfaceVariantDark.withOpacity(0.3);
      icon = Icons.remove_circle_outline;
      iconColor = AppColors.textTertiaryDark;
    } else if (isCompleted) {
      backgroundColor = AppColors.accentGreen.withOpacity(0.3);
      icon = Icons.check_circle;
      iconColor = AppColors.accentGreen;
    } else {
      backgroundColor = AppColors.error.withOpacity(0.2);
      icon = Icons.cancel;
      iconColor = AppColors.error.withOpacity(0.7);
    }

    if (isToday) {
      borderColor = AppColors.accent;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 12,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (icon != null && !isFuture) Icon(icon, size: 14, color: iconColor),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimaryDark,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }
}
