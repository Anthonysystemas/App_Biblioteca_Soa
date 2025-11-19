import 'package:flutter/material.dart';
import '../models/book_model.dart';
import 'common/book_image.dart';
import 'book/book_detail_modal.dart';
import 'book/quick_action_buttons.dart';

/// Widget de tarjeta de libro refactorizado y optimizado
class BookCard extends StatelessWidget {
  final BookModel? book;
  final String? title;
  final String? author;
  final String? imagePath;
  final Color? dominantColor;
  final VoidCallback? onTap;
  final bool showBibliotecaIcon;
  final bool showQuickActions;

  const BookCard({
    super.key,
    this.book,
    this.title,
    this.author,
    this.imagePath,
    this.dominantColor,
    this.onTap,
    this.showBibliotecaIcon = true,
    this.showQuickActions = true,
  });

  factory BookCard.fromBookModel(
    BookModel book, {
    VoidCallback? onTap,
    bool showBibliotecaIcon = true,
    bool showQuickActions = true,
  }) {
    return BookCard(
      book: book,
      onTap: onTap,
      showBibliotecaIcon: showBibliotecaIcon,
      showQuickActions: showQuickActions,
    );
  }

  factory BookCard.manual({
    required String title,
    required String author,
    required String imagePath,
    required Color dominantColor,
    VoidCallback? onTap,
    bool showBibliotecaIcon = true,
  }) {
    return BookCard(
      title: title,
      author: author,
      imagePath: imagePath,
      dominantColor: dominantColor,
      onTap: onTap,
      showBibliotecaIcon: showBibliotecaIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookTitle = book?.title ?? title ?? 'Sin título';
    final bookAuthor = book?.authorsString ?? author ?? 'Autor desconocido';
    final bookImagePath = book?.thumbnail ?? imagePath;
    final bookColor = dominantColor ?? _getColorFromTitle(bookTitle);

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return GestureDetector(
      onTap: onTap ?? () => _showBookDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
                  // Imagen del libro usando widget reutilizable
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      color: bookColor,
                    ),
                    child: BookImage(
                      imageUrl: bookImagePath,
                      backgroundColor: bookColor,
                      fallbackTitle: bookTitle,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            // Información del libro
            Expanded(
              flex: isSmallScreen ? 4 : 4,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título y autor
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
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
                          const SizedBox(height: 2),
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
                          if (book?.averageRating != null) ...[
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
                                  book!.averageRating!.toStringAsFixed(1),
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
                    ),
                    
                    // Botones de acción rápida
                    if (showQuickActions && book != null) ...[
                      const SizedBox(height: 6),
                      QuickActionButtons(
                        book: book!,
                        compact: true,
                      ),
                    ],
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
    if (book == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookDetailModal(book: book!),
    );
  }
}
