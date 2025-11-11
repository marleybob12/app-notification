class Reminder {
  int? id;
  String title;
  String description;
  DateTime dateTime;
  String category;
  int color; // Armazenado como ARGB
  bool isActive;

  Reminder({
    this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.category,
    required this.color,
    this.isActive = true,
  });

  // Converter de Map (SQLite) para Reminder
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      category: map['category'] as String,
      color: map['color'] as int,
      isActive: (map['isActive'] as int) == 1,
    );
  }

  // Converter de Reminder para Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'category': category,
      'color': color,
      'isActive': isActive ? 1 : 0,
    };
  }

  // Para depuração
  @override
  String toString() {
    return 'Reminder{id: $id, title: $title, dateTime: $dateTime, isActive: $isActive}';
  }
}
