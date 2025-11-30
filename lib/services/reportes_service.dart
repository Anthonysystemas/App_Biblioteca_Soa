import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'prestamos_service.dart';

class ReportesService {
  static const String baseUrl = 'https:


  static Future<Map<String, dynamic>> getResumenUsuario() async {
    
    final prestamos = await PrestamosService.getPrestamosActivos();
    final historial = await PrestamosService.getHistorial();
    
    final prefs = await SharedPreferences.getInstance();
    final prestamosJson = prefs.getString('prestamos_locales');
    int librosLeidos = 0;
    if (prestamosJson != null) {
      final List<dynamic> decoded = json.decode(prestamosJson);
      librosLeidos = decoded.where((p) => p['estado'] == 'devuelto').length;
    }
    
    final prefs2 = await SharedPreferences.getInstance();
    final reservasJson = prefs2.getString('user_reservas');
    int reservasPendientes = 0;
    if (reservasJson != null) {
      final List<dynamic> decoded = json.decode(reservasJson);
      reservasPendientes = decoded.where((r) => r['estado'] == 'pendiente').length;
    }
    
    return {
      'libros_leidos': librosLeidos,
      'libros_activos': prestamos.length,
      'reservas_activas': reservasPendientes,
      'historial': historial.length,
    };
  }

  static Future<List<Map<String, dynamic>>> getHistorialUsuario({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    
    return [
      {
        'id': '1',
        'libro_titulo': 'Clean Code',
        'autor': 'Robert C. Martin',
        'fecha_prestamo': '2025-09-01',
        'fecha_devolucion': '2025-09-15',
        'dias_prestamo': 14,
        'estado': 'devuelto',
        'renovaciones': 0,
      },
      {
        'id': '2',
        'libro_titulo': 'Design Patterns',
        'autor': 'Gang of Four',
        'fecha_prestamo': '2025-09-10',
        'fecha_devolucion': '2025-09-24',
        'dias_prestamo': 14,
        'estado': 'devuelto',
        'renovaciones': 1,
      },
    ];
  }

  static Future<List<Map<String, dynamic>>> getEstadisticasPorCategoria() async {
    
    final prefs = await SharedPreferences.getInstance();
    final prestamosJson = prefs.getString('prestamos_locales');
    
    if (prestamosJson == null) {
      return [];
    }
    
    final List<dynamic> decoded = json.decode(prestamosJson);
    
    final historial = decoded.where((p) => p['estado'] == 'devuelto').toList();
    
    if (historial.isEmpty) {
      return [];
    }
    
    final Map<String, int> categorias = {};
    
    for (var prestamo in historial) {
      String categoria = 'Otros';
      
      final titulo = (prestamo['titulo'] ?? '').toString().toLowerCase();
      final autor = (prestamo['autor'] ?? '').toString().toLowerCase();
      
      if (titulo.contains('program') || titulo.contains('code') || 
          titulo.contains('java') || titulo.contains('python') ||
          titulo.contains('flutter') || titulo.contains('dart') ||
          titulo.contains('javascript') || titulo.contains('react')) {
        categoria = 'Programación';
      } else if (titulo.contains('ficción') || titulo.contains('fiction') || 
                 titulo.contains('novel') || titulo.contains('cuento') ||
                 titulo.contains('fantasy') || titulo.contains('romance')) {
        categoria = 'Ficción';
      } else if (titulo.contains('ciencia') || titulo.contains('science') || 
                 titulo.contains('física') || titulo.contains('química') ||
                 titulo.contains('biology') || titulo.contains('physics')) {
        categoria = 'Ciencia';
      } else if (titulo.contains('historia') || titulo.contains('history') || 
                 autor.contains('historian') || titulo.contains('historical')) {
        categoria = 'Historia';
      } else if (titulo.contains('biografía') || titulo.contains('biography') ||
                 titulo.contains('memoir')) {
        categoria = 'Biografía';
      } else if (titulo.contains('arte') || titulo.contains('art') ||
                 titulo.contains('design') || titulo.contains('music')) {
        categoria = 'Arte';
      } else if (titulo.contains('filosofía') || titulo.contains('philosophy')) {
        categoria = 'Filosofía';
      } else if (titulo.contains('business') || titulo.contains('negocio') ||
                 titulo.contains('marketing') || titulo.contains('management')) {
        categoria = 'Negocios';
      } else if (titulo.contains('salud') || titulo.contains('health') ||
                 titulo.contains('medicina') || titulo.contains('medical')) {
        categoria = 'Salud';
      } else if (titulo.contains('cocina') || titulo.contains('cooking') ||
                 titulo.contains('recipe')) {
        categoria = 'Cocina';
      }
      
      categorias[categoria] = (categorias[categoria] ?? 0) + 1;
    }
    
    final total = historial.length;
    final List<Map<String, dynamic>> resultado = [];
    
    categorias.forEach((categoria, cantidad) {
      resultado.add({
        'categoria': categoria,
        'cantidad': cantidad,
        'porcentaje': total > 0 ? ((cantidad / total) * 100).round() : 0,
      });
    });
    
    resultado.sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));
    
    return resultado.take(5).toList();
  }


  static Future<Map<String, dynamic>> getReportePrestamos({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    
    return {
      'total_prestamos': 145,
      'prestamos_activos': 67,
      'prestamos_vencidos': 12,
      'prestamos_devueltos': 66,
      'promedio_dias': 12.5,
      'libro_mas_prestado': {
        'titulo': 'Clean Code',
        'cantidad': 15,
      },
    };
  }

  static Future<List<Map<String, dynamic>>> getUsuariosMasActivos({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    
    return [
      {'usuario': 'juan_perez', 'prestamos': 25, 'reservas': 5},
      {'usuario': 'maria_garcia', 'prestamos': 20, 'reservas': 3},
      {'usuario': 'carlos_lopez', 'prestamos': 18, 'reservas': 7},
    ];
  }

  static Future<List<Map<String, dynamic>>> getLibrosMasPopulares({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    
    return [
      {
        'libro_id': '1',
        'titulo': 'Clean Code',
        'autor': 'Robert C. Martin',
        'prestamos': 45,
        'reservas': 12,
        'rating_promedio': 4.8,
      },
      {
        'libro_id': '2',
        'titulo': 'Design Patterns',
        'autor': 'Gang of Four',
        'prestamos': 38,
        'reservas': 8,
        'rating_promedio': 4.6,
      },
    ];
  }

  static Future<Map<String, dynamic>> getReporteDisponibilidad() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    
    return {
      'total_libros': 1250,
      'disponibles': 980,
      'prestados': 245,
      'en_mantenimiento': 15,
      'reservados': 10,
      'porcentaje_disponibilidad': 78.4,
    };
  }

  static Future<Map<String, dynamic>> getReporteMultas({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    
    return {
      'multas_generadas': 28,
      'multas_pagadas': 20,
      'multas_pendientes': 8,
      'monto_total': 560.00,
      'monto_cobrado': 400.00,
      'monto_pendiente': 160.00,
    };
  }


  static Future<List<Map<String, dynamic>>> getTendenciasPorMes({
    int mesesAtras = 6,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    
    return [
      {'mes': 'Octubre', 'prestamos': 145, 'usuarios_activos': 87},
      {'mes': 'Septiembre', 'prestamos': 132, 'usuarios_activos': 78},
      {'mes': 'Agosto', 'prestamos': 128, 'usuarios_activos': 72},
      {'mes': 'Julio', 'prestamos': 115, 'usuarios_activos': 65},
      {'mes': 'Junio', 'prestamos': 98, 'usuarios_activos': 58},
      {'mes': 'Mayo', 'prestamos': 105, 'usuarios_activos': 62},
    ];
  }

  static Future<List<Map<String, dynamic>>> getTendenciasPorCategoria() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    
    return [
      {
        'categoria': 'Programación',
        'prestamos': 245,
        'tendencia': 'subiendo',
        'cambio_porcentual': 15.5,
      },
      {
        'categoria': 'Ficción',
        'prestamos': 198,
        'tendencia': 'estable',
        'cambio_porcentual': 2.1,
      },
    ];
  }


  static Future<String> exportarReporteCSV({
    required String tipoReporte,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    
    return '''
Usuario,Préstamos,Devoluciones,Multas
juan_perez,25,23,2
maria_garcia,20,20,0
carlos_lopez,18,16,2
''';
  }

  static Future<List<int>> exportarReportePDF({
    required String tipoReporte,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    
    
    return [];
  }


  static Future<bool> programarReporteAutomatico({
    required String tipoReporte,
    required String frecuencia,
    required String email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    
    return true;
  }
}