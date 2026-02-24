// lib/features/finance/data/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TransactionType { income, expense }

enum TransactionCategory {
  // INGRESOS
  salary('Salario', Icons.work, 0xFF4CAF50, TransactionType.income),
  freelance('Freelance', Icons.laptop_mac, 0xFF8BC34A, TransactionType.income),
  investment(
    'Inversiones',
    Icons.trending_up,
    0xFF009688,
    TransactionType.income,
  ),
  gift('Regalo', Icons.card_giftcard, 0xFF00BCD4, TransactionType.income),
  otherIncome(
    'Otro Ingreso',
    Icons.attach_money,
    0xFF03A9F4,
    TransactionType.income,
  ),

  // GASTOS
  food('Comida', Icons.restaurant, 0xFFFF5722, TransactionType.expense),
  transport(
    'Transporte',
    Icons.directions_car,
    0xFFFF9800,
    TransactionType.expense,
  ),
  housing('Vivienda', Icons.home, 0xFFF44336, TransactionType.expense),
  utilities('Servicios', Icons.lightbulb, 0xFFE91E63, TransactionType.expense),
  entertainment(
    'Entretenimiento',
    Icons.movie,
    0xFF9C27B0,
    TransactionType.expense,
  ),
  shopping('Compras', Icons.shopping_bag, 0xFF673AB7, TransactionType.expense),
  health('Salud', Icons.local_hospital, 0xFF3F51B5, TransactionType.expense),
  education('Educación', Icons.school, 0xFF2196F3, TransactionType.expense),
  subscriptions(
    'Suscripciones',
    Icons.subscriptions,
    0xFF00BCD4,
    TransactionType.expense,
  ),
  otherExpense(
    'Otro Gasto',
    Icons.receipt,
    0xFF607D8B,
    TransactionType.expense,
  );

  final String displayName;
  final IconData icon;
  final int color;
  final TransactionType type;

  const TransactionCategory(this.displayName, this.icon, this.color, this.type);

  static List<TransactionCategory> getIncomeCategories() {
    return values.where((c) => c.type == TransactionType.income).toList();
  }

  static List<TransactionCategory> getExpenseCategories() {
    return values.where((c) => c.type == TransactionType.expense).toList();
  }
}

enum PaymentMethod {
  cash('Efectivo', Icons.money),
  debitCard('Débito', Icons.credit_card),
  creditCard('Crédito', Icons.credit_card),
  transfer('Transferencia', Icons.account_balance),
  digitalWallet('Billetera Digital', Icons.account_balance_wallet);

  final String displayName;
  final IconData icon;

  const PaymentMethod(this.displayName, this.icon);
}

class FinanceTransaction {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final TransactionCategory category;
  final PaymentMethod paymentMethod;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final bool isRecurring;
  final String? recurringId;
  final List<String> tags;

  FinanceTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    this.description,
    required this.date,
    required this.createdAt,
    this.isRecurring = false,
    this.recurringId,
    this.tags = const [],
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  String get displayAmount {
    final sign = isIncome ? '+' : '-';
    return '$sign\$${amount.toStringAsFixed(2)}';
  }

  Color get amountColor {
    return isIncome ? const Color(0xFF4CAF50) : const Color(0xFFFF5722);
  }

  Map<String, dynamic> ToFirestore() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'category': category.name,
      'paymentMethod': paymentMethod.name,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'isRecurring': isRecurring,
      'recurringId': recurringId,
      'tags': tags,
    };
  }

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) {
    return FinanceTransaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (map['amount'] ?? 0).toDouble(),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.otherExpense,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      description: map['description'],
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRecurring: map['isRecurring'] ?? false,
      recurringId: map['recurringId'],
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  factory FinanceTransaction.fromFirestore(DocumentSnapshot doc) {
    return FinanceTransaction.fromMap({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    });
  }

  FinanceTransaction copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    TransactionCategory? category,
    PaymentMethod? paymentMethod,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    bool? isRecurring,
    String? recurringId,
    List<String>? tags,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      tags: tags ?? this.tags,
    );
  }
}

class SavingsGoal {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime? targetDate;
  final String icon;
  final int color;
  final bool isActive;
  final DateTime createdAt;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.startDate,
    this.targetDate,
    this.icon = '🎯',
    this.color = 0xFF2196F3,
    this.isActive = true,
    required this.createdAt,
  });

  double get progress => targetAmount > 0 ? currentAmount / targetAmount : 0;
  double get remaining => targetAmount - currentAmount;
  bool get isCompleted => currentAmount >= targetAmount;

  int? get daysRemaining {
    if (targetDate == null) return null;
    final now = DateTime.now();
    if (targetDate!.isBefore(now)) return 0;
    return targetDate!.difference(now).inDays;
  }

  double? get dailySavingsNeeded {
    if (targetDate == null || daysRemaining == null || daysRemaining! <= 0) {
      return null;
    }
    return remaining / daysRemaining!;
  }

  Map<String, dynamic> ToFirestore() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': Timestamp.fromDate(startDate),
      'targetDate': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
      'icon': icon,
      'color': color,
      'isActive': isActive,
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0).toDouble(),
      startDate: (map['startDate'] as Timestamp).toDate(),
      targetDate: map['targetDate'] != null
          ? (map['targetDate'] as Timestamp).toDate()
          : null,
      icon: map['icon'] ?? '🎯',
      color: map['color'] ?? 0xFF2196F3,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
  factory SavingsGoal.fromFirestore(DocumentSnapshot doc) {
    return SavingsGoal.fromMap({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    });
  }
  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? targetDate,
    String? icon,
    int? color,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt, //
    );
  }
}

class FinanceStats {
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final Map<String, double> expensesByCategory;
  final double averageDailyExpense;
  final double projectedMonthlyExpense;
  final double savingsRate;

  FinanceStats({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.expensesByCategory,
    required this.averageDailyExpense,
    required this.projectedMonthlyExpense,
    required this.savingsRate,
  });

  factory FinanceStats.calculate(List<FinanceTransaction> transactions) {
    double totalIncome = 0;
    double totalExpenses = 0;
    final expensesByCategory = <String, double>{};
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysPassed = now.difference(firstDayOfMonth).inDays + 1;

    for (final transaction in transactions) {
      if (transaction.isIncome) {
        totalIncome += transaction.amount;
      } else {
        totalExpenses += transaction.amount;

        // CAMBIO CLAVE AQUÍ: Usar 0.0 en lugar de 0
        expensesByCategory[transaction.category.displayName] =
            (expensesByCategory[transaction.category.displayName] ??
                0.0) + // <-- CORRECCIÓN
            transaction.amount;
      }
    }

    final balance = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0
        ? (balance / totalIncome) * 100
        : 0.0; // También 0.0 por seguridad
    final averageDailyExpense = daysPassed > 0
        ? totalExpenses / daysPassed
        : 0.0; // También 0.0
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final projectedMonthlyExpense = averageDailyExpense * daysInMonth;

    return FinanceStats(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      balance: balance,
      // El mapa 'expensesByCategory' ahora contiene solo doubles
      expensesByCategory: expensesByCategory,
      averageDailyExpense: averageDailyExpense,
      projectedMonthlyExpense: projectedMonthlyExpense,
      savingsRate: savingsRate,
    );
  }
}
