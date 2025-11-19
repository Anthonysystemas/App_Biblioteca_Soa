import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'prestamos_service.dart';
import 'reservas_service.dart';

/// Servicio de Reportes y Estadísticas
class ReportesService {
  // TODO: Reemplazar con tu URL del backend
  static const String baseUrl = 'https://tu-api.com/api';

  // ========== REPORTES DE USUARIO ==========

  /// Obtener resumen de actividad del usuario
  /// GET /api/reportes/usuario/resumen
  static Future<Map<String, dynamic>> getResumenUsuario() async {
    // TODO: Reemplazar con llamada al backend
    // Por ahora usa datos locales
    
    final prestamos = await PrestamosService.getPrestamosActivos();
    final reservas = await ReservasService.getReservasActivas();
    final historial = await PrestamosService.getHistorial();
    
    // Calcular libros leídos (préstamos devueltos)
    final prefs = await SharedPreferences.getInstance();
    final prestamosJson = prefs.getString('prestamos_locales');
    int librosLeidos = 0;
    if (prestamosJson != null) {
      final List<dynamic> decoded = json.decode(prestamosJson);
      librosLeidos = decoded.where((p) => p['estado'] == 'devuelto').length;
    }
    
    return {
      'libros_leidos': librosLeidos,
      'libros_activos': prestamos.length,
      'reservas_activas': reservas.length,
      'historial': historial.length,
    };
  }

  /// Historial completo de préstamos del usuario
  /// GET /api/reportes/usuario/historial
  static Future<List<Map<String, dynamic>>> getHistorialUsuario({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Reemplazar con llamada al backend
    
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

  /// Estadísticas de lectura por categoría
  /// GET /api/reportes/usuario/por-categoria
  static Future<List<Map<String, dynamic>>> getEstadisticasPorCategoria() async {
    // TODO: Reemplazar con llamada al backend
    
    // Obtener historial de préstamos (libros devueltos/leídos)
    final prefs = await SharedPreferences.getInstance();
    final prestamosJson = prefs.getString('prestamos_locales');
    
    if (prestamosJson == null) {
      return [];
    }
    
    final List<dynamic> decoded = json.decode(prestamosJson);
    
    // Filtrar solo préstamos devueltos (historial)
    final historial = decoded.where((p) => p['estado'] == 'devuelto').toList();
    
    if (historial.isEmpty) {
      return [];
    }
    
    final Map<String, int> categorias = {};
    
    // Contar libros por categoría basado en el historial
    for (var prestamo in historial) {
      // Obtener categoría del libro (si existe)
      String categoria = 'Otros';
      
      final titulo = (prestamo['titulo'] ?? '').toString().toLowerCase();
      final autor = (prestamo['autor'] ?? '').toString().toLowerCase();
      
      // Clasificar por palabras clave
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
    
    // Convertir a lista y calcular porcentajes
    final total = historial.length;
    final List<Map<String, dynamic>> resultado = [];
    
    categorias.forEach((categoria, cantidad) {
      resultado.add({
        'categoria': categoria,
        'cantidad': cantidad,
        'porcentaje': total > 0 ? ((cantidad / total) * 100).round() : 0,
      });
    });
    
    // Ordenar por cantidad descendente
    resultado.sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));
    
    // Limitar a máximo 5 categorías
    return resultado.take(5).toList();
  }

  // ========== REPORTES ADMINISTRATIVOS ==========

  /// Reporte de préstamos en un período
  /// GET /api/reportes/admin/prestamos
  static Future<Map<String, dynamic>> getReportePrestamos({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Reemplazar con llamada al backend
    
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

  /// Reporte de usuarios más activos
  /// GET /api/reportes/admin/usuarios-activos
  static Future<List<Map<String, dynamic>>> getUsuariosMasActivos({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Reemplazar con llamada al backend
    
    return [
      {'usuario': 'juan_perez', 'prestamos': 25, 'reservas': 5},
      {'usuario': 'maria_garcia', 'prestamos': 20, 'reservas': 3},
      {'usuario': 'carlos_lopez', 'prestamos': 18, 'reservas': 7},
    ];
  }

  /// Reporte de libros más populares
  /// GET /api/reportes/admin/libros-populares
  static Future<List<Map<String, dynamic>>> getLibrosMasPopulares({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Reemplazar con llamada al backend
    
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

  /// Reporte de disponibilidad del catálogo
  /// GET /api/reportes/admin/disponibilidad
  static Future<Map<String, dynamic>> getReporteDisponibilidad() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Reemplazar con llamada al backend
    
    return {
      'total_libros': 1250,
      'disponibles': 980,
      'prestados': 245,
      'en_mantenimiento': 15,
      'reservados': 10,
      'porcentaje_disponibilidad': 78.4,
    };
  }

  /// Reporte de multas y sanciones
  /// GET /api/reportes/admin/multas
  static Future<Map<String, dynamic>> getReporteMultas({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Reemplazar con llamada al backend
    
    return {
      'multas_generadas': 28,
      'multas_pagadas': 20,
      'multas_pendientes': 8,
      'monto_total': 560.00,
      'monto_cobrado': 400.00,
      'monto_pendiente': 160.00,
    };
  }

  // ========== REPORTES DE TENDENCIAS ==========

  /// Tendencias de préstamos por mes
  /// GET /api/reportes/tendencias/por-mes
  static Future<List<Map<String, dynamic>>> getTendenciasPorMes({
    int mesesAtras = 6,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Reemplazar con llamada al backend
    
    return [
      {'mes': 'Octubre', 'prestamos': 145, 'usuarios_activos': 87},
      {'mes': 'Septiembre', 'prestamos': 132, 'usuarios_activos': 78},
      {'mes': 'Agosto', 'prestamos': 128, 'usuarios_activos': 72},
      {'mes': 'Julio', 'prestamos': 115, 'usuarios_activos': 65},
      {'mes': 'Junio', 'prestamos': 98, 'usuarios_activos': 58},
      {'mes': 'Mayo', 'prestamos': 105, 'usuarios_activos': 62},
    ];
  }

  /// Tendencias por categoría
  /// GET /api/reportes/tendencias/por-categoria
  static Future<List<Map<String, dynamic>>> getTendenciasPorCategoria() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Reemplazar con llamada al backend
    
    return [
      {
        'categoria': 'Programación',
        'prestamos': 245,
        'tendencia': 'subiendo', // 'subiendo', 'bajando', 'estable'
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

  // ========== EXPORTAR REPORTES ==========

  /// Exportar reporte a CSV
  /// GET /api/reportes/exportar/csv
  static Future<String> exportarReporteCSV({
    required String tipoReporte,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // TODO: Reemplazar con llamada al backend que retorna CSV
    // final response = await http.get(
    //   '$baseUrl/reportes/exportar/csv?tipo=$tipoReporte&desde=$desde&hasta=$hasta'
    // );
    // return response.body;
    
    // Mock - Retorna CSV en string
    return '''
Usuario,Préstamos,Devoluciones,Multas
juan_perez,25,23,2
maria_garcia,20,20,0
carlos_lopez,18,16,2
''';
  }

  /// Exportar reporte a PDF
  /// GET /api/reportes/exportar/pdf
  static Future<List<int>> exportarReportePDF({
    required String tipoReporte,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    
    // TODO: Reemplazar con llamada al backend que retorna PDF bytes
    // final response = await http.get(
    //   '$baseUrl/reportes/exportar/pdf?tipo=$tipoReporte&desde=$desde&hasta=$hasta'
    // );
    // return response.bodyBytes;
    
    // Mock - Retorna bytes vacíos
    return [];
  }

  // ========== NOTIFICACIONES DE REPORTES ==========

  /// Programar reporte automático
  /// POST /api/reportes/programar
  static Future<bool> programarReporteAutomatico({
    required String tipoReporte,
    required String frecuencia, // 'diario', 'semanal', 'mensual'
    required String email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Reemplazar con llamada al backend
    
    return true; // Programación exitosa
  }
}
