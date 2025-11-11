import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reminder_model.dart';

class FirestoreService {
  // Singleton Pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Referência à coleção de lembretes do usuário atual
  CollectionReference get _remindersCollection {
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    return _firestore.collection('users').doc(userId).collection('reminders');
  }

  // Garantir que o usuário esteja autenticado anonimamente
  Future<void> ensureAuthenticated() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // Criar um novo lembrete
  Future<String?> createReminder(Reminder reminder) async {
    try {
      await ensureAuthenticated();
      final docRef = await _remindersCollection.add(reminder.toMap());
      return docRef.id;
    } catch (e) {
      print('Erro ao criar lembrete: $e');
      return null;
    }
  }

  // Buscar todos os lembretes (Stream para atualizações em tempo real)
  Stream<List<Reminder>> getAllReminders() {
    return _remindersCollection
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Reminder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Buscar apenas lembretes ativos (Stream)
  Stream<List<Reminder>> getActiveReminders() {
    return _remindersCollection
        .where('isActive', isEqualTo: true)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Reminder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Buscar um lembrete específico
  Future<Reminder?> getReminderById(String id) async {
    try {
      final doc = await _remindersCollection.doc(id).get();
      if (doc.exists) {
        return Reminder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar lembrete: $e');
      return null;
    }
  }

  // Atualizar um lembrete
  Future<bool> updateReminder(Reminder reminder) async {
    try {
      if (reminder.id == null) return false;
      await _remindersCollection.doc(reminder.id).update(reminder.toUpdateMap());
      return true;
    } catch (e) {
      print('Erro ao atualizar lembrete: $e');
      return false;
    }
  }

  // Deletar um lembrete
  Future<bool> deleteReminder(String id) async {
    try {
      await _remindersCollection.doc(id).delete();
      return true;
    } catch (e) {
      print('Erro ao deletar lembrete: $e');
      return false;
    }
  }

  // Marcar lembrete como inativo (sem deletar)
  Future<bool> deactivateReminder(String id) async {
    try {
      await _remindersCollection.doc(id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erro ao desativar lembrete: $e');
      return false;
    }
  }

  // Buscar lembretes por categoria
  Stream<List<Reminder>> getRemindersByCategory(String category) {
    return _remindersCollection
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Reminder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Buscar todas as categorias únicas
  Future<List<String>> getAllCategories() async {
    try {
      final snapshot = await _remindersCollection.get();
      final categories = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['category'] != null) {
          categories.add(data['category']);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      print('Erro ao buscar categorias: $e');
      return [];
    }
  }
}