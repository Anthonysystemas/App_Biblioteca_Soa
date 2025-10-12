import 'package:flutter/material.dart';
import 'circle_item.dart';
import '../screens/category_books_screen.dart';

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
              children: [
                CircleItem(
                  icon: Icons.code,
                  label: 'Programación',
                  color: Colors.blue,
                  onTap: () => _navigateToCategory(context, 'programming', Icons.code, Colors.blue),
                ),
                CircleItem(
                  icon: Icons.science,
                  label: 'Ciencias',
                  color: Colors.green,
                  onTap: () => _navigateToCategory(context, 'science', Icons.science, Colors.green),
                ),
                CircleItem(
                  icon: Icons.history_edu,
                  label: 'Historia',
                  color: Colors.orange,
                  onTap: () => _navigateToCategory(context, 'history', Icons.history_edu, Colors.orange),
                ),
                CircleItem(
                  icon: Icons.psychology,
                  label: 'Filosofía',
                  color: Colors.purple,
                  onTap: () => _navigateToCategory(context, 'philosophy', Icons.psychology, Colors.purple),
                ),
                CircleItem(
                  icon: Icons.theater_comedy,
                  label: 'Literatura',
                  color: Colors.red,
                  onTap: () => _navigateToCategory(context, 'fiction', Icons.theater_comedy, Colors.red),
                ),
                CircleItem(
                  icon: Icons.calculate,
                  label: 'Matemáticas',
                  color: Colors.teal,
                  onTap: () => _navigateToCategory(context, 'mathematics', Icons.calculate, Colors.teal),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToCategory(BuildContext context, String category, IconData icon, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryBooksScreen(
          categoryName: category,
          categoryIcon: icon,
          categoryColor: color,
          currentNavIndex: currentNavIndex,
          onNavTap: onNavTap,
        ),
      ),
    );
  }
}
