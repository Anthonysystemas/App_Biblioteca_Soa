import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_model.dart';

class BibliotecaService {
  static const String _bibliotecaKey = 'user_biblioteca';
  static const String _readingStatusKey = 'reading_status';

  // Obtener todos los libros de la biblioteca
  static Future<List<BookModel>> getBibliotecaBooks() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final bibliotecaJson = prefs.getString(_bibliotecaKey);
    final statusJson = prefs.getString(_readingStatusKey);
    
    if (bibliotecaJson == null) return [];
    
    final List<dynamic> bibliotecaList = json.decode(bibliotecaJson);
    final Map<String, dynamic> statusMap = statusJson != null 
        ? json.decode(statusJson) 
        : {};
    
    final List<BookModel> books = [];
    
    for (final bookData in bibliotecaList) {
      try {
        // CORRECCIÓN: Agregar readingStatus al JSON antes de crear el BookModel
        final bookJson = Map<String, dynamic>.from(bookData);
        bookJson['readingStatus'] = statusMap[bookJson['id']] ?? 'pendiente';
        
        final book = BookModel.fromJson(bookJson);
        books.add(book);
      } catch (e) {
        debugPrint('Error al cargar libro de biblioteca: $e');
        continue;
      }
    }
    
    return books;
  } catch (e) {
    debugPrint('Error al obtener biblioteca: $e');
    return [];
  }
}

  // Verificar si un libro está en la biblioteca
  static Future<bool> isInBiblioteca(String bookId) async {
    try {
      final books = await getBibliotecaBooks();
      return books.any((book) => book.id == bookId);
    } catch (e) {
      debugPrint('Error al verificar libro en biblioteca: $e');
      return false;
    }
  }

  // Agregar libro a la biblioteca
  static Future<bool> addToBiblioteca(BookModel book) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final books = await getBibliotecaBooks();
      
      // Verificar si ya existe
      if (books.any((b) => b.id == book.id)) {
        return false; // Ya existe
      }
      
      books.add(book);
      
      // Convertir todos los libros a JSON
      final bibliotecaJson = json.encode(
        books.map((b) => b.toJson()).toList(),
      );
      
      await prefs.setString(_bibliotecaKey, bibliotecaJson);
      
      // Agregar estado inicial como "pendiente"
      await updateReadingStatus(book.id, 'pendiente');
      
      return true;
    } catch (e) {
      debugPrint('Error al agregar a biblioteca: $e');
      return false;
    }
  }

  // Eliminar libro de la biblioteca
  static Future<bool> removeFromBiblioteca(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final books = await getBibliotecaBooks();
      
      books.removeWhere((book) => book.id == bookId);
      
      // Guardar lista actualizada
      final bibliotecaJson = json.encode(
        books.map((b) => b.toJson()).toList(),
      );
      
      await prefs.setString(_bibliotecaKey, bibliotecaJson);
      
      // También eliminar el estado de lectura
      final statusJson = prefs.getString(_readingStatusKey);
      if (statusJson != null) {
        final Map<String, dynamic> statusMap = json.decode(statusJson);
        statusMap.remove(bookId);
        await prefs.setString(_readingStatusKey, json.encode(statusMap));
      }
      
      return true;
    } catch (e) {
      debugPrint('Error al eliminar de biblioteca: $e');
      return false;
    }
  }

  // Alternar libro en biblioteca (agregar/quitar)
  static Future<bool> toggleBiblioteca(BookModel book) async {
    final isInBiblioteca = await BibliotecaService.isInBiblioteca(book.id);
    
    if (isInBiblioteca) {
      await removeFromBiblioteca(book.id);
      return false; // Fue eliminado
    } else {
      await addToBiblioteca(book);
      return true; // Fue agregado
    }
  }

  // Actualizar estado de lectura
  static Future<bool> updateReadingStatus(String bookId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_readingStatusKey);
      
      Map<String, dynamic> statusMap = {};
      if (statusJson != null) {
        statusMap = json.decode(statusJson);
      }
      
      statusMap[bookId] = status;
      
      await prefs.setString(_readingStatusKey, json.encode(statusMap));
      return true;
    } catch (e) {
      debugPrint('Error al actualizar estado de lectura: $e');
      return false;
    }
  }

  // Obtener estado de lectura de un libro
  static Future<String> getReadingStatus(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_readingStatusKey);
      
      if (statusJson == null) return 'pendiente';
      
      final Map<String, dynamic> statusMap = json.decode(statusJson);
      return statusMap[bookId] ?? 'pendiente';
    } catch (e) {
      debugPrint('Error al obtener estado de lectura: $e');
      return 'pendiente';
    }
  }

  // Limpiar toda la biblioteca
  static Future<bool> clearAllBiblioteca() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bibliotecaKey);
      await prefs.remove(_readingStatusKey);
      return true;
    } catch (e) {
      debugPrint('Error al limpiar biblioteca: $e');
      return false;
    }
  }

  // Obtener estadísticas de la biblioteca
  static Future<Map<String, int>> getBibliotecaStats() async {
    try {
      final books = await getBibliotecaBooks();
      
      return {
        'total': books.length,
        'leyendo': books.where((b) => b.readingStatus == 'leyendo').length,
        'pendientes': books.where((b) => b.readingStatus == 'pendiente').length,
        'completados': books.where((b) => b.readingStatus == 'completado').length,
      };
    } catch (e) {
      debugPrint('Error al obtener estadísticas: $e');
      return {
        'total': 0,
        'leyendo': 0,
        'pendientes': 0,
        'completados': 0,
      };
    }
  }

  // Obtener libros por estado
  static Future<List<BookModel>> getBooksByStatus(String status) async {
    try {
      final books = await getBibliotecaBooks();
      return books.where((book) => book.readingStatus == status).toList();
    } catch (e) {
      debugPrint('Error al obtener libros por estado: $e');
      return [];
    }
  }

  // Marcar libro como leído y moverlo a completados
  static Future<bool> markAsCompleted(String bookId) async {
    return await updateReadingStatus(bookId, 'completado');
  }

  // Comenzar a leer un libro
  static Future<bool> startReading(String bookId) async {
    return await updateReadingStatus(bookId, 'leyendo');
  }

  // Pausar lectura (mover a pendientes)
  static Future<bool> pauseReading(String bookId) async {
    return await updateReadingStatus(bookId, 'pendiente');
  }
}