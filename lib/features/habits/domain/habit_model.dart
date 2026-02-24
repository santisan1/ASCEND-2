import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// ENUM: HABIT CATEGORY
// ============================================================================

enum HabitCategory {
  salud('Salud', Icons.favorite, 0xFFE57373),
  familia('Familia', Icons.family_restroom, 0xFF81C784),
  finanzas('Finanzas', Icons.attach_money, 0xFF64B5F6),
  productividad('Productividad', Icons.work, 0xFF9575CD),
  aprendizaje('Aprendizaje', Icons.school, 0xFF4DB6AC),
  social('Social', Icons.people, 0xFFFFB74D),
  hogar('Hogar', Icons.home, 0xFFA1887F),
  bienestar('Bienestar', Icons.self_improvement, 0xFF7986CB);

  final String displayName;
  final IconData icon;
  final int color;

  const HabitCategory(this.displayName, this.icon, this.color);
}

// ============================================================================
// ENUM: HABIT PRIORITY
// ============================================================================

enum HabitPriority {
  low('Baja', 1),
  medium('Media', 2),
  high('Alta', 3),
  critical('Crítica', 4);

  final String displayName;
  final int value;

  const HabitPriority(this.displayName, this.value);
}

// ============================================================================
// ENUM: HABIT TRIGGER
// ============================================================================

enum HabitTrigger {
  morning('Mañana', '07:00 - 09:00'),
  noon('Mediodía', '12:00 - 14:00'),
  afternoon('Tarde', '17:00 - 19:00'),
  evening('Noche', '21:00 - 23:00'),
  anytime('Cuando quieras', 'Flexible');

  final String displayName;
  final String timeRange;

  const HabitTrigger(this.displayName, this.timeRange);
}

// ============================================================================
// MODEL: HABIT (MEJORADO)
// ============================================================================

class Habit {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String icon;
  final HabitCategory? category;
  final List<int> frequency;
  final String? reminderTime;
  final int difficulty;
  final int impact;
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final bool isActive;
  final int targetDays;
  final List<String> tags;
  final DateTime? lastCompleted;
  final List<String> completionHistory;
  final HabitPriority priority;
  final HabitTrigger trigger;
  final bool isTemplate;
  final String? templateId;

  final int completionsToday; // Cuántas veces se completó hoy

  // NUEVOS CAMPOS
  final int estimatedDuration; // en minutos
  final int dailyRepetitions; // cuántas veces por día
  final List<String> completionTimesToday; // timestamps de completions de hoy

  List<DateTime> completionDates; // Para el historial

  // Método para calcular totalCompletions

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    this.icon = 'fitness_center',
    this.category,
    this.frequency = const [1, 2, 3, 4, 5, 6, 7],
    this.reminderTime,
    this.difficulty = 3,
    this.impact = 3,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.createdAt,
    this.isActive = true,
    this.targetDays = 30,
    this.tags = const [],
    this.lastCompleted,
    this.completionHistory = const [],
    this.priority = HabitPriority.medium,
    this.trigger = HabitTrigger.anytime,
    this.isTemplate = false,
    this.templateId,
    this.estimatedDuration = 15, // 15 min por defecto
    this.dailyRepetitions = 1,
    this.completionsToday = 0, // 1 vez por día por defecto
    this.completionTimesToday = const [],
    this.completionDates = const [],
  });

  // ========== COMPUTED PROPERTIES ==========
  bool get isFullyCompletedToday => completionsToday >= dailyRepetitions;
  bool get isDueToday {
    final today = DateTime.now().weekday;
    return frequency.contains(today);
  }

  // Completado al menos una vez hoy
  bool get isCompletedToday {
    if (lastCompleted == null) return false;
    final now = DateTime.now();
    final last = lastCompleted!;
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  // Cuántas repeticiones faltan hoy
  int get remainingRepetitionsToday {
    return (dailyRepetitions - completionsToday).clamp(0, dailyRepetitions);
  }

  bool get isCompletedYesterday {
    if (lastCompleted == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final last = lastCompleted!;
    return last.year == yesterday.year &&
        last.month == yesterday.month &&
        last.day == yesterday.day;
  }

  double get completionRate {
    if (completionHistory.isEmpty) return 0.0;
    final totalDays = DateTime.now().difference(createdAt).inDays + 1;
    final completedDays = completionHistory.length;
    return (completedDays / totalDays).clamp(0.0, 1.0);
  }

  int get totalCompletions => completionHistory.length;

  // ========== METHODS ==========

  Habit markAsCompleted({String? notes, int mood = 3}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Si ya completó todas las repeticiones de hoy, no hacer nada
    if (isFullyCompletedToday) {
      return this;
    }

    final newHistory = [...completionHistory, now.toIso8601String()];
    final newCompletionsToday = [
      ...completionTimesToday,
      now.toIso8601String(),
    ];

    // LÓGICA MEJORADA DE STREAK
    int newStreak = currentStreak;

    // Obtener fechas de completions parseadas
    final completedDates = <DateTime>[];
    for (final completion in completionHistory) {
      try {
        final date = DateTime.parse(completion);
        completedDates.add(DateTime(date.year, date.month, date.day));
      } catch (e) {
        // Ignorar fechas inválidas
      }
    }

    // Ordenar de más reciente a más antigua
    completedDates.sort((a, b) => b.compareTo(a));

    // Verificar cuántos días consecutivos llevamos
    if (completedDates.isEmpty) {
      newStreak = 1;
    } else {
      final lastCompleted = completedDates.first;

      DateTime? lastValidDay;
      for (int i = 1; i <= 7; i++) {
        final checkDay = today.subtract(Duration(days: i));
        if (frequency.contains(checkDay.weekday)) {
          lastValidDay = checkDay;
          break;
        }
      }

      if (lastValidDay != null &&
          (lastCompleted.isAtSameMomentAs(lastValidDay) ||
              lastCompleted.isAfter(lastValidDay))) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1;
      }
    }

    return copyWith(
      lastCompleted: now,
      currentStreak: newStreak,
      longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
      completionHistory: newHistory,
      completionTimesToday: newCompletionsToday,
    );
  }

  // NUEVO: Deshacer la última completion de hoy
  Habit undoTodayCompletion() {
    if (completionTimesToday.isEmpty) {
      return this;
    }

    final newCompletionsToday = List<String>.from(completionTimesToday);
    final lastCompletion = newCompletionsToday.removeLast();

    // Remover también del historial general
    final newHistory = List<String>.from(completionHistory);
    newHistory.remove(lastCompletion);

    // Si no quedan completions de hoy, ajustar lastCompleted
    DateTime? newLastCompleted = lastCompleted;
    if (newCompletionsToday.isEmpty && newHistory.isNotEmpty) {
      try {
        newLastCompleted = DateTime.parse(newHistory.last);
      } catch (e) {
        newLastCompleted = null;
      }
    } else if (newHistory.isEmpty) {
      newLastCompleted = null;
    }

    // Recalcular streak
    int newStreak = currentStreak;
    if (newCompletionsToday.isEmpty) {
      // Si ya no tiene completions hoy, reducir streak
      newStreak = (currentStreak - 1).clamp(0, longestStreak);
    }

    return copyWith(
      completionHistory: newHistory,
      completionTimesToday: newCompletionsToday,
      lastCompleted: newLastCompleted,
      currentStreak: newStreak,
    );
  }

  bool get isStreakAtRisk {
    if (currentStreak == 0) return false;
    if (!isDueToday && isFullyCompletedToday) return false;

    final now = DateTime.now();

    if (now.hour >= 18 && isDueToday && !isFullyCompletedToday) {
      return true;
    }

    return false;
  }

  int get daysUntilStreakLost {
    if (currentStreak == 0) return 0;
    if (isFullyCompletedToday) {
      final now = DateTime.now();
      for (int i = 1; i <= 7; i++) {
        final checkDay = now.add(Duration(days: i));
        if (frequency.contains(checkDay.weekday)) {
          return i;
        }
      }
      return 7;
    }

    if (isDueToday && !isFullyCompletedToday) {
      return 0;
    }

    return 1;
  }

  Habit resetStreak() {
    return copyWith(currentStreak: 0);
  }

  Habit update({
    String? name,
    String? description,
    String? icon,
    HabitCategory? category,
    List<int>? frequency,
    String? reminderTime,
    int? difficulty,
    int? impact,
    bool? isActive,
    int? targetDays,
    List<String>? tags,
    int? estimatedDuration,
    int? dailyRepetitions,
  }) {
    return copyWith(
      name: name,
      description: description,
      icon: icon,
      category: category,
      frequency: frequency,
      reminderTime: reminderTime,
      difficulty: difficulty,
      impact: impact,
      isActive: isActive,
      targetDays: targetDays,
      tags: tags,
      estimatedDuration: estimatedDuration,
      dailyRepetitions: dailyRepetitions,
    );
  }

  Habit copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? icon,
    HabitCategory? category,
    List<int>? frequency,
    String? reminderTime,
    int? difficulty,
    int? impact,
    int? currentStreak,
    int? longestStreak,
    DateTime? createdAt,
    bool? isActive,
    int? targetDays,
    List<String>? tags,
    DateTime? lastCompleted,
    List<String>? completionHistory,
    HabitPriority? priority,
    HabitTrigger? trigger,
    bool? isTemplate,
    String? templateId,
    int? estimatedDuration,
    int? dailyRepetitions,
    List<String>? completionTimesToday,
    int? completionsToday, // Asegúrate de tener este
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      reminderTime: reminderTime ?? this.reminderTime,
      difficulty: difficulty ?? this.difficulty,
      impact: impact ?? this.impact,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      targetDays: targetDays ?? this.targetDays,
      tags: tags ?? this.tags,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      priority: priority ?? this.priority,
      trigger: trigger ?? this.trigger,
      isTemplate: isTemplate ?? this.isTemplate,
      templateId: templateId ?? this.templateId,
      completionHistory: completionHistory ?? this.completionHistory,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      dailyRepetitions: dailyRepetitions ?? this.dailyRepetitions,
      completionTimesToday: completionTimesToday ?? this.completionTimesToday,
    );
  }

  // ========== FIRESTORE CONVERSION ==========

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category?.index,
      'frequency': frequency,
      'reminderTime': reminderTime,
      'difficulty': difficulty,
      'impact': impact,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'targetDays': targetDays,
      'tags': tags,
      'lastCompleted': lastCompleted != null
          ? Timestamp.fromDate(lastCompleted!)
          : null,
      'completionHistory': completionHistory,
      'priority': priority.index,
      'trigger': trigger.index,
      'isTemplate': isTemplate,
      'templateId': templateId,
      'estimatedDuration': estimatedDuration,
      'dailyRepetitions': dailyRepetitions,
      'completionTimesToday': completionTimesToday,
    };
  }

  factory Habit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Limpiar completions de hoy si es otro día
    List<String> todayCompletions = List<String>.from(
      data['completionTimesToday'] ?? [],
    );

    final now = DateTime.now();
    todayCompletions = todayCompletions.where((timestamp) {
      try {
        final date = DateTime.parse(timestamp);
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      } catch (e) {
        return false;
      }
    }).toList();

    return Habit(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? 'fitness_center',
      category: data['category'] != null
          ? HabitCategory.values[data['category'] as int]
          : null,
      frequency: List<int>.from(data['frequency'] ?? [1, 2, 3, 4, 5, 6, 7]),
      reminderTime: data['reminderTime'],
      difficulty: data['difficulty'] ?? 3,
      impact: data['impact'] ?? 3,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      targetDays: data['targetDays'] ?? 30,
      tags: List<String>.from(data['tags'] ?? []),
      lastCompleted: (data['lastCompleted'] as Timestamp?)?.toDate(),
      priority: data['priority'] != null
          ? HabitPriority.values[data['priority'] as int]
          : HabitPriority.medium,
      trigger: data['trigger'] != null
          ? HabitTrigger.values[data['trigger'] as int]
          : HabitTrigger.anytime,
      isTemplate: data['isTemplate'] ?? false,
      templateId: data['templateId'],
      completionHistory: List<String>.from(data['completionHistory'] ?? []),
      estimatedDuration: data['estimatedDuration'] ?? 15,
      dailyRepetitions: data['dailyRepetitions'] ?? 1,
      completionTimesToday: todayCompletions,
    );
  }
}

// ============================================================================
// MODEL: HABIT COMPLETION
// ============================================================================

class HabitCompletion {
  final String id;
  final String habitId;
  final String userId;
  final DateTime completedAt;
  final String? notes;
  final int mood;
  final int energyLevel;
  final Duration? completionTime;

  HabitCompletion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    this.notes,
    this.mood = 3,
    this.energyLevel = 3,
    this.completionTime,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'habitId': habitId,
      'userId': userId,
      'completedAt': Timestamp.fromDate(completedAt),
      'notes': notes,
      'mood': mood,
      'energyLevel': energyLevel,
      'completionTime': completionTime?.inMinutes,
    };
  }

  factory HabitCompletion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HabitCompletion(
      id: doc.id,
      habitId: data['habitId'] ?? '',
      userId: data['userId'] ?? '',
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      notes: data['notes'],
      mood: data['mood'] ?? 3,
      energyLevel: data['energyLevel'] ?? 3,
      completionTime: data['completionTime'] != null
          ? Duration(minutes: data['completionTime'] as int)
          : null,
    );
  }
}

// ============================================================================
// MODEL: HABIT STATS
// ============================================================================

class HabitStats {
  final double weeklyConsistency;
  final double monthlyConsistency;
  final int currentStreak;
  final int longestStreak;
  final int totalHabits;
  final int activeHabits;
  final int completionsToday;
  final int completionsThisWeek;
  final Map<String, int> completionsByCategory;
  final Map<int, int> completionsByDayOfWeek;

  HabitStats({
    required this.weeklyConsistency,
    required this.monthlyConsistency,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalHabits,
    required this.activeHabits,
    required this.completionsToday,
    required this.completionsThisWeek,
    required this.completionsByCategory,
    required this.completionsByDayOfWeek,
  });

  factory HabitStats.fromHabits(
    List<Habit> habits,
    List<HabitCompletion> completions,
  ) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final completionsToday = completions.where((c) {
      final date = c.completedAt;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;

    final completionsThisWeek = completions
        .where((c) => c.completedAt.isAfter(weekAgo))
        .length;

    double weeklyConsistency = 0.0;
    if (habits.isNotEmpty) {
      final activeHabits = habits.where((h) => h.isActive).toList();
      if (activeHabits.isNotEmpty) {
        final totalExpected = activeHabits.fold(0, (sum, habit) {
          return sum + habit.frequency.length;
        });
        weeklyConsistency = totalExpected > 0
            ? completionsThisWeek / totalExpected
            : 0.0;
      }
    }

    final currentStreak = habits.fold(
      0,
      (sum, habit) => sum + habit.currentStreak,
    );

    final longestStreak = habits.fold(
      0,
      (maxStreak, habit) =>
          habit.longestStreak > maxStreak ? habit.longestStreak : maxStreak,
    );

    final completionsByCategory = <String, int>{};
    for (final habit in habits) {
      if (habit.category != null) {
        final categoryName = habit.category!.displayName;
        completionsByCategory[categoryName] =
            (completionsByCategory[categoryName] ?? 0) + habit.totalCompletions;
      }
    }

    final completionsByDayOfWeek = <int, int>{};
    for (final completion in completions) {
      final day = completion.completedAt.weekday;
      completionsByDayOfWeek[day] = (completionsByDayOfWeek[day] ?? 0) + 1;
    }

    return HabitStats(
      weeklyConsistency: weeklyConsistency,
      monthlyConsistency: weeklyConsistency * 0.9,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalHabits: habits.length,
      activeHabits: habits.where((h) => h.isActive).length,
      completionsToday: completionsToday,
      completionsThisWeek: completionsThisWeek,
      completionsByCategory: completionsByCategory,
      completionsByDayOfWeek: completionsByDayOfWeek,
    );
  }
}
