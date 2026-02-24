import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';

class ModuleReminder {
  final String module;
  final bool enabled;
  final int hour;
  final int minute;
  final String message;
  final String frequency; // daily | weekdays | weekend

  const ModuleReminder({
    required this.module,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.message,
    this.frequency = 'daily',
  });

  ModuleReminder copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    String? message,
    String? frequency,
  }) {
    return ModuleReminder(
      module: module,
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      message: message ?? this.message,
      frequency: frequency ?? this.frequency,
    );
  }

  Map<String, dynamic> toJson() => {
    'module': module,
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
    'message': message,
    'frequency': frequency,
  };

  factory ModuleReminder.fromJson(Map<String, dynamic> json) {
    return ModuleReminder(
      module: json['module'] as String,
      enabled: json['enabled'] as bool? ?? false,
      hour: json['hour'] as int? ?? 20,
      minute: json['minute'] as int? ?? 0,
      message: json['message'] as String? ?? 'Revisá tu módulo en ASCEND',
      frequency: json['frequency'] as String? ?? 'daily',
    );
  }
}

class NotificationPreferencesProvider extends ChangeNotifier {
  static const _storageKey = 'ascend_module_reminders_v2';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ModuleReminder> _reminders = const [
    ModuleReminder(
      module: 'Espiritualidad',
      enabled: true,
      hour: 7,
      minute: 30,
      message: 'Momento de conexión con Dios 🙏',
    ),
    ModuleReminder(
      module: 'Hábitos',
      enabled: true,
      hour: 20,
      minute: 0,
      message: 'Cerrá tus hábitos del día ✅',
    ),
    ModuleReminder(
      module: 'Finanzas',
      enabled: false,
      hour: 19,
      minute: 30,
      message: 'Registrá gastos e inversiones del día 💸',
    ),
    ModuleReminder(
      module: 'Relaciones',
      enabled: false,
      hour: 18,
      minute: 0,
      message: 'Contactá una persona importante 🤝',
    ),
  ];

  DateTime? _lastSyncAt;
  Map<String, DateTime> _lastSeenByModule = {};

  List<ModuleReminder> get reminders => _reminders;
  DateTime? get lastSyncAt => _lastSyncAt;
  Map<String, DateTime> get lastSeenByModule => _lastSeenByModule;

  NotificationPreferencesProvider() {
    _init();
  }

  Future<void> _init() async {
    await NotificationService.instance.initialize();
    await _loadLocal();
    await pullFromCloud();
    await _syncSchedules();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    final decoded = jsonDecode(raw);
    if (decoded is List) {
      _reminders = decoded
          .map((e) => ModuleReminder.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (decoded is Map<String, dynamic>) {
      _reminders = (decoded['reminders'] as List<dynamic>? ?? [])
          .map((e) => ModuleReminder.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final seen = Map<String, dynamic>.from(decoded['lastSeen'] ?? {});
      _lastSeenByModule = seen.map(
        (k, v) => MapEntry(k, DateTime.tryParse(v.toString()) ?? DateTime.now()),
      );
    }
    notifyListeners();
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'reminders': _reminders.map((e) => e.toJson()).toList(),
        'lastSeen': _lastSeenByModule.map((k, v) => MapEntry(k, v.toIso8601String())),
      }),
    );
  }

  Future<void> pullFromCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('notification_preferences')
        .get();

    if (!doc.exists) {
      await _pushToCloud();
      return;
    }

    final data = doc.data();
    final list = (data?['reminders'] as List<dynamic>? ?? [])
        .map((e) => ModuleReminder.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    if (list.isNotEmpty) {
      _reminders = list;
      _lastSyncAt = (data?['updatedAt'] as Timestamp?)?.toDate();
      final seenMap = Map<String, dynamic>.from(data?['lastSeenByModule'] ?? {});
      _lastSeenByModule = seenMap.map(
        (k, v) => MapEntry(
          k,
          v is Timestamp ? v.toDate() : (DateTime.tryParse(v.toString()) ?? DateTime.now()),
        ),
      );
      await _saveLocal();
      notifyListeners();
    }
  }

  Future<void> _pushToCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('notification_preferences')
        .set({
          'reminders': _reminders.map((e) => e.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastSeenByModule': _lastSeenByModule.map(
            (k, v) => MapEntry(k, Timestamp.fromDate(v)),
          ),
        }, SetOptions(merge: true));

    _lastSyncAt = DateTime.now();
    notifyListeners();
  }

  Future<void> updateReminder(String module, ModuleReminder updated) async {
    _reminders = _reminders.map((r) => r.module == module ? updated : r).toList();
    await _saveLocal();
    await _pushToCloud();
    await _syncSchedules();
    notifyListeners();
  }

  Future<void> _syncSchedules() async {
    for (int i = 0; i < _reminders.length; i++) {
      final reminder = _reminders[i];
      final baseId = 6000 + (i * 10);

      for (int j = 0; j < 8; j++) {
        await NotificationService.instance.cancel(baseId + j);
      }

      if (!reminder.enabled) continue;

      if (reminder.frequency == 'daily') {
        await NotificationService.instance.scheduleDailyReminder(
          id: baseId,
          title: 'ASCEND · ${reminder.module}',
          body: reminder.message,
          hour: reminder.hour,
          minute: reminder.minute,
        );
      } else {
        final weekdays = reminder.frequency == 'weekend' ? [6, 7] : [1, 2, 3, 4, 5];
        for (int w = 0; w < weekdays.length; w++) {
          await NotificationService.instance.scheduleWeeklyReminder(
            id: baseId + w,
            title: 'ASCEND · ${reminder.module}',
            body: reminder.message,
            weekday: weekdays[w],
            hour: reminder.hour,
            minute: reminder.minute,
          );
        }
      }
    }
  }


  Future<void> markModuleAsSeen(String module) async {
    _lastSeenByModule[module] = DateTime.now();
    await _saveLocal();
    await _pushToCloud();
    notifyListeners();
  }

  Future<void> testNotification(String module) async {
    final reminder = _reminders.firstWhere((r) => r.module == module);
    await NotificationService.instance.showInstant(
      id: 9000 + _reminders.indexOf(reminder),
      title: 'Prueba de notificación',
      body: '${reminder.module}: ${reminder.message}',
    );
  }
}
