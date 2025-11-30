import 'package:flutter/material.dart';
import '../services/ejemplares_digitales_service.dart';
import '../widgets/book/book_detail_modal.dart';
import '../models/book_model.dart';

class NotificacionesDisponibilidadScreen extends StatefulWidget {
  const NotificacionesDisponibilidadScreen({super.key});

  @override
  State<NotificacionesDisponibilidadScreen> createState() => _NotificacionesDisponibilidadScreenState();
}

class _NotificacionesDisponibilidadScreenState extends State<NotificacionesDisponibilidadScreen> {
  List<Map<String, dynamic>> _notificaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() => _cargando = true);

    final notifs = await EjemplaresDigitalesService.obtenerNotificaciones();

    if (mounted) {
      setState(() {
        _notificaciones = notifs;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _notificaciones.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _cargarNotificaciones,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notificaciones.length,
                    itemBuilder: (context, index) {
                      return _buildNotificacionCard(_notificaciones[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'No tienes notificaciones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aquí aparecerán las notificaciones cuando los libros que esperas estén disponibles.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificacionCard(Map<String, dynamic> notif) {
    final esLeida = notif['leida'] ?? false;
    final fechaNotif = DateTime.parse(notif['fechaNotificacion']);
    final disponibleHasta = DateTime.parse(notif['disponibleHasta']);
    final yaVencio = DateTime.now().isAfter(disponibleHasta);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: esLeida ? 1 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: esLeida
              ? Colors.grey[300]!
              : (yaVencio ? Colors.red : const Color(0xFF10B981)),
          width: esLeida ? 1 : 2,
        ),
      ),
      child: InkWell(
        onTap: () => _abrirLibro(notif),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    yaVencio ? Icons.timer_off : Icons.check_circle,
                    color: yaVencio
                        ? Colors.red
                        : (esLeida ? Colors.grey : const Color(0xFF10B981)),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif['titulo'] ?? 'Libro sin título',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: esLeida ? Colors.grey[600] : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (notif['autor'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            notif['autor'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!esLeida)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'NUEVA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: yaVencio
                      ? Colors.red[50]
                      : (esLeida ? Colors.grey[100] : Colors.green[50]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      yaVencio ? Icons.warning : Icons.schedule,
                      size: 18,
                      color: yaVencio ? Colors.red : Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        yaVencio
                            ? 'Tiempo expirado - El libro pasó al siguiente en la lista'
                            : notif['mensaje'] ?? '¡Libro disponible!',
                        style: TextStyle(
                          fontSize: 13,
                          color: yaVencio ? Colors.red[900] : Colors.green[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatearFecha(fechaNotif),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (!yaVencio && !esLeida)
                    Text(
                      'Disponible hasta ${_formatearFecha(disponibleHasta)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              if (!yaVencio && !esLeida) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirLibro(notif),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.book, size: 18),
                    label: const Text(
                      'Ver Libro y Tomar Prestado',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Justo ahora';
    } else if (diferencia.inHours < 1) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inDays < 1) {
      return 'Hace ${diferencia.inHours}h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays}d';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  Future<void> _abrirLibro(Map<String, dynamic> notif) async {
    await EjemplaresDigitalesService.marcarNotificacionComoLeida(notif['id']);
    await _cargarNotificaciones();

    final libroId = notif['libroId'];
    final titulo = notif['titulo'] ?? 'Libro sin título';
    final autor = notif['autor'] ?? 'Autor desconocido';

    final book = BookModel(
      id: libroId,
      title: titulo,
      authors: [autor],
      authorsString: autor,
      thumbnail: null,
      description: null,
      publisher: null,
      publishedDate: null,
      pageCount: null,
      categories: [],
      averageRating: null,
      ratingsCount: null,
      language: 'es',
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookDetailModal(book: book),
    );
  }
}