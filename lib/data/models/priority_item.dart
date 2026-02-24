// data/models/priority_item.dart
class PriorityItem {
  final String id;
  final String title;
  final String module;
  final DateTime deadline;
  final PriorityLevel priority;
  final bool isCompleted;

  PriorityItem({
    required this.id,
    required this.title,
    required this.module,
    required this.deadline,
    required this.priority,
    this.isCompleted = false,
  });
}

enum PriorityLevel { high, medium, low }
