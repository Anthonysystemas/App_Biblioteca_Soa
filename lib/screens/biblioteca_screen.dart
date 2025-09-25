import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/book_card.dart';
import '../services/books_api_service.dart';
import '../services/biblioteca_service.dart';

class BibliotecaScreen extends StatefulWidget {
  final int currentNavIndex;
  final Function(int) onNavTap;

  const BibliotecaScreen({
    super.key,
    required this.currentNavIndex,
    required this.onNavTap,
  });

  @override
  State<BibliotecaScreen> createState() => _BibliotecaScreenState();
}

class _BibliotecaScreenState extends State<BibliotecaScreen> {
  List<BookModel> _bibliotecaBooks = [];
  List<BookModel> _allBooks = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedFilter = 'todos';

  @override
  void initState() {
    super.initState();
    _loadBiblioteca();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBiblioteca();
  }

  Future<void> _loadBiblioteca() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final books = await BibliotecaService.getBibliotecaBooks();
      
      if (mounted) {
        setState(() {
          _allBooks = books;
          _bibliotecaBooks = _filterBooks(books);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar biblioteca: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<BookModel> _filterBooks(List<BookModel> books) {
    switch (_selectedFilter) {
      case 'leyendo':
        return books.where((book) => book.readingStatus == 'leyendo').toList();
      case 'pendiente':
        return books.where((book) => book.readingStatus == 'pendiente').toList();
      case 'completado':
        return books.where((book) => book.readingStatus == 'completado').toList();
      default:
        return books;
    }
  }

  void _applyFilter() {
    setState(() {
      _bibliotecaBooks = _filterBooks(_allBooks);
    });
  }

  Future<void> _showClearConfirmation() async {
    if (_allBooks.isEmpty) return;

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Limpiar Biblioteca',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar todos los ${_allBooks.length} libros de tu biblioteca?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      await _clearAllBiblioteca();
    }
  }

  Future<void> _clearAllBiblioteca() async {
    try {
      await BibliotecaService.clearAllBiblioteca();
      await _loadBiblioteca();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete_sweep, color: Colors.white),
                SizedBox(width: 8),
                Text('Biblioteca limpiada'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al limpiar biblioteca'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          'Mi Biblioteca',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_allBooks.isNotEmpty)
            IconButton(
              onPressed: _showClearConfirmation,
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Limpiar biblioteca',
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNav(
        currentIndex: widget.currentNavIndex,
        onTap: widget.onNavTap,
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildFilterTabs(),
        Expanded(
          child: _isLoading
              ? _buildLoadingState()
              : _error.isNotEmpty
                  ? _buildErrorState()
                  : _bibliotecaBooks.isEmpty
                      ? _buildEmptyState()
                      : _buildBibliotecaList(),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'todos', 'label': 'Todos'},
      {'key': 'leyendo', 'label': 'Leyendo'},
      {'key': 'pendiente', 'label': 'Pendientes'},
      {'key': 'completado', 'label': 'Completados'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter['key'];
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(
                  filter['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF667EEA),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selectedColor: const Color(0xFF667EEA),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter['key'] as String;
                  });
                  _applyFilter();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando biblioteca...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
            const SizedBox(height: 24),
            Text(
              'Error al cargar biblioteca',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                _error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBiblioteca,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.library_books,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedFilter == 'todos' 
                  ? 'Tu biblioteca está vacía'
                  : 'No tienes libros en esta categoría',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                _selectedFilter == 'todos'
                    ? 'Los libros que agregues a tu biblioteca aparecerán aquí'
                    : 'Cambia el estado de tus libros para organizarlos mejor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                widget.onNavTap(1);
              },
              icon: const Icon(Icons.search),
              label: const Text('Explorar Libros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBibliotecaList() {
    return RefreshIndicator(
      onRefresh: _loadBiblioteca,
      color: const Color(0xFF667EEA),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 3,
                    child: Text(
                      _getHeaderText(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_bibliotecaBooks.length}',
                      style: const TextStyle(
                        color: Color(0xFF667EEA),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final book = _bibliotecaBooks[index];
                  return BookCard.fromBookModel(
                    book,
                    showFavoriteIcon: false,
                    onTap: () => _showBookActions(book),
                  );
                },
                childCount: _bibliotecaBooks.length,
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 100),
          ),
        ],
      ),
    );
  }

  String _getHeaderText() {
    switch (_selectedFilter) {
      case 'leyendo':
        return 'Libros que estoy leyendo';
      case 'pendiente':
        return 'Libros pendientes';
      case 'completado':
        return 'Libros completados';
      default:
        return 'Mi biblioteca personal';
    }
  }

  void _showBookActions(BookModel book) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
              book.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              book.authorsString,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            ListTile(
              leading: const Icon(Icons.play_circle, color: Color(0xFF10B981)),
              title: const Text('Marcar como "Leyendo"'),
              onTap: () => _updateReadingStatus(book, 'leyendo'),
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: Color(0xFFF59E0B)),
              title: const Text('Marcar como "Pendiente"'),
              onTap: () => _updateReadingStatus(book, 'pendiente'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Color(0xFF059669)),
              title: const Text('Marcar como "Completado"'),
              onTap: () => _updateReadingStatus(book, 'completado'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar de biblioteca'),
              onTap: () => _removeFromBiblioteca(book),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateReadingStatus(BookModel book, String status) async {
    Navigator.pop(context);
    
    try {
      await BibliotecaService.updateReadingStatus(book.id, status);
      await _loadBiblioteca();
      
      String message;
      switch (status) {
        case 'leyendo':
          message = 'Libro marcado como "Leyendo"';
          break;
        case 'pendiente':
          message = 'Libro marcado como "Pendiente"';
          break;
        case 'completado':
          message = 'Libro marcado como "Completado"';
          break;
        default:
          message = 'Estado actualizado';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar estado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromBiblioteca(BookModel book) async {
    Navigator.pop(context);
    
    try {
      await BibliotecaService.removeFromBiblioteca(book.id);
      await _loadBiblioteca();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${book.title} eliminado de biblioteca'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar libro'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}