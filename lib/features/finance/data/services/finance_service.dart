// lib/features/finance/data/services/finance_service.dart
import 'package:ascend/features/finance/data/transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Transactions
  Future<List<FinanceTransaction>> getUserTransactions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FinanceTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar transacciones: $e');
    }
  }

  Future<void> addTransaction(FinanceTransaction transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .add(transaction.ToFirestore());
    } catch (e) {
      throw Exception('Error al agregar transacción: $e');
    }
  }

  Future<void> updateTransaction(FinanceTransaction transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.ToFirestore());
    } catch (e) {
      throw Exception('Error al actualizar transacción: $e');
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
    } catch (e) {
      throw Exception('Error al eliminar transacción: $e');
    }
  }

  // Savings Goals
  Future<List<SavingsGoal>> getUserSavingsGoals(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('savings_goals')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => SavingsGoal.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      throw Exception('Error al cargar metas: $e');
    }
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    try {
      await _firestore.collection('savings_goals').add(goal.ToFirestore());
    } catch (e) {
      throw Exception('Error al agregar meta: $e');
    }
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    try {
      await _firestore
          .collection('savings_goals')
          .doc(goal.id)
          .update(goal.ToFirestore());
    } catch (e) {
      throw Exception('Error al actualizar meta: $e');
    }
  }

  // Analytics
  Future<Map<String, dynamic>> getMonthlySummary(
    String userId,
    DateTime date,
  ) async {
    try {
      final firstDay = DateTime(date.year, date.month, 1);
      final lastDay = DateTime(date.year, date.month + 1, 0);

      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
          .get();

      double totalIncome = 0;
      double totalExpenses = 0;

      for (final doc in querySnapshot.docs) {
        final transaction = FinanceTransaction.fromFirestore(doc);
        if (transaction.isIncome) {
          totalIncome += transaction.amount;
        } else {
          totalExpenses += transaction.amount;
        }
      }

      return {
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'balance': totalIncome - totalExpenses,
        'transactionCount': querySnapshot.size,
      };
    } catch (e) {
      throw Exception('Error al obtener resumen: $e');
    }
  }

  // Get transactions by category
  Future<List<FinanceTransaction>> getTransactionsByCategory(
    String userId,
    TransactionCategory category,
    DateTime month,
  ) async {
    try {
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category.name)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FinanceTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar transacciones por categoría: $e');
    }
  }
}
