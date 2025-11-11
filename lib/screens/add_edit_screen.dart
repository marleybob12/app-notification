import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';
import '../database/database_service.dart';
import '../services/notification_service.dart';

class AddEditScreen extends StatefulWidget {
  final Reminder? reminder;

  const AddEditScreen({super.key, this.reminder});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedCategory;
  late Color _selectedColor;
  late bool _isActive;

  bool _isLoading = false;

  // Categorias disponíveis
  final List<String> _categories = [
    'Trabalho',
    'Pessoal',
    'Estudos',
    'Saúde',
    'Compras',
    'Reunião',
    'Outro',
  ];

  // Cores disponíveis
  final List<Color> _colors = [
    const Color(0xFF4CAF50), // Verde
    const Color(0xFF2196F3), // Azul
    const Color(0xFFF44336), // Vermelho
    const Color(0xFFFF9800), // Laranja
    const Color(0xFF9C27B0), // Roxo
    const Color(0xFFE91E63), // Rosa
    const Color(0xFF009688), // Teal
    const Color(0xFF795548), // Marrom
  ];

  @override
  void initState() {
    super.initState();

    // Se estiver editando, carrega os dados
    if (widget.reminder != null) {
      _titleController = TextEditingController(text: widget.reminder!.title);
      _descriptionController =
          TextEditingController(text: widget.reminder!.description);
      _selectedDate = widget.reminder!.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.reminder!.dateTime);
      _selectedCategory = widget.reminder!.category;
      _selectedColor = Color(widget.reminder!.color);
      _isActive = widget.reminder!.isActive;
    } else {
      // Valores padrão para novo lembrete
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedDate = DateTime.now().add(const Duration(hours: 1));
      _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
      _selectedCategory = _categories[0];
      _selectedColor = _colors[0];
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reminder != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Lembrete' : 'Novo Lembrete'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
              tooltip: 'Excluir',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira um título';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Descrição
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Data
                    ListTile(
                      title: const Text('Data'),
                      subtitle: Text(
                          DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate)),
                      leading: const Icon(Icons.calendar_today),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 16),

                    // Hora
                    ListTile(
                      title: const Text('Hora'),
                      subtitle: Text(_selectedTime.format(context)),
                      leading: const Icon(Icons.access_time),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      onTap: _selectTime,
                    ),
                    const SizedBox(height: 16),

                    // Categoria
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Cor
                    const Text(
                      'Cor do Lembrete',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _colors.map((color) {
                        final isSelected = color == _selectedColor;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Ativo/Inativo
                    if (isEditing)
                      SwitchListTile(
                        title: const Text('Lembrete Ativo'),
                        subtitle: Text(_isActive
                            ? 'Notificações ativadas'
                            : 'Notificações desativadas'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                    const SizedBox(height: 24),

                    // Botão Salvar
                    ElevatedButton.icon(
                      onPressed: _saveReminder,
                      icon: const Icon(Icons.save),
                      label: Text(
                          isEditing ? 'Salvar Alterações' : 'Criar Lembrete'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Selecionar data
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  // Selecionar hora
  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null && mounted) {
      setState(() {
        _selectedTime = pickedTime;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  // Salvar lembrete
  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Criar objeto Reminder
      final reminder = Reminder(
        id: widget.reminder?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: _selectedDate,
        category: _selectedCategory,
        color: _selectedColor.value,
        isActive: _isActive,
      );

      int reminderId;

      if (widget.reminder == null) {
        // Criar novo lembrete
        reminderId = await _databaseService.insertReminder(reminder);
      } else {
        // Atualizar lembrete existente
        await _databaseService.updateReminder(reminder);
        reminderId = reminder.id!;
      }

      // Agendar/reagendar notificação se estiver ativo
      if (_isActive) {
        await _notificationService.scheduleNotification(
          id: reminderId,
          title: reminder.title,
          body: reminder.description,
          scheduledDate: reminder.dateTime,
        );
      } else {
        // Cancelar notificação se foi desativado
        await _notificationService.cancelNotification(reminderId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.reminder == null
                ? 'Lembrete criado com sucesso!'
                : 'Lembrete atualizado!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Confirmar exclusão
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente excluir este lembrete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _deleteReminder();
    }
  }

  // Deletar lembrete
  Future<void> _deleteReminder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cancelar notificação
      await _notificationService.cancelNotification(widget.reminder!.id!);

      // Deletar do banco de dados
      await _databaseService.deleteReminder(widget.reminder!.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lembrete excluído'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
