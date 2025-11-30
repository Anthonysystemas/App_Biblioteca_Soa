import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      _initialized = true;
      
      await _requestPermissions();
    } catch (e) {
      debugPrint('Error inicializando notificaciones: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
    } catch (e) {
      debugPrint('Error solicitando permisos de notificación: $e');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notificación tocada: ${response.payload}');
  }

  Future<void> notifyBookAvailable(String bookTitle) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'book_available',
        'Libros Disponibles',
        channelDescription: 'Notificaciones cuando un libro está disponible',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '📚 Libro Disponible',
        '"$bookTitle" ya está disponible para préstamo',
        details,
        payload: 'book_available',
      );
    } catch (e) {
      debugPrint('Error mostrando notificación: $e');
    }
  }

  Future<void> notifyReturnDue(String bookTitle, int daysLeft) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'return_due',
        'Devoluciones Pendientes',
        channelDescription: 'Recordatorios de devolución de libros',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final message = daysLeft == 0
          ? '¡Hoy es el último día para devolver "$bookTitle"!'
          : daysLeft == 1
              ? 'Mañana vence el préstamo de "$bookTitle"'
              : 'Quedan $daysLeft días para devolver "$bookTitle"';

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '⏰ Recordatorio de Devolución',
        message,
        details,
        payload: 'return_due',
      );
    } catch (e) {
      debugPrint('Error mostrando notificación: $e');
    }
  }

  Future<void> notifyReservationReady(String bookTitle) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'reservation_ready',
        'Reservas Listas',
        channelDescription: 'Notificaciones de reservas listas para recoger',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '🎉 Reserva Lista',
        '"$bookTitle" está listo para que lo recojas',
        details,
        payload: 'reservation_ready',
      );
    } catch (e) {
      debugPrint('Error mostrando notificación: $e');
    }
  }

  Future<void> notifyLoanSuccess(String bookTitle, DateTime dueDate) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'loan_success',
        'Préstamos',
        channelDescription: 'Confirmación de préstamos',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final dueDateStr = '${dueDate.day}/${dueDate.month}/${dueDate.year}';

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '✅ Préstamo Confirmado',
        '"$bookTitle" - Devolver antes del $dueDateStr',
        details,
        payload: 'loan_success',
      );
    } catch (e) {
      debugPrint('Error mostrando notificación: $e');
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}