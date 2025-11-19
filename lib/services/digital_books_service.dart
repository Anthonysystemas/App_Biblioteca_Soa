import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Modelo de libro digital
class DigitalBook {
  final String libroId;
  final String titulo;
  final String filePath;
  final String fileType; // 'pdf', 'epub', 'txt'
  final DateTime addedDate;

  DigitalBook({
    required this.libroId,
    required this.titulo,
    required this.filePath,
    required this.fileType,
    required this.addedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'libroId': libroId,
      'titulo': titulo,
      'filePath': filePath,
      'fileType': fileType,
      'addedDate': addedDate.toIso8601String(),
    };
  }

  factory DigitalBook.fromJson(Map<String, dynamic> json) {
    return DigitalBook(
      libroId: json['libroId'],
      titulo: json['titulo'],
      filePath: json['filePath'],
      fileType: json['fileType'],
      addedDate: DateTime.parse(json['addedDate']),
    );
  }
}

/// Servicio para gestionar libros digitales (PDF, EPUB)
class DigitalBooksService {
  static const String _digitalBooksKey = 'digital_books';

  /// Obtener todos los libros digitales almacenados
  static Future<List<DigitalBook>> getDigitalBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getString(_digitalBooksKey);

      if (booksJson == null) return [];

      final List<dynamic> decoded = json.decode(booksJson);
      return decoded.map((json) => DigitalBook.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error al obtener libros digitales: $e');
      return [];
    }
  }

  /// Verificar si un libro tiene archivo digital asociado
  static Future<DigitalBook?> getDigitalBookByLibroId(String libroId) async {
    try {
      final books = await getDigitalBooks();
      return books.firstWhere(
        (book) => book.libroId == libroId,
        orElse: () => throw Exception('No encontrado'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Seleccionar un archivo PDF/EPUB desde el dispositivo
  static Future<String?> pickDigitalBook() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path!;
      }

      return null;
    } catch (e) {
      debugPrint('Error al seleccionar archivo: $e');
      return null;
    }
  }

  /// Asociar un archivo digital con un libro
  static Future<bool> addDigitalBook({
    required String libroId,
    required String titulo,
    required String filePath,
  }) async {
    try {
      // Verificar que el archivo existe
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('El archivo no existe: $filePath');
        return false;
      }

      // Determinar tipo de archivo
      String fileType = 'pdf';
      if (filePath.toLowerCase().endsWith('.epub')) {
        fileType = 'epub';
      } else if (filePath.toLowerCase().endsWith('.txt')) {
        fileType = 'txt';
      }

      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getString(_digitalBooksKey);

      List<Map<String, dynamic>> books = [];
      if (booksJson != null) {
        final List<dynamic> decoded = json.decode(booksJson);
        books = decoded.cast<Map<String, dynamic>>();
      }

      // Verificar si ya existe
      final exists = books.any((b) => b['libroId'] == libroId);
      if (exists) {
        // Actualizar la ruta del archivo
        for (var i = 0; i < books.length; i++) {
          if (books[i]['libroId'] == libroId) {
            books[i]['filePath'] = filePath;
            books[i]['fileType'] = fileType;
            break;
          }
        }
      } else {
        // Agregar nuevo
        final newBook = DigitalBook(
          libroId: libroId,
          titulo: titulo,
          filePath: filePath,
          fileType: fileType,
          addedDate: DateTime.now(),
        );
        books.add(newBook.toJson());
      }

      await prefs.setString(_digitalBooksKey, json.encode(books));
      return true;
    } catch (e) {
      debugPrint('Error al agregar libro digital: $e');
      return false;
    }
  }

  /// Eliminar libro digital
  static Future<bool> removeDigitalBook(String libroId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getString(_digitalBooksKey);

      if (booksJson == null) return false;

      final List<dynamic> decoded = json.decode(booksJson);
      List<Map<String, dynamic>> books = decoded.cast<Map<String, dynamic>>();

      books.removeWhere((b) => b['libroId'] == libroId);

      await prefs.setString(_digitalBooksKey, json.encode(books));
      return true;
    } catch (e) {
      debugPrint('Error al eliminar libro digital: $e');
      return false;
    }
  }

  /// Copiar archivo a almacenamiento local de la app
  static Future<String?> copyFileToAppStorage(String sourcePath, String libroId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${directory.path}/digital_books');

      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final sourceFile = File(sourcePath);
      final extension = sourcePath.split('.').last;
      final fileName = '${libroId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final newPath = '${booksDir.path}/$fileName';

      await sourceFile.copy(newPath);
      return newPath;
    } catch (e) {
      debugPrint('Error al copiar archivo: $e');
      return null;
    }
  }

  /// Crear un PDF de demostración para pruebas
  static Future<String?> createSamplePDF(String libroId, String titulo) async {
    try {
      // Por ahora, solo devuelve una URL de ejemplo
      // En producción, aquí descargarías el PDF del servidor
      debugPrint('Creando PDF de demostración para $titulo');

      // Simular descarga
      await Future.delayed(const Duration(seconds: 1));

      // Retornar path de ejemplo (en producción sería el archivo descargado)
      return 'sample';
    } catch (e) {
      debugPrint('Error al crear PDF de demostración: $e');
      return null;
    }
  }

  /// Verificar si el archivo existe
  static Future<bool> fileExists(String filePath) async {
    try {
      if (filePath == 'sample') return true; // Archivo de demostración
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Limpiar todos los libros digitales (desarrollo)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_digitalBooksKey);
  }
}
