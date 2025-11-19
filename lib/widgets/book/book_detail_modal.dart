import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../screens/book_reader_screen.dart';
import '../../screens/profile_screen.dart';
import '../../services/reservas_service.dart';
import '../../services/recently_viewed_service.dart';
import '../../services/stock_service.dart';
import '../../services/open_library_api_service.dart';
import '../../services/ejemplares_digitales_service.dart';
import '../../services/prestamos_service.dart';

/// Modal de detalles completo del libro con acciones
class BookDetailModal extends StatefulWidget {
  final BookModel book;

  const BookDetailModal({super.key, required this.book});

  @override
  State<BookDetailModal> createState() => _BookDetailModalState();
}

class _BookDetailModalState extends State<BookDetailModal> {
  int? _stockDisponible;

  // Disponibilidad digital
  DisponibilidadDigital? _disponibilidadDigital;
  bool _cargandoDigital = true;

  // Lista de espera
  bool _estaEnListaEspera = false;
  int? _posicionEnLista;
  int _cantidadEnEspera = 0;

  @override
  void initState() {
    super.initState();
    // Guardar como visto recientemente cuando se abre el modal
    RecentlyViewedService.addBook(widget.book);
    _cargarStock();
    _cargarDisponibilidadDigital();
  }

  Future<void> _cargarStock() async {
    try {
      final stockInfo = await StockService.getStockInfo(widget.book.id);
      if (mounted) {
        setState(() {
          _stockDisponible = stockInfo['cantidad'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stockDisponible = 0;
        });
      }
    }
  }

  Future<void> _cargarDisponibilidadDigital() async {
    setState(() => _cargandoDigital = true);

    try {
      final disponibilidad = await OpenLibraryApiService.getBookAvailability(widget.book.id);
      final enListaEspera = await EjemplaresDigitalesService.estaEnListaEspera(widget.book.id);
      final posicion = await EjemplaresDigitalesService.obtenerPosicionEnLista(widget.book.id);
      final cantidad = await EjemplaresDigitalesService.obtenerCantidadEnEspera(widget.book.id);

      if (mounted) {
        setState(() {
          _disponibilidadDigital = disponibilidad;
          _estaEnListaEspera = enListaEspera;
          _posicionEnLista = posicion;
          _cantidadEnEspera = cantidad;
          _cargandoDigital = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoDigital = false;
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
    final bool hayDigital = _disponibilidadDigital != null && _disponibilidadDigital!.disponible;

    return Column(
      children: [
        // DISPONIBILIDAD DIGITAL
        _buildDisponibilidadDigital(),
        const SizedBox(height: 16),

        // Botones principales: PRÉSTAMO DIGITAL / LISTA DE ESPERA
        if (!_cargandoDigital) ...[
          // Caso 1: HAY DISPONIBLES - Botón de préstamo
          if (hayDigital) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _prestarDigital(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.cloud_download, size: 22),
                label: const Text(
                  'Prestar Digital (14 días)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lectura digital por 14 días',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ]
          // Caso 2: NO HAY DISPONIBLES - Botones de lista de espera
          else ...[
            // Si ya está en lista de espera
            if (_estaEnListaEspera) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.hourglass_bottom, color: Colors.amber[700], size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EN LISTA DE ESPERA',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber[900],
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Posición: ${_posicionEnLista ?? '?'} de $_cantidadEnEspera',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.amber[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Te notificaremos cuando el libro esté disponible',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _salirDeListaEspera(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.exit_to_app, size: 18),
                        label: const Text('Salir de la Lista'),
                      ),
                    ),
                  ],
                ),
              ),
            ]
            // Si NO está en lista de espera
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _unirseAListaEspera(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.queue, size: 22),
                  label: const Text(
                    'Unirse a Lista de Espera',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _cantidadEnEspera > 0
                    ? '$_cantidadEnEspera persona${_cantidadEnEspera == 1 ? '' : 's'} esperando'
                    : 'Sé el primero en la lista de espera',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),

        // Botón principal: LEER AHORA (préstamo digital inmediato)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: hayStock ? () => _solicitarPrestamo() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hayStock ? const Color(0xFF10B981) : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: hayStock ? 4 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.auto_stories, size: 22),
            label: Text(
              hayStock ? 'Leer Ahora (14 días)' : 'No Disponible',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (!hayStock) ...[
          const SizedBox(height: 8),
          Text(
            'No hay licencias disponibles. Puedes reservar y te notificaremos cuando esté disponible.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          // Botón para reservar cuando no hay stock
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _reservarLibro(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF667EEA),
                side: const BorderSide(color: Color(0xFF667EEA)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.bookmark_add, size: 18),
              label: const Text(
                'Reservar y Esperar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),
        // Vista previa - Solo si hay préstamo activo
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              // Verificar si el libro está en préstamos activos
              final prestamoActivo = await PrestamosService.tienePrestamo(widget.book.id);
              
              if (!mounted) return;
              
              if (prestamoActivo) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookReaderScreen(book: widget.book),
                  ),
                );
              } else {
                // Mostrar mensaje de que necesita tener el libro prestado
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes tener este libro en préstamo activo para leerlo'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[400]!),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.menu_book, size: 16),
            label: const Text(
              'Leer Libro',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisponibilidadDigital() {
    if (_cargandoDigital) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Consultando disponibilidad digital...',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_disponibilidadDigital == null) {
      return const SizedBox.shrink();
    }

    final disp = _disponibilidadDigital!;
    final Color bgColor = disp.disponible
        ? (disp.ejemplaresDisponibles <= 2 ? Colors.orange[50]! : Colors.green[50]!)
        : Colors.red[50]!;
    final Color borderColor = disp.disponible
        ? (disp.ejemplaresDisponibles <= 2 ? Colors.orange : Colors.green)
        : Colors.red;
    final Color textColor = disp.disponible
        ? (disp.ejemplaresDisponibles <= 2 ? Colors.orange[900]! : Colors.green[900]!)
        : Colors.red[900]!;
    final IconData icon = disp.disponible
        ? (disp.ejemplaresDisponibles <= 2 ? Icons.warning_amber_rounded : Icons.check_circle)
        : Icons.cancel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EJEMPLARES DIGITALES',
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      disp.mensaje,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip('Total', disp.ejemplaresTotales.toString(), Colors.blue),
                _buildStatChip('En uso', disp.ejemplaresEnUso.toString(), Colors.purple),
                _buildStatChip('Disponibles', disp.ejemplaresDisponibles.toString(), borderColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Prestar ejemplar digital (FLUJO PRINCIPAL para préstamo digital)
  Future<void> _prestarDigital() async {
    // Verificar si ya tiene un préstamo activo de este libro
    final tieneActivo = await EjemplaresDigitalesService.tienePrestamoActivo(widget.book.id);

    if (!mounted) return;

    if (tieneActivo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya tienes un préstamo digital activo de este libro. Ve a "Mis Libros" para leerlo.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación con detalles del préstamo digital
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_download, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Expanded(child: Text('Préstamo Digital')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Deseas tomar prestado "${widget.book.title}" en formato digital?',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              // Información del préstamo digital
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green[700], size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Préstamo digital:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStep('1', 'Préstamo por 14 días'),
                    _buildStep('2', 'Lectura disponible inmediatamente'),
                    _buildStep('3', 'Acceso desde "Mis Libros"'),
                    _buildStep('4', 'Devolución automática al vencer'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Disponibilidad actual
              if (_disponibilidadDigital != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disponibilidad actual:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Ejemplares totales: ${_disponibilidadDigital!.ejemplaresTotales}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        '• En uso: ${_disponibilidadDigital!.ejemplaresEnUso}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        '• Disponibles: ${_disponibilidadDigital!.ejemplaresDisponibles}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.cloud_download, size: 18),
            label: const Text('Confirmar Préstamo'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Intentar prestar el ejemplar
    final prestado = await EjemplaresDigitalesService.prestarEjemplar(widget.book.id);

    if (!mounted) return;
    Navigator.pop(context); // Cerrar loading

    if (prestado) {
      // Generar ID único para el préstamo
      final prestamoId = '${widget.book.id}_${DateTime.now().millisecondsSinceEpoch}';

      // Registrar préstamo activo
      await EjemplaresDigitalesService.registrarPrestamoActivo(widget.book.id, prestamoId);

      // Recargar disponibilidad digital para actualizar la UI
      await _cargarDisponibilidadDigital();

      if (!mounted) return;

      // Mostrar éxito con opción de leer ahora
      final leerAhora = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 8),
              Expanded(child: Text('¡Préstamo Exitoso!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Has tomado prestado "${widget.book.title}" en formato digital.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue[700], size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Disponible por 14 días',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Puedes leerlo ahora o encontrarlo más tarde en la sección "Mis Libros".',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Más tarde'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.menu_book, size: 18),
              label: const Text('Leer Ahora'),
            ),
          ],
        ),
      );

      if (leerAhora == true && mounted) {
        // Cerrar el modal de detalles del libro
        Navigator.pop(context);

        // Intentar descargar y abrir el libro real
        await _descargarYAbrirLibro();
      }
    } else {
      // Error al prestar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo completar el préstamo. No hay ejemplares disponibles.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Unirse a la lista de espera
  Future<void> _unirseAListaEspera() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.queue, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(child: Text('Lista de Espera')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas unirte a la lista de espera para "${widget.book.title}"?',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[700], size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Cómo funciona:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.amber[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStep('1', 'Te unes a la lista de espera'),
                  _buildStep('2', 'Te notificaremos cuando esté disponible'),
                  _buildStep('3', 'Tendrás 24 horas para tomar prestado'),
                  _buildStep('4', 'Si no lo tomas, pasa al siguiente'),
                ],
              ),
            ),
            if (_cantidadEnEspera > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Actualmente hay $_cantidadEnEspera persona${_cantidadEnEspera == 1 ? '' : 's'} esperando.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.queue, size: 18),
            label: const Text('Unirme'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final unido = await EjemplaresDigitalesService.unirseAListaEspera(
      widget.book.id,
      titulo: widget.book.title,
      autor: widget.book.authorsString,
    );

    if (!mounted) return;
    Navigator.pop(context); // Cerrar loading

    if (unido) {
      await _cargarDisponibilidadDigital(); // Recargar datos

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Te has unido a la lista de espera! Posición: ${_posicionEnLista ?? '?'}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya estás en la lista de espera de este libro.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Salir de la lista de espera
  Future<void> _salirDeListaEspera() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.red),
            SizedBox(width: 8),
            Text('Salir de Lista de Espera'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas salir de la lista de espera?\n\n'
          'Perderás tu posición actual y tendrás que volver a unirte si cambias de opinión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final salido = await EjemplaresDigitalesService.salirDeListaEspera(widget.book.id);

    if (salido && mounted) {
      await _cargarDisponibilidadDigital(); // Recargar datos

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Has salido de la lista de espera.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Solicitar préstamo inmediato (biblioteca digital)
  Future<void> _solicitarPrestamo() async {
    // Verificar stock disponible
    final stockDisponible = await StockService.getStockDisponible(widget.book.id);

    if (!mounted) return;

    // Si no hay stock, mostrar diálogo y ofrecer reservar
    if (stockDisponible == 0) {
      final reservar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Expanded(child: Text('No Disponible')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lo sentimos, todas las licencias digitales de "${widget.book.title}" están en uso en este momento.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '¿Quieres reservarlo?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Puedes reservar este libro y te notificaremos cuando una licencia esté disponible.',
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
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.bookmark_add, size: 18),
              label: const Text('Reservar'),
            ),
          ],
        ),
      );

      if (reservar == true && mounted) {
        await _reservarLibro();
      }
      return;
    }

    // Si hay stock, confirmar préstamo digital
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_stories, color: const Color(0xFF10B981)),
            const SizedBox(width: 8),
            const Expanded(child: Text('Leer Libro Digital')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas comenzar a leer "${widget.book.title}"?',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green[700], size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Préstamo Digital:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Tendrás acceso durante 14 días',
                    style: TextStyle(fontSize: 11),
                  ),
                  const Text(
                    '• Podrás leer en cualquier momento',
                    style: TextStyle(fontSize: 11),
                  ),
                  const Text(
                    '• Después de 14 días el acceso se bloqueará automáticamente',
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
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.auto_stories, size: 18),
            label: const Text('Comenzar a Leer'),
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

      // Crear préstamo
      bool success = false;
      String? errorType;
      
      try {
        success = await PrestamosService.solicitarPrestamo(
          widget.book.id,
          titulo: widget.book.title,
          autor: widget.book.authorsString,
          thumbnail: widget.book.thumbnail,
        );
      } catch (e) {
        final errorMsg = e.toString();
        debugPrint('🚨 ERROR CAPTURADO: $errorMsg');
        
        if (errorMsg.contains('LIMITE_PRESTAMOS')) {
          errorType = 'LIMITE_PRESTAMOS';
          debugPrint('✅ Tipo de error detectado: LIMITE_PRESTAMOS');
        } else if (errorMsg.contains('LIBRO_YA_PRESTADO')) {
          errorType = 'LIBRO_YA_PRESTADO';
          debugPrint('✅ Tipo de error detectado: LIBRO_YA_PRESTADO');
        } else if (errorMsg.contains('LIBRO_YA_RESERVADO')) {
          errorType = 'LIBRO_YA_RESERVADO';
          debugPrint('✅ Tipo de error detectado: LIBRO_YA_RESERVADO');
        } else {
          debugPrint('⚠️ Error desconocido: $errorMsg');
        }
        success = false;
      }

      if (mounted) {
        navigator.pop(); // Cerrar loading

        if (success) {
          // Actualizar stock (-1)
          await StockService.actualizarStockLocal(widget.book.id, -1);
          
          // Recargar stock en el modal
          await _cargarStock();
        }

        // Mostrar resultado
        if (!context.mounted) return;
        
        // Determinar mensaje según el tipo de error
        String errorMessage;
        if (errorType == 'LIMITE_PRESTAMOS') {
          errorMessage = '⚠️ Límite Alcanzado\n\nYa tienes 5 préstamos activos (máximo permitido).\n\n💡 Devuelve un libro para solicitar uno nuevo.';
        } else if (errorType == 'LIBRO_YA_PRESTADO') {
          errorMessage = '📚 Libro Ya Prestado\n\nYa tienes este libro en tus préstamos activos.';
        } else if (errorType == 'LIBRO_YA_RESERVADO') {
          errorMessage = '🔖 Libro en Lista de Espera\n\nEste libro ya está en tu lista de espera.';
        } else {
          errorMessage = 'No se pudo crear el préstamo.';
        }
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '¡Préstamo creado! Tienes 14 días de acceso.'
                  : errorMessage,
            ),
            backgroundColor: success ? Colors.green : (errorType == 'LIMITE_PRESTAMOS' ? Colors.red : Colors.orange),
            duration: Duration(seconds: errorType == 'LIMITE_PRESTAMOS' ? 5 : 3),
            action: SnackBarAction(
              label: 'Mis Libros',
              textColor: Colors.white,
              onPressed: () {
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

  /// Reservar el libro (SOLO cuando NO hay stock disponible)
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

    // Mostrar información de disponibilidad y proceso de notificación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bookmark_add, color: const Color(0xFF667EEA)),
            const SizedBox(width: 8),
            const Expanded(child: Text('Reservar Libro Digital')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Deseas reservar "${widget.book.title}"?',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              
              // Proceso de notificación digital
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Sistema de reservas:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Te agregamos a la cola de espera',
                      style: TextStyle(fontSize: 11),
                    ),
                    const Text(
                      '• Te notificamos cuando una licencia esté disponible',
                      style: TextStyle(fontSize: 11),
                    ),
                    const Text(
                      '• Tendrás acceso inmediato por 14 días',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Disponibilidad
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado actual:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Licencias totales: ${disponibilidad['copiasTotales']}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      '• Disponibles ahora: ${disponibilidad['copiasDisponibles']}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      '• Personas esperando: ${disponibilidad['reservasActivas']}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.bookmark_add, size: 18),
            label: const Text('Confirmar Reserva'),
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
      bool success = false;
      String? errorTypeReserva;
      
      try {
        success = await ReservasService.crearReserva(
          widget.book.id,
          titulo: widget.book.title,
          autor: widget.book.authorsString,
          thumbnail: widget.book.thumbnail,
        );
      } catch (e) {
        final errorMsg = e.toString();
        debugPrint('🚨 ERROR CAPTURADO (RESERVA): $errorMsg');
        
        if (errorMsg.contains('LIMITE_RESERVAS')) {
          errorTypeReserva = 'LIMITE_RESERVAS';
          debugPrint('✅ Tipo de error detectado: LIMITE_RESERVAS');
        } else if (errorMsg.contains('LIBRO_YA_PRESTADO')) {
          errorTypeReserva = 'LIBRO_YA_PRESTADO';
          debugPrint('✅ Tipo de error detectado: LIBRO_YA_PRESTADO (en reserva)');
        } else if (errorMsg.contains('LIBRO_YA_RESERVADO')) {
          errorTypeReserva = 'LIBRO_YA_RESERVADO';
          debugPrint('✅ Tipo de error detectado: LIBRO_YA_RESERVADO');
        } else {
          debugPrint('⚠️ Error desconocido: $errorMsg');
        }
        success = false;
      }

      if (mounted) {
        navigator.pop(); // Cerrar loading

        if (success) {
          // Actualizar stock (-1)
          await StockService.actualizarStockLocal(widget.book.id, -1);
          
          // Recargar stock en el modal
          await _cargarStock();
        }

        // Mostrar resultado
        if (!context.mounted) return;
        
        // Determinar mensaje según el tipo de error
        String errorMessageReserva;
        if (errorTypeReserva == 'LIMITE_RESERVAS') {
          errorMessageReserva = '⚠️ Límite Alcanzado\n\nYa tienes 3 libros en lista de espera (máximo permitido).\n\n💡 Cancela una reserva para agregar otro libro.';
        } else if (errorTypeReserva == 'LIBRO_YA_PRESTADO') {
          errorMessageReserva = '📚 Libro Ya Prestado\n\nYa tienes este libro en tus préstamos activos.';
        } else if (errorTypeReserva == 'LIBRO_YA_RESERVADO') {
          errorMessageReserva = '🔖 Ya en Lista de Espera\n\nEste libro ya está en tu lista de espera.';
        } else {
          errorMessageReserva = 'No se pudo agregar a la lista de espera.';
        }
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '¡Agregado a lista de espera! Te notificaremos cuando esté disponible.'
                  : errorMessageReserva,
            ),
            backgroundColor: success ? Colors.green : (errorTypeReserva == 'LIMITE_RESERVAS' ? Colors.red : Colors.orange),
            duration: Duration(seconds: errorTypeReserva == 'LIMITE_RESERVAS' ? 5 : 3),
            action: SnackBarAction(
              label: 'Lista de Espera',
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

  /// Descargar y abrir el libro real desde Internet Archive
  Future<void> _descargarYAbrirLibro() async {
    // En lugar de descargar, abrimos directamente el visor web de Google Books
    try {
      // Navegar directamente al BookReaderScreen con WebView
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookReaderScreen(book: widget.book),
        ),
      );
    } catch (e) {
      // Error al abrir el lector
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir el libro: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Helper para construir pasos del proceso
  Widget _buildStep(String numero, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                numero,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
