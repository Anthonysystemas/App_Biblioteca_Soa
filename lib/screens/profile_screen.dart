import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../services/prestamos_service.dart';
import '../services/ejemplares_digitales_service.dart';
import '../services/recently_viewed_service.dart';
import '../models/user.dart';
import 'login_screen.dart';
import 'reportes_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/book_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  bool _isLoading = true;
  int _prestamosCount = 0;
  int _listaEsperaCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadContadores();
  }

  Future<void> _loadUser() async {
    final user = await UserService.getUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadContadores() async {
    final prestamos = await PrestamosService.getPrestamosActivos();
    final listaEspera = await EjemplaresDigitalesService.obtenerListaEsperaUsuario();
    
    if (mounted) {
      setState(() {
        _prestamosCount = prestamos.length;
        _listaEsperaCount = listaEspera.length;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar foto de perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF667EEA)),
              title: const Text('Seleccionar desde galería'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF667EEA)),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            if (_currentUser?.profileImage != null && _currentUser!.profileImage!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar foto'),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    if (result == 'remove') {
      final updatedUser = User(
        id: _currentUser?.id ?? '',
        name: _currentUser?.name ?? '',
        email: _currentUser?.email ?? '',
        profileImage: null,
      );
      await UserService.saveUser(updatedUser);
      _loadUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil eliminada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final ImagePicker picker = ImagePicker();
    XFile? image;

    try {
      if (result == 'camera') {
        image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
      } else {
        image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
      }

      if (image != null) {
        final updatedUser = User(
          id: _currentUser?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: _currentUser?.name ?? '',
          email: _currentUser?.email ?? '',
          profileImage: image.path,
        );

        await UserService.saveUser(updatedUser);
        _loadUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  void _showMisPrestamos() async {
    final prestamos = await PrestamosService.getPrestamosActivos();
    
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mis Préstamos Activos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: prestamos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes préstamos activos',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: prestamos.length,
                          itemBuilder: (context, index) {
                            final prestamo = prestamos[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildPrestamoCard(
                                prestamoId: prestamo.id,
                                titulo: prestamo.titulo,
                                autor: prestamo.autor,
                                fechaPrestamo: _formatDate(prestamo.fechaPrestamo),
                                fechaDevolucion: _formatDate(prestamo.fechaDevolucion),
                                diasRestantes: prestamo.diasRestantes,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    _loadContadores();
  }

  void _showListaEspera() async {
    final listaEspera = await EjemplaresDigitalesService.obtenerListaEsperaUsuario();
    
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Lista de Espera',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: listaEspera.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes libros en lista de espera',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: listaEspera.length,
                          itemBuilder: (context, index) {
                            final item = listaEspera[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildListaEsperaCard(
                                libroId: item['libroId'] as String,
                                titulo: item['titulo'] as String,
                                autor: item['autor'] as String,
                                fechaUnion: DateTime.parse(item['fechaUnion'] as String),
                                posicion: item['posicion'] as int,
                                totalEnEspera: item['totalEnEspera'] as int,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    _loadContadores();
  }

  void _showHistorial() async {
    final librosVistos = await RecentlyViewedService.getAllRecentlyViewed();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.history, color: Color(0xFF667EEA)),
                    const SizedBox(width: 8),
                    const Text(
                      'Historial de Libros Vistos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                  ],
                ),
                if (librosVistos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${librosVistos.length} ${librosVistos.length == 1 ? "libro" : "libros"}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: librosVistos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No has visto ningún libro aún',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Explora nuestra colección',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          controller: scrollController,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: librosVistos.length,
                          itemBuilder: (context, index) {
                            final book = librosVistos[index];
                            return BookCard.fromBookModel(book);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${meses[date.month - 1]} ${date.year}';
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              
              await UserService.clearUser();
              
              if (!mounted) return;
              navigator.popUntil((route) => route.isFirst);
              navigator.pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _limpiarHistorial() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.orange),
            SizedBox(width: 8),
            Text('Limpiar Historial'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar todo tu historial de préstamos?',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      await PrestamosService.clearHistorial();
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Historial eliminado correctamente'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userName = _currentUser?.name ?? 'Usuario';
    final userEmail = _currentUser?.email ?? '';
    final userImage = _currentUser?.profileImage;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF667EEA),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667EEA),
                      Color(0xFF764BA2),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            backgroundImage: userImage != null && userImage.isNotEmpty
                                ? (userImage.startsWith('http')
                                    ? NetworkImage(userImage) as ImageProvider
                                    : FileImage(File(userImage)))
                                : null,
                            child: userImage == null || userImage.isEmpty
                                ? Text(
                                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: Color(0xFF667EEA),
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickProfileImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Color(0xFF667EEA),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (userEmail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.book,
                          count: '$_prestamosCount',
                          label: 'Préstamos',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.bookmark,
                          count: '$_listaEsperaCount',
                          label: 'Lista de Espera',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Cuenta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: 'Editar Perfil',
                      subtitle: 'Actualiza tu información personal',
                      onTap: () async {
                        if (_currentUser != null) {
                          final result = await showEditProfileModal(context, _currentUser!);
                          if (result == true) {
                            _loadUser();
                          }
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.lock_outline,
                      title: 'Cambiar Contraseña',
                      subtitle: 'Actualiza tu contraseña',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Próximamente disponible')),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Text(
                        'Actividad de Biblioteca',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                      if (_prestamosCount + _listaEsperaCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_prestamosCount + _listaEsperaCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gestiona tus libros prestados y reservados',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF718096),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.book_outlined,
                      title: 'Mis Préstamos',
                      subtitle: _prestamosCount == 0 
                          ? 'Sin préstamos activos'
                          : '$_prestamosCount ${_prestamosCount == 1 ? "libro activo" : "libros activos"}',
                      trailing: _prestamosCount > 0 
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_prestamosCount',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => _showMisPrestamos(),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.bookmark_outline,
                      title: 'Lista de Espera',
                      subtitle: _listaEsperaCount == 0
                          ? 'Sin libros en lista de espera'
                          : '$_listaEsperaCount ${_listaEsperaCount == 1 ? "libro en espera" : "libros en espera"}',
                      trailing: _listaEsperaCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_listaEsperaCount',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => _showListaEspera(),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.history,
                      title: 'Historial',
                      subtitle: 'Libros que has visto recientemente',
                      onTap: () => _showHistorial(),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.bar_chart,
                      title: 'Estadísticas',
                      subtitle: 'Ver mi reporte de lectura',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportesScreen(),
                          ),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _limpiarHistorial,
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Limpiar Historial'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar Sesión'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF667EEA).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF667EEA), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A202C),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          height: 1.3,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[200],
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildPrestamoCard({
    required String prestamoId,
    required String titulo,
    required String autor,
    required String fechaPrestamo,
    required String fechaDevolucion,
    required int diasRestantes,
  }) {
    final bool isVencido = diasRestantes < 0;
    final color = isVencido ? Colors.red : (diasRestantes <= 3 ? Colors.orange : Colors.green);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.book, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      autor,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Préstamo: $fechaPrestamo',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    'Devolución: $fechaDevolucion',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isVencido ? 'Vencido' : '$diasRestantes días',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                final success = await PrestamosService.renovarPrestamo(prestamoId);
                
                if (!context.mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(success 
                      ? 'Préstamo renovado exitosamente' 
                      : 'Error al renovar préstamo'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                
                if (success) {
                  navigator.pop();
                  _showMisPrestamos();
                }
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Renovar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaEsperaCard({
    required String libroId,
    required String titulo,
    required String autor,
    required DateTime fechaUnion,
    required int posicion,
    required int totalEnEspera,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_empty, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      autor,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'En lista desde: ${_formatDate(fechaUnion)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total en espera: $totalEnEspera',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Posición: $posicion',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Salir de Lista de Espera'),
                    content: Text('¿Estás seguro de que deseas salir de la lista de espera de "$titulo"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Sí, salir'),
                      ),
                    ],
                  ),
                );
                
                if (confirmar == true) {
                  if (!context.mounted) return;
                  final success = await EjemplaresDigitalesService.salirDeListaEspera(libroId);
                  
                  if (!context.mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(success 
                        ? 'Has salido de la lista de espera' 
                        : 'Error al salir de la lista de espera'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                  
                  if (success) {
                    navigator.pop();
                    _showListaEspera();
                    _loadContadores();
                  }
                }
              },
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Salir de Lista de Espera'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}