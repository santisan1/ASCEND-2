import 'package:ascend/core/widgets/ascend_card.dart';
import 'package:ascend/features/finance/presentation/pages/finance_home_page.dart';
import 'package:ascend/features/habits/presentation/habits_page.dart';
import 'package:ascend/nueva_pagina.dart';
import 'package:ascend/features/notifications/presentation/notification_settings_page.dart';
import 'package:ascend/features/notifications/domain/notification_preferences_provider.dart';
import 'package:ascend/features/wellness/presentation/spirituality_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../features/auth/domain/auth_provider.dart';
import '../../../app/routes/app_routes.dart';

// ... tus imports existentes

// Agrega esto ANTES de class HomePage:
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final displayName =
        user?.displayName ?? user?.email.split('@')[0] ?? 'Usuario';

    final List<Widget> _pages = [
      HomeContentPage(displayName: displayName),
      const FinanceHomePage(),
      const HabitsPage(), // <--
      NuevaPagina(),
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
  // ... tus otros métodos existentes...

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

  // MODIFICAR _showQuickAddDialog:
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
  bool _showRefreshHint = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && _showRefreshHint) {
        setState(() {
          _showRefreshHint = false;
        });
      }
    });

    // Ocultar hint después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _showRefreshHint) {
        setState(() {
          _showRefreshHint = false;
        });
      }
    });
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
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Detectar cuando llega al top
              if (notification is ScrollStartNotification) {
                if (_scrollController.position.pixels == 0) {
                  _refreshData();
                  return true;
                }
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100), // Espacio extra
              child: Column(
                children: [
                  // Indicador de pull to refresh visible
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    color: AppColors.backgroundDark,
                    child: Column(
                      children: [
                        if (_showRefreshHint)
                          Column(
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Desliza hacia abajo para actualizar',
                                style: TextStyle(
                                  color: AppColors.textSecondaryDark,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        _buildGlassHeader(context, widget.displayName),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildWelcomeCard(widget.displayName),
                  const SizedBox(height: 24),
                  _buildPrioritiesSection(), // <-- AGREGÁ ESTA LÍNEA
                  const SizedBox(height: 24), // <-- AGREGÁ ESTA LÍNEA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _buildDayCard(),
                              const SizedBox(height: 16),
                              _buildHabitsCard(),
                              const SizedBox(height: 32),

                              // Widget adicional para ocupar espacio
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariantDark
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.borderDark,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.trending_up,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Progreso Mensual',
                                          style: AppTextStyles.h4.copyWith(
                                            color: AppColors.textPrimaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    LinearProgressIndicator(
                                      value: 0.65,
                                      backgroundColor:
                                          AppColors.surfaceVariantDark,
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Consistencia',
                                          style: TextStyle(
                                            color: AppColors.textSecondaryDark,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '65%',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _buildKPIsCard(),
                              const SizedBox(height: 16),
                              _buildRemindersCard(),
                              const SizedBox(height: 32),

                              // Widget adicional
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariantDark
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.borderDark,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.flag,
                                          color: AppColors.accent,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Metas',
                                          style: AppTextStyles.h4.copyWith(
                                            color: AppColors.textPrimaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '2 de 5 metas completadas esta semana',
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
                        ),
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

                  // Footer con instrucciones
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariantDark.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '💡 Consejo del día',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Revisa tus hábitos diarios para mantener la consistencia.',
                          style: TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _refreshData,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Actualizar manualmente',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ESPACIO FINAL PARA GARANTIZAR SCROLL
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                ],
              ),
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
                  // Navegar a perfil (índice 4)
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

  // REEMPLAZAR _buildWelcomeCard con:
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

  // REEMPLAZAR _buildDayCard con:
  Widget _buildDayCard() {
    return Container(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tu Día Hoy',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const Spacer(),
              // Selector de día
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Hoy',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Timeline con estado actual destacado
          _buildTimelineItemWithTime(
            time: '09:00 - 10:00',
            title: 'Reunión equipo',
            icon: Icons.videocam,
            status: TimelineStatus.completed,
            color: AppColors.primary,
          ),

          _buildTimelineItemWithTime(
            time: 'ACTUAL',
            title: 'Trabajo en proyecto',
            icon: Icons.work,
            status: TimelineStatus.current,
            color: AppColors.accent,
          ),

          _buildTimelineItemWithTime(
            time: '14:00 - 15:00',
            title: 'Almuerzo con María',
            icon: Icons.restaurant,
            status: TimelineStatus.upcoming,
            color: AppColors.secondary,
          ),

          _buildTimelineItemWithTime(
            time: '16:00 - 17:00',
            title: 'Revisión finanzas',
            icon: Icons.attach_money,
            status: TimelineStatus.upcoming,
            color: AppColors.accentGreen,
          ),

          _buildTimelineItemWithTime(
            time: '19:00 - 20:00',
            title: 'Meditación',
            icon: Icons.self_improvement,
            status: TimelineStatus.upcoming,
            color: AppColors.info,
          ),

          const SizedBox(height: 16),

          // Ver más
          InkWell(
            onTap: () {
              // Navegar a agenda completa
            },
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantDark.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ver agenda completa',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppColors.textSecondaryDark,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Función auxiliar para construir items de timeline
  Widget _buildTimelineItemWithTime({
    required String time,
    required String title,
    required IconData icon,
    required TimelineStatus status,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiempo
          SizedBox(
            width: 70,
            child: Text(
              time,
              style: TextStyle(
                color: status == TimelineStatus.current
                    ? AppColors.accent
                    : AppColors.textTertiaryDark,
                fontSize: 11,
                fontWeight: status == TimelineStatus.current
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),

          // Línea vertical y punto
          Column(
            children: [
              Container(
                width: 2,
                height: 8,
                color: status == TimelineStatus.completed
                    ? color
                    : AppColors.borderDark,
              ),
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: status == TimelineStatus.current
                      ? color
                      : Colors.transparent,
                  border: Border.all(
                    color: status == TimelineStatus.completed
                        ? color
                        : AppColors.borderDark,
                    width: 2,
                  ),
                ),
                child: status == TimelineStatus.completed
                    ? const Icon(Icons.check, size: 8, color: Colors.white)
                    : null,
              ),
              Container(
                width: 2,
                height: 24,
                color: status == TimelineStatus.completed
                    ? color.withOpacity(0.5)
                    : AppColors.borderDark,
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Contenido
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: status == TimelineStatus.current
                    ? color.withOpacity(0.1)
                    : AppColors.surfaceVariantDark.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: status == TimelineStatus.current
                      ? color.withOpacity(0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontSize: 14,
                        fontWeight: status == TimelineStatus.current
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (status == TimelineStatus.current)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Ahora',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsCard() {
    return AscendCardWithTitle(
      title: 'Hábitos del Día',
      icon: Icons.track_changes,
      iconColor: AppColors.accentGreen,
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildHabitChip('Meditar', Icons.self_improvement, true),
          _buildHabitChip('Ejercicio', Icons.directions_run, true),
          _buildHabitChip('Agua 2L', Icons.water_drop, false),
          _buildHabitChip('Lectura', Icons.menu_book, false),
          _buildHabitChip('Dormir 8h', Icons.nightlight, true),
        ],
      ),
    );
  }

  Widget _buildHabitChip(String label, IconData icon, bool completed) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: completed
            ? AppColors.primary.withOpacity(0.2)
            : AppColors.surfaceVariantDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed ? AppColors.primary : AppColors.borderDark,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: completed ? AppColors.primary : AppColors.textTertiaryDark,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: completed
                  ? AppColors.textPrimaryDark
                  : AppColors.textTertiaryDark,
              fontSize: 10,
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

  // REEMPLAZAR _buildKPICircle con:
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

  Widget _buildRemindersCard() {
    final reminders = context.watch<NotificationPreferencesProvider>().reminders;
    final active = reminders.where((r) => r.enabled).toList();

    return AscendCardWithTitle(
      title: 'Recordatorios',
      icon: Icons.notifications,
      iconColor: AppColors.accent,
      trailing: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationSettingsPage(),
            ),
          );
        },
        child: const Text('Configurar'),
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
// PLACEHOLDER PAGES
// ============================================================================
// ... tus otros métodos existentes...

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

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: AppColors.textTertiaryDark),
          const SizedBox(height: 16),
          Text(
            '$title - En construcción',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimaryDark),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PROFILE PAGE
// ============================================================================

class ProfilePage extends StatelessWidget {
  final String displayName;

  const ProfilePage({super.key, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Text(
                  (user?.displayName?[0] ?? user?.email[0] ?? 'U')
                      .toUpperCase(),
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
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimaryDark,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              user?.email ?? '',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),

            const SizedBox(height: 32),

            // Botón cerrar sesión
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
