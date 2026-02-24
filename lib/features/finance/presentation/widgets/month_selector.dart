import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => onMonthChanged(
              DateTime(selectedMonth.year, selectedMonth.month - 1, 1),
            ),
            icon: const Icon(
              Icons.chevron_left,
              color: AppColors.textSecondaryDark,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                _label(selectedMonth),
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => onMonthChanged(
              DateTime(selectedMonth.year, selectedMonth.month + 1, 1),
            ),
            icon: const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  String _label(DateTime date) {
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

    return '${months[date.month - 1]} ${date.year}';
  }
}
