import 'package:ascend/core/theme/app_colors.dart';
import 'package:ascend/core/theme/app_text_styles.dart';
import 'package:ascend/core/widgets/ascend_card.dart';
import 'package:ascend/features/finance/data/transaction_model.dart';
import 'package:ascend/features/finance/domain/finance_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as i;
import 'package:provider/provider.dart';
import 'package:ascend/features/finance/presentation/widgets/month_selector.dart';
import 'package:ascend/features/finance/presentation/widgets/category_chart.dart';
import 'package:ascend/features/finance/presentation/widgets/savings_goal_card.dart';
import 'package:ascend/features/finance/presentation/widgets/transaction_tile.dart';
import 'package:ascend/features/finance/presentation/widgets/add_transaction_dialog.dart';
import 'package:ascend/features/finance/presentation/widgets/add_savings_goal_dialog.dart';

class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({super.key});

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final stats = financeProvider.stats;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(financeProvider),

            // Content
            Expanded(
              child: financeProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selector de mes
                            MonthSelector(
                              selectedMonth: financeProvider.selectedMonth,
                              onMonthChanged: (month) {
                                financeProvider.setSelectedMonth(month);
                              },
                            ),

                            const SizedBox(height: 16),

                            // Balance principal
                            _buildBalanceCard(stats, financeProvider),

                            const SizedBox(height: 8),

                            // Stats rápidas (Ingresos, Gastos, Ahorro)
                            _buildQuickStats(stats),

                            const SizedBox(height: 8),

                            // Salud financiera
                            _buildFinancialHealth(financeProvider),

                            const SizedBox(height: 8),

                            _buildPaymentMethodBreakdown(financeProvider),

                            const SizedBox(height: 8),

                            _buildInvestmentSnapshot(financeProvider),

                            const SizedBox(height: 8),

                            // Gráfico de gastos por categoría
                            if (stats != null &&
                                stats.expensesByCategory.isNotEmpty)
                              _buildExpensesChart(stats),

                            // Metas de ahorro
                            if (financeProvider.savingsGoals.isNotEmpty)
                              _buildSavingsGoals(financeProvider),

                            // Transacciones recientes
                            _buildRecentTransactions(financeProvider),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),

      // FAB para agregar transacción
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildHeader(FinanceProvider provider) {
    return Container(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Finanzas',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                '💰 Gestión inteligente',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // TODO: Navegar a configuración/filtros
            },
            icon: const Icon(Icons.tune, color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(FinanceStats? stats, FinanceProvider provider) {
    final balance = stats?.balance ?? 0.0;
    final isPositive = balance >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositive
              ? [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.secondary.withOpacity(0.6),
                ]
              : [
                  AppColors.error.withOpacity(0.8),
                  AppColors.error.withOpacity(0.6),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppColors.primary : AppColors.error)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.account_balance_wallet
                    : Icons.warning_amber_rounded,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Balance del mes',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${balance.abs().toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              if (!isPositive)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'en negativo',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceItem(
                'Proyección',
                provider.getProjectedSavings(),
                Icons.trending_up,
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildBalanceItem(
                'Tasa ahorro',
                (stats?.savingsRate ?? 0) * 100,
                Icons.savings,
                isPercentage: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
    String label,
    double value,
    IconData icon, {
    bool isPercentage = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            Text(
              isPercentage
                  ? '${value.toStringAsFixed(1)}%'
                  : '\$${value.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(FinanceStats? stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Ingresos',
              stats?.totalIncome ?? 0,
              Icons.arrow_downward,
              AppColors.accentGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Gastos',
              stats?.totalExpenses ?? 0,
              Icons.arrow_upward,
              AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialHealth(FinanceProvider provider) {
    final status = provider.getFinancialHealthStatus();
    final message = provider.getFinancialHealthMessage();

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'excellent':
        statusColor = AppColors.accentGreen;
        statusIcon = Icons.trending_up;
        break;
      case 'good':
        statusColor = AppColors.accentGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'fair':
        statusColor = AppColors.warning;
        statusIcon = Icons.info;
        break;
      case 'warning':
        statusColor = AppColors.warning;
        statusIcon = Icons.warning_amber;
        break;
      case 'critical':
        statusColor = AppColors.error;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = AppColors.textSecondaryDark;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salud Financiera',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodBreakdown(FinanceProvider provider) {
    final byMethod = provider.getExpenseByPaymentMethod();

    if (byMethod.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = byMethod.values.fold(0.0, (sum, value) => sum + value);

    return AscendCardWithTitle(
      title: 'Métodos de pago (gastos)',
      icon: Icons.credit_card,
      iconColor: AppColors.info,
      content: Column(
        children: byMethod.entries.map((entry) {
          final ratio = total == 0 ? 0.0 : (entry.value / total).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(entry.key.icon, size: 16, color: AppColors.textSecondaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.key.displayName,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: ratio,
                      backgroundColor: AppColors.surfaceVariantDark,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${entry.value.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimaryDark),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInvestmentSnapshot(FinanceProvider provider) {
    final invested = provider.getTotalInvestedThisMonth();
    final ratio = provider.getInvestmentAllocationRatio();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                'Inversiones del mes',
                style: AppTextStyles.h4.copyWith(color: AppColors.textPrimaryDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '\$${invested.toStringAsFixed(2)}',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Asignación sobre ingresos: ${(ratio * 100).toStringAsFixed(1)}%',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesChart(FinanceStats stats) {
    return AscendCardWithTitle(
      title: 'Gastos por Categoría',
      icon: Icons.pie_chart,
      iconColor: AppColors.secondary,
      content: CategoryChart(expensesByCategory: stats.expensesByCategory),
    );
  }

  Widget _buildSavingsGoals(FinanceProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Metas de Ahorro',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddSavingsGoalDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: provider.savingsGoals.length,
            itemBuilder: (context, index) {
              final goal = provider.savingsGoals[index];
              return SavingsGoalCard(
                goal: goal,
                onTap: () => _showGoalDetails(goal),
                onAddAmount: () => _showAddToGoalDialog(goal),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(FinanceProvider provider) {
    final transactions = provider.monthTransactions.take(10).toList();

    if (transactions.isEmpty) {
      return _buildEmptyTransactions();
    }

    return AscendCardWithTitle(
      title: 'Transacciones Recientes',
      icon: Icons.history,
      iconColor: AppColors.accent,
      trailing: TextButton(
        onPressed: () {
          // TODO: Navegar a historial completo
        },
        child: const Text('Ver todo'),
      ),
      content: Column(
        children: [
          ...transactions.map((transaction) {
            return TransactionTile(
              transaction: transaction,
              onTap: () => _showTransactionDetails(transaction),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          const Text('📊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Sin transacciones aún',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Comenzá a registrar tus ingresos y gastos',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddTransactionDialog(TransactionType.expense),
            icon: const Icon(Icons.add),
            label: const Text('Primera transacción'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Botón de Ingreso
        FloatingActionButton.extended(
          onPressed: () => _showAddTransactionDialog(TransactionType.income),
          backgroundColor: AppColors.accentGreen,
          icon: const Icon(Icons.arrow_downward, size: 20),
          label: const Text('Ingreso'),
          heroTag: 'income',
        ),
        const SizedBox(height: 12),
        // Botón de Gasto
        FloatingActionButton.extended(
          onPressed: () => _showAddTransactionDialog(TransactionType.expense),
          backgroundColor: AppColors.error,
          icon: const Icon(Icons.arrow_upward, size: 20),
          label: const Text('Gasto'),
          heroTag: 'expense',
        ),
      ],
    );
  }

  // ============ DIALOGS ============

  void _showAddTransactionDialog(TransactionType type) {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(initialType: type),
    );
  }

  void _showAddSavingsGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddSavingsGoalDialog(),
    );
  }

  void _showTransactionDetails(FinanceTransaction transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(transaction.category.color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      transaction.category.icon,
                      color: Color(transaction.category.color),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.category.displayName,
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        Text(
                          i.DateFormat(
                            // USAR EL ALIAS 'i'
                            'dd/MM/yyyy HH:mm',
                          ).format(transaction.date),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    transaction.displayAmount,
                    style: AppTextStyles.h3.copyWith(
                      color: transaction.amountColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (transaction.description != null &&
                  transaction.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Descripción',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    transaction.paymentMethod.icon,
                    size: 16,
                    color: AppColors.textSecondaryDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    transaction.paymentMethod.displayName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Editar transacción
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDeleteTransaction(transaction),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Eliminar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGoalDetails(SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
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
              Text(
                goal.name,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              if (goal.description != null && goal.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  goal.description!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGoalStat(
                    'Actual',
                    '\$${goal.currentAmount.toStringAsFixed(0)}',
                  ),
                  _buildGoalStat(
                    'Meta',
                    '\$${goal.targetAmount.toStringAsFixed(0)}',
                  ),
                  _buildGoalStat(
                    'Falta',
                    '\$${goal.remaining.toStringAsFixed(0)}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddToGoalDialog(goal);
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar dinero'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  void _showAddToGoalDialog(SavingsGoal goal) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'Agregar a ${goal.name}',
          style: const TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimaryDark),
          decoration: const InputDecoration(
            labelText: 'Monto',
            prefixText: '\$ ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                try {
                  await context.read<FinanceProvider>().addToSavingsGoal(
                    goal.id,
                    amount,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Monto agregado'),
                        backgroundColor: AppColors.accentGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteTransaction(FinanceTransaction transaction) async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          '¿Eliminar transacción?',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<FinanceProvider>().deleteTransaction(transaction.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacción eliminada'),
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
