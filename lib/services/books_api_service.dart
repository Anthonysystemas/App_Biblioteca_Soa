import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class BookModel {
  final String id;
  final String title;
  final List<String> authors;
  final String authorsString;
  final String? thumbnail;
  final String? description;
  final String? publisher;
  final String? publishedDate;
  final double? averageRating;
  final int? ratingsCount;
  final List<String> categories;
  final int? pageCount;
  final String? language;
  final String? previewLink;
  final String? infoLink;
  
  // PROPIEDAD MUTABLE para biblioteca
  String _readingStatus;

  BookModel({
    required this.id,
    required this.title,
    required this.authors,
    required this.authorsString,
    this.thumbnail,
    this.description,
    this.publisher,
    this.publishedDate,
    this.averageRating,
    this.ratingsCount,
    required this.categories,
    this.pageCount,
    this.language,
    this.previewLink,
    this.infoLink,
    String? readingStatus,
  }) : _readingStatus = readingStatus ?? 'pendiente';

  // GETTER Y SETTER para readingStatus
  String get readingStatus => _readingStatus;
  set readingStatus(String value) => _readingStatus = value;

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    final authors = volumeInfo['authors'] != null 
        ? List<String>.from(volumeInfo['authors']) 
        : <String>[];
    
    return BookModel(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'Sin título',
      authors: authors,
      authorsString: authors.isNotEmpty ? authors.join(', ') : 'Autor desconocido',
      thumbnail: volumeInfo['imageLinks']?['thumbnail']?.toString().replaceAll('http:', 'https:'),
      description: volumeInfo['description']?.toString(),
      publisher: volumeInfo['publisher']?.toString(),
      publishedDate: volumeInfo['publishedDate']?.toString(),
      averageRating: volumeInfo['averageRating']?.toDouble(),
      ratingsCount: volumeInfo['ratingsCount']?.toInt(),
      categories: volumeInfo['categories'] != null 
          ? List<String>.from(volumeInfo['categories']) 
          : <String>[],
      pageCount: volumeInfo['pageCount']?.toInt(),
      language: volumeInfo['language']?.toString(),
      previewLink: volumeInfo['previewLink']?.toString(),
      infoLink: volumeInfo['infoLink']?.toString(),
      readingStatus: json['readingStatus']?.toString() ?? 'pendiente',
    );
  }

  // MÉTODO TOJSON REQUERIDO
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'volumeInfo': {
        'title': title,
        'authors': authors,
        'description': description,
        'publisher': publisher,
        'publishedDate': publishedDate,
        'averageRating': averageRating,
        'ratingsCount': ratingsCount,
        'categories': categories,
        'pageCount': pageCount,
        'language': language,
        'previewLink': previewLink,
        'infoLink': infoLink,
        'imageLinks': thumbnail != null ? {'thumbnail': thumbnail} : null,
      },
      'readingStatus': _readingStatus,
    };
  }

  // Compatibilidad con código existente
  String? get author => authors.isNotEmpty ? authors.first : null;
  String get categoriesString => categories.join(', ');

  // Métodos helper para estados
  Color getStatusColor() {
    switch (_readingStatus) {
      case 'leyendo':
        return const Color(0xFF10B981);
      case 'completado':
        return const Color(0xFF059669);
      case 'pendiente':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String getStatusText() {
    switch (_readingStatus) {
      case 'leyendo':
        return 'Leyendo';
      case 'completado':
        return 'Completado';
      case 'pendiente':
      default:
        return 'Pendiente';
    }
  }

  IconData getStatusIcon() {
    switch (_readingStatus) {
      case 'leyendo':
        return Icons.play_circle;
      case 'completado':
        return Icons.check_circle;
      case 'pendiente':
      default:
        return Icons.schedule;
    }
  }

  void updateReadingStatus(String newStatus) {
    _readingStatus = newStatus;
  }

  bool get isPending => _readingStatus == 'pendiente';
  bool get isReading => _readingStatus == 'leyendo';
  bool get isCompleted => _readingStatus == 'completado';

  BookModel copyWith({
    String? id,
    String? title,
    List<String>? authors,
    String? authorsString,
    String? thumbnail,
    String? description,
    String? publisher,
    String? publishedDate,
    double? averageRating,
    int? ratingsCount,
    List<String>? categories,
    int? pageCount,
    String? language,
    String? previewLink,
    String? infoLink,
    String? readingStatus,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      authorsString: authorsString ?? this.authorsString,
      thumbnail: thumbnail ?? this.thumbnail,
      description: description ?? this.description,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      averageRating: averageRating ?? this.averageRating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      categories: categories ?? this.categories,
      pageCount: pageCount ?? this.pageCount,
      language: language ?? this.language,
      previewLink: previewLink ?? this.previewLink,
      infoLink: infoLink ?? this.infoLink,
      readingStatus: readingStatus ?? this._readingStatus,
    );
  }

  @override
  String toString() {
    return 'BookModel(id: $id, title: $title, authors: $authorsString, status: $_readingStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class BooksApiService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1';
  
  // Puedes obtener una API key gratuita en Google Cloud Console
  // static const String _apiKey = 'TU_API_KEY_AQUI'; // Opcional para más requests

  /// Buscar libros por término de búsqueda
  static Future<List<BookModel>> searchBooks({
    required String query,
    int maxResults = 20,
    int startIndex = 0,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/volumes?q=${Uri.encodeQueryComponent(query)}'
        '&maxResults=$maxResults&startIndex=$startIndex'
        // '&key=$_apiKey' // Descomenta si tienes API key
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        
        return items.map((item) => BookModel.fromJson(item)).toList();
      } else {
        throw Exception('Error al buscar libros: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener libros por categoría
  static Future<List<BookModel>> getBooksByCategory({
    required String category,
    int maxResults = 20,
  }) async {
    return searchBooks(
      query: 'subject:$category',
      maxResults: maxResults,
    );
  }

  /// Obtener libros más populares
  static Future<List<BookModel>> getPopularBooks({
    int maxResults = 20,
  }) async {
    // Buscar libros populares usando términos comunes
    final popularTerms = [
      'bestseller',
      'popular fiction',
      'classic literature',
      'programming',
      'science',
    ];
    
    final randomTerm = popularTerms[DateTime.now().millisecond % popularTerms.length];
    return searchBooks(
      query: randomTerm,
      maxResults: maxResults,
    );
  }

  /// Obtener libros por autor
  static Future<List<BookModel>> getBooksByAuthor({
    required String author,
    int maxResults = 20,
  }) async {
    return searchBooks(
      query: 'inauthor:$author',
      maxResults: maxResults,
    );
  }

  /// Obtener detalles de un libro específico
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
      return null;
    }
  }

  /// Obtener libros recomendados basados en categorías
  static Future<List<BookModel>> getRecommendedBooks({
    List<String> categories = const ['fiction', 'programming', 'science'],
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
        print('Error al obtener libros de categoría $category: $e');
      }
    }
    
    return allBooks;
  }
}