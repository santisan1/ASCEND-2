// 📁 UBICACIÓN: lib/features/wellness/domain/wellness_provider.dart
//
// INSTRUCCIONES:
// 1. Creá la carpeta: lib/features/wellness/domain/
// 2. Creá este archivo: wellness_provider.dart
// 3. Copiá todo este código

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/wellness_models.dart';

class WellnessProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DailyCheckIn? _todayCheckIn;
  ContactZeroTracker? _contactZero;
  List<DailyMission> _todayMissions = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _checkInSubscription;
  StreamSubscription? _contactZeroSubscription;

  // Getters
  DailyCheckIn? get todayCheckIn => _todayCheckIn;
  ContactZeroTracker? get contactZero => _contactZero;
  List<DailyMission> get todayMissions => _todayMissions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Estado general del día
  String get todayAffirmation {
    if (_todayCheckIn?.todayAffirmation != null) {
      return _todayCheckIn!.todayAffirmation!;
    }
    return DailyAffirmations.getRandom();
  }

  MoodState? get currentMood {
    final hour = DateTime.now().hour;
    if (hour < 14) {
      return _todayCheckIn?.morningMood;
    } else {
      return _todayCheckIn?.eveningMood ?? _todayCheckIn?.morningMood;
    }
  }

  int get completedMissionsCount {
    return _todayMissions.where((m) => m.isCompleted).length;
  }

  // Referencias a colecciones
  CollectionReference _getUserCheckInsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_checkins');
  }

  CollectionReference _getUserContactZeroCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contact_zero');
  }

  WellnessProvider() {
    _init();
  }

  Future<void> _init() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _subscribeToUserData(user.uid);
    }

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToUserData(user.uid);
      } else {
        _unsubscribe();
        _todayCheckIn = null;
        _contactZero = null;
        _todayMissions = [];
        notifyListeners();
      }
    });
  }

  Future<void> _subscribeToUserData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _unsubscribe();

      // Suscribirse al check-in de hoy
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      _checkInSubscription = _getUserCheckInsCollection(userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .snapshots()
          .listen(
            (snapshot) async {
              if (snapshot.docs.isEmpty) {
                // Crear check-in vacío para hoy
                await _createTodayCheckIn(userId);
              } else {
                _todayCheckIn = DailyCheckIn.fromFirestore(snapshot.docs.first);
              }

              _isLoading = false;
              _error = null;
              notifyListeners();
            },
            onError: (error) {
              _error = 'Error al cargar datos: $error';
              _isLoading = false;
              notifyListeners();
            },
          );

      // Suscribirse a Contact Zero
      _contactZeroSubscription = _getUserContactZeroCollection(userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.docs.isNotEmpty) {
                _contactZero = ContactZeroTracker.fromFirestore(
                  snapshot.docs.first,
                );
              }
              notifyListeners();
            },
            onError: (error) {
              if (kDebugMode) {
                print('Error al cargar Contact Zero: $error');
              }
            },
          );

      // Generar misiones del día
      await _generateTodayMissions();
    } catch (e) {
      _error = 'Error al suscribirse: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _unsubscribe() async {
    await _checkInSubscription?.cancel();
    await _contactZeroSubscription?.cancel();
    _checkInSubscription = null;
    _contactZeroSubscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  // ========== CHECK-IN DIARIO ==========

  Future<void> _createTodayCheckIn(String userId) async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);

    final checkIn = DailyCheckIn.createEmpty(userId);
    final docRef = _getUserCheckInsCollection(userId).doc();

    final checkInWithId = checkIn.copyWith(
      id: docRef.id,
      todayAffirmation: DailyAffirmations.getRandom(),
    );

    await docRef.set(checkInWithId.toFirestore());
    _todayCheckIn = checkInWithId;
    notifyListeners();
  }

  Future<void> updateMood(MoodState mood, {String? notes}) async {
    if (_todayCheckIn == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final hour = DateTime.now().hour;
    final isMorning = hour < 14;

    final updated = _todayCheckIn!.copyWith(
      morningMood: isMorning ? mood : _todayCheckIn!.morningMood,
      eveningMood: !isMorning ? mood : _todayCheckIn!.eveningMood,
      moodNotes: notes,
    );

    await _getUserCheckInsCollection(
      user.uid,
    ).doc(_todayCheckIn!.id).update(updated.toFirestore());
  }

  Future<void> updateSleepQuality(SleepQuality quality) async {
    if (_todayCheckIn == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _getUserCheckInsCollection(
      user.uid,
    ).doc(_todayCheckIn!.id).update({'sleepQuality': quality.index});
  }

  Future<void> updateGymStatus(bool went) async {
    if (_todayCheckIn == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _getUserCheckInsCollection(
      user.uid,
    ).doc(_todayCheckIn!.id).update({'wentToGym': went});
  }

  Future<void> updatePhoneUsage(PhoneUsage usage) async {
    if (_todayCheckIn == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _getUserCheckInsCollection(
      user.uid,
    ).doc(_todayCheckIn!.id).update({'phoneUsage': usage.index});
  }

  Future<void> updateMealType(MealType type, {required bool isLunch}) async {
    if (_todayCheckIn == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _getUserCheckInsCollection(user.uid).doc(_todayCheckIn!.id).update({
      isLunch ? 'lunchType' : 'dinnerType': type.index,
    });
  }

  Future<void> updateStudyStatus(bool studied) async {
    if (_todayCheckIn == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _getUserCheckInsCollection(
      user.uid,
    ).doc(_todayCheckIn!.id).update({'studiedEnglish': studied});
  }

  // ========== CONTACT ZERO ==========

  Future<void> startContactZero() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final tracker = ContactZeroTracker(
      id: '',
      userId: user.uid,
      startDate: DateTime.now(),
      currentStreak: 0,
      longestStreak: 0,
      isActive: true,
    );

    final docRef = _getUserContactZeroCollection(user.uid).doc();
    await docRef.set(tracker.copyWith(id: docRef.id).toFirestore());
  }

  Future<void> recordTemptation(String note, {required bool letItPass}) async {
    if (_contactZero == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final newTemptationDates = [..._contactZero!.temptationDates, now];
    final newNotes = [..._contactZero!.temptationNotes, note];

    final updated = _contactZero!.copyWith(
      temptationDates: newTemptationDates,
      temptationNotes: newNotes,
      lastTemptation: now,
    );

    await _getUserContactZeroCollection(
      user.uid,
    ).doc(_contactZero!.id).update(updated.toFirestore());

    // También actualizar el check-in del día
    if (_todayCheckIn != null) {
      final currentCount = _todayCheckIn!.temptationCount ?? 0;
      final currentNotes = List<String>.from(_todayCheckIn!.temptationNotes);
      currentNotes.add(note);

      await _getUserCheckInsCollection(user.uid).doc(_todayCheckIn!.id).update({
        'temptationCount': currentCount + 1,
        'temptationNotes': currentNotes,
      });
    }
  }

  Future<void> resetContactZero() async {
    if (_contactZero == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _getUserContactZeroCollection(
      user.uid,
    ).doc(_contactZero!.id).update({'isActive': false});
  }

  // ========== EJERCICIOS DE CALMA ==========

  Future<void> completeExercise(CalmExercise exercise) async {
    if (_todayCheckIn == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final completedList = List<String>.from(
      _todayCheckIn!.calmExercisesCompleted,
    );
    completedList.add(exercise.name);

    final totalMinutes =
        _todayCheckIn!.totalCalmMinutes +
        (exercise.durationSeconds / 60).ceil();

    await _getUserCheckInsCollection(user.uid).doc(_todayCheckIn!.id).update({
      'calmExercisesCompleted': completedList,
      'totalCalmMinutes': totalMinutes,
    });
  }

  // ========== MISIONES DEL DÍA ==========

  Future<void> _generateTodayMissions() async {
    // Generar 3 misiones basadas en el estado del usuario
    _todayMissions = [
      DailyMission(
        id: '1',
        title: 'Ir 25 min al gym',
        description: 'Movimiento para tu cuerpo y mente',
        category: 'energy',
        date: DateTime.now(),
      ),
      DailyMission(
        id: '2',
        title: 'Cocinarte algo rico',
        description: 'Cuidarte desde lo básico',
        category: 'respect',
        date: DateTime.now(),
      ),
      DailyMission(
        id: '3',
        title: '20 min sin celular después de comer',
        description: 'Desconexión consciente',
        category: 'future',
        date: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  Future<void> completeMission(String missionId) async {
    if (_todayCheckIn == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final completedList = List<String>.from(_todayCheckIn!.completedMissions);
    if (!completedList.contains(missionId)) {
      completedList.add(missionId);
    }

    await _getUserCheckInsCollection(
      user.uid,
    ).doc(_todayCheckIn!.id).update({'completedMissions': completedList});

    // Actualizar localmente
    _todayMissions = _todayMissions.map((m) {
      if (m.id == missionId) {
        return m.copyWith(isCompleted: true);
      }
      return m;
    }).toList();
    notifyListeners();
  }

  // ========== CHECK-IN NOCTURNO ==========

  Future<void> submitNightReflection({
    required bool tookCare,
    String? learned,
    String? improve,
  }) async {
    if (_todayCheckIn == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _getUserCheckInsCollection(user.uid).doc(_todayCheckIn!.id).update({
      'tookCareOfSelf': tookCare,
      'whatLearned': learned,
      'whatToImprove': improve,
    });
  }

  // ========== ANALYTICS ==========

  Future<Map<String, dynamic>> getWeekStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    final snapshot = await _getUserCheckInsCollection(
      user.uid,
    ).where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo)).get();

    int gymDays = 0;
    int goodSleepDays = 0;
    int cookedMeals = 0;
    int studyDays = 0;

    for (final doc in snapshot.docs) {
      final checkIn = DailyCheckIn.fromFirestore(doc);
      if (checkIn.wentToGym == true) gymDays++;
      if (checkIn.sleepQuality != null && checkIn.sleepQuality!.value >= 3)
        goodSleepDays++;
      if (checkIn.lunchType == MealType.cooked) cookedMeals++;
      if (checkIn.dinnerType == MealType.cooked) cookedMeals++;
      if (checkIn.studiedEnglish == true) studyDays++;
    }

    return {
      'gymDays': gymDays,
      'goodSleepDays': goodSleepDays,
      'cookedMeals': cookedMeals,
      'studyDays': studyDays,
      'totalDays': snapshot.docs.length,
    };
  }

  String getMotivationalMessage() {
    if (_todayCheckIn == null) {
      return "Comenzá tu día registrando cómo te sentís";
    }

    final completion = _todayCheckIn!.completionPercentage;

    if (completion >= 80) {
      return "¡Estás haciendo un trabajo increíble! 🔥";
    } else if (completion >= 50) {
      return "Buen progreso. Seguí así 💪";
    } else if (completion >= 20) {
      return "Un paso a la vez. Vas bien 🌱";
    } else {
      return "Hoy es un nuevo día. Empecemos 🌅";
    }
  }
}
