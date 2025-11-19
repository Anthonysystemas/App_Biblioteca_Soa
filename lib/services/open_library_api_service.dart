import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';
import 'ejemplares_digitales_service.dart';

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

  /// Obtener libros por categoría/tema con búsqueda mejorada
  static Future<List<BookModel>> getBooksByCategory({
    required String category,
    int maxResults = 20,
  }) async {
    try {
      // Búsqueda más precisa usando subject con ordenamiento por rating
      final url = Uri.parse(
        '$_baseUrl/search.json?subject=${Uri.encodeQueryComponent(category)}'
        '&limit=$maxResults'
        '&sort=rating', // Ordenar por rating para obtener mejores libros
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> docs = data['docs'] ?? [];

        // Filtrar libros que tengan información completa
        final books = docs
            .map((doc) => _mapToBookModel(doc))
            .where((book) =>
              book.title.isNotEmpty &&
              book.authors.isNotEmpty &&
              book.thumbnail != null // Asegurar que tengan portada
            )
            .toList();

        return books;
      } else {
        throw Exception('Error al buscar por categoría: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener libros usando múltiples subjects para mayor precisión con validación balanceada
  static Future<List<BookModel>> getBooksByMultipleSubjects({
    required List<String> subjects,
    List<String> excludeKeywords = const [],
    int maxResults = 30,
  }) async {
    final Set<String> bookIds = {}; // Para evitar duplicados
    final List<BookModel> allBooks = [];

    // Convertir subjects a minúsculas para comparación
    final subjectsLower = subjects.map((s) => s.toLowerCase()).toList();
    final excludeKeywordsLower = excludeKeywords.map((k) => k.toLowerCase()).toList();

    // Usar más subjects para obtener más variedad
    final subjectsToSearch = subjects.take(6).toList();
    final resultsPerSubject = ((maxResults * 3) / subjectsToSearch.length).ceil();

    for (String subject in subjectsToSearch) {
      try {
        final url = Uri.parse(
          '$_baseUrl/search.json?subject=${Uri.encodeQueryComponent(subject)}'
          '&limit=$resultsPerSubject'
          '&sort=rating',
        );

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> docs = data['docs'] ?? [];

          for (var doc in docs) {
            // Verificar que el libro NO tenga palabras excluidas (solo las más obvias)
            if (_bookContainsStrictExcludedKeywords(doc, excludeKeywordsLower)) {
              continue; // Saltar este libro
            }

            final book = _mapToBookModel(doc);

            // Evitar duplicados y validar información básica
            if (!bookIds.contains(book.id) &&
                book.title.isNotEmpty &&
                book.authors.isNotEmpty) {

              // Solo verificar si tiene subjects relevantes O si no tiene exclude keywords
              final hasRelevantSubjects = book.categories.isEmpty ||
                  _bookHasRelevantSubjects(book.categories, subjectsLower);

              final noExcluded = !_categoriesContainExcludedKeywords(book.categories, excludeKeywordsLower);

              if (hasRelevantSubjects && noExcluded) {
                bookIds.add(book.id);
                allBooks.add(book);

                if (allBooks.length >= maxResults) break;
              }
            }
          }
        }

        if (allBooks.length >= maxResults) break;
      } catch (e) {
        debugPrint('Error obteniendo libros de $subject: $e');
        // Continuar con el siguiente subject
      }
    }

    return allBooks;
  }

  /// Verificar si las categorías del libro son relevantes
  static bool _bookHasRelevantSubjects(List<String> bookCategories, List<String> targetSubjects) {
    if (bookCategories.isEmpty) return false;

    final bookCategoriesLower = bookCategories.map((c) => c.toLowerCase()).toList();

    for (String targetSubject in targetSubjects) {
      for (String bookCategory in bookCategoriesLower) {
        if (bookCategory == targetSubject ||
            bookCategory.contains(targetSubject) ||
            targetSubject.contains(bookCategory.split(' ').first)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Verificar si un documento contiene palabras clave excluidas (versión estricta - solo obvias)
  static bool _bookContainsStrictExcludedKeywords(Map<String, dynamic> doc, List<String> excludeKeywords) {
    if (excludeKeywords.isEmpty) return false;

    final bookSubjects = doc['subject'];
    final title = (doc['title'] ?? '').toString().toLowerCase();

    // Solo rechazar si el título contiene palabras muy obvias
    final obviousKeywords = ['fiction', 'novel', 'romance', 'mystery', 'fantasy', 'adventure'];

    for (String keyword in obviousKeywords) {
      if (excludeKeywords.contains(keyword) && title.contains(keyword)) {
        return true;
      }
    }

    // Verificar subjects solo si existen
    if (bookSubjects != null && bookSubjects is List && bookSubjects.isNotEmpty) {
      final bookSubjectsLower = bookSubjects
          .map((s) => s.toString().toLowerCase())
          .toList();

      // Contar cuántas palabras excluidas tiene
      int excludeCount = 0;
      for (String excludeKeyword in excludeKeywords) {
        for (String bookSubject in bookSubjectsLower) {
          // Solo si es coincidencia exacta
          if (bookSubject == excludeKeyword) {
            excludeCount++;
            if (excludeCount >= 2) return true; // Si tiene 2 o más, rechazar
          }
        }
      }
    }

    return false;
  }

  /// Verificar si las categorías contienen palabras excluidas (versión flexible)
  static bool _categoriesContainExcludedKeywords(List<String> categories, List<String> excludeKeywords) {
    if (excludeKeywords.isEmpty) return false;
    if (categories.isEmpty) return false;

    final categoriesLower = categories.map((c) => c.toLowerCase()).toList();
    final obviousKeywords = ['fiction', 'novel', 'romance', 'mystery', 'fantasy'];

    int matchCount = 0;

    for (String excludeKeyword in excludeKeywords) {
      for (String category in categoriesLower) {
        // Solo rechazar si es coincidencia exacta con palabras obvias
        if (obviousKeywords.contains(excludeKeyword) && category == excludeKeyword) {
          matchCount++;
          if (matchCount >= 1) return true; // Una palabra obvia es suficiente
        }
      }
    }

    return false;
  }

  /// Buscar libros con términos específicos y mejor relevancia
  static Future<List<BookModel>> searchBooksAdvanced({
    required String query,
    List<String> subjects = const [],
    int maxResults = 20,
  }) async {
    try {
      // Construir query avanzada
      String fullQuery = query;

      // Si hay subjects, agregarlos para mejorar precisión
      if (subjects.isNotEmpty) {
        final subjectQuery = subjects.take(2).join(' OR ');
        fullQuery = '$query AND ($subjectQuery)';
      }

      final url = Uri.parse(
        '$_baseUrl/search.json?q=${Uri.encodeQueryComponent(fullQuery)}'
        '&limit=$maxResults'
        '&sort=rating',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> docs = data['docs'] ?? [];

        final books = docs
            .map((doc) => _mapToBookModel(doc))
            .where((book) =>
              book.title.isNotEmpty &&
              book.authors.isNotEmpty
            )
            .toList();

        return books;
      } else {
        throw Exception('Error en búsqueda avanzada: ${response.statusCode}');
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

  // ============================================================
  // MÉTODOS EXTENDIDOS CON DISPONIBILIDAD DIGITAL
  // ============================================================

  /// Buscar libros CON información de disponibilidad digital
  /// Extiende searchBooks() agregando disponibilidad de ejemplares
  static Future<List<Map<String, dynamic>>> searchBooksWithAvailability({
    required String query,
    int maxResults = 20,
    int startIndex = 0,
  }) async {
    final books = await searchBooks(
      query: query,
      maxResults: maxResults,
      startIndex: startIndex,
    );

    // Agregar disponibilidad a cada libro
    final booksWithAvailability = <Map<String, dynamic>>[];

    for (final book in books) {
      final disponibilidad = await EjemplaresDigitalesService.consultarDisponibilidad(book.id);

      booksWithAvailability.add({
        'book': book,
        'disponibilidad': disponibilidad,
        'ejemplaresTotales': disponibilidad.ejemplaresTotales,
        'ejemplaresDisponibles': disponibilidad.ejemplaresDisponibles,
        'ejemplaresEnUso': disponibilidad.ejemplaresEnUso,
        'disponible': disponibilidad.disponible,
        'mensaje': disponibilidad.mensaje,
      });
    }

    return booksWithAvailability;
  }

  /// Obtener libros por categoría CON disponibilidad
  static Future<List<Map<String, dynamic>>> getBooksByCategoryWithAvailability({
    required String category,
    int maxResults = 20,
  }) async {
    final books = await getBooksByCategory(
      category: category,
      maxResults: maxResults,
    );

    final booksWithAvailability = <Map<String, dynamic>>[];

    for (final book in books) {
      final disponibilidad = await EjemplaresDigitalesService.consultarDisponibilidad(book.id);

      booksWithAvailability.add({
        'book': book,
        'disponibilidad': disponibilidad,
        'ejemplaresTotales': disponibilidad.ejemplaresTotales,
        'ejemplaresDisponibles': disponibilidad.ejemplaresDisponibles,
        'ejemplaresEnUso': disponibilidad.ejemplaresEnUso,
        'disponible': disponibilidad.disponible,
        'mensaje': disponibilidad.mensaje,
      });
    }

    return booksWithAvailability;
  }

  /// Obtener información completa de un libro CON disponibilidad
  static Future<Map<String, dynamic>> getBookWithAvailability(BookModel book) async {
    final disponibilidad = await EjemplaresDigitalesService.consultarDisponibilidad(book.id);

    return {
      'book': book,
      'disponibilidad': disponibilidad,
      'ejemplaresTotales': disponibilidad.ejemplaresTotales,
      'ejemplaresDisponibles': disponibilidad.ejemplaresDisponibles,
      'ejemplaresEnUso': disponibilidad.ejemplaresEnUso,
      'disponible': disponibilidad.disponible,
      'mensaje': disponibilidad.mensaje,
    };
  }

  /// Obtener solo la disponibilidad de un libro (sin consultar API)
  static Future<DisponibilidadDigital> getBookAvailability(String libroId) async {
    return await EjemplaresDigitalesService.consultarDisponibilidad(libroId);
  }
}
