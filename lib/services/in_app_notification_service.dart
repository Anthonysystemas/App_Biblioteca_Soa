// Archivo: services/in_app_notification_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Modelo de Notificación In-App
class InAppNotification {
  final String id;
  final String titulo;
  final String mensaje;
  final String tipo; // 'prestamo', 'reserva', 'devolucion', 'disponible'
  final DateTime fecha;
  final bool leida;
  final String? libroId;

  InAppNotification({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.fecha,
    this.leida = false,
    this.libroId,
  });

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id'],
      titulo: json['titulo'],
      mensaje: json['mensaje'],
      tipo: json['tipo'],
      fecha: DateTime.parse(json['fecha']),
      leida: json['leida'] ?? false,
      libroId: json['libroId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'fecha': fecha.toIso8601String(),
      'leida': leida,
      'libroId': libroId,
    };
  }

  InAppNotification copyWith({bool? leida}) {
    return InAppNotification(
      id: id,
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
      fecha: fecha,
      leida: leida ?? this.leida,
      libroId: libroId,
    );
  }
}

/// Servicio de Notificaciones In-App
class InAppNotificationService {
  static const String _notificationsKey = 'in_app_notifications';
  static final InAppNotificationService _instance = InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  // Listeners para actualizar la UI
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  /// Agregar notificación de préstamo exitoso
  Future<void> addPrestamoNotification(String libroTitulo, DateTime fechaDevolucion) async {
    final notification = InAppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: '✅ Préstamo Confirmado',
      mensaje: 'Has solicitado el préstamo de "$libroTitulo". Debes devolverlo antes del ${_formatDate(fechaDevolucion)}.',
      tipo: 'prestamo',
      fecha: DateTime.now(),
      leida: false,
    );
    
    await _saveNotification(notification);
    _notifyListeners();
  }

  /// Agregar notificación de reserva exitosa
  Future<void> addReservaNotification(String libroTitulo) async {
    final notification = InAppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: '📚 Reserva Creada',
      mensaje: 'Has reservado "$libroTitulo". Te avisaremos cuando esté disponible para préstamo.',
      tipo: 'reserva',
      fecha: DateTime.now(),
      leida: false,
    );
    
    await _saveNotification(notification);
    _notifyListeners();
  }

  /// Agregar notificación de reserva cancelada
  Future<void> addReservaCanceladaNotification(String libroTitulo) async {
    final notification = InAppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: '❌ Reserva Eliminada',
      mensaje: 'Has cancelado la reserva de "$libroTitulo".',
      tipo: 'reserva',
      fecha: DateTime.now(),
      leida: false,
    );
    
    await _saveNotification(notification);
    _notifyListeners();
  }

  /// Agregar notificación de libro disponible
  Future<void> addLibroDisponibleNotification(String libroTitulo, String libroId) async {
    final notification = InAppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: '🎉 Libro Disponible',
      mensaje: '"$libroTitulo" ya está disponible. ¡Puedes solicitar el préstamo ahora!',
      tipo: 'disponible',
      fecha: DateTime.now(),
      leida: false,
      libroId: libroId,
    );
    
    await _saveNotification(notification);
    _notifyListeners();
  }

  /// Agregar notificación de devolución próxima
  Future<void> addDevolucionProximaNotification(String libroTitulo, int diasRestantes) async {
    final emoji = diasRestantes == 0 ? '⚠️' : '⏰';
    final mensaje = diasRestantes == 0
        ? '¡Hoy es el último día para devolver "$libroTitulo"!'
        : diasRestantes == 1
            ? 'Mañana vence el préstamo de "$libroTitulo".'
            : 'Quedan $diasRestantes días para devolver "$libroTitulo".';
    
    final notification = InAppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: '$emoji Recordatorio de Devolución',
      mensaje: mensaje,
      tipo: 'devolucion',
      fecha: DateTime.now(),
      leida: false,
    );
    
    await _saveNotification(notification);
    _notifyListeners();
  }

  /// Obtener todas las notificaciones
  Future<List<InAppNotification>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);
    
    if (notificationsJson == null) return [];
    
    final List<dynamic> decoded = json.decode(notificationsJson);
    final notifications = decoded
        .map((json) => InAppNotification.fromJson(json))
        .toList();
    
    // Ordenar por fecha (más recientes primero)
    notifications.sort((a, b) => b.fecha.compareTo(a.fecha));
    
    return notifications;
  }

  /// Obtener notificaciones no leídas
  Future<List<InAppNotification>> getUnread() async {
    final all = await getAll();
    return all.where((n) => !n.leida).toList();
  }

  /// Contar notificaciones no leídas
  Future<int> getUnreadCount() async {
    final unread = await getUnread();
    return unread.length;
  }

  /// Marcar notificación como leída
  Future<void> markAsRead(String notificationId) async {
    final notifications = await getAll();
    final index = notifications.indexWhere((n) => n.id == notificationId);
    
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(leida: true);
      await _saveAll(notifications);
      _notifyListeners();
    }
  }

  /// Marcar todas como leídas
  Future<void> markAllAsRead() async {
    final notifications = await getAll();
    final updated = notifications.map((n) => n.copyWith(leida: true)).toList();
    await _saveAll(updated);
    _notifyListeners();
  }

  /// Eliminar notificación
  Future<void> delete(String notificationId) async {
    final notifications = await getAll();
    notifications.removeWhere((n) => n.id == notificationId);
    await _saveAll(notifications);
    _notifyListeners();
  }

  /// Eliminar todas las notificaciones
  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
    _notifyListeners();
  }

  // Métodos privados
  Future<void> _saveNotification(InAppNotification notification) async {
    final notifications = await getAll();
    notifications.insert(0, notification);
    
    // Mantener máximo 50 notificaciones
    if (notifications.length > 50) {
      notifications.removeRange(50, notifications.length);
    }
    
    await _saveAll(notifications);
  }

  Future<void> _saveAll(List<InAppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notifications.map((n) => n.toJson()).toList();
    await prefs.setString(_notificationsKey, json.encode(jsonList));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
