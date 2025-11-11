import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  // Inicializar o serviço de notificações
  Future<void> init() async {
    // Configurações para Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configurações para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configurações gerais
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Criar canal de notificação para Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    // Solicitar permissões
    await _requestPermissions();
  }

  // Criar canal de notificação (Android)
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'lembretes_channel',
      'Lembretes',
      description: 'Canal para notificações de lembretes',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Solicitar permissões
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ requer permissão explícita para notificações
      final status = await Permission.notification.request();

      if (status.isDenied) {
        print('Permissão de notificação negada');
      }

      // Solicitar permissão para alarmes exatos (Android 12+)
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // Agendar notificação
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      // Converter ID string para int (usando hashCode)
      final notificationId = id.hashCode;

      // Verificar se a data está no futuro
      if (scheduledDate.isBefore(DateTime.now())) {
        print('Data de agendamento está no passado');
        return;
      }

      // Converter para timezone
      final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);

      // Detalhes da notificação para Android
      const androidDetails = AndroidNotificationDetails(
        'lembretes_channel',
        'Lembretes',
        channelDescription: 'Canal para notificações de lembretes',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      // Detalhes da notificação para iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Detalhes gerais
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Agendar notificação
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTZ,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('Notificação agendada para: $scheduledTZ');
    } catch (e) {
      print('Erro ao agendar notificação: $e');
    }
  }

  // Cancelar notificação específica
  Future<void> cancelNotification(String id) async {
    try {
      final notificationId = id.hashCode;
      await _notifications.cancel(notificationId);
      print('Notificação cancelada: $id');
    } catch (e) {
      print('Erro ao cancelar notificação: $e');
    }
  }

  // Cancelar todas as notificações
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('Todas as notificações canceladas');
    } catch (e) {
      print('Erro ao cancelar todas as notificações: $e');
    }
  }

  // Mostrar notificação imediata
  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
  }) async {
    try {
      final notificationId = id.hashCode;

      const androidDetails = AndroidNotificationDetails(
        'lembretes_channel',
        'Lembretes',
        channelDescription: 'Canal para notificações de lembretes',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      print('Erro ao mostrar notificação: $e');
    }
  }

  // Callback quando notificação é tocada
  void _onNotificationTap(NotificationResponse response) {
    print('Notificação tocada: ${response.payload}');
    // Aqui você pode navegar para uma tela específica ou realizar alguma ação
  }

  // Verificar se há notificações pendentes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}