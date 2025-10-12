import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Modelo de Stock
class StockItem {
  final String libroId;
  final int cantidad;
  final DateTime ultimaActualizacion;

  StockItem({
    required this.libroId,
    required this.cantidad,
    required this.ultimaActualizacion,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      libroId: json['libroId'],
      cantidad: json['cantidad'],
      ultimaActualizacion: DateTime.parse(json['ultimaActualizacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'libroId': libroId,
      'cantidad': cantidad,
      'ultimaActualizacion': ultimaActualizacion.toIso8601String(),
    };
  }
}

/// Servicio de Stock (MOCK - Datos temporales)
/// TODO: En el futuro, este servicio se conectará con el backend real
class StockService {
  // TODO: Reemplazar con tu URL del backend cuando esté listo
  // static const String baseUrl = 'https://tu-api.com/api/stock';
  
  static const String _stockKey = 'libros_stock';

  /// TODO: GET /api/stock/{libroId}
  /// Por ahora usa datos temporales en SharedPreferences
  static Future<int> getStockDisponible(String libroId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stockJson = prefs.getString(_stockKey);
      
      if (stockJson == null) {
        // Inicializar con stock por defecto para todos los libros
        return _getStockPorDefecto(libroId);
      }
      
      final List<dynamic> decoded = json.decode(stockJson);
      final stocks = decoded.map((json) => StockItem.fromJson(json)).toList();
      
      // Buscar el stock del libro
      final stockItem = stocks.firstWhere(
        (s) => s.libroId == libroId,
        orElse: () => StockItem(
          libroId: libroId,
          cantidad: _getStockPorDefecto(libroId),
          ultimaActualizacion: DateTime.now(),
        ),
      );
      
      return stockItem.cantidad;
    } catch (e) {
      debugPrint('Error al obtener stock: $e');
      return _getStockPorDefecto(libroId);
    }
  }

  /// TODO: PUT /api/stock/{libroId}
  /// Actualiza el stock localmente (suma o resta)
  /// cambio: puede ser negativo (-1 al prestar) o positivo (+1 al devolver)
  static Future<bool> actualizarStockLocal(String libroId, int cambio) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stockJson = prefs.getString(_stockKey);
      
      List<StockItem> stocks = [];
      if (stockJson != null) {
        final List<dynamic> decoded = json.decode(stockJson);
        stocks = decoded.map((json) => StockItem.fromJson(json)).toList();
      }
      
      // Buscar el índice del libro
      final index = stocks.indexWhere((s) => s.libroId == libroId);
      
      if (index != -1) {
        // Actualizar stock existente
        final nuevoStock = stocks[index].cantidad + cambio;
        stocks[index] = StockItem(
          libroId: libroId,
          cantidad: nuevoStock >= 0 ? nuevoStock : 0, // No permitir stock negativo
          ultimaActualizacion: DateTime.now(),
        );
      } else {
        // Crear nuevo registro de stock
        final stockInicial = _getStockPorDefecto(libroId);
        final nuevoStock = stockInicial + cambio;
        stocks.add(StockItem(
          libroId: libroId,
          cantidad: nuevoStock >= 0 ? nuevoStock : 0,
          ultimaActualizacion: DateTime.now(),
        ));
      }
      
      // Guardar
      await prefs.setString(_stockKey, json.encode(stocks.map((s) => s.toJson()).toList()));
      return true;
    } catch (e) {
      debugPrint('Error al actualizar stock: $e');
      return false;
    }
  }

  /// TODO: GET /api/stock/{libroId}/disponible
  /// Verifica si hay stock disponible
  static Future<bool> verificarDisponibilidad(String libroId) async {
    final stock = await getStockDisponible(libroId);
    return stock > 0;
  }

  /// Obtiene información detallada del stock
  static Future<Map<String, dynamic>> getStockInfo(String libroId) async {
    final stock = await getStockDisponible(libroId);
    final disponible = stock > 0;
    
    String mensaje;
    if (stock == 0) {
      mensaje = 'No disponible';
    } else if (stock <= 2) {
      mensaje = 'Últimas $stock unidades';
    } else if (stock <= 5) {
      mensaje = 'Stock limitado: $stock unidades';
    } else {
      mensaje = '$stock unidades disponibles';
    }
    
    return {
      'cantidad': stock,
      'disponible': disponible,
      'mensaje': mensaje,
    };
  }

  /// Stock por defecto para libros nuevos (MOCK)
  /// TODO: Eliminar cuando se conecte con backend
  static int _getStockPorDefecto(String libroId) {
    // Generar stock aleatorio entre 0 y 10 basado en el hash del ID
    // Esto hace que cada libro tenga siempre el mismo stock inicial
    final hash = libroId.hashCode.abs();
    return (hash % 11); // 0 a 10 unidades
  }

  /// Limpia datos locales (solo para desarrollo)
  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stockKey);
  }

  /// Inicializa stock para un libro si no existe
  static Future<void> inicializarStock(String libroId, {int cantidad = 5}) async {
    // Si ya existe un registro, no hacer nada
    final prefs = await SharedPreferences.getInstance();
    final stockJson = prefs.getString(_stockKey);
    
    if (stockJson != null) {
      final List<dynamic> decoded = json.decode(stockJson);
      final stocks = decoded.map((json) => StockItem.fromJson(json)).toList();
      final existe = stocks.any((s) => s.libroId == libroId);
      
      if (existe) return;
    }
    
    // Crear nuevo registro
    await actualizarStockLocal(libroId, cantidad - _getStockPorDefecto(libroId));
  }
}
