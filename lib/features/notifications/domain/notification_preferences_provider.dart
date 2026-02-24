import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';

class ModuleReminder {
  final String module;
  final bool enabled;
  final int hour;
  final int minute;
  final String message;

  const ModuleReminder({
    required this.module,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.message,
  });

  ModuleReminder copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    String? message,
  }) {
    return ModuleReminder(
      module: module,
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toJson() => {
    'module': module,
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
    'message': message,
  };

  factory ModuleReminder.fromJson(Map<String, dynamic> json) {
    return ModuleReminder(
      module: json['module'] as String,
      enabled: json['enabled'] as bool? ?? false,
      hour: json['hour'] as int? ?? 20,
      minute: json['minute'] as int? ?? 0,
      message: json['message'] as String? ?? 'Revisá tu módulo en ASCEND',
    );
  }
}

class NotificationPreferencesProvider extends ChangeNotifier {
  static const _storageKey = 'ascend_module_reminders_v1';

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

  List<ModuleReminder> get reminders => _reminders;

  NotificationPreferencesProvider() {
    _init();
  }

  Future<void> _init() async {
    await NotificationService.instance.initialize();
    await _load();
    await _syncSchedules();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    final list = (jsonDecode(raw) as List)
        .map((e) => ModuleReminder.fromJson(e as Map<String, dynamic>))
        .toList();
    _reminders = list;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_reminders.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> updateReminder(String module, ModuleReminder updated) async {
    _reminders = _reminders.map((r) => r.module == module ? updated : r).toList();
    await _save();
    await _syncSchedules();
    notifyListeners();
  }

  Future<void> _syncSchedules() async {
    for (int i = 0; i < _reminders.length; i++) {
      final reminder = _reminders[i];
      final id = 6000 + i;
      await NotificationService.instance.cancel(id);
      if (reminder.enabled) {
        await NotificationService.instance.scheduleDailyReminder(
          id: id,
          title: 'ASCEND · ${reminder.module}',
          body: reminder.message,
          hour: reminder.hour,
          minute: reminder.minute,
        );
      }
    }
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
