import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class HabitsStats extends StatelessWidget {
  final double weeklyConsistency;
  final int totalStreak;
  final int totalHabits;

  const HabitsStats({
    super.key,
    required this.weeklyConsistency,
    required this.totalStreak,
    required this.totalHabits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            'Consistencia',
            '${(weeklyConsistency * 100).toInt()}%',
            Icons.trending_up,
            AppColors.accent,
          ),
          _buildStat(
            'Streak Total',
            '$totalStreak',
            Icons.local_fire_department,
            AppColors.warning,
          ),
          _buildStat(
            'Hábitos',
            '$totalHabits',
            Icons.track_changes,
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimaryDark),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
        ),
      ],
    );
  }
}
