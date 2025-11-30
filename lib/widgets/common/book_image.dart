import 'package:flutter/material.dart';

class BookImage extends StatelessWidget {
  final String? imageUrl;
  final Color backgroundColor;
  final String? fallbackTitle;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const BookImage({
    super.key,
    this.imageUrl,
    required this.backgroundColor,
    this.fallbackTitle,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(0);

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: fit,
                width: width,
                height: height,
                alignment: Alignment.center,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: backgroundColor,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(isSmallScreen);
                },
              )
            : _buildPlaceholder(isSmallScreen),
      ),
    );
  }

  Widget _buildPlaceholder(bool isSmallScreen) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.book,
              color: Colors.white,
              size: isSmallScreen ? 32 : 40,
            ),
            if (fallbackTitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  fallbackTitle!.length > 15
                      ? '${fallbackTitle!.substring(0, 15)}...'
                      : fallbackTitle!,
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
          ],
        ),
      ),
    );
  }
}