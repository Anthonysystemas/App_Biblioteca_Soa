import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../services/prestamos_service.dart';
import '../services/ejemplares_digitales_service.dart';
import '../models/book_model.dart';
import '../services/google_books_api_service.dart';
import 'book_reader_screen.dart';

class MisLibrosScreen extends StatefulWidget {
  final int currentNavIndex;
  final Function(int) onNavTap;

  const MisLibrosScreen({
    super.key,
    required this.currentNavIndex,
    required this.onNavTap,
  });

  @override
  State<MisLibrosScreen> createState() => _MisLibrosScreenState();
}

class _MisLibrosScreenState extends State<MisLibrosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Prestamo> _prestamos = [];
  List<Map<String, dynamic>> _listaEspera = [];
  List<Prestamo> _historial = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await PrestamosService.verificarPrestamosVencidos();
      
      final prestamos = await PrestamosService.getPrestamosActivos();
      final listaEspera = await EjemplaresDigitalesService.obtenerListaEsperaUsuario();
      final historial = await PrestamosService.getHistorial();

      if (mounted) {
        setState(() {
          _prestamos = prestamos;
          _listaEspera = listaEspera;
          _historial = historial;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          'Mis Libros',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.auto_stories),
              text: 'Préstamos (${_prestamos.length})',
            ),
            Tab(
              icon: const Icon(Icons.bookmark),
              text: 'Lista de Espera (${_listaEspera.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'Historial',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPrestamosTab(),
          _buildReservasTab(),
          _buildHistorialTab(),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: widget.currentNavIndex,
        onTap: widget.onNavTap,
      ),
    );
  }

  Widget _buildPrestamosTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
        ),
      );
    }

    if (_prestamos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.auto_stories_outlined,
        title: 'No tienes préstamos activos',
        message: 'Explora libros y solicita préstamos\npara empezar a leer',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF667EEA),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _prestamos.length,
        itemBuilder: (context, index) {
          return _buildPrestamoCard(_prestamos[index]);
        },
      ),
    );
  }

  Widget _buildReservasTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
        ),
      );
    }

    if (_listaEspera.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_outline,
        title: 'No tienes libros en lista de espera',
        message: 'Únete a la lista cuando no haya stock disponible\n(Máximo 3 libros en espera)',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF667EEA),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _listaEspera.length,
        itemBuilder: (context, index) {
          return _buildListaEsperaCard(_listaEspera[index]);
        },
      ),
    );
  }

  Widget _buildHistorialTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
        ),
      );
    }

    if (_historial.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'Sin historial de préstamos',
        message: 'Aquí aparecerán los libros\nque has devuelto',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF667EEA),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _historial.length,
        itemBuilder: (context, index) {
          return _buildHistorialCard(_historial[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => widget.onNavTap(0),
            icon: const Icon(Icons.explore),
            label: const Text('Explorar libros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrestamoCard(Prestamo prestamo) {
    final diasRestantes = prestamo.diasRestantes;
    final estaVencido = prestamo.isVencido;
    final proximoAVencer = diasRestantes >= 0 && diasRestantes <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: estaVencido
            ? const BorderSide(color: Colors.red, width: 2)
            : proximoAVencer
                ? const BorderSide(color: Colors.orange, width: 2)
                : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: prestamo.thumbnail != null
                        ? Image.network(
                            prestamo.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.book, size: 30);
                            },
                          )
                        : const Icon(Icons.book, size: 30),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prestamo.titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A202C),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prestamo.autor,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Prestado: ${_formatDate(prestamo.fechaPrestamo)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  estaVencido ? Icons.warning : Icons.access_time,
                  size: 16,
                  color: estaVencido
                      ? Colors.red
                      : proximoAVencer
                          ? Colors.orange
                          : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    estaVencido
                        ? 'Vencido hace ${diasRestantes.abs()} día${diasRestantes.abs() != 1 ? 's' : ''}'
                        : 'Vence en $diasRestantes día${diasRestantes != 1 ? 's' : ''} (${_formatDate(prestamo.fechaDevolucion)})',
                    style: TextStyle(
                      fontSize: 12,
                      color: estaVencido
                          ? Colors.red
                          : proximoAVencer
                              ? Colors.orange
                              : Colors.grey[600],
                      fontWeight: estaVencido || proximoAVencer
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            if (estaVencido) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      'Multa: \$${(diasRestantes.abs() * 2).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (!estaVencido && prestamo.renovaciones < 1) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _renovarPrestamo(prestamo),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Renovar', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF667EEA),
                        side: const BorderSide(color: Color(0xFF667EEA)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _leerLibro(prestamo),
                    icon: const Icon(Icons.auto_stories, size: 16),
                    label: const Text('Leer', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _devolverPrestamo(prestamo),
                    icon: const Icon(Icons.assignment_return, size: 16),
                    label: const Text('Devolver', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: estaVencido ? Colors.red : const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaEsperaCard(Map<String, dynamic> item) {
    final libroId = item['libroId'] as String;
    final titulo = item['titulo'] as String;
    final autor = item['autor'] as String;
    final posicion = item['posicion'] as int;
    final totalEnEspera = item['totalEnEspera'] as int;
    final fechaUnion = DateTime.parse(item['fechaUnion'] as String);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: const Icon(Icons.book, size: 30),
                ),
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
                      const SizedBox(height: 4),
                      Text(
                        autor,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'En lista desde: ${_formatDate(fechaUnion)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Posición $posicion de $totalEnEspera en la lista de espera',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _salirDeListaEspera(libroId, titulo),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Salir de Lista de Espera', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialCard(Prestamo prestamo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: prestamo.thumbnail != null
                    ? Image.network(
                        prestamo.thumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.book, size: 25);
                        },
                      )
                    : const Icon(Icons.book, size: 25),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prestamo.titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prestamo.autor,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Devuelto: ${_formatDate(prestamo.fechaDevolucion)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _renovarPrestamo(Prestamo prestamo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renovar Préstamo'),
        content: Text(
          '¿Deseas renovar el préstamo de "${prestamo.titulo}"?\n\nSe extenderá por 14 días más.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA)),
            child: const Text('Renovar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préstamo renovado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    }
  }

  Future<void> _leerLibro(Prestamo prestamo) async {
    if (prestamo.estado != 'activo' && prestamo.estado != 'renovado') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            prestamo.estado == 'devuelto' 
              ? '❌ Este préstamo ya fue devuelto. No puedes leer este libro.'
              : '❌ Este préstamo ha vencido. No puedes leer este libro.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (prestamo.isVencido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Este préstamo ha vencido. Ya no puedes leer este libro.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      BookModel? bookModel = await GoogleBooksApiService.getBookById(prestamo.libroId);

      bookModel ??= BookModel(
        id: prestamo.libroId,
        title: prestamo.titulo,
        authors: [prestamo.autor],
        authorsString: prestamo.autor,
        thumbnail: prestamo.thumbnail,
        description: null,
        publisher: null,
        publishedDate: null,
        pageCount: null,
        categories: [],
        averageRating: null,
        ratingsCount: null,
        language: 'es',
      );

      if (mounted) {
        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookReaderScreen(book: bookModel!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el libro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _devolverPrestamo(Prestamo prestamo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Devolver Libro'),
        content: Text('¿Confirmas que has devuelto "${prestamo.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA)),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final success = await PrestamosService.devolverLibro(prestamo.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Libro devuelto exitosamente'
                  : 'Error al devolver el libro',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        
        if (success) {
          _loadData();
        }
      }
    }
  }

  Future<void> _salirDeListaEspera(String libroId, String titulo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir de Lista de Espera'),
        content: Text('¿Estás seguro de que quieres salir de la lista de espera de "$titulo"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, salir'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final success = await EjemplaresDigitalesService.salirDeListaEspera(libroId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Has salido de la lista de espera'
                  : 'Error al salir de la lista de espera',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        
        if (success) {
          _loadData();
        }
      }
    }
  }
}