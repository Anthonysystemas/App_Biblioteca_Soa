import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';


class GoogleBooksApiService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1';



  static Future<List<BookModel>> searchBooks({
    required String query,
    int maxResults = 20,
    int startIndex = 0,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/volumes?q=${Uri.encodeQueryComponent(query)}'
        '&maxResults=$maxResults'
        '&startIndex=$startIndex'
        '&printType=books'
        '&langRestrict=es,en',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        
        return items
            .map((item) => BookModel.fromJson(item))
            .where((book) => book.title.isNotEmpty)
            .toList();
      } else {
        throw Exception('Error al buscar libros: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<BookModel>> getBooksByCategory({
    required String category,
    int maxResults = 20,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/volumes?q=subject:${Uri.encodeQueryComponent(category)}'
        '&maxResults=$maxResults'
        '&printType=books'
        '&orderBy=relevance'
        '&langRestrict=es,en',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        return items
            .map((item) => BookModel.fromJson(item))
            .where((book) => 
              book.title.isNotEmpty &&
              book.authors.isNotEmpty &&
              book.thumbnail != null
            )
            .toList();
      } else {
        throw Exception('Error al buscar por categoría: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<BookModel>> getTrendingBooks({
    int maxResults = 20,
  }) async {
    try {
      // Buscar libros populares usando términos generales
      final url = Uri.parse(
        '$_baseUrl/volumes?q=bestseller OR trending'
        '&maxResults=$maxResults'
        '&printType=books'
        '&orderBy=relevance'
        '&langRestrict=es,en',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        return items
            .map((item) => BookModel.fromJson(item))
            .where((book) => 
              book.title.isNotEmpty &&
              book.thumbnail != null
            )
            .toList();
      } else {
        throw Exception('Error al obtener libros populares: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener detalles de un libro específico por ID
  static Future<BookModel?> getBookById(String bookId) async {
    try {
      final url = Uri.parse('$_baseUrl/volumes/$bookId');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BookModel.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error obteniendo libro $bookId: $e');
      return null;
    }
  }

  /// Obtener libros por múltiples categorías
  static Future<List<BookModel>> getBooksByMultipleCategories({
    required List<String> categories,
    int maxResults = 30,
  }) async {
    final Set<String> bookIds = {};
    final List<BookModel> allBooks = [];

    final resultsPerCategory = (maxResults / categories.length).ceil();

    for (String category in categories) {
      try {
        final books = await getBooksByCategory(
          category: category,
          maxResults: resultsPerCategory,
        );

        for (var book in books) {
          if (!bookIds.contains(book.id)) {
            bookIds.add(book.id);
            allBooks.add(book);

            if (allBooks.length >= maxResults) break;
          }
        }

        if (allBooks.length >= maxResults) break;
      } catch (e) {
        debugPrint('Error obteniendo libros de $category: $e');
      }
    }

    return allBooks;
  }
}
