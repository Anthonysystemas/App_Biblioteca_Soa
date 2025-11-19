import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Pantalla de lectura de PDF mejorada
class PdfReaderScreen extends StatefulWidget {
  final String filePath;
  final String bookTitle;
  final String? libroId;

  const PdfReaderScreen({
    super.key,
    required this.filePath,
    required this.bookTitle,
    this.libroId,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearchOpen = false;
  bool _showControls = true;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: _showControls ? _buildAppBar() : null,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: _buildPdfViewer(),
          ),
          if (_showControls) _buildBottomControls(),
          if (_isSearchOpen) _buildSearchBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.bookTitle.length > 25
                ? '${widget.bookTitle.substring(0, 25)}...'
                : widget.bookTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (_totalPages > 0)
            Text(
              'Página $_currentPage de $_totalPages',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
        ],
      ),
      backgroundColor: const Color(0xFF667EEA),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearchOpen = !_isSearchOpen;
            });
          },
          tooltip: 'Buscar en el libro',
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_border),
          onPressed: () {
            _showBookmarksDialog();
          },
          tooltip: 'Marcadores',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'zoom_in':
                _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
                break;
              case 'zoom_out':
                _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
                break;
              case 'fit_width':
                _pdfViewerController.zoomLevel = 1.0;
                break;
              case 'info':
                _showBookInfo();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'zoom_in',
              child: Row(
                children: [
                  Icon(Icons.zoom_in, size: 20),
                  SizedBox(width: 12),
                  Text('Ampliar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'zoom_out',
              child: Row(
                children: [
                  Icon(Icons.zoom_out, size: 20),
                  SizedBox(width: 12),
                  Text('Reducir'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'fit_width',
              child: Row(
                children: [
                  Icon(Icons.fit_screen, size: 20),
                  SizedBox(width: 12),
                  Text('Ajustar a pantalla'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Información'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPdfViewer() {
    // Si es un archivo de demostración, usar asset o URL
    if (widget.filePath == 'sample') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Text(
                'Vista previa de muestra',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Para leer este libro en PDF, necesitas subir el archivo desde tu dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _showUploadDialog();
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Subir archivo PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Leer archivo desde ruta local
    return SfPdfViewer.file(
      File(widget.filePath),
      key: _pdfViewerKey,
      controller: _pdfViewerController,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPages = details.document.pages.count;
        });
      },
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
      canShowScrollHead: true,
      canShowScrollStatus: true,
      enableDoubleTapZooming: true,
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.first_page, color: Colors.white),
              onPressed: _currentPage > 1
                  ? () {
                      _pdfViewerController.jumpToPage(1);
                    }
                  : null,
              tooltip: 'Primera página',
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: _currentPage > 1
                  ? () {
                      _pdfViewerController.previousPage();
                    }
                  : null,
              tooltip: 'Página anterior',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_currentPage / $_totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: _currentPage < _totalPages
                  ? () {
                      _pdfViewerController.nextPage();
                    }
                  : null,
              tooltip: 'Página siguiente',
            ),
            IconButton(
              icon: const Icon(Icons.last_page, color: Colors.white),
              onPressed: _currentPage < _totalPages
                  ? () {
                      _pdfViewerController.jumpToPage(_totalPages);
                    }
                  : null,
              tooltip: 'Última página',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar en el libro...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _pdfViewerController.searchText(value);
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearchOpen = false;
                  _searchController.clear();
                  _pdfViewerController.clearSelection();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcadores'),
        content: const Text(
          'Funcionalidad de marcadores próximamente.\n\n'
          'Podrás guardar páginas importantes para volver a ellas rápidamente.',
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

  void _showBookInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información del libro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Título: ${widget.bookTitle}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Páginas: $_totalPages'),
            const SizedBox(height: 8),
            Text('Formato: PDF'),
            const SizedBox(height: 8),
            Text('Ubicación: ${widget.filePath}'),
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

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF667EEA)),
            SizedBox(width: 8),
            Text('Contenido no disponible'),
          ],
        ),
        content: const Text(
          'El contenido de este libro no está disponible en este momento.\n\n'
          'Estamos trabajando para conseguir las licencias y contenido digital de todos nuestros libros.\n\n'
          'Te notificaremos cuando este libro esté listo para leer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
