import 'package:flutter/material.dart';
import 'circle_item.dart';
import '../screens/category_books_screen.dart';
import '../config/categories_config.dart';

class CategoriesSection extends StatelessWidget {
  final int currentNavIndex;
  final Function(int) onNavTap;

  const CategoriesSection({
    super.key,
    this.currentNavIndex = 0,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Categorías',
            style: TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // CORRECCIÓN: Contenedor con altura fija
        SizedBox(
          height: 120, // Altura suficiente para círculo + texto en 2 líneas
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: CategoriesConfig.categories.map((category) {
                return CircleItem(
                  icon: category.icon,
                  label: category.displayName,
                  color: category.color,
                  onTap: () => _navigateToCategory(context, category.id),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToCategory(BuildContext context, String categoryId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryBooksScreen(
          categoryId: categoryId,
          currentNavIndex: currentNavIndex,
          onNavTap: onNavTap,
        ),
      ),
    );
  }
}
