// Archivo: screens/book_reader_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/books_api_service.dart';

class BookReaderScreen extends StatefulWidget {
  final BookModel book;

  const BookReaderScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // URL de vista previa de Google Books
    final previewUrl = widget.book.previewLink ?? 
        'https://books.google.com/books?id=${widget.book.id}&printsec=frontcover&source=gbs_ge_summary_r&cad=0';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Opcional: mostrar progreso de carga
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = 'Error al cargar la vista previa: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(previewUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.book.title.length > 30 
              ? '${widget.book.title.substring(0, 30)}...'
              : widget.book.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showBookInfo(),
            icon: const Icon(Icons.info_outline),
            tooltip: 'Información del libro',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorState();
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) _buildLoadingState(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando vista previa...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF718096),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            const Text(
              'Vista previa no disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'No se pudo cargar la vista previa de este libro.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _initializeWebView(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _openInBrowser(),
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Abrir en navegador'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF667EEA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle del modal
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Información del libro
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen del libro
                      Container(
                        width: 80,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.book.thumbnail != null
                              ? Image.network(
                                  widget.book.thumbnail!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: const Color(0xFF667EEA),
                                      child: const Icon(
                                        Icons.book,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: const Color(0xFF667EEA),
                                  child: const Icon(
                                    Icons.book,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Detalles
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.book.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A202C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.book.authorsString,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF718096),
                              ),
                            ),
                            if (widget.book.publishedDate != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Publicado: ${widget.book.publishedDate}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            ],
                            if (widget.book.pageCount != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${widget.book.pageCount} páginas',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (widget.book.description != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.book.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A5568),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openInBrowser() async {
    final url = widget.book.previewLink ?? 
        'https://books.google.com/books?id=${widget.book.id}';
    
    // Aquí puedes usar url_launcher si lo tienes instalado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo en navegador: $url'),
        action: SnackBarAction(
          label: 'Copiar URL',
          onPressed: () {
            // Implementar copia al clipboard si es necesario
          },
        ),
      ),
    );
  }
}