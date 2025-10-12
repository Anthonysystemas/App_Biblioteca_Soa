import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/book_model.dart';

/// Servicio para gestionar libros vistos recientemente
class RecentlyViewedService {
  static const String _recentlyViewedKey = 'recently_viewed_books';
  static const int maxRecentBooks = 10; // Máximo de libros en el historial

  /// Agregar un libro al historial de vistos recientemente
  static Future<void> addBook(BookModel book) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentlyViewedJson = prefs.getString(_recentlyViewedKey);

      List<Map<String, dynamic>> books = [];
      if (recentlyViewedJson != null) {
        final List<dynamic> decoded = json.decode(recentlyViewedJson);
        books = decoded.cast<Map<String, dynamic>>();
      }

      // Crear mapa del libro
      final bookMap = {
        'id': book.id,
        'title': book.title,
        'authors': book.authors,
        'thumbnail': book.thumbnail,
        'averageRating': book.averageRating,
        'categories': book.categories,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Eliminar si ya existe (para moverlo al inicio)
      books.removeWhere((b) => b['id'] == book.id);

      // Agregar al inicio
      books.insert(0, bookMap);

      // Limitar a los últimos N libros
      if (books.length > maxRecentBooks) {
        books = books.sublist(0, maxRecentBooks);
      }

      await prefs.setString(_recentlyViewedKey, json.encode(books));
    } catch (e) {
      // Error silencioso, no afecta la experiencia del usuario
      debugPrint('Error al guardar libro visto: $e');
    }
  }

  /// Obtener el último libro visto
  static Future<BookModel?> getLastViewedBook() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentlyViewedJson = prefs.getString(_recentlyViewedKey);

      if (recentlyViewedJson == null) return null;

      final List<dynamic> decoded = json.decode(recentlyViewedJson);
      if (decoded.isEmpty) return null;

      final Map<String, dynamic> lastBook = decoded.first;

      // Construir BookModel desde el mapa
      final authors = (lastBook['authors'] as List<dynamic>?)?.cast<String>() ?? [];
      final categories = (lastBook['categories'] as List<dynamic>?)?.cast<String>() ?? [];
      return BookModel(
        id: lastBook['id'] as String,
        title: lastBook['title'] as String,
        authors: authors,
        authorsString: authors.join(', '),
        thumbnail: lastBook['thumbnail'] as String?,
        averageRating: lastBook['averageRating'] as double?,
        categories: categories,
      );
    } catch (e) {
      debugPrint('Error al obtener último libro visto: $e');
      return null;
    }
  }

  /// Obtener todos los libros vistos recientemente
  static Future<List<BookModel>> getAllRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentlyViewedJson = prefs.getString(_recentlyViewedKey);

      if (recentlyViewedJson == null) return [];

      final List<dynamic> decoded = json.decode(recentlyViewedJson);

      return decoded.map<BookModel>((bookMap) {
        final authors = (bookMap['authors'] as List<dynamic>?)?.cast<String>() ?? [];
        final categories = (bookMap['categories'] as List<dynamic>?)?.cast<String>() ?? [];
        return BookModel(
          id: bookMap['id'] as String,
          title: bookMap['title'] as String,
          authors: authors,
          authorsString: authors.join(', '),
          thumbnail: bookMap['thumbnail'] as String?,
          averageRating: bookMap['averageRating'] as double?,
          categories: categories,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener libros vistos: $e');
      return [];
    }
  }

  /// Limpiar historial
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentlyViewedKey);
    } catch (e) {
      debugPrint('Error al limpiar historial: $e');
    }
  }
}
