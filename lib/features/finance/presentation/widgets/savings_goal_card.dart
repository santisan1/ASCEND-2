import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/transaction_model.dart';

class SavingsGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback? onTap;
  final VoidCallback? onAddAmount;

  const SavingsGoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onAddAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(goal.color).withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(goal.color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        goal.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const Spacer(),
                    if (goal.isCompleted)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.accentGreen,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  goal.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '\$${goal.currentAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.h4.copyWith(
                        color: Color(goal.color),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / \$${goal.targetAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: goal.progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.surfaceVariantDark,
                  color: Color(goal.color),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(goal.progress * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    if (goal.daysRemaining != null && !goal.isCompleted)
                      Text(
                        '${goal.daysRemaining} días',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiaryDark,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
