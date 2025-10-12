import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

/// Servicio para consumir la API de Open Library
/// Open Library es completamente gratuita, sin límites y no requiere API Key
class OpenLibraryApiService {
  static const String _baseUrl = 'https://openlibrary.org';
  static const String _coversBaseUrl = 'https://covers.openlibrary.org/b';

  /// Buscar libros por término de búsqueda
  static Future<List<BookModel>> searchBooks({
    required String query,
    int maxResults = 20,
    int startIndex = 0,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/search.json?q=${Uri.encodeQueryComponent(query)}'
        '&limit=$maxResults&offset=$startIndex',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> docs = data['docs'] ?? [];
        
        return docs.map((doc) => _mapToBookModel(doc)).toList();
      } else {
        throw Exception('Error al buscar libros: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener libros por categoría/tema
  static Future<List<BookModel>> getBooksByCategory({
    required String category,
    int maxResults = 20,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/search.json?subject=${Uri.encodeQueryComponent(category)}'
        '&limit=$maxResults',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> docs = data['docs'] ?? [];
        
        return docs.map((doc) => _mapToBookModel(doc)).toList();
      } else {
        throw Exception('Error al buscar por categoría: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener libros más populares
  static Future<List<BookModel>> getPopularBooks({
    int maxResults = 20,
  }) async {
    // Buscar libros populares ordenados por número de ediciones
    final popularQueries = [
      'bestseller',
      'popular+fiction',
      'classic+literature',
      'programming',
      'science',
      'fantasy',
    ];
    
    final randomQuery = popularQueries[DateTime.now().millisecond % popularQueries.length];
    
    try {
      final url = Uri.parse(
        '$_baseUrl/search.json?q=$randomQuery'
        '&sort=editions&limit=$maxResults',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> docs = data['docs'] ?? [];
        
        return docs.map((doc) => _mapToBookModel(doc)).toList();
      } else {
        throw Exception('Error al buscar libros populares: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener libros por autor
  static Future<List<BookModel>> getBooksByAuthor({
    required String author,
    int maxResults = 20,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/search.json?author=${Uri.encodeQueryComponent(author)}'
        '&limit=$maxResults',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> docs = data['docs'] ?? [];
        
        return docs.map((doc) => _mapToBookModel(doc)).toList();
      } else {
        throw Exception('Error al buscar por autor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener detalles de un libro específico
  static Future<BookModel?> getBookById(String workId) async {
    try {
      // Limpiar el ID si viene con formato /works/OLXXXW
      final cleanId = workId.replaceAll('/works/', '');
      final url = Uri.parse('$_baseUrl/works/$cleanId.json');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _mapWorkToBookModel(data);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error al obtener detalles del libro: $e');
      return null;
    }
  }

  /// Obtener libros recomendados basados en categorías
  static Future<List<BookModel>> getRecommendedBooks({
    List<String> categories = const ['fiction', 'programming', 'science', 'history'],
    int maxResults = 20,
  }) async {
    final List<BookModel> allBooks = [];
    
    for (String category in categories) {
      try {
        final books = await getBooksByCategory(
          category: category,
          maxResults: maxResults ~/ categories.length,
        );
        allBooks.addAll(books);
      } catch (e) {
        debugPrint('Error obteniendo libros de $category: $e');
      }
    }
    
    return allBooks;
  }

  /// Construir URL de portada desde cover_id
  static String? getCoverUrl(dynamic coverId, {String size = 'M'}) {
    if (coverId == null) return null;
    
    // Tamaños disponibles: S (small), M (medium), L (large)
    return '$_coversBaseUrl/id/$coverId-$size.jpg';
  }

  /// Mapear documento de búsqueda de Open Library a BookModel
  static BookModel _mapToBookModel(Map<String, dynamic> doc) {
    final authors = doc['author_name'] != null 
        ? List<String>.from(doc['author_name']) 
        : <String>[];
    
    final coverId = doc['cover_i'];
    final thumbnail = getCoverUrl(coverId, size: 'M');
    
    // Tomar las primeras 5 categorías para no sobrecargar
    final subjects = doc['subject'] != null 
        ? (doc['subject'] as List).take(5).map((s) => s.toString()).toList()
        : <String>[];
    
    // El key en Open Library es algo como "/works/OL45804W"
    final workKey = doc['key'] ?? '';
    
    // Usar cover_edition_key como ID si está disponible, si no usar el work key
    final bookId = doc['cover_edition_key'] ?? workKey;
    
    return BookModel(
      id: bookId,
      title: doc['title'] ?? 'Sin título',
      authors: authors,
      authorsString: authors.isNotEmpty ? authors.join(', ') : 'Autor desconocido',
      thumbnail: thumbnail,
      description: doc['first_sentence']?.join(' '), // Descripción corta si está disponible
      publisher: doc['publisher'] != null && (doc['publisher'] as List).isNotEmpty
          ? doc['publisher'][0] 
          : null,
      publishedDate: doc['first_publish_year']?.toString(),
      averageRating: doc['ratings_average']?.toDouble(),
      ratingsCount: doc['ratings_count']?.toInt(),
      categories: subjects,
      pageCount: doc['number_of_pages_median']?.toInt(),
      language: doc['language'] != null && (doc['language'] as List).isNotEmpty
          ? doc['language'][0]
          : 'en',
      previewLink: 'https://openlibrary.org$workKey',
      infoLink: 'https://openlibrary.org$workKey',
    );
  }

  /// Mapear obra (work) de Open Library a BookModel
  static BookModel _mapWorkToBookModel(Map<String, dynamic> work) {
    // Extraer autores (vienen como referencias {key: "/authors/OL123A"})
    final List<String> authors = [];
    if (work['authors'] != null) {
      for (var author in work['authors']) {
        // Por ahora usamos el key del autor, en producción harías otro request
        final authorKey = author['author']?['key'] ?? '';
        if (authorKey.isNotEmpty) {
          authors.add(authorKey.split('/').last);
        }
      }
    }
    
    // Extraer cover_id si existe
    final coverId = work['covers'] != null && (work['covers'] as List).isNotEmpty
        ? work['covers'][0]
        : null;
    
    final thumbnail = getCoverUrl(coverId, size: 'L');
    
    // Extraer subjects (categorías)
    final subjects = work['subjects'] != null 
        ? (work['subjects'] as List).take(5).map((s) => s.toString()).toList()
        : <String>[];
    
    final workKey = work['key'] ?? '';
    
    return BookModel(
      id: workKey,
      title: work['title'] ?? 'Sin título',
      authors: authors,
      authorsString: authors.isNotEmpty ? authors.join(', ') : 'Autor desconocido',
      thumbnail: thumbnail,
      description: work['description'] is String 
          ? work['description']
          : (work['description']?['value'] ?? 'Sin descripción disponible'),
      publishedDate: work['first_publish_date']?.toString(),
      categories: subjects,
      previewLink: 'https://openlibrary.org$workKey',
      infoLink: 'https://openlibrary.org$workKey',
    );
  }
}
