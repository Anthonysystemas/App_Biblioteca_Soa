import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';
import 'in_app_notification_service.dart';
import 'reservas_service.dart';
import 'stock_service.dart';

class Prestamo {
  final String id;
  final String libroId;
  final String titulo;
  final String autor;
  final String? thumbnail;
  final DateTime fechaPrestamo;
  final DateTime fechaDevolucion;
  final String estado;
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

class PrestamosService {
  static const String baseUrl = 'https:
  static const String _prestamosKey = 'user_prestamos';

  static Future<List<Prestamo>> getPrestamosActivos() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final prefs = await SharedPreferences.getInstance();
    final prestamosJson = prefs.getString(_prestamosKey);
    
    if (prestamosJson == null) return [];
    
    final List<dynamic> decoded = json.decode(prestamosJson);
    
    debugPrint('📚 TOTAL PRÉSTAMOS EN BD: ${decoded.length}');
    for (var p in decoded) {
      debugPrint('  - ${p['titulo']}: estado="${p['estado']}"');
    }
    
    final prestamos = decoded
        .map((json) => Prestamo.fromJson(json))
        .where((p) => p.estado == 'activo' || p.estado == 'renovado')
        .toList();
    
    debugPrint('✅ PRÉSTAMOS ACTIVOS FILTRADOS: ${prestamos.length}');
    
    return prestamos;
  }

  static Future<List<Prestamo>> getHistorial() async {
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

  static Future<bool> solicitarPrestamo(String libroId, {String? titulo, String? autor, String? thumbnail}) async {
    final prefs = await SharedPreferences.getInstance();
    final prestamosJson = prefs.getString(_prestamosKey);
    
    List<Map<String, dynamic>> prestamos = [];
    if (prestamosJson != null) {
      final List<dynamic> decoded = json.decode(prestamosJson);
      prestamos = decoded.cast<Map<String, dynamic>>();
    }
    
      final prestamosActivos = prestamos.where((p) => 
        p['estado'] == 'activo' || p['estado'] == 'renovado' || p['estado'] == 'vencido'
      ).length;
      
      debugPrint('🔍 Préstamos activos: $prestamosActivos/5');
      debugPrint('🔍 Intentando prestar libro ID: $libroId');
      
      if (prestamosActivos >= 5) {
        debugPrint('❌ LÍMITE ALCANZADO: Ya tienes $prestamosActivos/5 préstamos activos');
        throw Exception('LIMITE_PRESTAMOS');
      }    final yaExiste = prestamos.any((p) => 
      p['libroId'] == libroId && 
      (p['estado'] == 'activo' || p['estado'] == 'renovado')
    );
    
    if (yaExiste) {
      debugPrint('❌ DUPLICADO: Este libro ya está en préstamo activo');
      throw Exception('LIBRO_YA_PRESTADO');
    }
    
    final reservasJson = prefs.getString('user_reservas');
    if (reservasJson != null) {
      final List<dynamic> decodedReservas = json.decode(reservasJson);
      final tieneReserva = decodedReservas.any((r) => 
        r['libroId'] == libroId && 
        (r['estado'] == 'pendiente' || r['estado'] == 'disponible')
      );
      
      if (tieneReserva) {
        debugPrint('❌ EN LISTA DE ESPERA: Este libro ya está en tu lista de espera');
        throw Exception('LIBRO_YA_RESERVADO');
      }
    }
    
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
    
    try {
      await ReservasService.cancelarReservaPorLibroId(libroId);
    } catch (e) {
      debugPrint('Error al cancelar item de lista de espera: $e');
    }
    
    try {
      await NotificationService().notifyLoanSuccess(
        nuevoPrestamo.titulo,
        nuevoPrestamo.fechaDevolucion,
      );
    } catch (notifError) {
      debugPrint('Notificación no enviada (no disponible): $notifError');
    }
    
    try {
      await InAppNotificationService().addPrestamoNotification(
        nuevoPrestamo.titulo,
        nuevoPrestamo.fechaDevolucion,
      );
    } catch (e) {
      debugPrint('Error en notificación in-app: $e');
    }
    
    return true;
  }

  static Future<bool> renovarPrestamo(String prestamoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prestamosJson = prefs.getString(_prestamosKey);
      
      if (prestamosJson == null) return false;
      
      final List<dynamic> decoded = json.decode(prestamosJson);
      List<Map<String, dynamic>> prestamos = decoded.cast<Map<String, dynamic>>();
      
      for (var i = 0; i < prestamos.length; i++) {
        if (prestamos[i]['id'] == prestamoId) {
          final renovaciones = (prestamos[i]['renovaciones'] as int? ?? 0);
          if (renovaciones >= 1) return false;
          
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

  static Future<bool> devolverLibro(String prestamoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prestamosJson = prefs.getString(_prestamosKey);
      
      if (prestamosJson == null) return false;
      
      final List<dynamic> decoded = json.decode(prestamosJson);
      List<Map<String, dynamic>> prestamos = decoded.cast<Map<String, dynamic>>();
      
      bool found = false;
      String? libroId;
      String? tituloLibro;
      for (var i = 0; i < prestamos.length; i++) {
        if (prestamos[i]['id'] == prestamoId) {
          prestamos[i]['estado'] = 'devuelto';
          prestamos[i]['fechaDevolucion'] = DateTime.now().toIso8601String();
          libroId = prestamos[i]['libroId'];
          tituloLibro = prestamos[i]['titulo'];
          found = true;
          break;
        }
      }
      
      if (!found) return false;
      
      await prefs.setString(_prestamosKey, json.encode(prestamos));
      
      if (libroId != null) {
        await StockService.actualizarStockLocal(libroId, 1);
        
        await _notificarSiguienteEnCola(libroId, tituloLibro ?? 'Libro');
      }
      
      return true;
    } catch (e) {
      debugPrint('Error al devolver libro: $e');
      return false;
    }
  }

  static Future<void> checkAndNotifyDueDates() async {
    try {
      final prestamos = await getPrestamosActivos();
      final now = DateTime.now();
      
      for (final prestamo in prestamos) {
        final daysLeft = prestamo.fechaDevolucion.difference(now).inDays;
        
        if (daysLeft >= 0 && daysLeft <= 3) {
          await NotificationService().notifyReturnDue(
            prestamo.titulo,
            daysLeft,
          );
        }
      }
    } catch (e) {
    }
  }

  static Future<void> verificarPrestamosVencidos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prestamosJson = prefs.getString(_prestamosKey);

      if (prestamosJson == null) return;

      final List<dynamic> decoded = json.decode(prestamosJson);
      List<Map<String, dynamic>> prestamos = decoded.cast<Map<String, dynamic>>();

      final now = DateTime.now();
      bool hayVencidos = false;
      List<String> librosIdsVencidos = [];

      for (var i = 0; i < prestamos.length; i++) {
        final estado = prestamos[i]['estado'];

        if (estado == 'activo' || estado == 'renovado') {
          final fechaDevolucion = DateTime.parse(prestamos[i]['fechaDevolucion']);

          if (now.isAfter(fechaDevolucion)) {
            debugPrint('⏰ PRÉSTAMO VENCIDO DETECTADO: ${prestamos[i]['titulo']}');
            debugPrint('   Estado anterior: ${prestamos[i]['estado']}');
            
            prestamos[i]['estado'] = 'devuelto';
            prestamos[i]['devuelto_automaticamente'] = true;
            prestamos[i]['fecha_devolucion_real'] = now.toIso8601String();
            hayVencidos = true;
            
            debugPrint('   Estado nuevo: ${prestamos[i]['estado']}');
            debugPrint('   ✅ Cambiado a DEVUELTO');

            final libroId = prestamos[i]['libroId'];
            if (libroId != null) {
              librosIdsVencidos.add(libroId);
            }

            try {
              await NotificationService().notifyReturnDue(
                prestamos[i]['titulo'],
                -1,
              );
            } catch (notifError) {
            }

            await InAppNotificationService().addNotification(
              'Préstamo devuelto automáticamente ✅',
              'El préstamo de "${prestamos[i]['titulo']}" venció y fue devuelto automáticamente.',
              'prestamo',
            );
          }
        }
      }

      if (hayVencidos) {
        debugPrint('💾 GUARDANDO CAMBIOS EN SHARED PREFERENCES...');
        await prefs.setString(_prestamosKey, json.encode(prestamos));
        debugPrint('✅ CAMBIOS GUARDADOS - Préstamos marcados como devueltos');

        for (final libroId in librosIdsVencidos) {
          try {
            await StockService.actualizarStockLocal(libroId, 1);
            
            final prestamoDevuelto = prestamos.firstWhere(
              (p) => p['libroId'] == libroId && p['estado'] == 'devuelto',
              orElse: () => {},
            );
            final tituloLibro = prestamoDevuelto['titulo'] ?? 'Libro';
            
            await _notificarSiguienteEnCola(libroId, tituloLibro);
            
            debugPrint('📚 Stock liberado automáticamente por vencimiento: $libroId');
          } catch (e) {
            debugPrint('Error al liberar stock de $libroId: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error al verificar préstamos vencidos: $e');
    }
  }

  static Future<void> notificarProximosAVencer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prestamosJson = prefs.getString(_prestamosKey);
      
      if (prestamosJson == null) return;
      
      final List<dynamic> decoded = json.decode(prestamosJson);
      final prestamos = decoded
          .map((json) => Prestamo.fromJson(json))
          .where((p) => p.estado == 'activo' || p.estado == 'renovado')
          .toList();
      
      final now = DateTime.now();
      
      for (final prestamo in prestamos) {
        final daysLeft = prestamo.fechaDevolucion.difference(now).inDays;
        
        if (daysLeft == 2) {
          await InAppNotificationService().addNotification(
            'Préstamo próximo a vencer ⏰',
            'El préstamo de "${prestamo.titulo}" vence en 2 días.',
            'prestamo',
          );
        }
      }
    } catch (e) {
      debugPrint('Error al notificar próximos a vencer: $e');
    }
  }

  static Future<void> _notificarSiguienteEnCola(String libroId, String tituloLibro) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservasJson = prefs.getString('user_reservas');
      
      if (reservasJson == null) return;
      
      final List<dynamic> decoded = json.decode(reservasJson);
      List<Map<String, dynamic>> reservas = decoded.cast<Map<String, dynamic>>();
      
      final reservasLibro = reservas
          .where((r) => r['libroId'] == libroId && r['estado'] == 'pendiente')
          .toList()
        ..sort((a, b) => (a['posicionCola'] as int).compareTo(b['posicionCola'] as int));
      
      if (reservasLibro.isEmpty) return;
      
      final primeraReserva = reservasLibro.first;
      final reservaId = primeraReserva['id'];
      
      for (var i = 0; i < reservas.length; i++) {
        if (reservas[i]['id'] == reservaId) {
          reservas[i]['estado'] = 'disponible';
          reservas[i]['fechaDisponible'] = DateTime.now().add(const Duration(days: 3)).toIso8601String();
          break;
        }
      }
      
      await prefs.setString('user_reservas', json.encode(reservas));
      
      await InAppNotificationService().addNotification(
        '¡Tu libro está disponible! 🎉',
        '"$tituloLibro" ya está listo. Tienes 3 días para solicitarlo.',
        'reserva_disponible',
      );
      
      try {
        await NotificationService().notifyBookAvailable(tituloLibro);
      } catch (e) {
        debugPrint('Notificación del sistema no disponible: $e');
      }
    } catch (e) {
      debugPrint('Error al notificar siguiente en cola: $e');
    }
  }

  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prestamosKey);
  }

  static Future<void> clearHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prestamosJson = prefs.getString(_prestamosKey);
      
      if (prestamosJson == null) return;
      
      final List<dynamic> decoded = json.decode(prestamosJson);
      List<Map<String, dynamic>> prestamos = decoded.cast<Map<String, dynamic>>();
      
      prestamos.removeWhere((p) => p['estado'] == 'devuelto');
      
      await prefs.setString(_prestamosKey, json.encode(prestamos));
      debugPrint('✅ Historial de préstamos limpiado');
    } catch (e) {
      debugPrint('Error al limpiar historial: $e');
    }
  }

  static Future<bool> tienePrestamo(String libroId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prestamosJson = prefs.getString(_prestamosKey);
      
      if (prestamosJson == null) return false;
      
      final List<dynamic> decoded = json.decode(prestamosJson);
      
      final tieneActivo = decoded.any((p) => 
        p['libroId'] == libroId && 
        (p['estado'] == 'activo' || p['estado'] == 'vencido')
      );
      
      return tieneActivo;
    } catch (e) {
      debugPrint('Error al verificar préstamo: $e');
      return false;
    }
  }
}