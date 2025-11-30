import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';
import 'in_app_notification_service.dart';
import 'stock_service.dart';

class Reserva {
  final String id;
  final String libroId;
  final String titulo;
  final String autor;
  final String? thumbnail;
  final DateTime fechaReserva;
  final int posicionCola;
  final String estado;
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

class ReservasService {
  static const String baseUrl = 'https:
  static const String _reservasKey = 'user_reservas';

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

  static Future<bool> crearReserva(String libroId, {String? titulo, String? autor, String? thumbnail}) async {
    final prefs = await SharedPreferences.getInstance();
    
    final reservasJson = prefs.getString(_reservasKey);
    
    List<Map<String, dynamic>> reservas = [];
    if (reservasJson != null) {
      final List<dynamic> decoded = json.decode(reservasJson);
      reservas = decoded.cast<Map<String, dynamic>>();
    }
    
    final reservasActivas = reservas.where((r) => 
      r['estado'] == 'pendiente' || r['estado'] == 'disponible'
    ).length;
    
    debugPrint('🔍 Reservas activas: $reservasActivas/3');
    debugPrint('🔍 Intentando reservar libro ID: $libroId');
    
    if (reservasActivas >= 3) {
      debugPrint('❌ LÍMITE ALCANZADO: Ya tienes $reservasActivas/3 en lista de espera');
      throw Exception('LIMITE_RESERVAS');
    }
    
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
      fechaDisponible: DateTime.now().add(const Duration(hours: 48)),
    );
    
    reservas.add(nuevaReserva.toJson());
    await prefs.setString(_reservasKey, json.encode(reservas));
    
    try {
      await InAppNotificationService().addReservaNotification(nuevaReserva.titulo);
    } catch (e) {
      debugPrint('Error en notificación in-app: $e');
    }
    
    if (nuevaReserva.posicionCola == 1) {
      try {
        await NotificationService().notifyBookAvailable(nuevaReserva.titulo);
      } catch (notifError) {
        debugPrint('Notificación no enviada (no disponible): $notifError');
      }
    }
    
    return true;
  }

  static Future<bool> cancelarReserva(String reservaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservasJson = prefs.getString(_reservasKey);
      
      if (reservasJson == null) return false;
      
      final List<dynamic> decoded = json.decode(reservasJson);
      List<Map<String, dynamic>> reservas = decoded.cast<Map<String, dynamic>>();
      
      final reserva = reservas.firstWhere(
        (r) => r['id'] == reservaId,
        orElse: () => {},
      );
      
      final titulo = reserva['titulo'] ?? 'libro';
      final libroId = reserva['libroId'];
      
      reservas.removeWhere((r) => r['id'] == reservaId);
      
      await prefs.setString(_reservasKey, json.encode(reservas));
      
      if (libroId != null) {
        await StockService.actualizarStockLocal(libroId, 1);
      }
      
      await InAppNotificationService().addReservaCanceladaNotification(titulo);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> cancelarReservaPorLibroId(String libroId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservasJson = prefs.getString(_reservasKey);
      
      if (reservasJson == null) return;
      
      final List<dynamic> decoded = json.decode(reservasJson);
      List<Map<String, dynamic>> reservas = decoded.cast<Map<String, dynamic>>();
      
      reservas.removeWhere((r) => r['libroId'] == libroId);
      
      await prefs.setString(_reservasKey, json.encode(reservas));
    } catch (e) {
    }
  }

  static Future<Map<String, dynamic>> verificarDisponibilidad(String libroId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return {
      'disponible': false,
      'copiasTotales': 3,
      'copiasDisponibles': 0,
      'reservasActivas': 2,
      'fechaEstimada': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    };
  }

  static Future<bool> marcarComoLista(String reservaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservasJson = prefs.getString(_reservasKey);
      
      if (reservasJson == null) return false;
      
      final List<dynamic> decoded = json.decode(reservasJson);
      List<Map<String, dynamic>> reservas = decoded.cast<Map<String, dynamic>>();
      
      bool found = false;
      String? titulo;
      
      for (var i = 0; i < reservas.length; i++) {
        if (reservas[i]['id'] == reservaId && reservas[i]['estado'] == 'pendiente') {
          reservas[i]['estado'] = 'disponible';
          reservas[i]['fechaDisponible'] = DateTime.now().add(const Duration(hours: 48)).toIso8601String();
          titulo = reservas[i]['titulo'];
          found = true;
          break;
        }
      }
      
      if (!found) return false;
      
      await prefs.setString(_reservasKey, json.encode(reservas));
      
      if (titulo != null) {
        try {
          await NotificationService().notifyBookAvailable(titulo);
        } catch (notifError) {
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

  static Future<bool> marcarComoRecogida(String reservaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservasJson = prefs.getString(_reservasKey);
      
      if (reservasJson == null) return false;
      
      final List<dynamic> decoded = json.decode(reservasJson);
      List<Map<String, dynamic>> reservas = decoded.cast<Map<String, dynamic>>();
      
      Map<String, dynamic>? reservaData;
      for (var reserva in reservas) {
        if (reserva['id'] == reservaId && reserva['estado'] == 'disponible') {
          reservaData = reserva;
          break;
        }
      }
      
      if (reservaData == null) return false;
      
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
      
      reservas.removeWhere((r) => r['id'] == reservaId);
      await prefs.setString(_reservasKey, json.encode(reservas));
      
      try {
        await NotificationService().notifyLoanSuccess(
          reservaData['titulo'],
          DateTime.now().add(const Duration(days: 14)),
        );
      } catch (notifError) {
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
        
        if (estado == 'pendiente' || estado == 'disponible') {
          DateTime? fechaLimite;
          
          if (estado == 'disponible' && reservas[i]['fechaDisponible'] != null) {
            fechaLimite = DateTime.parse(reservas[i]['fechaDisponible']);
          } else if (estado == 'pendiente') {
            final fechaReserva = DateTime.parse(reservas[i]['fechaReserva']);
            fechaLimite = fechaReserva.add(const Duration(days: 30));
          }
          
          if (fechaLimite != null && now.isAfter(fechaLimite)) {
            reservas[i]['estado'] = 'expirada';
            librosIdsExpirados.add(reservas[i]['libroId']);
            hayExpiradas = true;
            
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
        
        for (final libroId in librosIdsExpirados) {
          await StockService.actualizarStockLocal(libroId, 1);
        }
      }
    } catch (e) {
      debugPrint('Error al verificar reservas expiradas: $e');
    }
  }

  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reservasKey);
  }
}