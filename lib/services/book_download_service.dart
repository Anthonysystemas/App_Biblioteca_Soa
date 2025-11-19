import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Servicio para descargar libros desde Internet Archive y otras fuentes
class BookDownloadService {
  static final Dio _dio = Dio();

  /// Obtener información de lectura desde Open Library Read API
  /// Retorna URLs para leer el libro online o descargar
  static Future<Map<String, dynamic>?> getBookReadInfo(String isbn) async {
    try {
      final url = 'https://openlibrary.org/api/volumes/brief/isbn/$isbn.json';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
    } catch (e) {
      debugPrint('Error al obtener info de lectura: $e');
    }
    return null;
  }

  /// Buscar libro en Internet Archive y obtener URLs de descarga
  /// Internet Archive ID suele ser: /details/[identifier]
  static Future<Map<String, dynamic>?> searchInternetArchive(String title, String author) async {
    try {
      // Limpiar título y autor para búsqueda
      final query = Uri.encodeComponent('$title $author');
      final url = 'https://archive.org/advancedsearch.php?'
          'q=$query&'
          'fl[]=identifier,title,creator,format,downloads&'
          'output=json&'
          'rows=5';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final docs = data['response']?['docs'] as List?;

        if (docs != null && docs.isNotEmpty) {
          // Buscar el primer resultado que tenga EPUB o PDF
          for (var doc in docs) {
            final formats = doc['format'];
            if (formats != null) {
              if (formats is List) {
                if (formats.contains('EPUB') || formats.contains('PDF')) {
                  return {
                    'identifier': doc['identifier'],
                    'title': doc['title'],
                    'creator': doc['creator'],
                    'hasEpub': formats.contains('EPUB'),
                    'hasPdf': formats.contains('PDF'),
                  };
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error al buscar en Internet Archive: $e');
    }
    return null;
  }

  /// Obtener URLs de descarga directa desde Internet Archive
  /// Formato: https://archive.org/download/[identifier]/[identifier].epub
  static String getInternetArchiveEpubUrl(String identifier) {
    return 'https://archive.org/download/$identifier/$identifier.epub';
  }

  static String getInternetArchivePdfUrl(String identifier) {
    return 'https://archive.org/download/$identifier/$identifier.pdf';
  }

  /// Descargar archivo EPUB/PDF desde una URL
  static Future<String?> downloadBook({
    required String url,
    required String fileName,
    Function(int, int)? onProgress,
  }) async {
    try {
      // Obtener directorio de documentos de la app
      final dir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${dir.path}/books');

      // Crear carpeta si no existe
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final filePath = '${booksDir.path}/$fileName';
      final file = File(filePath);

      // Si ya existe, retornar ruta
      if (await file.exists()) {
        debugPrint('📚 Libro ya descargado: $filePath');
        return filePath;
      }

      debugPrint('📥 Descargando libro desde: $url');

      // Descargar usando Dio para tener progreso
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received, total);
          }
        },
      );

      debugPrint('✅ Libro descargado: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Error al descargar libro: $e');
      return null;
    }
  }

  /// Verificar si un libro ya está descargado localmente
  static Future<String?> getLocalBookPath(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/books/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }
    } catch (e) {
      debugPrint('Error al verificar libro local: $e');
    }
    return null;
  }

  /// Eliminar libro descargado localmente
  static Future<bool> deleteLocalBook(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/books/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Libro eliminado: $filePath');
        return true;
      }
    } catch (e) {
      debugPrint('Error al eliminar libro: $e');
    }
    return false;
  }

  /// Buscar y descargar libro automáticamente
  /// 1. Busca en Internet Archive
  /// 2. Intenta descargar EPUB primero, luego PDF
  /// 3. Retorna ruta del archivo descargado
  static Future<Map<String, dynamic>?> searchAndDownloadBook({
    required String bookId,
    required String title,
    required String author,
    Function(String)? onStatusUpdate,
    Function(int, int)? onProgress,
  }) async {
    try {
      onStatusUpdate?.call('Buscando libro en Internet Archive...');

      // Buscar en Internet Archive
      final archiveInfo = await searchInternetArchive(title, author);

      if (archiveInfo == null) {
        onStatusUpdate?.call('No se encontró el libro en Internet Archive');
        return null;
      }

      final identifier = archiveInfo['identifier'];
      final hasEpub = archiveInfo['hasEpub'] ?? false;
      final hasPdf = archiveInfo['hasPdf'] ?? false;

      if (!hasEpub && !hasPdf) {
        onStatusUpdate?.call('El libro no tiene formato descargable');
        return null;
      }

      // Priorizar EPUB sobre PDF
      String? downloadUrl;
      String? fileExtension;
      String? format;

      if (hasEpub) {
        downloadUrl = getInternetArchiveEpubUrl(identifier);
        fileExtension = 'epub';
        format = 'EPUB';
        onStatusUpdate?.call('Descargando libro en formato EPUB...');
      } else if (hasPdf) {
        downloadUrl = getInternetArchivePdfUrl(identifier);
        fileExtension = 'pdf';
        format = 'PDF';
        onStatusUpdate?.call('Descargando libro en formato PDF...');
      }

      if (downloadUrl == null) return null;

      // Descargar el libro
      final fileName = '${bookId}_$identifier.$fileExtension';
      final localPath = await downloadBook(
        url: downloadUrl,
        fileName: fileName,
        onProgress: onProgress,
      );

      if (localPath != null) {
        onStatusUpdate?.call('¡Libro descargado exitosamente!');
        return {
          'path': localPath,
          'format': format,
          'identifier': identifier,
          'fileName': fileName,
        };
      }
    } catch (e) {
      debugPrint('Error en searchAndDownloadBook: $e');
      onStatusUpdate?.call('Error al descargar el libro');
    }
    return null;
  }

  /// Obtener tamaño del directorio de libros descargados
  static Future<int> getDownloadedBooksSize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${dir.path}/books');

      if (!await booksDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (var entity in booksDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error al calcular tamaño: $e');
      return 0;
    }
  }

  /// Limpiar todos los libros descargados
  static Future<bool> clearAllBooks() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${dir.path}/books');

      if (await booksDir.exists()) {
        await booksDir.delete(recursive: true);
        debugPrint('🗑️ Todos los libros eliminados');
        return true;
      }
    } catch (e) {
      debugPrint('Error al limpiar libros: $e');
    }
    return false;
  }
}
