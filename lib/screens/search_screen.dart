import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/bottom_nav.dart';
import '../widgets/book_card.dart';
import '../services/google_books_api_service.dart';
import '../models/book_model.dart';

class SearchScreen extends StatefulWidget {
  final int currentNavIndex;
  final Function(int) onNavTap;

  const SearchScreen({
    super.key,
    required this.currentNavIndex,
    required this.onNavTap,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BookModel> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String _searchQuery = '';
  String _error = '';
  Timer? _debounceTimer;

  final List<String> _popularSearches = [
    'Harry Potter',
    'Clean Code',
    'JavaScript',
    'Python',
    'Fiction',
    'Science',
    'Programming',
    '1984',
    'El Alquimista',
    'Sapiens',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadRecentSearches() {
    // Búsquedas recientes simuladas
    _recentSearches = [
      'Programación',
      'Literatura',
      'Java',
      'Filosofía',
    ];
  }

  void _saveRecentSearch(String query) {
    setState(() {
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches.removeLast();
        }
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    _debounceTimer?.cancel();
    
    setState(() {
      _searchQuery = query;
      _error = '';
    });

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _isLoading = false;
      });
      return;
    }

    // Debounce de 800ms
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (_searchController.text.trim() == query && query.isNotEmpty) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _isLoading = true;
      _error = '';
    });

    try {
      debugPrint('Buscando: "$query"');
      
      final results = await GoogleBooksApiService.searchBooks(
        query: query,
        maxResults: 40,
      );

      debugPrint('Resultados encontrados: ${results.length}');

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });

        _saveRecentSearch(query);
      }
    } catch (e) {
      debugPrint('Error en búsqueda: $e');
      
      if (mounted) {
        setState(() {
          _error = 'Error al buscar libros: ${e.toString()}';
          _isLoading = false;
          _searchResults = [];
        });
      }
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty && !_isLoading) {
      _debounceTimer?.cancel();
      _performSearch(query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
      _isSearching = false;
      _isLoading = false;
      _error = '';
    });
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _debounceTimer?.cancel();
    _performSearch(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: widget.currentNavIndex,
        onTap: widget.onNavTap,
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: const Color(0xFF667EEA),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _isLoading 
                      ? const Color(0xFF667EEA).withAlpha(128)
                      : Colors.grey.withAlpha(77),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onSubmitted: _onSearchSubmitted,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D3748),
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar libros, autores, categorías...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  prefixIcon: _isLoading
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF667EEA),
                              ),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.search,
                          color: Colors.grey[400],
                          size: 22,
                        ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[500],
                            size: 22,
                          ),
                          onPressed: _clearSearch,
                        )
                      : Icon(
                          Icons.mic,
                          color: Colors.grey[400],
                          size: 22,
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error.isNotEmpty) {
      return _buildErrorState();
    }

    if (_isSearching) {
      return _buildSearchResults();
    }

    return _buildSearchSuggestions();
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'No se encontraron resultados',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'para "$_searchQuery"',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Intenta con:\n• Términos más generales\n• Nombres de autores\n• Categorías como "ficción" o "programación"',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Resultados para "$_searchQuery"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A202C),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_searchResults.length}',
                  style: const TextStyle(
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
         GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Proporción corregida
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final book = _searchResults[index];
              return BookCard.fromBookModel(
                book,
                onTap: () {
                  // Acción al tocar la tarjeta del libro
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Buscando "$_searchQuery"...',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF667EEA),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: 8,
            itemBuilder: (context, index) {
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
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(6),
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
            },
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
              'Error en la búsqueda',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _performSearch(_searchQuery),
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

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            const Text(
              'Búsquedas recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.take(5).map((search) {
                return GestureDetector(
                  onTap: () => _onSuggestionTap(search),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          search,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
          
          const Text(
            'Búsquedas populares',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches.map((search) {
              return GestureDetector(
                onTap: () => _onSuggestionTap(search),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 16,
                        color: const Color(0xFF667EEA),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        search,
                        style: const TextStyle(
                          color: Color(0xFF667EEA),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}