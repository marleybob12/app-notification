import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';
import '../database/database_service.dart';
import '../services/notification_service.dart';
import 'add_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Reminder> _reminders = [];
  bool _showOnlyActive = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // Carregar lembretes do banco de dados
  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reminders = _showOnlyActive
          ? await _databaseService.getActiveReminders()
          : await _databaseService.getAllReminders();

      if (mounted) {
        setState(() {
          _reminders = reminders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar lembretes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Lembretes'),
        actions: [
          // Filtro: Mostrar apenas ativos
          IconButton(
            icon: Icon(_showOnlyActive
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() {
                _showOnlyActive = !_showOnlyActive;
              });
              _loadReminders();
            },
            tooltip: _showOnlyActive ? 'Mostrar Todos' : 'Apenas Ativos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? _buildEmptyState()
              : _buildRemindersList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(null),
        tooltip: 'Adicionar Lembrete',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Estado vazio
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showOnlyActive ? Icons.check_circle_outline : Icons.event_note,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _showOnlyActive
                ? 'Nenhum lembrete ativo'
                : 'Nenhum lembrete cadastrado',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para adicionar',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Lista de lembretes
  Widget _buildRemindersList() {
    return ListView.builder(
      itemCount: _reminders.length,
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        return _buildReminderCard(reminder);
      },
    );
  }

  // Widget do card de lembrete
  Widget _buildReminderCard(Reminder reminder) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
    final timeFormat = DateFormat('HH:mm');
    final isPast = reminder.dateTime.isBefore(DateTime.now());

    return Dismissible(
      key: Key(reminder.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: const Text('Deseja realmente excluir este lembrete?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteReminder(reminder);
      },
      child: Card(
        color: Color(reminder.color).withOpacity(reminder.isActive ? 1.0 : 0.5),
        child: InkWell(
          onTap: () => _navigateToAddEdit(reminder),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: reminder.isActive
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    if (!reminder.isActive)
                      const Icon(Icons.check_circle, color: Colors.white70),
                    if (isPast && reminder.isActive)
                      const Icon(Icons.alarm_off, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reminder.description,
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(reminder.dateTime),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      timeFormat.format(reminder.dateTime),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reminder.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navegar para tela de adicionar/editar
  void _navigateToAddEdit(Reminder? reminder) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditScreen(reminder: reminder),
      ),
    );

    // Recarregar lista após adicionar/editar
    if (result == true) {
      _loadReminders();
    }
  }

  // Deletar lembrete
  Future<void> _deleteReminder(Reminder reminder) async {
    try {
      // Cancelar notificação
      await _notificationService.cancelNotification(reminder.id!);

      // Deletar do banco de dados
      await _databaseService.deleteReminder(reminder.id!);

      // Recarregar lista
      _loadReminders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lembrete excluído'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
