import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder_model.dart';

class DatabaseService {
  // Singleton Pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  // Getter para o banco de dados
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializar o banco de dados
  Future<Database> _initDatabase() async {
    // Obter o caminho do banco de dados
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'lembretes.db');

    // Abrir/criar o banco de dados
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Criar as tabelas do banco de dados
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        category TEXT NOT NULL,
        color INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  // ==================== OPERAÇÕES CRUD ====================

  // CREATE - Inserir um novo lembrete
  Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    try {
      final id = await db.insert(
        'reminders',
        reminder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Lembrete inserido com ID: $id');
      return id;
    } catch (e) {
      print('Erro ao inserir lembrete: $e');
      rethrow;
    }
  }

  // READ - Buscar todos os lembretes
  Future<List<Reminder>> getAllReminders() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'reminders',
        orderBy: 'dateTime ASC',
      );

      return List.generate(maps.length, (i) {
        return Reminder.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar lembretes: $e');
      return [];
    }
  }

  // READ - Buscar lembretes ativos
  Future<List<Reminder>> getActiveReminders() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'reminders',
        where: 'isActive = ?',
        whereArgs: [1],
        orderBy: 'dateTime ASC',
      );

      return List.generate(maps.length, (i) {
        return Reminder.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar lembretes ativos: $e');
      return [];
    }
  }

  // READ - Buscar um lembrete específico por ID
  Future<Reminder?> getReminderById(int id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'reminders',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Reminder.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar lembrete por ID: $e');
      return null;
    }
  }

  // READ - Buscar lembretes por categoria
  Future<List<Reminder>> getRemindersByCategory(String category) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'reminders',
        where: 'category = ? AND isActive = ?',
        whereArgs: [category, 1],
        orderBy: 'dateTime ASC',
      );

      return List.generate(maps.length, (i) {
        return Reminder.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar lembretes por categoria: $e');
      return [];
    }
  }

  // UPDATE - Atualizar um lembrete
  Future<int> updateReminder(Reminder reminder) async {
    final db = await database;
    try {
      final count = await db.update(
        'reminders',
        reminder.toMap(),
        where: 'id = ?',
        whereArgs: [reminder.id],
      );
      print('Lembrete atualizado: ${reminder.id}');
      return count;
    } catch (e) {
      print('Erro ao atualizar lembrete: $e');
      rethrow;
    }
  }

  // UPDATE - Marcar lembrete como inativo
  Future<int> deactivateReminder(int id) async {
    final db = await database;
    try {
      final count = await db.update(
        'reminders',
        {'isActive': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Lembrete desativado: $id');
      return count;
    } catch (e) {
      print('Erro ao desativar lembrete: $e');
      return 0;
    }
  }

  // DELETE - Deletar um lembrete
  Future<int> deleteReminder(int id) async {
    final db = await database;
    try {
      final count = await db.delete(
        'reminders',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Lembrete deletado: $id');
      return count;
    } catch (e) {
      print('Erro ao deletar lembrete: $e');
      return 0;
    }
  }

  // DELETE - Deletar todos os lembretes
  Future<int> deleteAllReminders() async {
    final db = await database;
    try {
      final count = await db.delete('reminders');
      print('Todos os lembretes deletados');
      return count;
    } catch (e) {
      print('Erro ao deletar todos os lembretes: $e');
      return 0;
    }
  }

  // Buscar todas as categorias únicas
  Future<List<String>> getAllCategories() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'reminders',
        columns: ['category'],
        distinct: true,
      );

      return maps.map((map) => map['category'] as String).toList()..sort();
    } catch (e) {
      print('Erro ao buscar categorias: $e');
      return [];
    }
  }

  // Fechar o banco de dados
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
