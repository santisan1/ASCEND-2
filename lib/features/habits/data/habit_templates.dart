import 'package:ascend/features/habits/domain/habit_model.dart';

class HabitTemplates {
  static final List<Habit> templates = [
    // PRODUCTIVIDAD
    Habit(
      id: 'template_morning_routine',
      userId: 'template',
      name: 'Rutina Matutina',
      description: 'Planificar el día y prepararte mentalmente',
      icon: 'wb_sunny',
      category: HabitCategory.productividad,
      frequency: [1, 2, 3, 4, 5, 6, 7],
      trigger: HabitTrigger.morning,
      priority: HabitPriority.high,
      difficulty: 2,
      impact: 5,
      targetDays: 30,
      tags: ['productividad', 'mañana'],
      isTemplate: true,
      templateId: 'morning_routine',
      createdAt: DateTime.now(),
    ),

    Habit(
      id: 'template_review_day',
      userId: 'template',
      name: 'Revisión del Día',
      description: 'Reflexionar sobre logros y aprendizajes',
      icon: 'event_note',
      category: HabitCategory.productividad,
      frequency: [1, 2, 3, 4, 5, 6, 7],
      trigger: HabitTrigger.evening,
      priority: HabitPriority.medium,
      difficulty: 2,
      impact: 4,
      targetDays: 21,
      tags: ['productividad', 'reflexión'],
      isTemplate: true,
      templateId: 'review_day',
      createdAt: DateTime.now(),
    ),

    // SALUD
    Habit(
      id: 'template_exercise',
      userId: 'template',
      name: 'Ejercicio 30 min',
      description: 'Actividad física moderada',
      icon: 'directions_run',
      category: HabitCategory.salud,
      frequency: [1, 3, 5],
      trigger: HabitTrigger.morning,
      priority: HabitPriority.high,
      difficulty: 3,
      impact: 5,
      targetDays: 30,
      tags: ['salud', 'ejercicio'],
      isTemplate: true,
      templateId: 'exercise',
      createdAt: DateTime.now(),
    ),

    Habit(
      id: 'template_water',
      userId: 'template',
      name: 'Tomar 2L de agua',
      description: 'Mantener hidratación durante el día',
      icon: 'water_drop',
      category: HabitCategory.salud,
      frequency: [1, 2, 3, 4, 5, 6, 7],
      trigger: HabitTrigger.anytime,
      priority: HabitPriority.medium,
      difficulty: 2,
      impact: 4,
      targetDays: 21,
      tags: ['salud', 'hidratación'],
      isTemplate: true,
      templateId: 'water',
      createdAt: DateTime.now(),
    ),

    // BIENESTAR
    Habit(
      id: 'template_meditation',
      userId: 'template',
      name: 'Meditar 10 min',
      description: 'Práctica de mindfulness',
      icon: 'self_improvement',
      category: HabitCategory.bienestar,
      frequency: [1, 2, 3, 4, 5, 6, 7],
      trigger: HabitTrigger.morning,
      priority: HabitPriority.high,
      difficulty: 2,
      impact: 5,
      targetDays: 21,
      tags: ['bienestar', 'meditación'],
      isTemplate: true,
      templateId: 'meditation',
      createdAt: DateTime.now(),
    ),

    Habit(
      id: 'template_reading',
      userId: 'template',
      name: 'Leer 20 minutos',
      description: 'Lectura recreativa o educativa',
      icon: 'menu_book',
      category: HabitCategory.aprendizaje,
      frequency: [1, 2, 3, 4, 5, 6, 7],
      trigger: HabitTrigger.evening,
      priority: HabitPriority.medium,
      difficulty: 2,
      impact: 4,
      targetDays: 30,
      tags: ['aprendizaje', 'lectura'],
      isTemplate: true,
      templateId: 'reading',
      createdAt: DateTime.now(),
    ),

    // SOCIAL
    Habit(
      id: 'template_family_time',
      userId: 'template',
      name: 'Tiempo en Familia',
      description: 'Conexión con seres queridos',
      icon: 'family_restroom',
      category: HabitCategory.familia,
      frequency: [6, 7],
      trigger: HabitTrigger.afternoon,
      priority: HabitPriority.high,
      difficulty: 2,
      impact: 5,
      targetDays: 8,
      tags: ['familia', 'social'],
      isTemplate: true,
      templateId: 'family_time',
      createdAt: DateTime.now(),
    ),

    // HOGAR
    Habit(
      id: 'template_clean',
      userId: 'template',
      name: 'Orden 15 min',
      description: 'Mantener espacios limpios',
      icon: 'cleaning_services',
      category: HabitCategory.hogar,
      frequency: [1, 3, 5],
      trigger: HabitTrigger.evening,
      priority: HabitPriority.low,
      difficulty: 1,
      impact: 3,
      targetDays: 14,
      tags: ['hogar', 'limpieza'],
      isTemplate: true,
      templateId: 'clean',
      createdAt: DateTime.now(),
    ),

    // FINANZAS
    Habit(
      id: 'template_track_expenses',
      userId: 'template',
      name: 'Registrar Gastos',
      description: 'Anotar gastos del día',
      icon: 'receipt',
      category: HabitCategory.finanzas,
      frequency: [1, 2, 3, 4, 5, 6, 7],
      trigger: HabitTrigger.evening,
      priority: HabitPriority.medium,
      difficulty: 1,
      impact: 4,
      targetDays: 30,
      tags: ['finanzas', 'control'],
      isTemplate: true,
      templateId: 'track_expenses',
      createdAt: DateTime.now(),
    ),
  ];

  static Habit createFromTemplate(Habit template, String userId) {
    return Habit(
      id: '', // Se genera al guardar
      userId: userId,
      name: template.name,
      description: template.description,
      icon: template.icon,
      category: template.category,
      frequency: List.from(template.frequency),
      trigger: template.trigger,
      priority: template.priority,
      difficulty: template.difficulty,
      impact: template.impact,
      targetDays: template.targetDays,
      tags: List.from(template.tags),
      isTemplate: false,
      templateId: template.templateId,
      createdAt: DateTime.now(),
    );
  }

  static List<Habit> getByCategory(HabitCategory category) {
    return templates.where((t) => t.category == category).toList();
  }

  static List<Habit> getByTrigger(HabitTrigger trigger) {
    return templates.where((t) => t.trigger == trigger).toList();
  }
}
