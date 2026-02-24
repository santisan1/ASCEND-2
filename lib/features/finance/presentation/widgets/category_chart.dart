import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CategoryChart extends StatelessWidget {
  final Map<String, double> expensesByCategory;

  const CategoryChart({super.key, required this.expensesByCategory});

  @override
  Widget build(BuildContext context) {
    if (expensesByCategory.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'Sin datos para mostrar',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiaryDark,
          ),
        ),
      );
    }

    // Calcular total
    final total = expensesByCategory.values.fold(
      0.0,
      (sum, value) => sum + value,
    );

    // Ordenar por monto
    final sortedEntries = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Tomar top 5
    final topEntries = sortedEntries.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra de progreso por categoría
        ...topEntries.map((entry) {
          final percentage = (entry.value / total * 100);
          final color = _getCategoryColor(entry.key);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$${entry.value.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiaryDark,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      AppColors.error,
      AppColors.warning,
      AppColors.secondary,
      AppColors.accent,
      AppColors.primary,
    ];

    final hash = category.hashCode.abs();
    return colors[hash % colors.length];
  }
}
