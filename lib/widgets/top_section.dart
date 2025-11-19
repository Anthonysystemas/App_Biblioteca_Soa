import 'package:flutter/material.dart';
import 'dart:io';
import '../services/user_service.dart';
import '../services/recently_viewed_service.dart';
import '../models/user.dart';
import '../models/book_model.dart';
import '../screens/book_reader_screen.dart';
import '../screens/profile_screen.dart';

class TopSection extends StatefulWidget {
  const TopSection({super.key});

  @override
  State<TopSection> createState() => _TopSectionState();
}

class _TopSectionState extends State<TopSection> {
  User? _currentUser;
  BookModel? _lastViewedBook;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadLastBook();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar usuario cuando se regrese a esta pantalla
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserService.getUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _loadLastBook() async {
    final lastBook = await RecentlyViewedService.getLastViewedBook();
    if (mounted) {
      setState(() {
        _lastViewedBook = lastBook;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    // Navegar al perfil para cambiar la foto
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
    
    // Recargar usuario después de regresar del perfil
    if (mounted) {
      _loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _currentUser?.name ?? 'Usuario';
    final userImage = _currentUser?.profileImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila: Saludo a la izquierda y Avatar a la derecha
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola $userName!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Encuentra tu próximo libro favorito',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Avatar con foto de perfil o inicial
            GestureDetector(
              onTap: _pickProfileImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    backgroundImage: userImage != null && userImage.isNotEmpty
                        ? (userImage.startsWith('http')
                            ? NetworkImage(userImage) as ImageProvider
                            : FileImage(File(userImage)))
                        : null,
                    child: userImage == null || userImage.isEmpty
                        ? Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  // Indicador de edición
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // TARJETA DEL LIBRO DESTACADO - CORRECCIÓN COMPLETA
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 140,
            maxHeight: 160,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // SECCIÓN DE TEXTO - OPTIMIZADA
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Etiqueta
                      Text(
                        _lastViewedBook != null ? 'Continuar leyendo' : 'Libro destacado',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Título del libro
                      Text(
                        _lastViewedBook?.title ?? 'Explora nuestra colección',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Botón
                      ElevatedButton(
                        onPressed: _lastViewedBook != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookReaderScreen(
                                      book: _lastViewedBook!,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667EEA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          elevation: 0,
                          minimumSize: const Size(100, 36),
                        ),
                        child: Text(
                          _lastViewedBook != null ? 'Leer ahora' : 'Explorar',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // ICONO DEL LIBRO - OPTIMIZADO
                Container(
                  width: 70,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}