import 'package:flutter/material.dart';
import '../widgets/search_bar.dart';
import '../widgets/top_section.dart';
import '../widgets/categories_section.dart';
import '../widgets/libros_mas_leidos.dart';
import '../widgets/bottom_nav.dart';
import 'search_screen.dart';
import 'Favorites_screen.dart';
import 'biblioteca_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navegar según el índice
    switch (index) {
      case 0:
        // Inicio - ya estamos aquí
        break;
      case 1:
        // Buscar
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SearchScreen(
              currentNavIndex: index,
              onNavTap: _onBottomNavTap,
            ),
          ),
        ).then((_) {
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 2:
        // Mi Biblioteca - navegar a la pantalla de biblioteca
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BibliotecaScreen(
              currentNavIndex: index,
              onNavTap: _onBottomNavTap,
            ),
          ),
        ).then((_) {
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 3:
        // Favoritos
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FavoritesScreen(
              currentNavIndex: index,
              onNavTap: _onBottomNavTap,
            ),
          ),
        ).then((_) {
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 4:
        // Perfil - implementar después
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil - Próximamente'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
    }
  }

  void _onSearchBarTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          currentNavIndex: 1,
          onNavTap: _onBottomNavTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.05;
    final verticalSpacing = screenHeight * 0.02;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding, 
              vertical: verticalSpacing
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra de búsqueda clickeable
                GestureDetector(
                  onTap: _onSearchBarTap,
                  child: AbsorbPointer(
                    child: const AppSearchBar(),
                  ),
                ),
                SizedBox(height: verticalSpacing * 1.5),
                
                // Sección superior con saludo y libro destacado
                const TopSection(),
                SizedBox(height: verticalSpacing * 2),
                
                // Sección de categorías con íconos circulares
                const CategoriesSection(),
                SizedBox(height: verticalSpacing * 2),
                
                // Sección de libros más leídos con API (con íconos de favorito)
                const LibrosMasLeidosSection(),
                
                // Espaciado inferior para el BottomNav
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}