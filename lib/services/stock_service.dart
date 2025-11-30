import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

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

class StockService {
  
  static const String _stockKey = 'libros_stock';

  static Future<int> getStockDisponible(String libroId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stockJson = prefs.getString(_stockKey);
      
      if (stockJson == null) {
        return _getStockPorDefecto(libroId);
      }
      
      final List<dynamic> decoded = json.decode(stockJson);
      final stocks = decoded.map((json) => StockItem.fromJson(json)).toList();
      
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

  static Future<bool> actualizarStockLocal(String libroId, int cambio) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stockJson = prefs.getString(_stockKey);
      
      List<StockItem> stocks = [];
      if (stockJson != null) {
        final List<dynamic> decoded = json.decode(stockJson);
        stocks = decoded.map((json) => StockItem.fromJson(json)).toList();
      }
      
      final index = stocks.indexWhere((s) => s.libroId == libroId);
      
      if (index != -1) {
        final nuevoStock = stocks[index].cantidad + cambio;
        stocks[index] = StockItem(
          libroId: libroId,
          cantidad: nuevoStock >= 0 ? nuevoStock : 0,
          ultimaActualizacion: DateTime.now(),
        );
      } else {
        final stockInicial = _getStockPorDefecto(libroId);
        final nuevoStock = stockInicial + cambio;
        stocks.add(StockItem(
          libroId: libroId,
          cantidad: nuevoStock >= 0 ? nuevoStock : 0,
          ultimaActualizacion: DateTime.now(),
        ));
      }
      
      await prefs.setString(_stockKey, json.encode(stocks.map((s) => s.toJson()).toList()));
      return true;
    } catch (e) {
      debugPrint('Error al actualizar stock: $e');
      return false;
    }
  }

  static Future<bool> verificarDisponibilidad(String libroId) async {
    final stock = await getStockDisponible(libroId);
    return stock > 0;
  }

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

  static int _getStockPorDefecto(String libroId) {
    final hash = libroId.hashCode.abs();
    final modulo = hash % 20;
    
    if (modulo < 6) {
      return 0;
    } else if (modulo < 10) {
      return 1 + (modulo % 2);
    } else {
      return 3 + (modulo % 8);
    }
  }

  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stockKey);
  }

  static Future<void> inicializarStock(String libroId, {int cantidad = 5}) async {
    final prefs = await SharedPreferences.getInstance();
    final stockJson = prefs.getString(_stockKey);
    
    if (stockJson != null) {
      final List<dynamic> decoded = json.decode(stockJson);
      final stocks = decoded.map((json) => StockItem.fromJson(json)).toList();
      final existe = stocks.any((s) => s.libroId == libroId);
      
      if (existe) return;
    }
    
    await actualizarStockLocal(libroId, cantidad - _getStockPorDefecto(libroId));
  }

  static Future<void> setStockManual(String libroId, int cantidad) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stockJson = prefs.getString(_stockKey);
      
      List<StockItem> stocks = [];
      if (stockJson != null) {
        final List<dynamic> decoded = json.decode(stockJson);
        stocks = decoded.map((json) => StockItem.fromJson(json)).toList();
      }
      
      final index = stocks.indexWhere((s) => s.libroId == libroId);
      
      if (index != -1) {
        stocks[index] = StockItem(
          libroId: libroId,
          cantidad: cantidad >= 0 ? cantidad : 0,
          ultimaActualizacion: DateTime.now(),
        );
      } else {
        stocks.add(StockItem(
          libroId: libroId,
          cantidad: cantidad >= 0 ? cantidad : 0,
          ultimaActualizacion: DateTime.now(),
        ));
      }
      
      await prefs.setString(_stockKey, json.encode(stocks.map((s) => s.toJson()).toList()));
      debugPrint('📦 Stock actualizado manualmente para $libroId: $cantidad unidades');
    } catch (e) {
      debugPrint('Error al establecer stock manual: $e');
    }
  }

  static Future<void> configurarLibrosParaPruebas() async {
    final librosConStockCero = [
      'nggnmAEACAAJ',
      'wrOQLV6xB-wC',
      '_ojXNuzgHRcC',
      'yxv1LK5gyAYC',
      'yl4dILkcqm4C',
    ];

    for (final libroId in librosConStockCero) {
      await setStockManual(libroId, 0);
    }

    debugPrint('✅ Configurados ${librosConStockCero.length} libros con stock = 0 para testing');
  }
}