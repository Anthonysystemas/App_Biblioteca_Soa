import 'package:flutter/material.dart';

/// Configuración de categorías con términos de búsqueda precisos
class CategoryConfig {
  final String id;
  final String displayName;
  final IconData icon;
  final Color color;
  final List<String> searchTerms;
  final List<String> subjects; // Subjects específicos de Open Library
  final List<String> excludeKeywords; // Palabras clave para excluir libros no relacionados

  const CategoryConfig({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.color,
    required this.searchTerms,
    required this.subjects,
    this.excludeKeywords = const [],
  });
}

/// Categorías disponibles en la aplicación
class CategoriesConfig {
  static const List<CategoryConfig> categories = [
    CategoryConfig(
      id: 'programming',
      displayName: 'Programación',
      icon: Icons.code,
      color: Colors.blue,
      searchTerms: [
        'computer programming',
        'software engineering',
        'coding',
      ],
      subjects: [
        'Computer programming',
        'Programming',
        'Software engineering',
        'Programming languages',
        'Computers',
        'Electronic data processing',
        'Software development',
        'Object-oriented programming',
      ],
      excludeKeywords: [
        'fiction',
        'novel',
        'romance',
        'fantasy',
        'poetry',
      ],
    ),
    CategoryConfig(
      id: 'science',
      displayName: 'Ciencias',
      icon: Icons.science,
      color: Colors.green,
      searchTerms: [
        'science',
        'natural sciences',
        'scientific research',
      ],
      subjects: [
        'Science',
        'Natural sciences',
        'Biology',
        'Chemistry',
        'Physics',
        'Astronomy',
        'Geology',
        'Zoology',
      ],
      excludeKeywords: [
        'fiction',
        'novel',
        'romance',
        'fantasy',
      ],
    ),
    CategoryConfig(
      id: 'history',
      displayName: 'Historia',
      icon: Icons.history_edu,
      color: Colors.orange,
      searchTerms: [
        'history',
        'historical',
      ],
      subjects: [
        'History',
        'World history',
        'Ancient history',
        'Medieval history',
        'Modern history',
        'Historiography',
        'Historical geography',
        'Civilization',
      ],
      excludeKeywords: [
        'fiction',
        'novel',
        'romance',
        'fantasy',
      ],
    ),
    CategoryConfig(
      id: 'philosophy',
      displayName: 'Filosofía',
      icon: Icons.psychology,
      color: Colors.purple,
      searchTerms: [
        'philosophy',
        'philosophical',
      ],
      subjects: [
        'Philosophy',
        'Ethics',
        'Metaphysics',
        'Logic',
        'Epistemology',
        'Political philosophy',
        'Aesthetics',
        'Existentialism',
      ],
      excludeKeywords: [
        'fiction',
        'novel',
        'romance',
        'fantasy',
      ],
    ),
    CategoryConfig(
      id: 'literature',
      displayName: 'Literatura',
      icon: Icons.theater_comedy,
      color: Colors.red,
      searchTerms: [
        'fiction',
        'literature',
      ],
      subjects: [
        'Fiction',
        'Literature',
        'Novels',
        'Short stories',
        'Drama',
        'Poetry',
        'Literary criticism',
        'English literature',
      ],
      excludeKeywords: [
        'programming',
        'computer',
        'mathematics',
      ],
    ),
    CategoryConfig(
      id: 'mathematics',
      displayName: 'Matemáticas',
      icon: Icons.calculate,
      color: Colors.teal,
      searchTerms: [
        'mathematics',
      ],
      subjects: [
        'Mathematics',
        'Algebra',
        'Calculus',
        'Geometry',
        'Statistics',
        'Number theory',
        'Mathematical analysis',
        'Trigonometry',
      ],
      excludeKeywords: [
        'fiction',
        'novel',
        'romance',
        'fantasy',
      ],
    ),
    CategoryConfig(
      id: 'psychology',
      displayName: 'Psicología',
      icon: Icons.psychology_alt,
      color: Colors.indigo,
      searchTerms: [
        'psychology',
      ],
      subjects: [
        'Psychology',
        'Psychotherapy',
        'Cognitive psychology',
        'Social psychology',
        'Developmental psychology',
        'Clinical psychology',
        'Psychiatry',
        'Mental health',
      ],
      excludeKeywords: [
        'fiction',
        'novel',
        'romance',
        'fantasy',
      ],
    ),
    CategoryConfig(
      id: 'business',
      displayName: 'Negocios',
      icon: Icons.business,
      color: Colors.amber,
      searchTerms: [
        'business',
        'economics',
      ],
      subjects: [
        'Business',
        'Economics',
        'Management',
        'Finance',
        'Entrepreneurship',
        'Marketing',
        'Business enterprises',
        'Commerce',
      ],
      excludeKeywords: [
        'fiction',
        'novel',
        'romance',
        'fantasy',
      ],
    ),
    CategoryConfig(
      id: 'art',
      displayName: 'Arte',
      icon: Icons.palette,
      color: Colors.pink,
      searchTerms: [
        'art',
        'fine arts',
      ],
      subjects: [
        'Art',
        'Fine arts',
        'Art, modern',
        'Painting',
        'Sculpture',
        'Artists',
        'Design',
        'Architecture',
      ],
      excludeKeywords: [
        'fiction',
        'novel',
        'romance',
        'fantasy',
      ],
    ),
  ];

  /// Obtener categoría por ID
  static CategoryConfig? getCategoryById(String id) {
    try {
      return categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtener categoría por nombre de display
  static CategoryConfig? getCategoryByDisplayName(String displayName) {
    try {
      return categories.firstWhere((cat) => cat.displayName == displayName);
    } catch (e) {
      return null;
    }
  }
}
