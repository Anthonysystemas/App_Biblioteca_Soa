import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/favorites_service.dart';
import '../../services/biblioteca_service.dart';

/// Botón de favorito reutilizable con estado
class FavoriteButton extends StatefulWidget {
  final BookModel book;
  final double size;
  final EdgeInsets padding;

  const FavoriteButton({
    super.key,
    required this.book,
    this.size = 14,
    this.padding = const EdgeInsets.all(6),
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await FavoritesService.isFavorite(widget.book.id);
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isToggling) return;

    setState(() => _isToggling = true);

    try {
      final wasAdded = await FavoritesService.toggleFavorite(widget.book);

      if (mounted) {
        setState(() {
          _isFavorite = wasAdded;
          _isToggling = false;
        });

        _showSnackBar(
          wasAdded ? 'Agregado a favoritos' : 'Eliminado de favoritos',
          wasAdded ? Colors.green : Colors.orange,
          wasAdded ? Icons.favorite : Icons.favorite_border,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isToggling = false);
        _showSnackBar(
          'Error al actualizar favoritos',
          Colors.red,
          Icons.error,
        );
      }
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Flexible(child: Text(message, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: _isToggling
            ? SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red[400]!),
                ),
              )
            : Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red[400] : Colors.grey[600],
                size: widget.size,
              ),
      ),
    );
  }
}

/// Botón de biblioteca reutilizable con estado
class BibliotecaButton extends StatefulWidget {
  final BookModel book;
  final double size;
  final bool isOutlined;

  const BibliotecaButton({
    super.key,
    required this.book,
    this.size = 16,
    this.isOutlined = false,
  });

  @override
  State<BibliotecaButton> createState() => _BibliotecaButtonState();
}

class _BibliotecaButtonState extends State<BibliotecaButton> {
  bool _isInBiblioteca = false;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _checkBibliotecaStatus();
  }

  Future<void> _checkBibliotecaStatus() async {
    final isInBib = await BibliotecaService.isInBiblioteca(widget.book.id);
    if (mounted) {
      setState(() => _isInBiblioteca = isInBib);
    }
  }

  Future<void> _toggleBiblioteca() async {
    if (_isToggling) return;

    setState(() => _isToggling = true);

    try {
      final wasAdded = await BibliotecaService.toggleBiblioteca(widget.book);

      if (mounted) {
        setState(() {
          _isInBiblioteca = wasAdded;
          _isToggling = false;
        });

        _showSnackBar(
          wasAdded ? 'Agregado a biblioteca' : 'Eliminado de biblioteca',
          wasAdded ? Colors.green : Colors.orange,
          wasAdded ? Icons.library_books : Icons.library_add,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isToggling = false);
        _showSnackBar(
          'Error al actualizar biblioteca',
          Colors.red,
          Icons.error,
        );
      }
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = _isToggling
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
            size: widget.size,
          );

    final label = Text(
      _isInBiblioteca ? 'En Biblioteca' : 'Biblioteca',
      style: const TextStyle(fontSize: 12),
    );

    return Expanded(
      child: ElevatedButton.icon(
        onPressed: _isToggling ? null : _toggleBiblioteca,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isInBiblioteca ? Colors.green : const Color(0xFF667EEA),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: icon,
        label: label,
      ),
    );
  }
}
