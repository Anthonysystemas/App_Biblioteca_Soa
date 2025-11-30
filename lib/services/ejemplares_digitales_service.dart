import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisponibilidadDigital {
  final String libroId;
  final int ejemplaresTotales;
  final int ejemplaresEnUso;
  final int ejemplaresDisponibles;
  final bool disponible;

  DisponibilidadDigital({
    required this.libroId,
    required this.ejemplaresTotales,
    required this.ejemplaresEnUso,
  })  : ejemplaresDisponibles = ejemplaresTotales - ejemplaresEnUso,
        disponible = (ejemplaresTotales - ejemplaresEnUso) > 0;

  String get mensaje {
    if (!disponible) {
      return 'Sin ejemplares (0 de $ejemplaresTotales en uso)';
    } else if (ejemplaresDisponibles == 1) {
      return '¡Último ejemplar! (1 de $ejemplaresTotales)';
    } else if (ejemplaresDisponibles <= 3) {
      return 'Pocos ejemplares ($ejemplaresDisponibles de $ejemplaresTotales)';
    } else {
      return '$ejemplaresDisponibles de $ejemplaresTotales disponibles';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'libroId': libroId,
      'ejemplaresTotales': ejemplaresTotales,
      'ejemplaresEnUso': ejemplaresEnUso,
      'ejemplaresDisponibles': ejemplaresDisponibles,
      'disponible': disponible,
    };
  }
}

class EjemplaresDigitalesService {
  static const String _ejemplaresKey = 'ejemplares_digitales';
  static const String _prestamosDigitalesKey = 'prestamos_digitales_activos';
  static const String _listaEsperaKey = 'lista_espera_digital';
  static const String _notificacionesKey = 'notificaciones_disponibilidad';

  static Future<void> _inicializarEjemplares(String libroId) async {
    final prefs = await SharedPreferences.getInstance();
    final ejemplaresJson = prefs.getString(_ejemplaresKey);

    Map<String, dynamic> ejemplares = {};
    if (ejemplaresJson != null) {
      ejemplares = json.decode(ejemplaresJson);
    }

    if (!ejemplares.containsKey(libroId)) {
      final random = Random();
      final hash = libroId.hashCode.abs();
      final modulo = hash % 20;
      
      int totales;
      int enUso;
      
      if (modulo < 6) {
        totales = 2 + (modulo % 4);
        enUso = totales;
      } else if (modulo < 10) {
        totales = 1 + (modulo % 3);
        enUso = totales > 1 ? totales - 1 : 0;
      } else {
        totales = 3 + (modulo % 8);
        enUso = random.nextInt(totales ~/ 2);
      }

      ejemplares[libroId] = {
        'totales': totales,
        'enUso': enUso,
      };

      await prefs.setString(_ejemplaresKey, json.encode(ejemplares));
      debugPrint('📚 Ejemplares digitales generados para $libroId: $totales totales, $enUso en uso');
    }
  }

  static Future<DisponibilidadDigital> consultarDisponibilidad(String libroId) async {
    await _inicializarEjemplares(libroId);

    final prefs = await SharedPreferences.getInstance();
    final ejemplaresJson = prefs.getString(_ejemplaresKey);

    if (ejemplaresJson == null) {
      return DisponibilidadDigital(
        libroId: libroId,
        ejemplaresTotales: 5,
        ejemplaresEnUso: 0,
      );
    }

    final ejemplares = json.decode(ejemplaresJson);
    final libroData = ejemplares[libroId];

    if (libroData == null) {
      return DisponibilidadDigital(
        libroId: libroId,
        ejemplaresTotales: 5,
        ejemplaresEnUso: 0,
      );
    }

    final totales = libroData['totales'] as int;
    final enUso = libroData['enUso'] as int;

    return DisponibilidadDigital(
      libroId: libroId,
      ejemplaresTotales: totales,
      ejemplaresEnUso: enUso,
    );
  }

  static Future<bool> prestarEjemplar(String libroId) async {
    try {
      final disponibilidad = await consultarDisponibilidad(libroId);

      if (!disponibilidad.disponible) {
        debugPrint('❌ No hay ejemplares disponibles de $libroId');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final ejemplaresJson = prefs.getString(_ejemplaresKey);

      if (ejemplaresJson == null) return false;

      final ejemplares = json.decode(ejemplaresJson);

      if (ejemplares[libroId] != null) {
        ejemplares[libroId]['enUso'] = (ejemplares[libroId]['enUso'] as int) + 1;
        await prefs.setString(_ejemplaresKey, json.encode(ejemplares));

        debugPrint('📈 Ejemplar prestado de $libroId. En uso: ${ejemplares[libroId]['enUso']}');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error al prestar ejemplar: $e');
      return false;
    }
  }

  static Future<bool> devolverEjemplar(String libroId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ejemplaresJson = prefs.getString(_ejemplaresKey);

      if (ejemplaresJson == null) return false;

      final ejemplares = json.decode(ejemplaresJson);

      if (ejemplares[libroId] != null) {
        final enUso = ejemplares[libroId]['enUso'] as int;
        ejemplares[libroId]['enUso'] = max(0, enUso - 1);
        await prefs.setString(_ejemplaresKey, json.encode(ejemplares));

        debugPrint('📉 Ejemplar devuelto de $libroId. En uso: ${ejemplares[libroId]['enUso']}');

        await notificarSiguienteEnLista(libroId);

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error al devolver ejemplar: $e');
      return false;
    }
  }

  static Future<bool> tienePrestamoActivo(String libroId) async {
    final prefs = await SharedPreferences.getInstance();
    final prestamosJson = prefs.getString(_prestamosDigitalesKey);

    if (prestamosJson == null) return false;

    final List<dynamic> prestamos = json.decode(prestamosJson);
    return prestamos.any((p) => p['libroId'] == libroId && p['activo'] == true);
  }

  static Future<void> registrarPrestamoActivo(String libroId, String prestamoId) async {
    final prefs = await SharedPreferences.getInstance();
    final prestamosJson = prefs.getString(_prestamosDigitalesKey);

    List<dynamic> prestamos = [];
    if (prestamosJson != null) {
      prestamos = json.decode(prestamosJson);
    }

    prestamos.add({
      'libroId': libroId,
      'prestamoId': prestamoId,
      'activo': true,
      'fecha': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_prestamosDigitalesKey, json.encode(prestamos));
  }

  static Future<void> finalizarPrestamo(String prestamoId) async {
    final prefs = await SharedPreferences.getInstance();
    final prestamosJson = prefs.getString(_prestamosDigitalesKey);

    if (prestamosJson == null) return;

    List<dynamic> prestamos = json.decode(prestamosJson);

    for (var prestamo in prestamos) {
      if (prestamo['prestamoId'] == prestamoId) {
        prestamo['activo'] = false;
      }
    }

    await prefs.setString(_prestamosDigitalesKey, json.encode(prestamos));
  }

  static Future<Map<String, dynamic>> getEstadisticas() async {
    final prefs = await SharedPreferences.getInstance();
    final ejemplaresJson = prefs.getString(_ejemplaresKey);

    if (ejemplaresJson == null) {
      return {
        'totalLibros': 0,
        'totalEjemplares': 0,
        'ejemplaresEnUso': 0,
        'ejemplaresDisponibles': 0,
      };
    }

    final ejemplares = json.decode(ejemplaresJson);
    int totalLibros = ejemplares.length;
    int totalEjemplares = 0;
    int ejemplaresEnUso = 0;

    ejemplares.forEach((key, value) {
      totalEjemplares += value['totales'] as int;
      ejemplaresEnUso += value['enUso'] as int;
    });

    return {
      'totalLibros': totalLibros,
      'totalEjemplares': totalEjemplares,
      'ejemplaresEnUso': ejemplaresEnUso,
      'ejemplaresDisponibles': totalEjemplares - ejemplaresEnUso,
    };
  }


  static Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId == null) {
      userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('user_id', userId);
    }

    return userId;
  }

  static Future<bool> unirseAListaEspera(String libroId, {String? titulo, String? autor}) async {
    try {
      final userId = await _getUserId();
      final prefs = await SharedPreferences.getInstance();
      final listaJson = prefs.getString(_listaEsperaKey);

      Map<String, dynamic> listas = {};
      if (listaJson != null) {
        listas = json.decode(listaJson);
      }

      if (!listas.containsKey(libroId)) {
        listas[libroId] = [];
      }

      final lista = listas[libroId] as List;

      final yaEnLista = lista.any((item) => item['userId'] == userId);
      if (yaEnLista) {
        debugPrint('⚠️ Usuario ya está en la lista de espera de $libroId');
        return false;
      }

      lista.add({
        'userId': userId,
        'libroId': libroId,
        'titulo': titulo,
        'autor': autor,
        'fechaUnion': DateTime.now().toIso8601String(),
      });

      listas[libroId] = lista;
      await prefs.setString(_listaEsperaKey, json.encode(listas));

      debugPrint('📋 Usuario añadido a lista de espera de $libroId. Posición: ${lista.length}');
      return true;
    } catch (e) {
      debugPrint('Error al unirse a lista de espera: $e');
      return false;
    }
  }

  static Future<bool> salirDeListaEspera(String libroId) async {
    try {
      final userId = await _getUserId();
      final prefs = await SharedPreferences.getInstance();
      final listaJson = prefs.getString(_listaEsperaKey);

      if (listaJson == null) return false;

      Map<String, dynamic> listas = json.decode(listaJson);

      if (!listas.containsKey(libroId)) return false;

      final lista = listas[libroId] as List;
      lista.removeWhere((item) => item['userId'] == userId);

      listas[libroId] = lista;
      await prefs.setString(_listaEsperaKey, json.encode(listas));

      debugPrint('❌ Usuario removido de lista de espera de $libroId');
      return true;
    } catch (e) {
      debugPrint('Error al salir de lista de espera: $e');
      return false;
    }
  }

  static Future<bool> estaEnListaEspera(String libroId) async {
    try {
      final userId = await _getUserId();
      final prefs = await SharedPreferences.getInstance();
      final listaJson = prefs.getString(_listaEsperaKey);

      if (listaJson == null) return false;

      Map<String, dynamic> listas = json.decode(listaJson);

      if (!listas.containsKey(libroId)) return false;

      final lista = listas[libroId] as List;
      return lista.any((item) => item['userId'] == userId);
    } catch (e) {
      debugPrint('Error al verificar lista de espera: $e');
      return false;
    }
  }

  static Future<int?> obtenerPosicionEnLista(String libroId) async {
    try {
      final userId = await _getUserId();
      final prefs = await SharedPreferences.getInstance();
      final listaJson = prefs.getString(_listaEsperaKey);

      if (listaJson == null) return null;

      Map<String, dynamic> listas = json.decode(listaJson);

      if (!listas.containsKey(libroId)) return null;

      final lista = listas[libroId] as List;
      final index = lista.indexWhere((item) => item['userId'] == userId);

      return index == -1 ? null : index + 1;
    } catch (e) {
      debugPrint('Error al obtener posición en lista: $e');
      return null;
    }
  }

  static Future<int> obtenerCantidadEnEspera(String libroId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listaJson = prefs.getString(_listaEsperaKey);

      if (listaJson == null) return 0;

      Map<String, dynamic> listas = json.decode(listaJson);

      if (!listas.containsKey(libroId)) return 0;

      final lista = listas[libroId] as List;
      return lista.length;
    } catch (e) {
      debugPrint('Error al obtener cantidad en espera: $e');
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerListaEsperaUsuario() async {
    try {
      final userId = await _getUserId();
      final prefs = await SharedPreferences.getInstance();
      final listaJson = prefs.getString(_listaEsperaKey);

      if (listaJson == null) return [];

      Map<String, dynamic> listas = json.decode(listaJson);
      List<Map<String, dynamic>> librosEnEspera = [];

      listas.forEach((libroId, lista) {
        if (lista is List) {
          final index = lista.indexWhere((item) => item['userId'] == userId);
          if (index != -1) {
            final item = lista[index] as Map<String, dynamic>;
            librosEnEspera.add({
              'libroId': libroId,
              'titulo': item['titulo'] ?? 'Sin título',
              'autor': item['autor'] ?? 'Autor desconocido',
              'fechaUnion': item['fechaUnion'] ?? DateTime.now().toIso8601String(),
              'posicion': index + 1,
              'totalEnEspera': lista.length,
            });
          }
        }
      });

      librosEnEspera.sort((a, b) {
        final fechaA = DateTime.parse(a['fechaUnion']);
        final fechaB = DateTime.parse(b['fechaUnion']);
        return fechaB.compareTo(fechaA);
      });

      return librosEnEspera;
    } catch (e) {
      debugPrint('Error al obtener lista de espera del usuario: $e');
      return [];
    }
  }

  static Future<void> notificarSiguienteEnLista(String libroId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listaJson = prefs.getString(_listaEsperaKey);

      if (listaJson == null) return;

      Map<String, dynamic> listas = json.decode(listaJson);

      if (!listas.containsKey(libroId)) return;

      final lista = listas[libroId] as List;

      if (lista.isEmpty) {
        debugPrint('📋 No hay usuarios en lista de espera de $libroId');
        return;
      }

      final siguienteUsuario = lista[0];
      final siguienteUserId = siguienteUsuario['userId'];

      final notificacionesJson = prefs.getString(_notificacionesKey);
      List<dynamic> notificaciones = [];
      if (notificacionesJson != null) {
        notificaciones = json.decode(notificacionesJson);
      }

      notificaciones.add({
        'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
        'userId': siguienteUserId,
        'libroId': libroId,
        'titulo': siguienteUsuario['titulo'] ?? 'Libro disponible',
        'autor': siguienteUsuario['autor'],
        'mensaje': '¡Tu turno! El libro que esperabas está disponible.',
        'fechaNotificacion': DateTime.now().toIso8601String(),
        'leida': false,
        'disponibleHasta': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      });

      await prefs.setString(_notificacionesKey, json.encode(notificaciones));

      lista.removeAt(0);
      listas[libroId] = lista;
      await prefs.setString(_listaEsperaKey, json.encode(listas));

      debugPrint('🔔 Notificación enviada a $siguienteUserId para $libroId');
    } catch (e) {
      debugPrint('Error al notificar siguiente en lista: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
    try {
      final userId = await _getUserId();
      final prefs = await SharedPreferences.getInstance();
      final notificacionesJson = prefs.getString(_notificacionesKey);

      if (notificacionesJson == null) return [];

      List<dynamic> todasNotificaciones = json.decode(notificacionesJson);

      final misNotificaciones = todasNotificaciones
          .where((n) => n['userId'] == userId)
          .map((n) => n as Map<String, dynamic>)
          .toList();

      misNotificaciones.sort((a, b) {
        final fechaA = DateTime.parse(a['fechaNotificacion']);
        final fechaB = DateTime.parse(b['fechaNotificacion']);
        return fechaB.compareTo(fechaA);
      });

      return misNotificaciones;
    } catch (e) {
      debugPrint('Error al obtener notificaciones: $e');
      return [];
    }
  }

  static Future<void> marcarNotificacionComoLeida(String notifId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificacionesJson = prefs.getString(_notificacionesKey);

      if (notificacionesJson == null) return;

      List<dynamic> notificaciones = json.decode(notificacionesJson);

      for (var notif in notificaciones) {
        if (notif['id'] == notifId) {
          notif['leida'] = true;
        }
      }

      await prefs.setString(_notificacionesKey, json.encode(notificaciones));
    } catch (e) {
      debugPrint('Error al marcar notificación como leída: $e');
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ejemplaresKey);
    await prefs.remove(_prestamosDigitalesKey);
    await prefs.remove(_listaEsperaKey);
    await prefs.remove(_notificacionesKey);
    debugPrint('🗑️ Ejemplares digitales y listas de espera limpiados');
  }

  static Future<void> resetLibro(String libroId) async {
    final prefs = await SharedPreferences.getInstance();
    final ejemplaresJson = prefs.getString(_ejemplaresKey);

    if (ejemplaresJson != null) {
      final ejemplares = json.decode(ejemplaresJson);
      ejemplares.remove(libroId);
      await prefs.setString(_ejemplaresKey, json.encode(ejemplares));
      debugPrint('🔄 Ejemplares reseteados para $libroId');
    }
  }
}