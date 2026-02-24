import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/transaction_model.dart';

class AddSavingsGoalDialog extends StatefulWidget {
  final SavingsGoal? goalToEdit;

  const AddSavingsGoalDialog({super.key, this.goalToEdit});

  @override
  State<AddSavingsGoalDialog> createState() => _AddSavingsGoalDialogState();
}

class _AddSavingsGoalDialogState extends State<AddSavingsGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();

  DateTime? _selectedTargetDate;
  String _selectedIcon = '🎯';
  int _selectedColor = 0xFF2196F3; // Color azul por defecto
  bool _isLoading = false;

  // Opciones de iconos y colores
  final List<String> _availableIcons = [
    '🎯',
    '💰',
    '🏠',
    '🚗',
    '✈️',
    '🎓',
    '💍',
    '🛒',
    '🏖️',
    '🎁',
    '💻',
    '📱',
    '🎨',
    '🎸',
    '🏋️',
    '📚',
    '🛏️',
    '🍽️',
    '🎮',
    '🎥',
  ];

  final List<Map<String, dynamic>> _availableColors = [
    {'name': 'Azul', 'value': 0xFF2196F3},
    {'name': 'Verde', 'value': 0xFF4CAF50},
    {'name': 'Rojo', 'value': 0xFFF44336},
    {'name': 'Naranja', 'value': 0xFFFF9800},
    {'name': 'Morado', 'value': 0xFF9C27B0},
    {'name': 'Rosa', 'value': 0xFFE91E63},
    {'name': 'Cian', 'value': 0xFF00BCD4},
    {'name': 'Amarillo', 'value': 0xFFFFEB3B},
  ];

  @override
  void initState() {
    super.initState();

    if (widget.goalToEdit != null) {
      final goal = widget.goalToEdit!;
      _nameController.text = goal.name;
      _descriptionController.text = goal.description ?? '';
      _targetAmountController.text = goal.targetAmount.toStringAsFixed(2);
      _selectedTargetDate = goal.targetDate;
      _selectedIcon = goal.icon;
      _selectedColor = goal.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
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
                        color: Color(_selectedColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedIcon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.goalToEdit != null
                                ? 'Editar Meta de Ahorro'
                                : 'Nueva Meta de Ahorro',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          Text(
                            'Definí tu objetivo financiero',
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

                // Nombre
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la meta',
                    prefixIcon: Icon(Icons.flag),
                    hintText: 'Ej: Viaje a la playa',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresá un nombre';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.notes),
                    hintText: 'Agregá detalles sobre tu objetivo...',
                  ),
                ),

                const SizedBox(height: 20),

                // Monto objetivo
                TextFormField(
                  controller: _targetAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Monto objetivo',
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: 'Ej: 5000.00',
                  ),
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

                const SizedBox(height: 20),

                // Fecha objetivo
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha objetivo (opcional)',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedTargetDate != null
                          ? DateFormat(
                              'dd/MM/yyyy',
                            ).format(_selectedTargetDate!)
                          : 'Sin fecha específica',
                      style: const TextStyle(color: AppColors.textPrimaryDark),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Icono
                Text(
                  'Icono',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableIcons.length,
                    itemBuilder: (context, index) {
                      final icon = _availableIcons[index];
                      final isSelected = _selectedIcon == icon;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedIcon = icon;
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(_selectedColor).withOpacity(0.2)
                                  : AppColors.surfaceVariantDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Color(_selectedColor)
                                    : AppColors.borderDark,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Color
                Text(
                  'Color',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableColors.map((colorData) {
                    final colorValue = colorData['value'] as int;
                    final isSelected = _selectedColor == colorValue;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = colorValue;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Color(colorValue).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Color(colorValue)
                                : AppColors.borderDark,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Color(colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              colorData['name'],
                              style: TextStyle(
                                color: isSelected
                                    ? Color(colorValue)
                                    : AppColors.textSecondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
                        onPressed: _isLoading ? null : _saveGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(_selectedColor),
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
                                widget.goalToEdit != null
                                    ? 'Actualizar'
                                    : 'Crear Meta',
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

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedTargetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365 * 5),
      ), // 5 años máximo
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(_selectedColor),
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedTargetDate = date;
      });
    }
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    // Crear el objeto SavingsGoal
    final goal = SavingsGoal(
      id:
          widget.goalToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // Esto debería venir del usuario autenticado
      name: _nameController.text,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      targetAmount: double.parse(_targetAmountController.text),
      currentAmount: widget.goalToEdit?.currentAmount ?? 0.0,
      startDate: widget.goalToEdit?.startDate ?? DateTime.now(),
      targetDate: _selectedTargetDate,
      icon: _selectedIcon,
      color: _selectedColor,
      isActive: true,
      createdAt: widget.goalToEdit?.createdAt ?? DateTime.now(),
    );

    // Devolver el goal a través de Navigator.pop
    Navigator.pop(context, goal);
  }
}
