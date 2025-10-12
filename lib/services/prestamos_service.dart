import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'in_app_notification_service.dart';
import 'reservas_service.dart';
import 'stock_service.dart';

/// Modelo de Préstamo
class Prestamo {
  final String id;
  final String libroId;
  final String titulo;
  final String autor;
  final String? thumbnail;
  final DateTime fechaPrestamo;
  final DateTime fechaDevolucion;
  final String estado; // 'activo', 'vencido', 'renovado', 'devuelto'
  final int renovaciones;

  Prestamo({
    required this.id,
    required this.libroId,
    required this.titulo,
    required this.autor,
    this.thumbnail,
    required this.fechaPrestamo,
    required this.fechaDevolucion,
    required this.estado,
    this.renovaciones = 0,
  });

  factory Prestamo.fromJson(Map<String, dynamic> json) {
    return Prestamo(
      id: json['id'],
      libroId: json['libroId'],
      titulo: json['titulo'],
      autor: json['autor'],
      thumbnail: json['thumbnail'],
      fechaPrestamo: DateTime.parse(json['fechaPrestamo']),
      fechaDevolucion: DateTime.parse(json['fechaDevolucion']),
      estado: json['estado'],
      renovaciones: json['renovaciones'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libroId': libroId,
      'titulo': titulo,
      'autor': autor,
      'thumbnail': thumbnail,
      'fechaPrestamo': fechaPrestamo.toIso8601String(),
      'fechaDevolucion': fechaDevolucion.toIso8601String(),
      'estado': estado,
      'renovaciones': renovaciones,
    };
  }

  int get diasRestantes {
    final hoy = DateTime.now();
    return fechaDevolucion.difference(hoy).inDays;
  }

  bool get isVencido => diasRestantes < 0;
}

/// Servicio de Préstamos
class PrestamosService {
  // TODO: Reemplazar con tu URL del backend
  static const String baseUrl = 'https://tu-api.com/api';
  static const String _prestamosKey = 'user_prestamos';

  // TODO: Reemplazar con llamada al backend
  /// GET /api/prestamos/activos
  static Future<List<Prestamo>> getPrestamosActivos() async {
    // MOCK - Datos temporales
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Por ahora usa SharedPreferences local
    final prefs = await SharedPreferences.getInstance();
    final prestamosJson = prefs.getString(_prestamosKey);
    
    if (prestamosJson == null) return [];
    
    final List<dynamic> decoded = json.decode(prestamosJson);
    final prestamos = decoded
        .map((json) => Prestamo.fromJson(json))
        .where((p) => p.estado == 'activo' || p.estado == 'vencido')
        .toList();
    
    return prestamos;
  }

  // TODO: Reemplazar con llamada al backend
  /// GET /api/prestamos/historial
  static Future<List<Prestamo>> getHistorial() async {
    // TODO: Reemplazar con llamada al backend
    
    final prefs = await SharedPreferences.getInstance();
    final prestamosJson = prefs.getString(_prestamosKey);
    
    if (prestamosJson == null) return [];
    
    final List<dynamic> decoded = json.decode(prestamosJson);
    final historial = decoded
        .map((json) => Prestamo.fromJson(json))
        .where((p) => p.estado == 'devuelto')
        .toList();
    
    return historial;
  }

  // TODO: Reemplazar con llamada al backend
  /// POST /api/prestamos/solicitar
  static Future<bool> solicitarPrestamo(String libroId, {String? titulo, String? autor, String? thumbnail}) async {
    try {
      // TODO: Reemplazar con llamada al backend
      // final response = await http.post('$baseUrl/prestamos/solicitar', body: {'libro_id': libroId});
      
      // Por ahora guarda localmente
      final prefs = await SharedPreferences.getInstance();
      final prestamosJson = prefs.getString(_prestamosKey);
      
      List<Map<String, dynamic>> prestamos = [];
      if (prestamosJson != null) {
        final List<dynamic> decoded = json.decode(prestamosJson);
        prestamos = decoded.cast<Map<String, dynamic>>();
      }
      
      // Verificar si ya existe un préstamo activo del mismo libro
      final yaExiste = prestamos.any((p) => 
        p['libroId'] == libroId && 
        (p['estado'] == 'activo' || p['estado'] == 'renovado')
      );
      
      if (yaExiste) {
        return false; // Ya existe un préstamo activo
      }
      
      // VERIFICAR: No se puede prestar si ya tienes una reserva activa del mismo libro
      final reservasJson = prefs.getString('user_reservas');
      if (reservasJson != null) {
        final List<dynamic> decodedReservas = json.decode(reservasJson);
        final tieneReserva = decodedReservas.any((r) => 
          r['libroId'] == libroId && 
          (r['estado'] == 'pendiente' || r['estado'] == 'disponible')
        );
        
        if (tieneReserva) {
          return false; // Ya tienes este libro reservado
        }
      }
      
      // Crear nuevo préstamo
      final nuevoPrestamo = Prestamo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        libroId: libroId,
        titulo: titulo ?? 'Libro sin título',
        autor: autor ?? 'Autor desconocido',
        thumbnail: thumbnail,
        fechaPrestamo: DateTime.now(),
        fechaDevolucion: DateTime.now().add(const Duration(days: 14)),
        estado: 'activo',
        renovaciones: 0,
      );
      
      prestamos.add(nuevoPrestamo.toJson());
      await prefs.setString(_prestamosKey, json.encode(prestamos));
      
      // Si había una reserva del mismo libro, eliminarla
      await ReservasService.cancelarReservaPorLibroId(libroId);
      
      // Enviar notificación de préstamo exitoso
      try {
        await NotificationService().notifyLoanSuccess(
          nuevoPrestamo.titulo,
          nuevoPrestamo.fechaDevolucion,
        );
      } catch (notifError) {
        // Ignorar errores de notificaciones (no disponibles en Windows)
      }
      
      // Agregar notificación in-app
      await InAppNotificationService().addPrestamoNotification(
        nuevoPrestamo.titulo,
        nuevoPrestamo.fechaDevolucion,
      );
      
      return true;
    } catch (e) {
      debugPrint('Error al solicitar préstamo: $e');
      return false;
    }
  }

  // TODO: Reemplazar con llamada al backend
  /// POST /api/prestamos/{id}/renovar
  static Future<bool> renovarPrestamo(String prestamoId) async {
    try {
      // TODO: Reemplazar con llamada al backend
      
      final prefs = await SharedPreferences.getInstance();
      final prestamosJson = prefs.getString(_prestamosKey);
      
      if (prestamosJson == null) return false;
      
      final List<dynamic> decoded = json.decode(prestamosJson);
      List<Map<String, dynamic>> prestamos = decoded.cast<Map<String, dynamic>>();
      
      // Buscar y renovar el préstamo
      for (var i = 0; i < prestamos.length; i++) {
        if (prestamos[i]['id'] == prestamoId) {
          final renovaciones = (prestamos[i]['renovaciones'] as int? ?? 0);
          if (renovaciones >= 1) return false; // Máximo 1 renovación
          
          prestamos[i]['fechaDevolucion'] = DateTime.parse(prestamos[i]['fechaDevolucion'])
              .add(const Duration(days: 14))
              .toIso8601String();
          prestamos[i]['renovaciones'] = renovaciones + 1;
          prestamos[i]['estado'] = 'renovado';
          break;
        }
      }
      
      await prefs.setString(_prestamosKey, json.encode(prestamos));
      return true;
    } catch (e) {
      return false;
    }
  }

  // TODO: Reemplazar con llamada al backend
  /// POST /api/prestamos/{id}/devolver
  static Future<bool> devolverLibro(String prestamoId) async {
    try {
      // TODO: Reemplazar con llamada al backend
      
      final prefs = await SharedPreferences.getInstance();
      final prestamosJson = prefs.getString(_prestamosKey);
      
      if (prestamosJson == null) return false;
      
      final List<dynamic> decoded = json.decode(prestamosJson);
      List<Map<String, dynamic>> prestamos = decoded.cast<Map<String, dynamic>>();
      
      // Buscar y marcar como devuelto
      bool found = false;
      String? libroId;
      for (var i = 0; i < prestamos.length; i++) {
        if (prestamos[i]['id'] == prestamoId) {
          prestamos[i]['estado'] = 'devuelto';
          prestamos[i]['fechaDevolucion'] = DateTime.now().toIso8601String();
          libroId = prestamos[i]['libroId'];
          found = true;
          break;
        }
      }
      
      if (!found) return false;
      
      await prefs.setString(_prestamosKey, json.encode(prestamos));
      
      // Aumentar stock (+1) cuando se devuelve el libro
      if (libroId != null) {
        await StockService.actualizarStockLocal(libroId, 1);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error al devolver libro: $e');
      return false;
    }
  }

  /// Verifica préstamos próximos a vencer y envía notificaciones
  static Future<void> checkAndNotifyDueDates() async {
    try {
      final prestamos = await getPrestamosActivos();
      final now = DateTime.now();
      
      for (final prestamo in prestamos) {
        final daysLeft = prestamo.fechaDevolucion.difference(now).inDays;
        
        // Notificar si quedan 3 días, 1 día o el mismo día
        if (daysLeft >= 0 && daysLeft <= 3) {
          await NotificationService().notifyReturnDue(
            prestamo.titulo,
            daysLeft,
          );
        }
      }
    } catch (e) {
      // Silenciar errores
    }
  }

  /// Limpia datos locales (solo para desarrollo)
  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prestamosKey);
  }
}
