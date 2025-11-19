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
        .where((p) => p.estado == 'activo' || p.estado == 'renovado' || p.estado == 'vencido')
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
    
      // VALIDACIÓN 1: Máximo 5 préstamos activos (VERIFICAR PRIMERO)
      final prestamosActivos = prestamos.where((p) => 
        p['estado'] == 'activo' || p['estado'] == 'renovado' || p['estado'] == 'vencido'
      ).length;
      
      debugPrint('🔍 Préstamos activos: $prestamosActivos/5');
      debugPrint('🔍 Intentando prestar libro ID: $libroId');
      
      // PRIMERO: Verificar límite de préstamos
      if (prestamosActivos >= 5) {
        debugPrint('❌ LÍMITE ALCANZADO: Ya tienes $prestamosActivos/5 préstamos activos');
        throw Exception('LIMITE_PRESTAMOS');
      }    // SEGUNDO: Verificar si ya existe un préstamo activo del mismo libro
    final yaExiste = prestamos.any((p) => 
      p['libroId'] == libroId && 
      (p['estado'] == 'activo' || p['estado'] == 'renovado')
    );
    
    if (yaExiste) {
      debugPrint('❌ DUPLICADO: Este libro ya está en préstamo activo');
      throw Exception('LIBRO_YA_PRESTADO');
    }
    
    // TERCERO: Verificar si ya está en lista de espera
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
    
    // Si había un item en lista de espera del mismo libro, eliminarlo
    try {
      await ReservasService.cancelarReservaPorLibroId(libroId);
    } catch (e) {
      debugPrint('Error al cancelar item de lista de espera: $e');
    }
    
    // Enviar notificación de préstamo exitoso
    try {
      await NotificationService().notifyLoanSuccess(
        nuevoPrestamo.titulo,
        nuevoPrestamo.fechaDevolucion,
      );
    } catch (notifError) {
      // Ignorar errores de notificaciones (no disponibles en Windows)
      debugPrint('Notificación no enviada (no disponible): $notifError');
    }
    
    // Agregar notificación in-app
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
      
      // Aumentar stock (+1) cuando se devuelve el libro
      if (libroId != null) {
        await StockService.actualizarStockLocal(libroId, 1);
        
        // Notificar al siguiente en la lista de espera
        await _notificarSiguienteEnCola(libroId, tituloLibro ?? 'Libro');
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

  /// Verificar y marcar préstamos vencidos (se ejecuta diariamente)
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

        // Solo revisar préstamos activos o renovados
        if (estado == 'activo' || estado == 'renovado') {
          final fechaDevolucion = DateTime.parse(prestamos[i]['fechaDevolucion']);

          // Si pasó la fecha de devolución, marcar como vencido
          if (now.isAfter(fechaDevolucion)) {
            prestamos[i]['estado'] = 'vencido';
            hayVencidos = true;

            // Guardar el libroId para devolver el ejemplar digital después
            final libroId = prestamos[i]['libroId'];
            if (libroId != null) {
              librosIdsVencidos.add(libroId);
            }

            // Notificación de vencimiento
            try {
              await NotificationService().notifyReturnDue(
                prestamos[i]['titulo'],
                -1, // días negativos = vencido
              );
            } catch (notifError) {
              // Ignorar errores
            }

            await InAppNotificationService().addNotification(
              'Préstamo vencido ⚠️',
              'El préstamo de "${prestamos[i]['titulo']}" está vencido. Devuélvelo lo antes posible.',
              'prestamo',
            );
          }
        }
      }

      if (hayVencidos) {
        await prefs.setString(_prestamosKey, json.encode(prestamos));

        // 🆕 DEVOLVER EJEMPLARES DIGITALES y notificar al siguiente en la lista
        for (final libroId in librosIdsVencidos) {
          try {
            // Aumentar stock (+1) cuando se devuelve automáticamente
            await StockService.actualizarStockLocal(libroId, 1);
            
            // Buscar título del libro para la notificación
            final prestamoVencido = prestamos.firstWhere(
              (p) => p['libroId'] == libroId && p['estado'] == 'vencido',
              orElse: () => {},
            );
            final tituloLibro = prestamoVencido['titulo'] ?? 'Libro';
            
            // Notificar al siguiente en la lista de espera
            await _notificarSiguienteEnCola(libroId, tituloLibro);
            
            debugPrint('📚 Libro devuelto automáticamente por vencimiento: $libroId');
          } catch (e) {
            debugPrint('Error al devolver ejemplar vencido de $libroId: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error al verificar préstamos vencidos: $e');
    }
  }

  /// Enviar notificaciones de advertencia (2 días antes de vencer)
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
        
        // Notificar 2 días antes
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

  /// Notifica al siguiente usuario en la lista de espera cuando un libro está disponible
  static Future<void> _notificarSiguienteEnCola(String libroId, String tituloLibro) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reservasJson = prefs.getString('user_reservas');
      
      if (reservasJson == null) return;
      
      final List<dynamic> decoded = json.decode(reservasJson);
      List<Map<String, dynamic>> reservas = decoded.cast<Map<String, dynamic>>();
      
      // Buscar reservas pendientes para este libro, ordenadas por posición en cola
      final reservasLibro = reservas
          .where((r) => r['libroId'] == libroId && r['estado'] == 'pendiente')
          .toList()
        ..sort((a, b) => (a['posicionCola'] as int).compareTo(b['posicionCola'] as int));
      
      if (reservasLibro.isEmpty) return;
      
      // Marcar la primera reserva como disponible
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
      
      // Enviar notificación in-app
      await InAppNotificationService().addNotification(
        '¡Tu libro está disponible! 🎉',
        '"$tituloLibro" ya está listo. Tienes 3 días para solicitarlo.',
        'reserva_disponible',
      );
      
      // Intentar notificación del sistema (puede fallar en Windows)
      try {
        await NotificationService().notifyBookAvailable(tituloLibro);
      } catch (e) {
        debugPrint('Notificación del sistema no disponible: $e');
      }
    } catch (e) {
      debugPrint('Error al notificar siguiente en cola: $e');
    }
  }

  /// Limpia datos locales (solo para desarrollo)
  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prestamosKey);
  }

  /// Limpiar solo el historial de préstamos devueltos
  static Future<void> clearHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prestamosJson = prefs.getString(_prestamosKey);
      
      if (prestamosJson == null) return;
      
      final List<dynamic> decoded = json.decode(prestamosJson);
      List<Map<String, dynamic>> prestamos = decoded.cast<Map<String, dynamic>>();
      
      // Mantener solo los préstamos activos (eliminar los devueltos)
      prestamos.removeWhere((p) => p['estado'] == 'devuelto');
      
      await prefs.setString(_prestamosKey, json.encode(prestamos));
      debugPrint('✅ Historial de préstamos limpiado');
    } catch (e) {
      debugPrint('Error al limpiar historial: $e');
    }
  }

  /// Verificar si el usuario tiene un préstamo activo del libro
  static Future<bool> tienePrestamo(String libroId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prestamosJson = prefs.getString(_prestamosKey);
      
      if (prestamosJson == null) return false;
      
      final List<dynamic> decoded = json.decode(prestamosJson);
      
      // Buscar si existe un préstamo activo para este libro
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
