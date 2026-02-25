import 'package:ascend/features/habits/presentation/habit_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/habits_provider.dart';
import 'widgets/habit_tile.dart';
import 'widgets/habits_stats.dart';
import 'widgets/add_habit_dialog.dart';
import 'widgets/habit_progress_calendar.dart';
import 'widgets/habits_timeline_view.dart';
import '../domain/habit_model.dart';

enum HabitViewMode { list, timeline, calendar }

enum HabitFilter { todos, hoy, completados, pendientes }

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  HabitFilter _currentFilter = HabitFilter.todos;
  HabitViewMode _viewMode = HabitViewMode.list;

  @override
  void initState() {
    super.initState();
  }

  List<Habit> _getFilteredHabits(HabitsProvider provider) {
    switch (_currentFilter) {
      case HabitFilter.todos:
        return provider.habits;
      case HabitFilter.hoy:
        return provider.habitsDueToday;
      case HabitFilter.completados:
        return provider.completedToday;
      case HabitFilter.pendientes:
        return provider.habitsDueToday
            .where((h) => !h.isFullyCompletedToday)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsProvider = context.watch<HabitsProvider>();
    final filteredHabits = _getFilteredHabits(habitsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                border: Border(bottom: BorderSide(color: AppColors.borderDark)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Hábitos',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const Spacer(),

                  // Selector de vista
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildViewModeButton(HabitViewMode.list, Icons.list),
                        _buildViewModeButton(
                          HabitViewMode.timeline,
                          Icons.timeline,
                        ),
                        _buildViewModeButton(
                          HabitViewMode.calendar,
                          Icons.calendar_month,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    onPressed: () => _showAddHabitDialog(),
                    icon: const Icon(Icons.add, color: AppColors.primary),
                  ),
                ],
              ),
            ),

            // Filtros (solo para lista y timeline)
            if (_viewMode != HabitViewMode.calendar)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'Todos',
                        HabitFilter.todos,
                        habitsProvider.habits.length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Hoy',
                        HabitFilter.hoy,
                        habitsProvider.habitsDueToday.length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Completados',
                        HabitFilter.completados,
                        habitsProvider.completedToday.length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Pendientes',
                        HabitFilter.pendientes,
                        habitsProvider.habitsDueToday
                            .where((h) => !h.isFullyCompletedToday)
                            .length,
                      ),
                    ],
                  ),
                ),
              ),

            // Estadísticas (solo para lista)
            if (_viewMode == HabitViewMode.list)
              HabitsStats(
                weeklyConsistency: habitsProvider.getWeeklyConsistency(),
                totalStreak: habitsProvider.getTotalStreak(),
                totalHabits: habitsProvider.habits.length,
              ),

            if (_viewMode == HabitViewMode.list)
              _buildWeeklyMonthlyInsights(habitsProvider),

            // Contenido según el modo de vista
            Expanded(
              child: habitsProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _buildContent(filteredHabits, habitsProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeButton(HabitViewMode mode, IconData icon) {
    final isSelected = _viewMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _viewMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildContent(List<Habit> filteredHabits, HabitsProvider provider) {
    switch (_viewMode) {
      case HabitViewMode.timeline:
        return _buildTimelineView(provider);
      case HabitViewMode.calendar:
        return _buildCalendarView(provider);
      case HabitViewMode.list:
      default:
        return _buildListView(filteredHabits, provider);
    }
  }

  Widget _buildListView(List<Habit> filteredHabits, HabitsProvider provider) {
    if (filteredHabits.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Hábitos actualizados'),
              backgroundColor: AppColors.accentGreen,
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredHabits.length,
        itemBuilder: (context, index) {
          final habit = filteredHabits[index];
          return HabitTile(
            habit: habit,
            onCompleted: () => _completeHabit(habit.id),
            onPressed: () => _showHabitDetails(habit),
            onUndo: () => _undoHabitCompletion(habit.id),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyMonthlyInsights(HabitsProvider provider) {
    final weekly = provider.getWeeklyConsistency();
    final monthly = provider.getMonthlyConsistencyByWeek();
    final atRisk = provider.getAtRiskHabits();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trackeo semanal + mensual',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Semana actual: ${(weekly * 100).toStringAsFixed(0)}% de consistencia',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...monthly.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: entry.value,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceDark,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(entry.value * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (atRisk.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withOpacity(0.35)),
              ),
              child: Text(
                '⚠️ Hoy en riesgo: ${atRisk.map((h) => h.name).take(2).join(', ')}${atRisk.length > 2 ? '...' : ''}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineView(HabitsProvider provider) {
    final habitsToday = provider.habitsDueToday;

    if (habitsToday.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📅', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                'No hay hábitos programados para hoy',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return HabitsTimelineView(
      habits: provider.habits, // Todos los hábitos
      onComplete: (habitId) {
        // Lógica para completar hábito
        provider.completeHabitSimple(habitId);
      },
      onUndo: (habitId) {
        // Lógica para deshacer completado
        provider.undoCompletion(habitId);
      },
      onTap: (habit) {
        // Navegar a detalles del hábito
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HabitDetailScreen(habit: habit),
          ),
        );
      },
    );
  }

  Widget _buildCalendarView(HabitsProvider provider) {
    return SingleChildScrollView(
      child: HabitsProgressCalendar(habits: provider.habits),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String emoji;

    switch (_currentFilter) {
      case HabitFilter.completados:
        message = 'No hay hábitos completados hoy';
        emoji = '⏳';
        break;
      case HabitFilter.pendientes:
        message = '¡Genial! No hay hábitos pendientes';
        emoji = '🎉';
        break;
      case HabitFilter.hoy:
        message = 'No hay hábitos programados para hoy';
        emoji = '📅';
        break;
      default:
        message = 'Sin hábitos aún';
        emoji = '🚀';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                    if (_currentFilter == HabitFilter.todos) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Comenzá tu viaje de crecimiento personal',
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _showAddHabitDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Crear mi primer hábito'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, HabitFilter filter, int count) {
    final isSelected = _currentFilter == filter;

    return InkWell(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.surfaceVariantDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderDark,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondaryDark,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textTertiaryDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.surfaceDark,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _completeHabit(String habitId) async {
    final habitsProvider = context.read<HabitsProvider>();
    final habit = habitsProvider.habits.firstWhere((h) => h.id == habitId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Completando...',
                style: TextStyle(color: AppColors.textPrimaryDark),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await habitsProvider.completeHabit(habitId);

      if (mounted) {
        Navigator.pop(context);

        final updatedHabit = habitsProvider.habits.firstWhere(
          (h) => h.id == habitId,
        );
        final isNewStreak = updatedHabit.currentStreak > habit.currentStreak;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¡${habit.name} completado!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (updatedHabit.dailyRepetitions > 1)
                        Text(
                          '${updatedHabit.completionsToday}/${updatedHabit.dailyRepetitions} completado',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      if (isNewStreak)
                        Text(
                          '🔥 Streak: ${updatedHabit.currentStreak} días',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
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

  Future<void> _undoHabitCompletion(String habitId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          '¿Deshacer completion?',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: const Text(
          'Esto eliminará la última vez que marcaste este hábito como completado hoy.',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Deshacer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final habitsProvider = context.read<HabitsProvider>();

    try {
      await habitsProvider.undoHabitCompletion(habitId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Completion deshecha'),
          backgroundColor: AppColors.info,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _showAddHabitDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const AddHabitDialog(),
    );
  }

  void _showHabitDetails(Habit habit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Icon(
                          habit.category?.icon ?? Icons.track_changes,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            habit.name,
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (habit.description.isNotEmpty)
                      Text(
                        habit.description,
                        style: TextStyle(color: AppColors.textSecondaryDark),
                      ),

                    const SizedBox(height: 20),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Streak actual',
                          '${habit.currentStreak} días',
                        ),
                        _buildStatItem('Récord', '${habit.longestStreak} días'),
                        _buildStatItem(
                          'Completados',
                          '${habit.totalCompletions}',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    IndividualHabitCalendar(habit: habit),

                    const SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Navegar a editar
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Editar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDeleteHabit(habit),
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Eliminar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteHabit(Habit habit) async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          '¿Eliminar hábito?',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: Text(
          '¿Estás seguro de que querés eliminar "${habit.name}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<HabitsProvider>().deleteHabit(habit.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hábito eliminado'),
            backgroundColor: AppColors.error,
          ),
        );
      } catch (e) {
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
