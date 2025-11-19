import 'package:flutter/material.dart';
import '../services/google_books_api_service.dart';
import '../models/book_model.dart';
import 'book_card.dart';
import 'book/book_detail_modal.dart';

class LibrosMasLeidosSection extends StatefulWidget {
  const LibrosMasLeidosSection({super.key});

  @override
  State<LibrosMasLeidosSection> createState() => _LibrosMasLeidosSectionState();
}

class _LibrosMasLeidosSectionState extends State<LibrosMasLeidosSection> {
  List<BookModel> _books = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final List<BookModel> allBooks = [];
      
      final categories = [
        'fiction',
        'programming',
        'science',
        'history',
        'philosophy',
        'biography',
      ];
      
      for (String category in categories) {
        try {
          final categoryBooks = await GoogleBooksApiService.getBooksByCategory(
            category: category,
            maxResults: 4,
          );
          allBooks.addAll(categoryBooks);
        } catch (e) {
          debugPrint('Error cargando categoría $category: $e');
        }
      }

      setState(() {
        _books = allBooks.take(18).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar los libros: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Libros más leídos',
              style: TextStyle(
                color: Color(0xFF1A202C),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_isLoading)
              TextButton.icon(
                onPressed: _loadBooks,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Actualizar', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF667EEA),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isLoading)
          _buildLoadingState(isSmallScreen)
        else if (_error.isNotEmpty)
          _buildErrorState()
        else if (_books.isEmpty)
          _buildEmptyState()
        else
          _buildBooksGrid(isSmallScreen),
      ],
    );
  }

  Widget _buildLoadingState(bool isSmallScreen) {
    return SizedBox(
      height: isSmallScreen ? 500 : 620,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return _buildLoadingCard();
        },
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF667EEA),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 12),
            Text(
              'Error al cargar libros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                _error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadBooks,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No se encontraron libros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta actualizar la página',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadBooks,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Actualizar', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksGrid(bool isSmallScreen) {
    return SizedBox(
      height: isSmallScreen ? 500 : 620,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          return BookCard.fromBookModel(
            book,
            onTap: () {
              _showBookPreview(book);
            },
          );
        },
      ),
    );
  }

  void _showBookPreview(BookModel book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookDetailModal(book: book),
    );
  }
}