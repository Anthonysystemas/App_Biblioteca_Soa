import 'package:flutter/material.dart';

import '../widgets/search_bar.dart';
import '../widgets/top_section.dart';
import '../widgets/categories_section.dart';
import '../widgets/libros_mas_leidos.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/notification_badge.dart';
import 'search_screen.dart';
import 'mis_libros_screen.dart';
import 'profile_screen.dart';

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

    switch (index) {
      case 0:
        break;
      case 1:
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MisLibrosScreen(
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        ).then((_) {
          setState(() {
            _selectedIndex = 0;
          });
        });
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
        child: Column(
          children: [
            Expanded(
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
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _onSearchBarTap,
                        child: const AbsorbPointer(
                          child: AppSearchBar(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const NotificationBadge(),
                  ],
                ),
                SizedBox(height: verticalSpacing * 1.5),
                
                const TopSection(),
                SizedBox(height: verticalSpacing * 2),
                
                CategoriesSection(
                  currentNavIndex: _selectedIndex,
                  onNavTap: _onBottomNavTap,
                ),
                SizedBox(height: verticalSpacing * 2),
                
                const LibrosMasLeidosSection(),
                
                const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}