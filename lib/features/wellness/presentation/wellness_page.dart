// 📁 UBICACIÓN: lib/features/wellness/presentation/wellness_page.dart
//
// INSTRUCCIONES:
// 1. Creá la carpeta: lib/features/wellness/presentation/
// 2. Creá este archivo: wellness_page.dart
// 3. Copiá todo este código

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/wellness_provider.dart';
import '../data/models/wellness_models.dart';

class WellnessPage extends StatefulWidget {
  const WellnessPage({super.key});

  @override
  State<WellnessPage> createState() => _WellnessPageState();
}

class _WellnessPageState extends State<WellnessPage> {
  @override
  Widget build(BuildContext context) {
    final wellnessProvider = context.watch<WellnessProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: wellnessProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(wellnessProvider),

                    const SizedBox(height: 24),

                    // Afirmación del día
                    _buildAffirmationCard(wellnessProvider),

                    const SizedBox(height: 24),

                    // Estado emocional
                    _buildMoodTracker(wellnessProvider),

                    const SizedBox(height: 24),

                    // Contact Zero (si está activo)
                    if (wellnessProvider.contactZero != null)
                      _buildContactZeroCard(wellnessProvider),

                    if (wellnessProvider.contactZero != null)
                      const SizedBox(height: 24),

                    // Hábitos Base
                    _buildBaseHabits(wellnessProvider),

                    const SizedBox(height: 24),

                    // Misiones del día
                    _buildDailyMissions(wellnessProvider),

                    const SizedBox(height: 24),

                    // Centro de calma - acceso rápido
                    _buildCalmCenterAccess(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(WellnessProvider provider) {
    final hour = DateTime.now().hour;
    String greeting = 'Buenos días';
    if (hour >= 12 && hour < 20) greeting = 'Buenas tardes';
    if (hour >= 20 || hour < 6) greeting = 'Buenas noches';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: AppTextStyles.h3.copyWith(color: AppColors.textSecondaryDark),
        ),
        const SizedBox(height: 4),
        Text(
          'Balance & Bienestar',
          style: AppTextStyles.h1.copyWith(color: AppColors.textPrimaryDark),
        ),
        const SizedBox(height: 12),
        Text(
          provider.getMotivationalMessage(),
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildAffirmationCard(WellnessProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withOpacity(0.15),
            const Color(0xFF764BA2).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text('💭', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 16),
          Text(
            provider.todayAffirmation,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTracker(WellnessProvider provider) {
    final currentMood = provider.currentMood;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo te sentís?',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: MoodState.values.map((mood) {
              final isSelected = currentMood == mood;
              return InkWell(
                onTap: () => provider.updateMood(mood),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(mood.color).withOpacity(0.2)
                        : AppColors.surfaceVariantDark,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Color(mood.color)
                          : AppColors.borderDark,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          if (currentMood != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                currentMood.label,
                style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactZeroCard(WellnessProvider provider) {
    final contactZero = provider.contactZero!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.info.withOpacity(0.15),
            AppColors.info.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.block, color: AppColors.info, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contacto 0',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      'Estabilidad emocional',
                      style: TextStyle(
                        color: AppColors.textTertiaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${contactZero.daysOfContactZero}',
                      style: const TextStyle(
                        color: AppColors.info,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'días',
                      style: TextStyle(color: AppColors.info, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () => _showTemptationDialog(provider),
            icon: const Icon(Icons.warning_amber, size: 18),
            label: const Text('Estoy tentado'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseHabits(WellnessProvider provider) {
    final checkIn = provider.todayCheckIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hábitos Base',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimaryDark),
        ),
        const SizedBox(height: 4),
        Text(
          'Lo importante, sin presión',
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        ),
        const SizedBox(height: 16),

        // Sueño
        _buildBaseHabitCard(
          title: 'Sueño',
          icon: Icons.nightlight,
          color: const Color(0xFF7C4DFF),
          isCompleted: checkIn?.sleepQuality != null,
          onTap: () => _showSleepDialog(provider),
          subtitle: checkIn?.sleepQuality?.label,
        ),

        const SizedBox(height: 12),

        // Gym
        _buildBaseHabitCard(
          title: 'Gym',
          icon: Icons.fitness_center,
          color: const Color(0xFFE53935),
          isCompleted: checkIn?.wentToGym == true,
          onTap: () => provider.updateGymStatus(true),
          subtitle: checkIn?.wentToGym == true ? 'Completado' : null,
        ),

        const SizedBox(height: 12),

        // Celular
        _buildBaseHabitCard(
          title: 'Uso del celular',
          icon: Icons.phone_android,
          color: const Color(0xFFFF6F00),
          isCompleted: checkIn?.phoneUsage != null,
          onTap: () => _showPhoneDialog(provider),
          subtitle: checkIn?.phoneUsage != null
              ? '${checkIn!.phoneUsage!.emoji} ${checkIn.phoneUsage!.label}'
              : null,
        ),

        const SizedBox(height: 12),

        // Comida
        _buildBaseHabitCard(
          title: 'Comida',
          icon: Icons.restaurant,
          color: const Color(0xFF00897B),
          isCompleted:
              checkIn?.lunchType != null || checkIn?.dinnerType != null,
          onTap: () => _showMealDialog(provider),
          subtitle: _getMealSubtitle(checkIn),
        ),

        const SizedBox(height: 12),

        // Estudio
        _buildBaseHabitCard(
          title: 'Inglés / Estudio',
          icon: Icons.school,
          color: const Color(0xFF1E88E5),
          isCompleted: checkIn?.studiedEnglish == true,
          onTap: () => provider.updateStudyStatus(true),
          subtitle: checkIn?.studiedEnglish == true ? 'Completado' : null,
        ),
      ],
    );
  }

  String? _getMealSubtitle(DailyCheckIn? checkIn) {
    if (checkIn == null) return null;

    final lunch = checkIn.lunchType;
    final dinner = checkIn.dinnerType;

    if (lunch == null && dinner == null) return null;

    List<String> parts = [];
    if (lunch != null) parts.add('Almuerzo: ${lunch.label}');
    if (dinner != null) parts.add('Cena: ${dinner.label}');

    return parts.join(' • ');
  }

  Widget _buildBaseHabitCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isCompleted,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return InkWell(
      onTap: isCompleted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? color.withOpacity(0.1)
              : AppColors.surfaceVariantDark.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? color.withOpacity(0.3) : AppColors.borderDark,
          ),
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
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: isCompleted ? color : AppColors.textTertiaryDark,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyMissions(WellnessProvider provider) {
    final missions = provider.todayMissions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Misiones de Hoy',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimaryDark),
        ),
        const SizedBox(height: 4),
        Text(
          'Para ser tu mejor versión',
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        ),
        const SizedBox(height: 16),

        ...missions.map((mission) {
          final color = _getMissionColor(mission.category);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: mission.isCompleted
                  ? null
                  : () => provider.completeMission(mission.id),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: mission.isCompleted
                      ? color.withOpacity(0.1)
                      : AppColors.surfaceVariantDark.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: mission.isCompleted
                        ? color.withOpacity(0.3)
                        : AppColors.borderDark,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      mission.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: mission.isCompleted
                          ? color
                          : AppColors.textTertiaryDark,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission.title,
                            style: TextStyle(
                              color: AppColors.textPrimaryDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mission.description,
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
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getMissionColor(String category) {
    switch (category) {
      case 'future':
        return AppColors.primary;
      case 'energy':
        return AppColors.accentGreen;
      case 'respect':
        return AppColors.accent;
      default:
        return AppColors.secondary;
    }
  }

  Widget _buildCalmCenterAccess() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF43E97B).withOpacity(0.15),
            const Color(0xFF38F9D7).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF43E97B).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.spa, color: Color(0xFF43E97B), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Centro de Calma',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCalmButton('Reset 60s', Icons.air, () {
                  // TODO: Navegar a ejercicio respiración
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCalmButton('Descargar', Icons.edit_note, () {
                  // TODO: Abrir journaling
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalmButton(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF43E97B),
        side: BorderSide(color: const Color(0xFF43E97B).withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  // ========== DIALOGS ==========

  Future<void> _showSleepDialog(WellnessProvider provider) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          '¿Cómo dormiste?',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SleepQuality.values.map((quality) {
            return ListTile(
              title: Text(
                quality.label,
                style: const TextStyle(color: AppColors.textPrimaryDark),
              ),
              onTap: () {
                provider.updateSleepQuality(quality);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showPhoneDialog(WellnessProvider provider) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Uso del celular hoy',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PhoneUsage.values.map((usage) {
            return ListTile(
              leading: Text(usage.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(
                usage.label,
                style: const TextStyle(color: AppColors.textPrimaryDark),
              ),
              onTap: () {
                provider.updatePhoneUsage(usage);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showMealDialog(WellnessProvider provider) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          '¿Qué comiste?',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'Almuerzo - Cociné',
                style: TextStyle(color: AppColors.textPrimaryDark),
              ),
              onTap: () {
                provider.updateMealType(MealType.cooked, isLunch: true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(
                'Almuerzo - Pedí',
                style: TextStyle(color: AppColors.textPrimaryDark),
              ),
              onTap: () {
                provider.updateMealType(MealType.ordered, isLunch: true);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Cena - Cociné',
                style: TextStyle(color: AppColors.textPrimaryDark),
              ),
              onTap: () {
                provider.updateMealType(MealType.cooked, isLunch: false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(
                'Cena - Pedí',
                style: TextStyle(color: AppColors.textPrimaryDark),
              ),
              onTap: () {
                provider.updateMealType(MealType.ordered, isLunch: false);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTemptationDialog(WellnessProvider provider) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Estás tentado',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Es normal. Elegí cómo querés manejarlo:',
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.recordTemptation(
                  'Dejé pasar la tentación',
                  letItPass: true,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bien hecho. Seguí así 💪'),
                    backgroundColor: AppColors.accentGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Lo voy a dejar pasar'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Abrir ejercicio de respiración
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Necesito sacarlo de la cabeza'),
            ),
          ],
        ),
      ),
    );
  }
}
