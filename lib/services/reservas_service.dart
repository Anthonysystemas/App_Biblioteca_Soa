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
    final prefs = await SharedPreferences.getInstance();
    
    // Obtener reservas existentes
    final reservasJson = prefs.getString(_reservasKey);
    
    List<Map<String, dynamic>> reservas = [];
    if (reservasJson != null) {
      final List<dynamic> decoded = json.decode(reservasJson);
      reservas = decoded.cast<Map<String, dynamic>>();
    }
    
    // VALIDACIÓN 1: Máximo 3 en lista de espera (VERIFICAR PRIMERO)
    final reservasActivas = reservas.where((r) => 
      r['estado'] == 'pendiente' || r['estado'] == 'disponible'
    ).length;
    
    debugPrint('🔍 Reservas activas: $reservasActivas/3');
    debugPrint('🔍 Intentando reservar libro ID: $libroId');
    
    // PRIMERO: Verificar límite de reservas
    if (reservasActivas >= 3) {
      debugPrint('❌ LÍMITE ALCANZADO: Ya tienes $reservasActivas/3 en lista de espera');
      throw Exception('LIMITE_RESERVAS');
    }
    
    // VALIDACIÓN 2: No se puede reservar si ya tienes un préstamo activo del mismo libro
    final prestamosJson = prefs.getString('user_prestamos');
    if (prestamosJson != null) {
      final List<dynamic> decodedPrestamos = json.decode(prestamosJson);
      final tienePrestamo = decodedPrestamos.any((p) => 
        p['libroId'] == libroId && 
        (p['estado'] == 'activo' || p['estado'] == 'renovado')
      );
      
      if (tienePrestamo) {
        debugPrint('❌ YA PRESTADO: Este libro ya está en préstamo activo');
        throw Exception('LIBRO_YA_PRESTADO');
      }
    }
    
    // VALIDACIÓN 3: Verificar si ya existe una reserva activa del mismo libro
    final yaExisteReserva = reservas.any((r) => 
      r['libroId'] == libroId && 
      (r['estado'] == 'pendiente' || r['estado'] == 'disponible')
    );
    
    if (yaExisteReserva) {
      debugPrint('❌ DUPLICADO: Este libro ya está en tu lista de espera');
      throw Exception('LIBRO_YA_RESERVADO');
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
    try {
      await InAppNotificationService().addReservaNotification(nuevaReserva.titulo);
    } catch (e) {
      debugPrint('Error en notificación in-app: $e');
    }
    
    // Simular que la reserva estará lista en 7 días
    // En producción, esto vendría del backend cuando el libro esté disponible
    if (nuevaReserva.posicionCola == 1) {
      // Si eres el primero en la cola, notificamos cuando esté disponible
      try {
        await NotificationService().notifyBookAvailable(nuevaReserva.titulo);
      } catch (notifError) {
        // Ignorar errores de notificaciones (no disponibles en Windows)
        debugPrint('Notificación no enviada (no disponible): $notifError');
      }
    }
    
    return true;
  }

  // TODO: Reemplazar con llamada  /// Cancelar un item de la lista de espera
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

  /// Cancelar item de lista de espera por ID del libro (usado cuando se solicita préstamo)
  static Future<void> cancelarReservaPorLibroId(String libroId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservasJson = prefs.getString(_reservasKey);
      
      if (reservasJson == null) return;
      
      final List<dynamic> decoded = json.decode(reservasJson);
      List<Map<String, dynamic>> reservas = decoded.cast<Map<String, dynamic>>();
      
      // Eliminar todos los items de lista de espera del libro
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

  /// Marcar reserva como lista para recoger (biblioteca marca el libro como disponible)
  static Future<bool> marcarComoLista(String reservaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservasJson = prefs.getString(_reservasKey);
      
      if (reservasJson == null) return false;
      
      final List<dynamic> decoded = json.decode(reservasJson);
      List<Map<String, dynamic>> reservas = decoded.cast<Map<String, dynamic>>();
      
      // Buscar y marcar como disponible
      bool found = false;
      String? titulo;
      
      for (var i = 0; i < reservas.length; i++) {
        if (reservas[i]['id'] == reservaId && reservas[i]['estado'] == 'pendiente') {
          reservas[i]['estado'] = 'disponible';
          reservas[i]['fechaDisponible'] = DateTime.now().add(const Duration(days: 2)).toIso8601String();
          titulo = reservas[i]['titulo'];
          found = true;
          break;
        }
      }
      
      if (!found) return false;
      
      await prefs.setString(_reservasKey, json.encode(reservas));
      
      // Enviar notificación de libro listo para recoger
      if (titulo != null) {
        try {
          await NotificationService().notifyBookAvailable(titulo);
        } catch (notifError) {
          // Ignorar errores de notificaciones (no disponibles en Windows)
        }
        
        await InAppNotificationService().addNotification(
          '¡Tu reserva está lista! 🎉',
          'El libro "$titulo" está listo para recoger. Tienes 2 días.',
          'reserva',
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Error al marcar como lista: $e');
      return false;
    }
  }

  /// Marcar reserva como recogida y convertir a préstamo
  static Future<bool> marcarComoRecogida(String reservaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservasJson = prefs.getString(_reservasKey);
      
      if (reservasJson == null) return false;
      
      final List<dynamic> decoded = json.decode(reservasJson);
      List<Map<String, dynamic>> reservas = decoded.cast<Map<String, dynamic>>();
      
      // Buscar la reserva disponible
      Map<String, dynamic>? reservaData;
      for (var reserva in reservas) {
        if (reserva['id'] == reservaId && reserva['estado'] == 'disponible') {
          reservaData = reserva;
          break;
        }
      }
      
      if (reservaData == null) return false;
      
      // Crear préstamo desde la reserva
      final prestamosJson = prefs.getString('user_prestamos');
      List<Map<String, dynamic>> prestamos = [];
      if (prestamosJson != null) {
        final List<dynamic> decodedPrestamos = json.decode(prestamosJson);
        prestamos = decodedPrestamos.cast<Map<String, dynamic>>();
      }
      
      final nuevoPrestamo = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'libroId': reservaData['libroId'],
        'titulo': reservaData['titulo'],
        'autor': reservaData['autor'],
        'thumbnail': reservaData['thumbnail'],
        'fechaPrestamo': DateTime.now().toIso8601String(),
        'fechaDevolucion': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
        'estado': 'activo',
        'renovaciones': 0,
      };
      
      prestamos.add(nuevoPrestamo);
      await prefs.setString('user_prestamos', json.encode(prestamos));
      
      // Eliminar la reserva
      reservas.removeWhere((r) => r['id'] == reservaId);
      await prefs.setString(_reservasKey, json.encode(reservas));
      
      // Enviar notificación de préstamo creado
      try {
        await NotificationService().notifyLoanSuccess(
          reservaData['titulo'],
          DateTime.now().add(const Duration(days: 14)),
        );
      } catch (notifError) {
        // Ignorar errores
      }
      
      await InAppNotificationService().addNotification(
        'Préstamo activo ✅',
        'Libro "${reservaData['titulo']}" prestado. Devuelve en 14 días.',
        'prestamo',
      );
      
      return true;
    } catch (e) {
      debugPrint('Error al marcar como recogida: $e');
      return false;
    }
  }

  /// Verificar y marcar reservas expiradas (se ejecuta diariamente)
  static Future<void> verificarReservasExpiradas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservasJson = prefs.getString(_reservasKey);
      
      if (reservasJson == null) return;
      
      final List<dynamic> decoded = json.decode(reservasJson);
      List<Map<String, dynamic>> reservas = decoded.cast<Map<String, dynamic>>();
      
      final now = DateTime.now();
      bool hayExpiradas = false;
      List<String> librosIdsExpirados = [];
      
      for (var i = 0; i < reservas.length; i++) {
        final estado = reservas[i]['estado'];
        
        // Solo revisar reservas pendientes o disponibles
        if (estado == 'pendiente' || estado == 'disponible') {
          DateTime? fechaLimite;
          
          // Si está 'disponible', usar fechaDisponible
          if (estado == 'disponible' && reservas[i]['fechaDisponible'] != null) {
            fechaLimite = DateTime.parse(reservas[i]['fechaDisponible']);
          } else if (estado == 'pendiente') {
            // Si está pendiente por más de 30 días, expirar
            final fechaReserva = DateTime.parse(reservas[i]['fechaReserva']);
            fechaLimite = fechaReserva.add(const Duration(days: 30));
          }
          
          // Verificar si expiró
          if (fechaLimite != null && now.isAfter(fechaLimite)) {
            reservas[i]['estado'] = 'expirada';
            librosIdsExpirados.add(reservas[i]['libroId']);
            hayExpiradas = true;
            
            // Notificación de expiración
            await InAppNotificationService().addNotification(
              'Reserva expirada ⚠️',
              'Tu reserva de "${reservas[i]['titulo']}" ha expirado.',
              'reserva',
            );
          }
        }
      }
      
      if (hayExpiradas) {
        await prefs.setString(_reservasKey, json.encode(reservas));
        
        // Restaurar stock (+1) de libros expirados
        for (final libroId in librosIdsExpirados) {
          await StockService.actualizarStockLocal(libroId, 1);
        }
      }
    } catch (e) {
      debugPrint('Error al verificar reservas expiradas: $e');
    }
  }

  /// Limpia datos locales
  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reservasKey);
  }
}
