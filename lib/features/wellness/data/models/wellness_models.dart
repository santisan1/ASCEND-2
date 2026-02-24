// 📁 UBICACIÓN: lib/features/wellness/data/models/wellness_models.dart
//
// INSTRUCCIONES:
// 1. Creá la carpeta: lib/features/wellness/data/models/
// 2. Creá este archivo: wellness_models.dart
// 3. Copiá todo este código

import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// ENUMS - Estados y Categorías
// ============================================================================

/// Estado de ánimo general
enum MoodState {
  great('Excelente', '😊', 0xFF4CAF50),
  good('Bien', '🙂', 0xFF8BC34A),
  okay('Normal', '😐', 0xFFFFC107),
  bad('Mal', '😔', 0xFFFF9800),
  terrible('Terrible', '😢', 0xFFF44336);

  final String label;
  final String emoji;
  final int color;
  const MoodState(this.label, this.emoji, this.color);
}

/// Calidad de sueño
enum SleepQuality {
  great('Dormí excelente', 5),
  good('Dormí bien', 4),
  normal('Dormí normal', 3),
  bad('Dormí mal', 2),
  terrible('No dormí', 1);

  final String label;
  final int value;
  const SleepQuality(this.label, this.value);
}

/// Uso del celular
enum PhoneUsage {
  good('Bien', '🟢'),
  medium('Medio', '🟡'),
  bad('Me excedí', '🔴');

  final String label;
  final String emoji;
  const PhoneUsage(this.label, this.emoji);
}

/// Tipo de comida
enum MealType {
  cooked('Cociné', true),
  ordered('Pedí', false);

  final String label;
  final bool isHealthy;
  const MealType(this.label, this.isHealthy);
}

/// Tipo de ejercicio de calma
enum CalmExercise {
  breathing('Reset 60s', 'Respiración guiada', 60),
  journaling('Descargar cabeza', 'Escribir libremente', 300),
  grounding('Estoy ansioso', 'Ejercicio de grounding', 180),
  planning('Plan del día', 'Organizar prioridades', 240);

  final String title;
  final String description;
  final int durationSeconds;
  const CalmExercise(this.title, this.description, this.durationSeconds);
}

// ============================================================================
// MODEL: Daily Check-in (Estado del día)
// ============================================================================

class DailyCheckIn {
  final String id;
  final String userId;
  final DateTime date;

  // Estado emocional
  final MoodState? morningMood;
  final MoodState? eveningMood;
  final String? moodNotes;

  // Hábitos base
  final SleepQuality? sleepQuality;
  final bool? wentToGym;
  final PhoneUsage? phoneUsage;
  final MealType? lunchType;
  final MealType? dinnerType;
  final bool? studiedEnglish;

  // Contacto 0
  final int? temptationCount; // Veces que sintió tentación
  final List<String> temptationNotes; // Notas de cada tentación

  // Foco y calma
  final List<String> calmExercisesCompleted; // IDs de ejercicios hechos
  final int totalCalmMinutes; // Minutos totales de ejercicios

  // Misiones del día
  final List<String> completedMissions;
  final String? todayAffirmation;

  // Check-in nocturno
  final bool? tookCareOfSelf;
  final String? whatLearned;
  final String? whatToImprove;

  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;

  DailyCheckIn({
    required this.id,
    required this.userId,
    required this.date,
    this.morningMood,
    this.eveningMood,
    this.moodNotes,
    this.sleepQuality,
    this.wentToGym,
    this.phoneUsage,
    this.lunchType,
    this.dinnerType,
    this.studiedEnglish,
    this.temptationCount = 0,
    this.temptationNotes = const [],
    this.calmExercisesCompleted = const [],
    this.totalCalmMinutes = 0,
    this.completedMissions = const [],
    this.todayAffirmation,
    this.tookCareOfSelf,
    this.whatLearned,
    this.whatToImprove,
    required this.createdAt,
    this.updatedAt,
  });

  // ========== COMPUTED PROPERTIES ==========

  bool get isComplete {
    return sleepQuality != null &&
        wentToGym != null &&
        phoneUsage != null &&
        (lunchType != null || dinnerType != null);
  }

  int get completionPercentage {
    int total = 0;
    int completed = 0;

    // Hábitos base (6 items)
    total += 6;
    if (sleepQuality != null) completed++;
    if (wentToGym != null) completed++;
    if (phoneUsage != null) completed++;
    if (lunchType != null) completed++;
    if (dinnerType != null) completed++;
    if (studiedEnglish != null) completed++;

    // Check-in emocional (1 item)
    total += 1;
    if (morningMood != null || eveningMood != null) completed++;

    return ((completed / total) * 100).round();
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // ========== METHODS ==========

  DailyCheckIn copyWith({
    String? id,
    String? userId,
    DateTime? date,
    MoodState? morningMood,
    MoodState? eveningMood,
    String? moodNotes,
    SleepQuality? sleepQuality,
    bool? wentToGym,
    PhoneUsage? phoneUsage,
    MealType? lunchType,
    MealType? dinnerType,
    bool? studiedEnglish,
    int? temptationCount,
    List<String>? temptationNotes,
    List<String>? calmExercisesCompleted,
    int? totalCalmMinutes,
    List<String>? completedMissions,
    String? todayAffirmation,
    bool? tookCareOfSelf,
    String? whatLearned,
    String? whatToImprove,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyCheckIn(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      morningMood: morningMood ?? this.morningMood,
      eveningMood: eveningMood ?? this.eveningMood,
      moodNotes: moodNotes ?? this.moodNotes,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      wentToGym: wentToGym ?? this.wentToGym,
      phoneUsage: phoneUsage ?? this.phoneUsage,
      lunchType: lunchType ?? this.lunchType,
      dinnerType: dinnerType ?? this.dinnerType,
      studiedEnglish: studiedEnglish ?? this.studiedEnglish,
      temptationCount: temptationCount ?? this.temptationCount,
      temptationNotes: temptationNotes ?? this.temptationNotes,
      calmExercisesCompleted:
          calmExercisesCompleted ?? this.calmExercisesCompleted,
      totalCalmMinutes: totalCalmMinutes ?? this.totalCalmMinutes,
      completedMissions: completedMissions ?? this.completedMissions,
      todayAffirmation: todayAffirmation ?? this.todayAffirmation,
      tookCareOfSelf: tookCareOfSelf ?? this.tookCareOfSelf,
      whatLearned: whatLearned ?? this.whatLearned,
      whatToImprove: whatToImprove ?? this.whatToImprove,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ========== FIRESTORE CONVERSION ==========

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'morningMood': morningMood?.index,
      'eveningMood': eveningMood?.index,
      'moodNotes': moodNotes,
      'sleepQuality': sleepQuality?.index,
      'wentToGym': wentToGym,
      'phoneUsage': phoneUsage?.index,
      'lunchType': lunchType?.index,
      'dinnerType': dinnerType?.index,
      'studiedEnglish': studiedEnglish,
      'temptationCount': temptationCount,
      'temptationNotes': temptationNotes,
      'calmExercisesCompleted': calmExercisesCompleted,
      'totalCalmMinutes': totalCalmMinutes,
      'completedMissions': completedMissions,
      'todayAffirmation': todayAffirmation,
      'tookCareOfSelf': tookCareOfSelf,
      'whatLearned': whatLearned,
      'whatToImprove': whatToImprove,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory DailyCheckIn.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DailyCheckIn(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      morningMood: data['morningMood'] != null
          ? MoodState.values[data['morningMood'] as int]
          : null,
      eveningMood: data['eveningMood'] != null
          ? MoodState.values[data['eveningMood'] as int]
          : null,
      moodNotes: data['moodNotes'],
      sleepQuality: data['sleepQuality'] != null
          ? SleepQuality.values[data['sleepQuality'] as int]
          : null,
      wentToGym: data['wentToGym'],
      phoneUsage: data['phoneUsage'] != null
          ? PhoneUsage.values[data['phoneUsage'] as int]
          : null,
      lunchType: data['lunchType'] != null
          ? MealType.values[data['lunchType'] as int]
          : null,
      dinnerType: data['dinnerType'] != null
          ? MealType.values[data['dinnerType'] as int]
          : null,
      studiedEnglish: data['studiedEnglish'],
      temptationCount: data['temptationCount'] ?? 0,
      temptationNotes: List<String>.from(data['temptationNotes'] ?? []),
      calmExercisesCompleted: List<String>.from(
        data['calmExercisesCompleted'] ?? [],
      ),
      totalCalmMinutes: data['totalCalmMinutes'] ?? 0,
      completedMissions: List<String>.from(data['completedMissions'] ?? []),
      todayAffirmation: data['todayAffirmation'],
      tookCareOfSelf: data['tookCareOfSelf'],
      whatLearned: data['whatLearned'],
      whatToImprove: data['whatToImprove'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory DailyCheckIn.createEmpty(String userId) {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);

    return DailyCheckIn(
      id: '',
      userId: userId,
      date: dateOnly,
      createdAt: today,
    );
  }
}

// ============================================================================
// MODEL: Contact Zero Tracker
// ============================================================================

class ContactZeroTracker {
  final String id;
  final String userId;
  final DateTime startDate;
  final int currentStreak; // Días consecutivos sin contacto
  final int longestStreak;
  final List<DateTime> temptationDates; // Fechas en las que sintió tentación
  final List<String> temptationNotes; // Notas de contención
  final DateTime? lastTemptation;
  final bool isActive;

  ContactZeroTracker({
    required this.id,
    required this.userId,
    required this.startDate,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.temptationDates = const [],
    this.temptationNotes = const [],
    this.lastTemptation,
    this.isActive = true,
  });

  int get daysOfContactZero {
    if (!isActive) return 0;
    return DateTime.now().difference(startDate).inDays;
  }

  int get temptationsThisWeek {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return temptationDates.where((date) => date.isAfter(weekAgo)).length;
  }

  bool get hadTemptationToday {
    if (lastTemptation == null) return false;
    final now = DateTime.now();
    return lastTemptation!.year == now.year &&
        lastTemptation!.month == now.month &&
        lastTemptation!.day == now.day;
  }

  ContactZeroTracker copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    int? currentStreak,
    int? longestStreak,
    List<DateTime>? temptationDates,
    List<String>? temptationNotes,
    DateTime? lastTemptation,
    bool? isActive,
  }) {
    return ContactZeroTracker(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      temptationDates: temptationDates ?? this.temptationDates,
      temptationNotes: temptationNotes ?? this.temptationNotes,
      lastTemptation: lastTemptation ?? this.lastTemptation,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'startDate': Timestamp.fromDate(startDate),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'temptationDates': temptationDates
          .map((d) => Timestamp.fromDate(d))
          .toList(),
      'temptationNotes': temptationNotes,
      'lastTemptation': lastTemptation != null
          ? Timestamp.fromDate(lastTemptation!)
          : null,
      'isActive': isActive,
    };
  }

  factory ContactZeroTracker.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ContactZeroTracker(
      id: doc.id,
      userId: data['userId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      temptationDates:
          (data['temptationDates'] as List<dynamic>?)
              ?.map((t) => (t as Timestamp).toDate())
              .toList() ??
          [],
      temptationNotes: List<String>.from(data['temptationNotes'] ?? []),
      lastTemptation: (data['lastTemptation'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }
}

// ============================================================================
// MODEL: Daily Mission (Misión del día)
// ============================================================================

class DailyMission {
  final String id;
  final String title;
  final String description;
  final String category; // 'future', 'energy', 'respect'
  final bool isCompleted;
  final DateTime date;

  DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.isCompleted = false,
    required this.date,
  });

  DailyMission copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    bool? isCompleted,
    DateTime? date,
  }) {
    return DailyMission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
    );
  }
}

// ============================================================================
// AFFIRMATIONS POOL
// ============================================================================

class DailyAffirmations {
  static const List<String> affirmations = [
    "Estoy construyendo estabilidad.",
    "No necesito correr detrás de nada.",
    "Las cosas que son para mí, llegan solas.",
    "Me respeto.",
    "Cada día soy más fuerte.",
    "Mis decisiones me acercan a mi mejor versión.",
    "Merezco paz y claridad.",
    "Estoy en control de mi tiempo y energía.",
    "Priorizo mi bienestar sin culpa.",
    "Avanzo a mi propio ritmo.",
    "No me comparo, me enfoco en crecer.",
    "Acepto lo que no puedo controlar.",
    "Mi progreso es valioso, aunque sea pequeño.",
    "Descansar también es productivo.",
    "Confío en mi proceso.",
  ];

  static String getAffirmationForDate(DateTime date) {
    // Usar el día del año como seed para que sea consistente
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final index = dayOfYear % affirmations.length;
    return affirmations[index];
  }

  static String getRandom() {
    final now = DateTime.now();
    return getAffirmationForDate(now);
  }
}
