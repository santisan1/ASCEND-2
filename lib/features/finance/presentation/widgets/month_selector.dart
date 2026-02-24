import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/transaction_model.dart';
import '../../domain/finance_provider.dart' hide DateFormat;

class AddTransactionDialog extends StatefulWidget {
  final TransactionType initialType;
  final FinanceTransaction? transactionToEdit;

  const AddTransactionDialog({
    super.key,
    required this.initialType,
    this.transactionToEdit,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late TransactionType _type;
  TransactionCategory? _selectedCategory;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;

    if (widget.transactionToEdit != null) {
      final transaction = widget.transactionToEdit!;
      _amountController.text = transaction.amount.toString();
      _descriptionController.text = transaction.description ?? '';
      _type = transaction.type;
      _selectedCategory = transaction.category;
      _selectedPaymentMethod = transaction.paymentMethod;
      _selectedDate = transaction.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<TransactionCategory> get _categories {
    return _type == TransactionType.income
        ? TransactionCategory.getIncomeCategories()
        : TransactionCategory.getExpenseCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            (_type == TransactionType.income
                                    ? AppColors.accentGreen
                                    : AppColors.error)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _type == TransactionType.income
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: _type == TransactionType.income
                            ? AppColors.accentGreen
                            : AppColors.error,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.transactionToEdit != null
                                ? 'Editar Transacción'
                                : (_type == TransactionType.income
                                      ? 'Nuevo Ingreso'
                                      : 'Nuevo Gasto'),
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          Text(
                            'Registrá tu movimiento',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Toggle Ingreso/Gasto
                if (widget.transactionToEdit == null)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTypeToggle(
                            'Ingreso',
                            TransactionType.income,
                            Icons.arrow_downward,
                            AppColors.accentGreen,
                          ),
                        ),
                        Expanded(
                          child: _buildTypeToggle(
                            'Gasto',
                            TransactionType.expense,
                            Icons.arrow_upward,
                            AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Monto
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 32,
                    ),
                    hintText: '0.00',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresá un monto';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Monto inválido';
                    }
                    return null;
                  },
                ),

                const Divider(color: AppColors.borderDark),
                const SizedBox(height: 20),

                // Categoría
                Text(
                  'Categoría',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(category.color).withOpacity(0.2)
                              : AppColors.surfaceVariantDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Color(category.color)
                                : AppColors.borderDark,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category.icon,
                              size: 18,
                              color: isSelected
                                  ? Color(category.color)
                                  : AppColors.textSecondaryDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              category.displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? Color(category.color)
                                    : AppColors.textSecondaryDark,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Método de pago
                DropdownButtonFormField<PaymentMethod>(
                  value: _selectedPaymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Método de pago',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  dropdownColor: AppColors.surfaceDark,
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Row(
                        children: [
                          Icon(method.icon, size: 18),
                          const SizedBox(width: 8),
                          Text(method.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPaymentMethod = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),

                // Fecha
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(color: AppColors.textPrimaryDark),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.notes),
                    hintText: 'Agregá detalles...',
                  ),
                ),

                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _type == TransactionType.income
                              ? AppColors.accentGreen
                              : AppColors.error,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.transactionToEdit != null
                                    ? 'Actualizar'
                                    : 'Guardar',
                              ),
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

  Widget _buildTypeToggle(
    String label,
    TransactionType type,
    IconData icon,
    Color color,
  ) {
    final isSelected = _type == type;
    return InkWell(
      onTap: () {
        setState(() {
          _type = type;
          _selectedCategory = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondaryDark,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondaryDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _type == TransactionType.income
                  ? AppColors.accentGreen
                  : AppColors.error,
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccioná una categoría'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.trim();

      final transaction = FinanceTransaction(
        id: widget.transactionToEdit?.id ?? '',
        userId: '',
        type: _type,
        amount: amount,
        category: _selectedCategory!,
        paymentMethod: _selectedPaymentMethod,
        description: description.isEmpty ? null : description,
        date: _selectedDate,
        createdAt: widget.transactionToEdit?.createdAt ?? DateTime.now(),
      );

      final provider = context.read<FinanceProvider>();

      if (widget.transactionToEdit != null) {
        await provider.updateTransaction(transaction);
      } else {
        await provider.addTransaction(transaction);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.transactionToEdit != null
                  ? '✓ Transacción actualizada'
                  : '✓ Transacción registrada',
            ),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
