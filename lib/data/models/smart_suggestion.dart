// data/models/smart_suggestion.dart
enum SuggestionType { pantry, finance, habit, social, academy, household }

class SmartSuggestion {
  final String id;
  final String title;
  final String description;
  final SuggestionType type;
  final String action;
  final String actionRoute;
  final DateTime createdAt;

  SmartSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.action,
    required this.actionRoute,
    required this.createdAt,
  });
}
