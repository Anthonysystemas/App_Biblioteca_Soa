import 'package:flutter/material.dart';
import '../services/books_api_service.dart';
import '../services/favorites_service.dart';
import '../services/biblioteca_service.dart';

class BookCard extends StatefulWidget {
  final BookModel? book;
  final String? title;
  final String? author;
  final String? imagePath;
  final Color? dominantColor;
  final VoidCallback? onTap;
  final bool showFavoriteIcon;
  final bool showBibliotecaIcon;

  const BookCard({
    super.key,
    this.book,
    this.title,
    this.author,
    this.imagePath,
    this.dominantColor,
    this.onTap,
    this.showFavoriteIcon = false,
    this.showBibliotecaIcon = true,
  });

  factory BookCard.fromBookModel(BookModel book, {VoidCallback? onTap, bool showFavoriteIcon = false, bool showBibliotecaIcon = true}) {
    return BookCard(
      book: book,
      onTap: onTap,
      showFavoriteIcon: showFavoriteIcon,
      showBibliotecaIcon: showBibliotecaIcon,
    );
  }

  factory BookCard.manual({
    required String title,
    required String author,
    required String imagePath,
    required Color dominantColor,
    VoidCallback? onTap,
    bool showFavoriteIcon = false,
    bool showBibliotecaIcon = true,
  }) {
    return BookCard(
      title: title,
      author: author,
      imagePath: imagePath,
      dominantColor: dominantColor,
      onTap: onTap,
      showFavoriteIcon: showFavoriteIcon,
      showBibliotecaIcon: showBibliotecaIcon,
    );
  }

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _isFavorite = false;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    if (widget.book?.id != null) {
      final isFav = await FavoritesService.isFavorite(widget.book!.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.book == null || _isToggling) return;

    setState(() {
      _isToggling = true;
    });

    try {
      final wasAdded = await FavoritesService.toggleFavorite(widget.book!);
      
      if (mounted) {
        setState(() {
          _isFavorite = wasAdded;
          _isToggling = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  wasAdded ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    wasAdded 
                      ? 'Agregado a favoritos'
                      : 'Eliminado de favoritos',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: wasAdded ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar favoritos'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookTitle = widget.book?.title ?? widget.title ?? 'Sin título';
    final bookAuthor = widget.book?.authorsString ?? widget.author ?? 'Autor desconocido';
    final bookImagePath = widget.book?.thumbnail ?? widget.imagePath;
    final bookColor = widget.dominantColor ?? _getColorFromTitle(bookTitle);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return GestureDetector(
      onTap: widget.onTap ?? () => _showBookDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: isSmallScreen ? 6 : 7,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      color: bookColor,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child: bookImagePath != null && bookImagePath!.isNotEmpty
                          ? Image.network(
                              bookImagePath!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              alignment: Alignment.center,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: bookColor,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white.withOpacity(0.8),
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: bookColor,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.book,
                                          color: Colors.white,
                                          size: isSmallScreen ? 32 : 40,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          bookTitle.length > 15 
                                              ? '${bookTitle.substring(0, 15)}...'
                                              : bookTitle,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isSmallScreen ? 8 : 9,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: bookColor,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.book,
                                      color: Colors.white,
                                      size: isSmallScreen ? 32 : 40,
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        bookTitle.length > 15 
                                            ? '${bookTitle.substring(0, 15)}...'
                                            : bookTitle,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 8 : 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                  
                  if (widget.showFavoriteIcon && widget.book != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: _toggleFavorite,
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: _isToggling
                              ? SizedBox(
                                  width: isSmallScreen ? 12 : 14,
                                  height: isSmallScreen ? 12 : 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.red[400]!,
                                    ),
                                  ),
                                )
                              : Icon(
                                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: _isFavorite ? Colors.red[400] : Colors.grey[600],
                                  size: isSmallScreen ? 12 : 14,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            Expanded(
              flex: isSmallScreen ? 3 : 3,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        bookTitle,
                        style: TextStyle(
                          color: const Color(0xFF2D3748),
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bookAuthor,
                          style: TextStyle(
                            color: const Color(0xFF718096),
                            fontSize: isSmallScreen ? 9 : 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        if (widget.book?.averageRating != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber[600],
                                size: isSmallScreen ? 10 : 11,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                widget.book!.averageRating!.toStringAsFixed(1),
                                style: TextStyle(
                                  color: const Color(0xFF718096),
                                  fontSize: isSmallScreen ? 8 : 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromTitle(String title) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    
    return colors[title.hashCode % colors.length];
  }

  void _showBookDetails(BuildContext context) {
    if (widget.book == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookDetailModal(book: widget.book!),
    );
  }
}

// PANTALLA DE LECTURA CON WEBVIEW ALTERNATIVA (SIN WEBVIEW)
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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final previewUrl = widget.book.previewLink ?? 
        'https://books.google.com/books?id=${widget.book.id}&printsec=frontcover&source=gbs_ge_summary_r&cad=0';

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagen del libro
              Container(
                width: 150,
                height: 225,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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
                                size: 80,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFF667EEA),
                          child: const Icon(
                            Icons.book,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Icon(
                Icons.preview,
                size: 80,
                color: Colors.grey[400],
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Vista previa disponible en Google Books',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'La vista previa de este libro está disponible en el sitio web de Google Books.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: () => _openInBrowser(previewUrl),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Abrir en navegador'),
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
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Volver',
                  style: TextStyle(
                    color: Color(0xFF667EEA),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openInBrowser(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Abriendo en navegador...',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              url,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: const Color(0xFF667EEA),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Copiar URL',
          textColor: Colors.white,
          onPressed: () {
            // Aquí podrías implementar copiar al clipboard
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('URL copiada al portapapeles'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showBookInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.book.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.book.authorsString,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.book.publishedDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Publicado: ${widget.book.publishedDate}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// MODAL DE DETALLES COMPLETO
class BookDetailModal extends StatefulWidget {
  final BookModel book;

  const BookDetailModal({super.key, required this.book});

  @override
  State<BookDetailModal> createState() => _BookDetailModalState();
}

class _BookDetailModalState extends State<BookDetailModal> {
  bool _isFavorite = false;
  bool _isToggling = false;
  bool _isInBiblioteca = false;
  bool _isTogglingBiblioteca = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _checkBibliotecaStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await FavoritesService.isFavorite(widget.book.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _checkBibliotecaStatus() async {
    final isInBib = await BibliotecaService.isInBiblioteca(widget.book.id);
    if (mounted) {
      setState(() {
        _isInBiblioteca = isInBib;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isToggling) return;

    setState(() {
      _isToggling = true;
    });

    try {
      final wasAdded = await FavoritesService.toggleFavorite(widget.book);
      
      if (mounted) {
        setState(() {
          _isFavorite = wasAdded;
          _isToggling = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  wasAdded ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  wasAdded 
                    ? 'Agregado a favoritos'
                    : 'Eliminado de favoritos',
                ),
              ],
            ),
            backgroundColor: wasAdded ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar favoritos'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleBiblioteca() async {
    if (_isTogglingBiblioteca) return;

    setState(() {
      _isTogglingBiblioteca = true;
    });

    try {
      final wasAdded = await BibliotecaService.toggleBiblioteca(widget.book);
      
      if (mounted) {
        setState(() {
          _isInBiblioteca = wasAdded;
          _isTogglingBiblioteca = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  wasAdded ? Icons.library_books : Icons.library_add,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  wasAdded 
                    ? 'Agregado a biblioteca'
                    : 'Eliminado de biblioteca',
                ),
              ],
            ),
            backgroundColor: wasAdded ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTogglingBiblioteca = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar biblioteca'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
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
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.book.thumbnail != null
                            ? Image.network(
                                widget.book.thumbnail!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.center,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.blue,
                                    child: const Icon(
                                      Icons.book,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.blue,
                                child: const Icon(
                                  Icons.book,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.book.title,
                            style: const TextStyle(
                              fontSize: 18,
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.book.publisher != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.book.publisher!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF718096),
                              ),
                            ),
                          ],
                          if (widget.book.publishedDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.book.publishedDate!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF718096),
                              ),
                            ),
                          ],
                          if (widget.book.averageRating != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    Icons.star,
                                    color: index < widget.book.averageRating!.round()
                                        ? Colors.amber
                                        : Colors.grey[300],
                                    size: 14,
                                  );
                                }),
                                const SizedBox(width: 4),
                                Text(
                                  widget.book.averageRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                if (widget.book.categories.isNotEmpty) ...[
                  const Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.book.categories.take(4).map((category) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF667EEA).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF667EEA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (widget.book.description != null) ...[
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
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // BOTONES DE ACCIÓN CON WEBVIEW
                Column(
                  children: [
                    // BOTÓN PRINCIPAL: LEER MUESTRA CON WEBVIEW
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Cerrar modal
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookReaderScreen(book: widget.book),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.preview, size: 18),
                        label: const Text(
                          'Leer muestra', 
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // SEGUNDA FILA: FAVORITOS Y BIBLIOTECA
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isToggling ? null : _toggleFavorite,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _isFavorite ? Colors.red : const Color(0xFF667EEA),
                              side: BorderSide(
                                color: _isFavorite ? Colors.red : const Color(0xFF667EEA),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: _isToggling
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(
                                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                                    size: 16,
                                  ),
                            label: Text(
                              _isFavorite ? 'Favorito' : 'Favoritos',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 10),
                        
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isTogglingBiblioteca ? null : _toggleBiblioteca,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isInBiblioteca ? Colors.green : const Color(0xFF667EEA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: _isTogglingBiblioteca
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, 
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(
                                    _isInBiblioteca ? Icons.library_books : Icons.library_add,
                                    size: 16,
                                  ),
                            label: Text(
                              _isInBiblioteca ? 'En Biblioteca' : 'Biblioteca',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}