import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  String? id; // ID do documento no Firestore
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

  // Converter de Map (Firestore) para Reminder
  factory Reminder.fromMap(Map<String, dynamic> map, String documentId) {
    return Reminder(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      category: map['category'] ?? '',
      color: map['color'] ?? 0xFF4CAF50,
      isActive: map['isActive'] ?? true,
    );
  }

  // Converter de Reminder para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'category': category,
      'color': color,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Para atualização (não inclui createdAt novamente)
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'category': category,
      'color': color,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}