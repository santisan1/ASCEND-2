import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'habit_model.dart';

class HabitsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Habit> _habits = [];
  List<HabitCompletion> _completions = [];
  HabitStats? _stats;
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _habitsSubscription;
  StreamSubscription? _completionsSubscription;

  List<Habit> get habits => _habits;
  List<HabitCompletion> get completions => _completions;
  HabitStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters útiles
  List<Habit> get activeHabits => _habits.where((h) => h.isActive).toList();
  List<Habit> get habitsDueToday =>
      activeHabits.where((h) => h.isDueToday).toList();
  List<Habit> get completedToday =>
      activeHabits.where((h) => h.isFullyCompletedToday).toList();
  double get todayCompletionRate {
    if (habitsDueToday.isEmpty) return 0.0;
    return completedToday.length / habitsDueToday.length;
  }

  // NUEVO: Hábitos por momento del día
  List<Habit> getHabitsByTimeOfDay() {
    final sorted = List<Habit>.from(activeHabits);
    sorted.sort((a, b) {
      final timeOrder = {
        HabitTrigger.morning: 1,
        HabitTrigger.noon: 2,
        HabitTrigger.afternoon: 3,
        HabitTrigger.evening: 4,
        HabitTrigger.anytime: 5,
      };
      return (timeOrder[a.trigger] ?? 5).compareTo(timeOrder[b.trigger] ?? 5);
    });
    return sorted;
  }

  // NUEVO: Tiempo total estimado del día
  int getTotalEstimatedTimeToday() {
    return habitsDueToday.fold(
      0,
      (sum, habit) => sum + (habit.estimatedDuration * habit.dailyRepetitions),
    );
  }

  // NUEVO: Tiempo completado hoy
  int getCompletedTimeToday() {
    return habitsDueToday.fold(
      0,
      (sum, habit) => sum + (habit.estimatedDuration * habit.completionsToday),
    );
  }

  // Métodos helper para obtener referencias a las colecciones del usuario
  CollectionReference _getUserHabitsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('habits');
  }

  CollectionReference _getUserCompletionsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('habit_completions');
  }

  HabitsProvider() {
    _init();
  }

  Future<void> _init() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _subscribeToUserHabits(user.uid);
    }

    // Escuchar cambios de autenticación
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToUserHabits(user.uid);
      } else {
        _unsubscribe();
        _habits = [];
        _completions = [];
        _stats = null;
        notifyListeners();
      }
    });
  }

  Future<void> _subscribeToUserHabits(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _unsubscribe();

      _habitsSubscription = _getUserHabitsCollection(userId).snapshots().listen(
        (snapshot) {
          _habits = snapshot.docs.map((doc) {
            return Habit.fromFirestore(doc);
          }).toList();

          _calculateStats();
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (error) {
          _error = 'Error al cargar hábitos: $error';
          _isLoading = false;
          notifyListeners();
        },
      );

      _completionsSubscription = _getUserCompletionsCollection(userId)
          .orderBy('completedAt', descending: true)
          .limit(100)
          .snapshots()
          .listen(
            (snapshot) {
              _completions = snapshot.docs.map((doc) {
                return HabitCompletion.fromFirestore(doc);
              }).toList();

              _calculateStats();
              notifyListeners();
            },
            onError: (error) {
              if (kDebugMode) {
                print('Error al cargar completions: $error');
              }
            },
          );
    } catch (e) {
      _error = 'Error al suscribirse: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _unsubscribe() async {
    await _habitsSubscription?.cancel();
    await _completionsSubscription?.cancel();
    _habitsSubscription = null;
    _completionsSubscription = null;
  }

  void _calculateStats() {
    _stats = HabitStats.fromHabits(_habits, _completions);
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  // ========== CRUD OPERATIONS ==========

  Future<void> createHabit(Habit habit) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final habitWithUser = Habit(
        id: _getUserHabitsCollection(user.uid).doc().id,
        userId: user.uid,
        name: habit.name,
        description: habit.description,
        icon: habit.icon,
        category: habit.category,
        difficulty: habit.difficulty,
        impact: habit.impact,
        frequency: habit.frequency,
        reminderTime: habit.reminderTime,
        targetDays: habit.targetDays,
        priority: habit.priority,
        trigger: habit.trigger,
        estimatedDuration: habit.estimatedDuration,
        dailyRepetitions: habit.dailyRepetitions,
        createdAt: DateTime.now(),
        tags: habit.tags,
      );

      await _getUserHabitsCollection(
        user.uid,
      ).doc(habitWithUser.id).set(habitWithUser.toFirestore());

      if (habit.reminderTime != null) {
        await _scheduleReminder(habitWithUser);
      }
    } catch (e) {
      _error = 'Error al crear hábito: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      await _getUserHabitsCollection(
        user.uid,
      ).doc(habit.id).update(habit.toFirestore());

      if (habit.reminderTime != null) {
        await _scheduleReminder(habit);
      }
    } catch (e) {
      _error = 'Error al actualizar hábito: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      await _getUserHabitsCollection(user.uid).doc(habitId).delete();

      final completionsSnapshot = await _getUserCompletionsCollection(
        user.uid,
      ).where('habitId', isEqualTo: habitId).get();

      final batch = _firestore.batch();
      for (final doc in completionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      _error = 'Error al eliminar hábito: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> completeHabit(
    String habitId, {
    String? notes,
    int mood = 3,
    int energyLevel = 3,
    Duration? completionTime,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final habit = _habits.firstWhere((h) => h.id == habitId);

      // Si ya completó todas las repeticiones, no hacer nada
      if (habit.isFullyCompletedToday) {
        return;
      }

      final updatedHabit = habit.markAsCompleted(notes: notes, mood: mood);

      await _getUserHabitsCollection(
        user.uid,
      ).doc(habitId).update(updatedHabit.toFirestore());

      final completion = HabitCompletion(
        id: _getUserCompletionsCollection(user.uid).doc().id,
        habitId: habitId,
        userId: user.uid,
        completedAt: DateTime.now(),
        notes: notes,
        mood: mood,
        energyLevel: energyLevel,
        completionTime: completionTime,
      );

      await _getUserCompletionsCollection(
        user.uid,
      ).doc(completion.id).set(completion.toFirestore());

      if (updatedHabit.currentStreak == updatedHabit.targetDays) {
        await _celebrateMilestone(updatedHabit);
      }
    } catch (e) {
      _error = 'Error al completar hábito: $e';
      notifyListeners();
      rethrow;
    }
  }

  // NUEVO: Deshacer última completion de hoy
  Future<void> undoHabitCompletion(String habitId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final habit = _habits.firstWhere((h) => h.id == habitId);

      // Si no tiene completions de hoy, no hacer nada
      if (habit.completionTimesToday.isEmpty) {
        return;
      }

      final updatedHabit = habit.undoTodayCompletion();

      await _getUserHabitsCollection(
        user.uid,
      ).doc(habitId).update(updatedHabit.toFirestore());

      // Eliminar la última completion de Firestore
      final completionsSnapshot = await _getUserCompletionsCollection(user.uid)
          .where('habitId', isEqualTo: habitId)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();

      if (completionsSnapshot.docs.isNotEmpty) {
        await completionsSnapshot.docs.first.reference.delete();
      }
    } catch (e) {
      _error = 'Error al deshacer hábito: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> skipHabit(String habitId, {String? reason}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final habit = _habits.firstWhere((h) => h.id == habitId);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('habit_skips')
          .add({
            'habitId': habitId,
            'skippedAt': FieldValue.serverTimestamp(),
            'reason': reason,
          });

      if (!habit.isCompletedYesterday) {
        final resetHabit = habit.resetStreak();
        await _getUserHabitsCollection(
          user.uid,
        ).doc(habitId).update(resetHabit.toFirestore());
      }
    } catch (e) {
      _error = 'Error al saltar hábito: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ========== ANALYTICS ==========

  Future<Map<DateTime, int>> getCompletionHeatmap() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final snapshot = await _getUserCompletionsCollection(
      user.uid,
    ).orderBy('completedAt').get();

    final heatmap = <DateTime, int>{};

    for (final doc in snapshot.docs) {
      final completion = HabitCompletion.fromFirestore(doc);
      final date = DateTime(
        completion.completedAt.year,
        completion.completedAt.month,
        completion.completedAt.day,
      );
      heatmap[date] = (heatmap[date] ?? 0) + 1;
    }

    return heatmap;
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdown() async {
    final breakdown = <Map<String, dynamic>>[];

    for (final category in HabitCategory.values) {
      final categoryHabits = _habits
          .where((h) => h.category == category)
          .toList();
      final completions = categoryHabits.fold(
        0,
        (sum, habit) => sum + habit.totalCompletions,
      );

      if (categoryHabits.isNotEmpty) {
        breakdown.add({
          'category': category,
          'count': categoryHabits.length,
          'completions': completions,
          'consistency':
              categoryHabits
                  .map((h) => h.completionRate)
                  .fold(0.0, (sum, rate) => sum + rate) /
              categoryHabits.length,
        });
      }
    }

    return breakdown;
  }

  // ========== HELPER METHODS ==========

  Future<void> _scheduleReminder(Habit habit) async {
    if (kDebugMode) {
      print(
        'Recordatorio programado para ${habit.name} a las ${habit.reminderTime}',
      );
    }
  }

  Future<void> _celebrateMilestone(Habit habit) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('achievements')
        .add({
          'habitId': habit.id,
          'habitName': habit.name,
          'milestone': habit.targetDays,
          'achievedAt': FieldValue.serverTimestamp(),
          'type': 'streak_milestone',
        });
  }

  // ========== BULK OPERATIONS ==========

  Future<void> archiveCompletedHabits() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final now = DateTime.now();
      final archiveDate = now.subtract(const Duration(days: 90));

      for (final habit in _habits) {
        if (habit.lastCompleted != null &&
            habit.lastCompleted!.isBefore(archiveDate)) {
          final archivedHabit = habit.update(isActive: false);
          batch.update(
            _getUserHabitsCollection(user.uid).doc(habit.id),
            archivedHabit.toFirestore(),
          );
        }
      }

      await batch.commit();
    } catch (e) {
      _error = 'Error al archivar hábitos: $e';
      notifyListeners();
    }
  }

  Future<void> resetAllStreaks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();

      for (final habit in _habits) {
        batch.update(_getUserHabitsCollection(user.uid).doc(habit.id), {
          'currentStreak': 0,
        });
      }

      await batch.commit();
    } catch (e) {
      _error = 'Error al resetear streaks: $e';
      notifyListeners();
    }
  }

  // ========== MÉTODOS ADICIONALES ==========

  double getWeeklyConsistency() {
    if (_habits.isEmpty) return 0.0;
    final completedTodayCount = _habits
        .where((h) => h.isFullyCompletedToday)
        .length;
    return completedTodayCount / _habits.length;
  }

  int getTotalStreak() {
    return _habits.fold(0, (sum, habit) => sum + habit.currentStreak);
  }

  double getCompletionRate(String habitId) {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    return habit.completionRate;
  }

  List<Habit> getHabitsByCategory(HabitCategory category) {
    return _habits.where((h) => h.category == category).toList();
  }

  bool isHabitDueToday(String habitId) {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    return habit.isDueToday;
  }

  DateTime? getLastCompleted(String habitId) {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    return habit.lastCompleted;
  }

  Future<void> completeHabitSimple(String habitId) async {
    return completeHabit(habitId, mood: 3);
  }

  Habit? getHabitById(String habitId) {
    try {
      return _habits.firstWhere((h) => h.id == habitId);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> getConsistencyAnalysis() {
    if (_habits.isEmpty) {
      return {
        'overall_score': 0.0,
        'trend': 'neutral',
        'message': 'Comenzá creando tus primeros hábitos',
      };
    }

    final completedToday = _habits.where((h) => h.isFullyCompletedToday).length;
    final dueToday = habitsDueToday.length;
    final todayRate = dueToday > 0 ? completedToday / dueToday : 0.0;

    double overallScore = 0.0;
    for (final habit in activeHabits) {
      overallScore += habit.completionRate;
    }
    overallScore = activeHabits.isNotEmpty
        ? overallScore / activeHabits.length
        : 0.0;

    String trend = 'neutral';
    if (todayRate > 0.8) {
      trend = 'improving';
    } else if (todayRate < 0.4) {
      trend = 'declining';
    }

    String message = _getConsistencyMessage(overallScore, trend);

    return {
      'overall_score': overallScore,
      'today_rate': todayRate,
      'trend': trend,
      'message': message,
      'completed_today': completedToday,
      'due_today': dueToday,
    };
  }

  String _getConsistencyMessage(double score, String trend) {
    if (score >= 0.8) {
      return '¡Excelente! Tu consistencia es sobresaliente';
    } else if (score >= 0.6) {
      return 'Buen trabajo. Seguí así para formar hábitos sólidos';
    } else if (score >= 0.4) {
      return 'Vas por buen camino. La práctica hace al maestro';
    } else {
      return 'Cada día es una oportunidad. Empezá con hábitos pequeños';
    }
  }

  List<Habit> getHabitsByPriority(HabitPriority priority) {
    return activeHabits.where((h) => h.priority == priority).toList();
  }

  List<Habit> getHabitsByTrigger(HabitTrigger trigger) {
    return activeHabits.where((h) => h.trigger == trigger).toList();
  }

  List<Habit> getCriticalHabitsToday() {
    return habitsDueToday
        .where(
          (h) =>
              h.priority == HabitPriority.critical ||
              h.priority == HabitPriority.high,
        )
        .toList();
  }

  String getDailySummary() {
    final analysis = getConsistencyAnalysis();
    final completedCount = analysis['completed_today'] as int;
    final dueCount = analysis['due_today'] as int;
    final pending = dueCount - completedCount;

    if (completedCount == dueCount && dueCount > 0) {
      return '🎉 ¡Día perfecto! Completaste todos tus hábitos';
    } else if (pending == 0) {
      return '✨ ¡Buen trabajo! No tenés hábitos pendientes';
    } else if (pending == 1) {
      return '💪 Casi ahí! Te queda 1 hábito por completar';
    } else {
      return '📝 Tenés $pending hábitos pendientes para hoy';
    }
  }
  // En habits_provider.dart, agrega este método después de completeHabit:

  Future<void> undoCompletion(String habitId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Obtener el hábito actual
      final habit = getHabitById(habitId);
      if (habit == null) throw Exception('Hábito no encontrado');

      if (habit.completionsToday == 0) {
        throw Exception('Este hábito no ha sido completado hoy');
      }

      // Buscar la última completación de hoy para este hábito
      final completionsSnapshot = await _getUserCompletionsCollection(user.uid)
          .where('habitId', isEqualTo: habitId)
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime.now().copyWith(
                hour: 0,
                minute: 0,
                second: 0,
                millisecond: 0,
                microsecond: 0,
              ),
            ),
          )
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();

      if (completionsSnapshot.docs.isEmpty) {
        throw Exception('No se encontró registro de completación');
      }

      // Eliminar la completación de Firestore
      final completionDoc = completionsSnapshot.docs.first;
      await _getUserCompletionsCollection(
        user.uid,
      ).doc(completionDoc.id).delete();

      // Calcular nuevos valores para el hábito
      final newCompletionsToday = habit.completionsToday - 1;

      // Determinar si debemos resetear el streak
      bool shouldResetStreak = false;
      if (newCompletionsToday == 0) {
        // Verificar si se completó ayer
        if (habit.lastCompleted != null) {
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          final lastCompleted = habit.lastCompleted!;

          if (lastCompleted.year == yesterday.year &&
              lastCompleted.month == yesterday.month &&
              lastCompleted.day == yesterday.day) {
            // Se completó ayer, mantener el streak
            shouldResetStreak = false;
          } else {
            // No se completó ayer, resetear streak
            shouldResetStreak = true;
          }
        } else {
          // Nunca se completó, mantener en 0
          shouldResetStreak = false;
        }
      }

      // Preparar actualización del hábito
      Map<String, dynamic> updates = {'completionsToday': newCompletionsToday};

      if (shouldResetStreak) {
        updates['currentStreak'] = 0;
        updates['lastCompleted'] = null;
      } else if (newCompletionsToday == 0) {
        // Solo actualizar lastCompleted si ya no hay completaciones hoy
        updates['lastCompleted'] = habit.completionDates.isNotEmpty
            ? habit.completionDates.last
            : null;
      }

      // Actualizar hábito en Firestore
      await _getUserHabitsCollection(user.uid).doc(habitId).update(updates);

      // Actualizar localmente para respuesta inmediata
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        final updatedHabit = _habits[index].copyWith(
          completionsToday: newCompletionsToday,
          currentStreak: shouldResetStreak ? 0 : _habits[index].currentStreak,
          lastCompleted: newCompletionsToday == 0
              ? (habit.completionDates.isNotEmpty
                    ? habit.completionDates.last
                    : null)
              : _habits[index].lastCompleted,
        );
        _habits[index] = updatedHabit;
      }

      // Recalcular estadísticas
      _calculateStats();
      notifyListeners();
    } catch (e) {
      _error = 'Error al deshacer completación: $e';
      notifyListeners();
      rethrow;
    }
  }
}
