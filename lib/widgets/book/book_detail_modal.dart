import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../common/action_button.dart';
import '../../screens/book_reader_screen.dart';
import '../../screens/profile_screen.dart';
import '../../services/prestamos_service.dart';
import '../../services/reservas_service.dart';
import '../../services/recently_viewed_service.dart';
import '../../services/biblioteca_service.dart';
import '../../services/stock_service.dart';

/// Modal de detalles completo del libro con acciones
class BookDetailModal extends StatefulWidget {
  final BookModel book;

  const BookDetailModal({super.key, required this.book});

  @override
  State<BookDetailModal> createState() => _BookDetailModalState();
}

class _BookDetailModalState extends State<BookDetailModal> {
  int? _stockDisponible;
  bool _cargandoStock = true;
  String _mensajeStock = '';

  @override
  void initState() {
    super.initState();
    // Guardar como visto recientemente cuando se abre el modal
    RecentlyViewedService.addBook(widget.book);
    _cargarStock();
  }

  Future<void> _cargarStock() async {
    setState(() => _cargandoStock = true);
    
    try {
      final stockInfo = await StockService.getStockInfo(widget.book.id);
      if (mounted) {
        setState(() {
          _stockDisponible = stockInfo['cantidad'];
          _mensajeStock = stockInfo['mensaje'];
          _cargandoStock = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stockDisponible = 0;
          _mensajeStock = 'Error al cargar stock';
          _cargandoStock = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHandle(),
                const SizedBox(height: 20),
                _buildBookHeader(),
                const SizedBox(height: 20),
                _buildCategories(),
                _buildDescription(),
                _buildActionButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildBookHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.book.thumbnail != null
                ? Image.network(
                    widget.book.thumbnail!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.blue,
                        child: const Icon(
                          Icons.book,
                          color: Colors.white,
                          size: 50,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.blue,
                    child: const Icon(
                      Icons.book,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.book.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.book.authorsString,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.book.publisher != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.book.publisher!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
              if (widget.book.publishedDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.book.publishedDate!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
              if (widget.book.averageRating != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        color: index < widget.book.averageRating!.round()
                            ? Colors.amber
                            : Colors.grey[300],
                        size: 14,
                      );
                    }),
                    const SizedBox(width: 4),
                    Text(
                      widget.book.averageRating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    if (widget.book.categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categorías',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A202C),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: widget.book.categories.take(4).map((category) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF667EEA),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStockInfo() {
    if (_cargandoStock) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'Consultando disponibilidad...',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final bool hayStock = _stockDisponible != null && _stockDisponible! > 0;
    final Color bgColor = hayStock 
        ? (_stockDisponible! <= 2 ? Colors.orange[50]! : Colors.green[50]!)
        : Colors.red[50]!;
    final Color borderColor = hayStock 
        ? (_stockDisponible! <= 2 ? Colors.orange : Colors.green)
        : Colors.red;
    final Color textColor = hayStock 
        ? (_stockDisponible! <= 2 ? Colors.orange[900]! : Colors.green[900]!)
        : Colors.red[900]!;
    final IconData icon = hayStock 
        ? (_stockDisponible! <= 2 ? Icons.warning_amber_rounded : Icons.check_circle)
        : Icons.cancel;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: borderColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disponibilidad',
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _mensajeStock,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    if (widget.book.description == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A202C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.book.description!,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF4A5568),
            height: 1.4,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionButtons() {
    final bool hayStock = _stockDisponible != null && _stockDisponible! > 0;
    
    return Column(
      children: [
        // STOCK DISPONIBLE
        _buildStockInfo(),
        const SizedBox(height: 16),
        
        // Primera fila: Solicitar Préstamo y Reservar
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hayStock ? () => _solicitarPrestamo() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.book, size: 18),
                label: Text(
                  hayStock ? 'Solicitar Préstamo' : 'No Disponible',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hayStock ? () => _reservarLibro() : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF667EEA),
                  disabledForegroundColor: Colors.grey[600],
                  side: BorderSide(
                    color: hayStock ? const Color(0xFF667EEA) : Colors.grey[400]!,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.bookmark_add, size: 18),
                label: Text(
                  hayStock ? 'Reservar' : 'Sin Stock',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Segunda fila: Leer libro
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookReaderScreen(book: widget.book),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.menu_book, size: 18),
            label: const Text(
              'Leer libro',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Tercera fila: Solo Favoritos (centrado)
        SizedBox(
          width: double.infinity,
          child: FavoriteButton(
            book: widget.book,
            size: 16,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Solicitar préstamo del libro
  Future<void> _solicitarPrestamo() async {
    // PRIMERO: Verificar stock disponible
    final stockDisponible = await StockService.getStockDisponible(widget.book.id);
    
    if (!mounted) return;
    
    // Si NO hay stock, sugerir reservar en su lugar
    if (stockDisponible == 0) {
      final reservar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Libro No Disponible'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                'El libro "${widget.book.title}" está actualmente ocupado.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bookmark_add, size: 16, color: Colors.orange),
                        SizedBox(width: 6),
                        Text(
                          '¿Deseas reservarlo?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Te notificaremos cuando esté disponible para recoger.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.bookmark_add, size: 18),
              label: const Text('Reservar'),
            ),
          ],
        ),
      );
      
      if (reservar == true && mounted) {
        // Llamar a la función de reservar
        await _reservarLibro();
      }
      return;
    }
    
    // Si HAY stock disponible, mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Préstamo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas solicitar el préstamo de "${widget.book.title}"?'),
            const SizedBox(height: 12),
            // Mostrar stock disponible
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stockDisponible == 1
                          ? '¡Última unidad disponible!'
                          : '$stockDisponible unidades disponibles',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Condiciones del préstamo:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SizedBox(height: 6),
                  Text('• Duración: 14 días', style: TextStyle(fontSize: 11)),
                  Text('• Renovable 1 vez', style: TextStyle(fontSize: 11)),
                  Text('• Multa por retraso: \$2/día', style: TextStyle(fontSize: 11)),
                ],
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
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      // Obtener referencias antes de operaciones asíncronas
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Llamar al servicio con datos del libro
      final success = await PrestamosService.solicitarPrestamo(
        widget.book.id,
        titulo: widget.book.title,
        autor: widget.book.authorsString,
        thumbnail: widget.book.thumbnail,
      );

      if (mounted) {
        navigator.pop(); // Cerrar loading

        // Si el préstamo fue exitoso, agregar automáticamente a Mi Biblioteca
        if (success) {
          await BibliotecaService.addToBiblioteca(widget.book);
          await BibliotecaService.updateReadingStatus(widget.book.id, 'leyendo');
          
          // Actualizar stock (-1)
          await StockService.actualizarStockLocal(widget.book.id, -1);
          
          // Recargar stock en el modal
          await _cargarStock();
        }

        // Mostrar resultado
        if (!context.mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '¡Préstamo solicitado! El libro se agregó a Mi Biblioteca.'
                  : 'No se pudo solicitar el préstamo. Verifica que no tengas este libro ya prestado o reservado.',
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: success ? 'Ver Biblioteca' : 'Mis Préstamos',
              textColor: Colors.white,
              onPressed: () {
                // Navegar al perfil y abrir Mis Préstamos
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
        );

        if (success) {
          navigator.pop(); // Cerrar modal
        }
      }
    }
  }

  /// Reservar el libro
  Future<void> _reservarLibro() async {
    // Primero verificar disponibilidad
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final disponibilidad = await ReservasService.verificarDisponibilidad(widget.book.id);

    if (!mounted) return;

    Navigator.pop(context); // Cerrar loading

    // Mostrar información de disponibilidad
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reservar Libro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas reservar "${widget.book.title}"?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Disponibilidad:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Copias totales: ${disponibilidad['copiasTotales']}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    '• Disponibles: ${disponibilidad['copiasDisponibles']}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    '• Reservas activas: ${disponibilidad['reservasActivas']}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    disponibilidad['disponible']
                        ? '✓ Disponible ahora'
                        : '⏳ Estimado: ${disponibilidad['fechaEstimada']?.substring(0, 10) ?? 'Por determinar'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: disponibilidad['disponible'] ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
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
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Reserva'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      // Obtener referencias antes de operaciones asíncronas
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Llamar al servicio con datos del libro
      final success = await ReservasService.crearReserva(
        widget.book.id,
        titulo: widget.book.title,
        autor: widget.book.authorsString,
        thumbnail: widget.book.thumbnail,
      );

      if (mounted) {
        navigator.pop(); // Cerrar loading

        // CAMBIO: NO agregar a biblioteca inmediatamente
        // Solo se agrega cuando la reserva está lista para recoger
        // (esto se maneja en el servicio de reservas)
        
        if (success) {
          // Actualizar stock (-1)
          await StockService.actualizarStockLocal(widget.book.id, -1);
          
          // Recargar stock en el modal
          await _cargarStock();
        }

        // Mostrar resultado
        if (!context.mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '¡Reserva creada! Te notificaremos cuando esté lista para recoger.'
                  : 'No se pudo crear la reserva. Verifica que no tengas este libro ya prestado o reservado.',
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Mis Reservas',
              textColor: Colors.white,
              onPressed: () {
                // Navegar al perfil y abrir Mis Reservas
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
        );

        if (success) {
          navigator.pop(); // Cerrar modal
        }
      }
    }
  }
}
