import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'in_app_notification_service.dart';
import 'stock_service.dart';

/// Modelo de Reserva
class Reserva {
  final String id;
  final String libroId;
  final String titulo;
  final String autor;
  final String? thumbnail;
  final DateTime fechaReserva;
  final int posicionCola;
  final String estado; // 'pendiente', 'disponible', 'cancelada', 'completada'
  final DateTime? fechaDisponible;

  Reserva({
    required this.id,
    required this.libroId,
    required this.titulo,
    required this.autor,
    this.thumbnail,
    required this.fechaReserva,
    required this.posicionCola,
    required this.estado,
    this.fechaDisponible,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'],
      libroId: json['libroId'],
      titulo: json['titulo'],
      autor: json['autor'],
      thumbnail: json['thumbnail'],
      fechaReserva: DateTime.parse(json['fechaReserva']),
      posicionCola: json['posicionCola'],
      estado: json['estado'],
      fechaDisponible: json['fechaDisponible'] != null 
          ? DateTime.parse(json['fechaDisponible']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libroId': libroId,
      'titulo': titulo,
      'autor': autor,
      'thumbnail': thumbnail,
      'fechaReserva': fechaReserva.toIso8601String(),
      'posicionCola': posicionCola,
      'estado': estado,
      'fechaDisponible': fechaDisponible?.toIso8601String(),
    };
  }

  String get disponibleEn {
    if (fechaDisponible != null) {
      final dias = fechaDisponible!.difference(DateTime.now()).inDays;
      if (dias <= 0) return 'Disponible ahora';
      if (dias == 1) return '1 día';
      return '$dias días';
    }
    return 'Por determinar';
  }
}

/// Servicio de Reservas
class ReservasService {
  // TODO: Reemplazar con tu URL del backend
  static const String baseUrl = 'https://tu-api.com/api';
  static const String _reservasKey = 'user_reservas';

  // TODO: Reemplazar con llamada al backend
  /// GET /api/reservas/activas
  static Future<List<Reserva>> getReservasActivas() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final prefs = await SharedPreferences.getInstance();
    final reservasJson = prefs.getString(_reservasKey);
    
    if (reservasJson == null) return [];
    
    final List<dynamic> decoded = json.decode(reservasJson);
    final reservas = decoded
        .map((json) => Reserva.fromJson(json))
        .where((r) => r.estado == 'pendiente' || r.estado == 'disponible')
        .toList();
    
    return reservas;
  }

  // TODO: Reemplazar con llamada al backend
  /// POST /api/reservas/crear
  static Future<bool> crearReserva(String libroId, {String? titulo, String? autor, String? thumbnail}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // VERIFICAR: No se puede reservar si ya tienes un préstamo activo del mismo libro
      final prestamosJson = prefs.getString('user_prestamos');
      if (prestamosJson != null) {
        final List<dynamic> decodedPrestamos = json.decode(prestamosJson);
        final tienePrestamo = decodedPrestamos.any((p) => 
          p['libroId'] == libroId && 
          (p['estado'] == 'activo' || p['estado'] == 'renovado')
        );
        
        if (tienePrestamo) {
          return false; // Ya tienes este libro prestado
        }
      }
      
      // Verificar si ya existe una reserva activa del mismo libro
      final reservasJson = prefs.getString(_reservasKey);
      
      List<Map<String, dynamic>> reservas = [];
      if (reservasJson != null) {
        final List<dynamic> decoded = json.decode(reservasJson);
        reservas = decoded.cast<Map<String, dynamic>>();
      }
      
      final yaExisteReserva = reservas.any((r) => 
        r['libroId'] == libroId && 
        (r['estado'] == 'pendiente' || r['estado'] == 'disponible')
      );
      
      if (yaExisteReserva) {
        return false; // Ya existe una reserva activa
      }
      
      final nuevaReserva = Reserva(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        libroId: libroId,
        titulo: titulo ?? 'Libro sin título',
        autor: autor ?? 'Autor desconocido',
        thumbnail: thumbnail,
        fechaReserva: DateTime.now(),
        posicionCola: 1,
        estado: 'pendiente',
        fechaDisponible: DateTime.now().add(const Duration(days: 7)),
      );
      
      reservas.add(nuevaReserva.toJson());
      await prefs.setString(_reservasKey, json.encode(reservas));
      
      // Notificación in-app de reserva creada
      await InAppNotificationService().addReservaNotification(nuevaReserva.titulo);
      
      // Simular que la reserva estará lista en 7 días
      // En producción, esto vendría del backend cuando el libro esté disponible
      if (nuevaReserva.posicionCola == 1) {
        // Si eres el primero en la cola, notificamos cuando esté disponible
        try {
          await NotificationService().notifyBookAvailable(nuevaReserva.titulo);
        } catch (notifError) {
          // Ignorar errores de notificaciones (no disponibles en Windows)
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error al crear reserva: $e');
      return false;
    }
  }

  // TODO: Reemplazar con llamada  /// Cancelar una reserva
  /// DELETE /api/reservas/{id}
  static Future<bool> cancelarReserva(String reservaId) async {
    try {
      // TODO: Reemplazar con llamada al backend
      
      final prefs = await SharedPreferences.getInstance();
      final reservasJson = prefs.getString(_reservasKey);
      
      if (reservasJson == null) return false;
      
      final List<dynamic> decoded = json.decode(reservasJson);
      List<Map<String, dynamic>> reservas = decoded.cast<Map<String, dynamic>>();
      
      // Encontrar la reserva para obtener el título y libroId
      final reserva = reservas.firstWhere(
        (r) => r['id'] == reservaId,
        orElse: () => {},
      );
      
      final titulo = reserva['titulo'] ?? 'libro';
      final libroId = reserva['libroId'];
      
      reservas.removeWhere((r) => r['id'] == reservaId);
      
      await prefs.setString(_reservasKey, json.encode(reservas));
      
      // Aumentar stock (+1) cuando se cancela la reserva
      if (libroId != null) {
        await StockService.actualizarStockLocal(libroId, 1);
      }
      
      // Notificación in-app de reserva cancelada
      await InAppNotificationService().addReservaCanceladaNotification(titulo);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cancelar reserva por ID del libro (usado cuando se solicita préstamo)
  static Future<void> cancelarReservaPorLibroId(String libroId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservasJson = prefs.getString(_reservasKey);
      
      if (reservasJson == null) return;
      
      final List<dynamic> decoded = json.decode(reservasJson);
      List<Map<String, dynamic>> reservas = decoded.cast<Map<String, dynamic>>();
      
      // Eliminar todas las reservas del libro
      reservas.removeWhere((r) => r['libroId'] == libroId);
      
      await prefs.setString(_reservasKey, json.encode(reservas));
    } catch (e) {
      // Silenciar errores
    }
  }

  // TODO: Reemplazar con llamada al backend
  /// GET /api/libros/{id}/disponibilidad
  static Future<Map<String, dynamic>> verificarDisponibilidad(String libroId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // MOCK - Retorna disponibilidad del libro
    return {
      'disponible': false,
      'copiasTotales': 3,
      'copiasDisponibles': 0,
      'reservasActivas': 2,
      'fechaEstimada': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    };
  }

  /// Limpia datos locales
  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reservasKey);
  }
}
