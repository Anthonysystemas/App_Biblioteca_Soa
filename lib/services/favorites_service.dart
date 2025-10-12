import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_model.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_books';

  /// Obtener todos los libros favoritos
  static Future<List<BookModel>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
      
      return favoritesJson.map((jsonString) {
        final Map<String, dynamic> bookData = json.decode(jsonString);
        return BookModel.fromJson({'id': bookData['id'], 'volumeInfo': bookData});
      }).toList();
    } catch (e) {
      debugPrint('Error al cargar favoritos: $e');
      return [];
    }
  }

  /// Agregar un libro a favoritos
  static Future<bool> addToFavorites(BookModel book) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
      
      // Verificar si ya está en favoritos
      final isAlreadyFavorite = favoritesJson.any((jsonString) {
        final Map<String, dynamic> bookData = json.decode(jsonString);
        return bookData['id'] == book.id;
      });

      if (isAlreadyFavorite) {
        return false; // Ya está en favoritos
      }

      // Crear objeto JSON del libro
      final bookJson = json.encode({
        'id': book.id,
        'title': book.title,
        'authors': book.authors,
        'description': book.description,
        'thumbnail': book.thumbnail,
        'publishedDate': book.publishedDate,
        'publisher': book.publisher,
        'pageCount': book.pageCount,
        'categories': book.categories,
        'averageRating': book.averageRating,
        'language': book.language,
        'previewLink': book.previewLink,
      });

      favoritesJson.add(bookJson);
      await prefs.setStringList(_favoritesKey, favoritesJson);
      return true;
    } catch (e) {
      debugPrint('Error al agregar a favoritos: $e');
      return false;
    }
  }

  /// Eliminar un libro de favoritos
  static Future<bool> removeFromFavorites(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
      
      favoritesJson.removeWhere((jsonString) {
        final Map<String, dynamic> bookData = json.decode(jsonString);
        return bookData['id'] == bookId;
      });

      await prefs.setStringList(_favoritesKey, favoritesJson);
      return true;
    } catch (e) {
      debugPrint('Error al eliminar de favoritos: $e');
      return false;
    }
  }

  /// Verificar si un libro está en favoritos
  static Future<bool> isFavorite(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
      
      return favoritesJson.any((jsonString) {
        final Map<String, dynamic> bookData = json.decode(jsonString);
        return bookData['id'] == bookId;
      });
    } catch (e) {
      debugPrint('Error al verificar favoritos: $e');
      return false;
    }
  }

  /// Alternar estado de favorito (agregar si no está, eliminar si está)
  static Future<bool> toggleFavorite(BookModel book) async {
    try {
      final isFav = await isFavorite(book.id);
      
      if (isFav) {
        await removeFromFavorites(book.id);
        return false; // Eliminado de favoritos
      } else {
        await addToFavorites(book);
        return true; // Agregado a favoritos
      }
    } catch (e) {
      debugPrint('Error al alternar favorito: $e');
      return false;
    }
  }

  /// Obtener cantidad de favoritos
  static Future<int> getFavoritesCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
      return favoritesJson.length;
    } catch (e) {
      debugPrint('Error al obtener cantidad de favoritos: $e');
      return 0;
    }
  }

  /// Limpiar todos los favoritos
  static Future<bool> clearAllFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      return true;
    } catch (e) {
      debugPrint('Error al limpiar favoritos: $e');
      return false;
    }
  }
}