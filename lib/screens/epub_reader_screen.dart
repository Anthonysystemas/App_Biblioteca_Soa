import 'dart:io';
import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';

class EpubReaderScreen extends StatefulWidget {
  final String filePath;
  final String bookTitle;
  final String? libroId;

  const EpubReaderScreen({
    super.key,
    required this.filePath,
    required this.bookTitle,
    this.libroId,
  });

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  late EpubController _epubController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final file = File(widget.filePath);
      if (!await file.exists()) {
        setState(() {
          _error = 'El archivo no existe en la ruta especificada';
          _isLoading = false;
        });
        return;
      }

      _epubController = EpubController(
        document: EpubDocument.openFile(file),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el libro: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _epubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bookTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _error == null)
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => _showChaptersDialog(),
              tooltip: 'Índice',
            ),
          if (!_isLoading && _error == null)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(),
              tooltip: 'Configuración',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Cargando libro...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[300],
              ),
              const SizedBox(height: 20),
              Text(
                'Error al cargar el libro',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return EpubView(
      controller: _epubController,
      builders: EpubViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(
          textStyle: TextStyle(
            fontSize: 18,
            height: 1.6,
            letterSpacing: 0.3,
          ),
        ),
        chapterDividerBuilder: (_) => const Divider(
          height: 32,
          thickness: 2,
        ),
      ),
    );
  }

  void _showChaptersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.list, color: Color(0xFF667EEA)),
            SizedBox(width: 8),
            Text('Índice de Capítulos'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<EpubBook>(
            future: _epubController.document,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: Text('No se pudo cargar el índice'),
                );
              }

              final chapters = snapshot.data!.Chapters;
              if (chapters == null || chapters.isEmpty) {
                return const Center(
                  child: Text('No hay capítulos disponibles'),
                );
              }

              return ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF667EEA),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      chapter.Title ?? 'Capítulo ${index + 1}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      _epubController.scrollTo(index: index);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: Color(0xFF667EEA)),
            SizedBox(width: 8),
            Text('Configuración de Lectura'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Próximamente:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• Ajustar tamaño de fuente'),
            Text('• Cambiar tema (claro/oscuro)'),
            Text('• Cambiar tipo de fuente'),
            Text('• Ajustar interlineado'),
            Text('• Modo lectura nocturna'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}