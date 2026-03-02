import 'package:ascend/core/widgets/ascend_card.dart';
import 'package:ascend/features/finance/presentation/pages/finance_home_page.dart';
import 'package:ascend/features/finance/domain/finance_provider.dart';
import 'package:ascend/features/habits/presentation/habits_page.dart';
import 'package:ascend/features/habits/domain/habits_provider.dart';
import 'package:ascend/features/notifications/presentation/notification_settings_page.dart';
import 'package:ascend/features/notifications/domain/notification_preferences_provider.dart';
import 'package:ascend/features/wellness/presentation/spirituality_page.dart';
import 'package:ascend/features/wellness/presentation/wellness_hub_page.dart';
import 'package:ascend/features/agenda/presentation/agenda_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../features/auth/domain/auth_provider.dart' as local_auth;
import '../../../app/routes/app_routes.dart';

enum TimelineStatus { completed, current, upcoming }

enum PriorityLevel { high, medium, low }

class PriorityItem {
  final String title;
  final String module;
  final DateTime deadline;
  final PriorityLevel priority;

  PriorityItem({
    required this.title,
    required this.module,
    required this.deadline,
    required this.priority,
  });
}


class DayPlanItem {
  final String time;
  final String title;
  final TimelineStatus status;
  final IconData icon;
  final Color color;

  const DayPlanItem({
    required this.time,
    required this.title,
    required this.status,
    required this.icon,
    required this.color,
  });
}

class HabitSummaryItem {
  final String label;
  final IconData icon;
  final bool completed;

  const HabitSummaryItem({
    required this.label,
    required this.icon,
    required this.completed,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<local_auth.AuthProvider>();
    final user = authProvider.user;
    final displayName =
        user?.displayName ?? user?.email.split('@')[0] ?? 'Usuario';

    final List<Widget> _pages = [
      HomeContentPage(displayName: displayName),
      const FinanceHomePage(),
      const HabitsPage(),
      const AgendaPage(),
      const WellnessHubPage(),
      ProfilePage(displayName: displayName),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showQuickAddDialog,
              backgroundColor: AppColors.primary,
              elevation: 8,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Widget _buildPrioritiesSection() {
    final List<PriorityItem> priorities = [
      PriorityItem(
        title: 'Entrega proyecto final',
        module: 'Academia',
        deadline: DateTime.now().add(const Duration(days: 2)),
        priority: PriorityLevel.high,
      ),
      PriorityItem(
        title: 'Comprar leche y huevos',
        module: 'Pantry',
        deadline: DateTime.now().add(const Duration(hours: 12)),
        priority: PriorityLevel.medium,
      ),
      PriorityItem(
        title: 'Llamar a mamá',
        module: 'Social',
        deadline: DateTime.now().add(const Duration(days: 1)),
        priority: PriorityLevel.medium,
      ),
    ];

    return AscendCardWithTitle(
      title: 'Prioridades del Día',
      icon: Icons.flag,
      iconColor: AppColors.warning,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${priorities.length} urgente${priorities.length > 1 ? 's' : ''}',
          style: TextStyle(color: AppColors.warning, fontSize: 12),
        ),
      ),
      content: Column(
        children: priorities
            .map((priority) => _buildPriorityItem(priority))
            .toList(),
      ),
    );
  }

  Widget _buildPriorityItem(PriorityItem priority) {
    final hoursLeft = priority.deadline.difference(DateTime.now()).inHours;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority.priority).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getPriorityColor(priority.priority).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: _getPriorityColor(priority.priority),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priority.title,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        priority.module,
                        style: TextStyle(
                          color: AppColors.textTertiaryDark,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.textTertiaryDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hoursLeft <= 24
                          ? '$hoursLeft h'
                          : '${(hoursLeft / 24).ceil()} d',
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
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textTertiaryDark,
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(PriorityLevel level) {
    switch (level) {
      case PriorityLevel.high:
        return AppColors.error;
      case PriorityLevel.medium:
        return AppColors.warning;
      case PriorityLevel.low:
        return AppColors.info;
    }
  }

  void _showQuickAddDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear Nuevo',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¿Qué te gustaría agregar?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Categorías
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          _buildQuickActionCategory('Tareas y Eventos', [
                            _buildQuickActionTile(
                              'Nueva Tarea',
                              Icons.add_task,
                              AppColors.primary,
                              'Agregar a tu día',
                            ),
                            _buildQuickActionTile(
                              'Crear Evento',
                              Icons.event,
                              AppColors.accent,
                              'Agenda',
                            ),
                            _buildQuickActionTile(
                              'Recordatorio',
                              Icons.notifications,
                              AppColors.warning,
                              'Notificación',
                            ),
                          ]),

                          const SizedBox(height: 24),

                          _buildQuickActionCategory('Seguimiento', [
                            _buildQuickActionTile(
                              'Registrar Gasto',
                              Icons.receipt,
                              AppColors.error,
                              'Finanzas',
                            ),
                            _buildQuickActionTile(
                              'Check Hábito',
                              Icons.done_all,
                              AppColors.success,
                              'Hábitos',
                            ),
                            _buildQuickActionTile(
                              'Agregar Stock',
                              Icons.inventory,
                              AppColors.info,
                              'Pantry',
                            ),
                          ]),

                          const SizedBox(height: 24),

                          _buildQuickActionCategory('Personal', [
                            _buildQuickActionTile(
                              'Nueva Nota',
                              Icons.note_add,
                              AppColors.secondary,
                              'Ideas',
                            ),
                            _buildQuickActionTile(
                              'Contactar',
                              Icons.person_add,
                              AppColors.accentGreen,
                              'Social',
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCategory(String title, List<Widget> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimaryDark,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: actions),
      ],
    );
  }

  Widget _buildQuickActionTile(
    String label,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // Navegar a formulario correspondiente
      },
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariantDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HOME CONTENT - GLASS DASHBOARD
// ============================================================================

class HomeContentPage extends StatefulWidget {
  final String displayName;

  const HomeContentPage({super.key, required this.displayName});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    // Mostrar snackbar de carga
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              'Actualizando datos...',
              style: TextStyle(color: AppColors.textPrimaryDark),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceDark,
        duration: const Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    // Aquí actualizas tus datos
    setState(() {
      // Actualizar estado de la UI
    });

    // Mostrar confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Dashboard actualizado',
            style: TextStyle(color: AppColors.accentGreen),
          ),
          backgroundColor: AppColors.surfaceDark,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  color: AppColors.backgroundDark,
                  child: _buildGlassHeader(context, widget.displayName),
                ),

                  const SizedBox(height: 24),
                  _buildWelcomeCard(widget.displayName),
                  const SizedBox(height: 16),
                  _buildLifeInsightsCard(),
                  const SizedBox(height: 24),
                  _buildPrioritiesSection(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildDayCard(),
                        const SizedBox(height: 16),
                        _buildHabitsCard(),
                        const SizedBox(height: 16),
                        _buildKPIsCard(),
                        const SizedBox(height: 16),
                        _buildRemindersCard(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildModulesBar(),
                  const SizedBox(height: 48),

                  // Sección de logros
                  _buildAchievementsSection(),

                  const SizedBox(height: 16),

                  // Sección de consejos
                  _buildTipsSection(),

                  const SizedBox(height: 56),
                ],
              ),
            ),

          // Botón de refresh flotante
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              onPressed: _refreshData,
              backgroundColor: AppColors.primary,
              mini: true,
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassHeader(BuildContext context, String displayName) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark.withOpacity(0.1),
                AppColors.secondary.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ASCEND',
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              InkWell(
                onTap: () {
                  // Navegar a perfil
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Center(
                    child: Text(
                      displayName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String displayName) {
    final hour = DateTime.now().hour;
    String greeting = 'Buenos días';
    if (hour >= 12 && hour < 20) greeting = 'Buenas tardes';
    if (hour >= 20 || hour < 6) greeting = 'Buenas noches';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Anillo de consistencia más grande
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: 0.87,
                      strokeWidth: 6,
                      backgroundColor: AppColors.surfaceVariantDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '87%',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.textPrimaryDark,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        'Nivel 5',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 20),

              // Información de bienvenida y stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mini stats en fila
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniStat('5/7', 'Hábitos', Icons.check_circle),
                        _buildMiniStat('3', 'Pendientes', Icons.access_time),
                        _buildMiniStat('\$240', 'Gasto', Icons.attach_money),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Barra de progreso semanal
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso semanal',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  Text(
                    '87% ↗',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantDark,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.87,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildDayCard() {
    final habitsProvider = context.watch<HabitsProvider>();
    final notificationsProvider = context.watch<NotificationPreferencesProvider>();

    final items = <DayPlanItem>[];

    for (final reminder in notificationsProvider.reminders.where((r) => r.enabled).take(3)) {
      items.add(
        DayPlanItem(
          time: '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}',
          title: reminder.module,
          status: TimelineStatus.upcoming,
          icon: Icons.notifications_active,
          color: AppColors.accent,
        ),
      );
    }

    if (items.isEmpty) {
      for (final habit in habitsProvider.habitsDueToday.take(3)) {
        items.add(
          DayPlanItem(
            time: 'Hoy',
            title: habit.name,
            status: habit.isFullyCompletedToday
                ? TimelineStatus.completed
                : TimelineStatus.current,
            icon: habit.category?.icon ?? Icons.check_circle,
            color: habit.isFullyCompletedToday
                ? AppColors.accentGreen
                : AppColors.primary,
          ),
        );
      }
    }

    if (items.isEmpty) {
      items.add(
        const DayPlanItem(
          time: 'Sin tareas',
          title: 'No tenés recordatorios activos',
          status: TimelineStatus.upcoming,
          icon: Icons.event_available,
          color: AppColors.textTertiaryDark,
        ),
      );
    }

    final completedCount =
        items.where((item) => item.status == TimelineStatus.completed).length;

    return AscendCardWithTitle(
      title: 'Tu día hoy',
      icon: Icons.calendar_today,
      iconColor: AppColors.primary,
      trailing: Text(
        '$completedCount/${items.length} listo',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondaryDark,
        ),
      ),
      content: Column(
        children: [
          for (final item in items)
            _buildTimelineItemWithTime(
              time: item.time,
              title: item.title,
              icon: item.icon,
              status: item.status,
              color: item.color,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItemWithTime({
    required String time,
    required String title,
    required IconData icon,
    required TimelineStatus status,
    required Color color,
  }) {
    final done = status == TimelineStatus.completed;
    final current = status == TimelineStatus.current;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: current
            ? color.withOpacity(0.1)
            : AppColors.surfaceVariantDark.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: current ? color.withOpacity(0.35) : AppColors.borderDark,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: done ? color : color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check : icon,
              size: 18,
              color: done ? Colors.white : color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          if (current)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Ahora',
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHabitsCard() {
    final habitsProvider = context.watch<HabitsProvider>();

    final habits = habitsProvider.habitsDueToday
        .map(
          (habit) => HabitSummaryItem(
            label: habit.name,
            icon: habit.category?.icon ?? Icons.check_circle,
            completed: habit.isFullyCompletedToday,
          ),
        )
        .toList();

    final completedCount = habits.where((habit) => habit.completed).length;

    return AscendCardWithTitle(
      title: 'Hábitos del día',
      icon: Icons.track_changes,
      iconColor: AppColors.accentGreen,
      trailing: Text(
        '$completedCount/${habits.length}',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondaryDark,
        ),
      ),
      content: habits.isEmpty
          ? Text(
              'No hay hábitos programados para hoy',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            )
          : Column(
              children: [
                LinearProgressIndicator(
                  value: habits.isEmpty ? 0 : completedCount / habits.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: AppColors.surfaceVariantDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accentGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final habit in habits)
                      _buildHabitChip(habit.label, habit.icon, habit.completed),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildHabitChip(String label, IconData icon, bool completed) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: completed
            ? AppColors.primary.withOpacity(0.16)
            : AppColors.surfaceVariantDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed ? AppColors.primary.withOpacity(0.4) : AppColors.borderDark,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: completed ? AppColors.primary : AppColors.textTertiaryDark,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: completed ? AppColors.textPrimaryDark : AppColors.textSecondaryDark,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIsCard() {
    return AscendCardWithTitle(
      title: 'KPIs de Vida',
      icon: Icons.analytics,
      iconColor: AppColors.primary,
      content: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _buildKPICircle('Energía', 0.8, Icons.bolt, AppColors.warning),
          _buildKPICircle(
            'Consist.',
            0.87,
            Icons.trending_up,
            AppColors.accent,
          ),
          _buildKPICircle('Product.', 0.65, Icons.work, AppColors.primary),
          _buildKPICircle(
            'Finanzas',
            0.92,
            Icons.attach_money,
            AppColors.accentGreen,
          ),
          _buildKPICircle(
            'Orden',
            0.75,
            Icons.cleaning_services,
            AppColors.secondary,
          ),
          _buildKPICircle('Social', 0.6, Icons.people, AppColors.info),
        ],
      ),
    );
  }

  Widget _buildKPICircle(
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        // Navegar a detalle del KPI
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 4,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      '${(value * 100).toInt()}%',
                      style: TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifeInsightsCard() {
    final habitsProvider = context.watch<HabitsProvider>();
    final financeProvider = context.watch<FinanceProvider>();
    final notificationsProvider = context.watch<NotificationPreferencesProvider>();

    final habitsScore = habitsProvider.getWeeklyConsistency();
    final savingsRate = financeProvider.savingsRate.clamp(0.0, 1.0);
    final notifScore = notificationsProvider.reminders.where((r) => r.enabled).isEmpty
        ? 0.3
        : 0.8;

    final integralScore = ((habitsScore * 0.45) + (savingsRate * 0.35) + (notifScore * 0.2))
        .clamp(0.0, 1.0);

    final status = integralScore >= 0.75
        ? 'verde'
        : integralScore >= 0.45
        ? 'amarillo'
        : 'rojo';

    final statusColor = status == 'verde'
        ? AppColors.accentGreen
        : status == 'amarillo'
        ? AppColors.warning
        : AppColors.error;

    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Insights de vida (hoy)',
                style: AppTextStyles.h4.copyWith(color: AppColors.textPrimaryDark),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: integralScore,
            minHeight: 9,
            backgroundColor: AppColors.surfaceVariantDark,
            valueColor: AlwaysStoppedAnimation(statusColor),
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Text(
            'Índice integral: ${(integralScore * 100).toStringAsFixed(0)}% · Hábitos ${(habitsScore * 100).toStringAsFixed(0)}% · Finanzas ${(savingsRate * 100).toStringAsFixed(0)}%',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Sync notif: ${notificationsProvider.syncState.name}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
          ),
          const SizedBox(height: 12),
          if (userId != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('spiritual_entries')
                  .orderBy('createdAt', descending: true)
                  .limit(7)
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;
                final spiritualityScore = (count / 7).clamp(0.0, 1.0);
                return Text(
                  'Espiritualidad (7 días): ${(spiritualityScore * 100).toStringAsFixed(0)}% (${count}/7 entradas)',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRemindersCard() {
    final provider = context.watch<NotificationPreferencesProvider>();
    final reminders = provider.reminders;
    final active = reminders.where((r) => r.enabled).toList();
    final now = DateTime.now();
    final unseen = active.where((r) {
      final seenAt = provider.lastSeenByModule[r.module];
      if (seenAt == null) return true;
      return seenAt.year != now.year || seenAt.month != now.month || seenAt.day != now.day;
    }).length;

    return AscendCardWithTitle(
      title: 'Recordatorios',
      icon: Icons.notifications,
      iconColor: AppColors.accent,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unseen > 0)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$unseen',
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
            ),
          TextButton(
            onPressed: () {
              for (final r in active) {
                provider.markModuleAsSeen(r.module);
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsPage(),
                ),
              );
            },
            child: const Text('Configurar'),
          ),
        ],
      ),
      content: Column(
        children: [
          if (active.isEmpty)
            _buildReminderItem(
              'Sin recordatorios activos',
              'Activá módulos clave desde Configurar',
              AppColors.textTertiaryDark,
            )
          else
            ...active.take(3).map(
              (item) => _buildReminderItem(
                item.module,
                '${item.hour.toString().padLeft(2, '0')}:${item.minute.toString().padLeft(2, '0')} · ${item.message}',
                AppColors.accent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textTertiaryDark,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildModulesBar() {
    final List<Map<String, dynamic>> modules = [
      {
        'title': 'Espiritualidad',
        'icon': Icons.auto_stories,
        'color': AppColors.accent,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SpiritualityPage()),
        ),
      },
      {
        'title': 'Hábitos',
        'icon': Icons.track_changes,
        'color': AppColors.primary,
      },
      {
        'title': 'Agenda',
        'icon': Icons.calendar_today,
        'color': AppColors.info,
      },
      {
        'title': 'Relaciones',
        'icon': Icons.people,
        'color': AppColors.secondary,
      },
      {
        'title': 'Finanzas',
        'icon': Icons.attach_money,
        'color': AppColors.accentGreen,
      },
      {
        'title': 'Salud',
        'icon': Icons.favorite,
        'color': AppColors.warning,
      },
      {
        'title': 'Hogar',
        'icon': Icons.home,
        'color': AppColors.error,
      },
      {
        'title': 'Notifs',
        'icon': Icons.notifications_active,
        'color': AppColors.primaryDark,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
        ),
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Text(
            'Módulos ASCEND',
            style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: modules.map((module) {
              return _buildModuleButton(
                module['title'] as String,
                module['icon'] as IconData,
                module['color'] as Color,
                onTap: module['onTap'] as VoidCallback?,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleButton(
    String label,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Logros de la Semana',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildAchievementBadge(
                '7 días seguidos',
                Icons.local_fire_department,
              ),
              _buildAchievementBadge('Ahorro récord', Icons.savings),
              _buildAchievementBadge('Productividad +20%', Icons.rocket_launch),
              _buildAchievementBadge('Hábitos completados', Icons.check_circle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            '💡 Consejo de hoy',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: 12),
          Text(
            'Programa tus tareas más importantes en tu hora de mayor energía.',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PROFILE PAGE
// ============================================================================

class ProfilePage extends StatefulWidget {
  final String displayName;

  const ProfilePage({super.key, required this.displayName});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadHealthProfile();
  }

  Future<void> _loadHealthProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('health_profile')
        .get();

    final data = doc.data();
    if (data == null) return;

    _weightController.text = (data['weightKg'] ?? '').toString();
    _heightController.text = (data['heightCm'] ?? '').toString();
    if (mounted) setState(() {});
  }

  Future<void> _saveHealthProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);

    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('health_profile')
        .set({
          'weightKg': weight,
          'heightCm': height,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos guardados ✅')),
      );
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<local_auth.AuthProvider>();
    final user = authProvider.user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Text(
                  (user?.displayName?[0] ?? user?.email[0] ?? 'U').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Usuario',
              style: AppTextStyles.h2.copyWith(color: AppColors.textPrimaryDark),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perfil de salud',
                    style: AppTextStyles.h4.copyWith(color: AppColors.textPrimaryDark),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Peso (kg)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Altura (cm)'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _saveHealthProfile,
                    icon: const Icon(Icons.save),
                    label: Text(_saving ? 'Guardando...' : 'Guardar datos'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Google Health: integración planificada para la pestaña Salud (pasos, calorías, etc.).',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
