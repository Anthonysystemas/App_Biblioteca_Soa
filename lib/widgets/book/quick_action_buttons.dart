import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/prestamos_service.dart';
import '../../services/reservas_service.dart';
import '../../screens/profile_screen.dart';

/// Botones de acción rápida para préstamo y reserva
class QuickActionButtons extends StatelessWidget {
  final BookModel book;
  final bool compact;

  const QuickActionButtons({
    super.key,
    required this.book,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        children: [
          Expanded(
            child: _buildCompactButton(
              context,
              icon: Icons.book,
              label: 'Prestar',
              color: const Color(0xFF667EEA),
              onPressed: () => _solicitarPrestamo(context),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildCompactButton(
              context,
              icon: Icons.bookmark_add,
              label: 'Reservar',
              color: Colors.orange,
              onPressed: () => _reservarLibro(context),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _solicitarPrestamo(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.book, size: 16),
            label: const Text(
              'Prestar',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _reservarLibro(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.bookmark_add, size: 16),
            label: const Text(
              'Reservar',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        minimumSize: const Size(0, 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Solicitar préstamo
  Future<void> _solicitarPrestamo(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.book, color: Color(0xFF667EEA), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Solicitar Préstamo',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (book.authorsString.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                book.authorsString,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF667EEA), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Condiciones del préstamo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• Duración: 14 días', style: TextStyle(fontSize: 11)),
                  Text('• Renovable: 1 vez', style: TextStyle(fontSize: 11)),
                  Text('• Multa por retraso: \$2/día', style: TextStyle(fontSize: 11)),
                  SizedBox(height: 6),
                  Text(
                    'Recoge el libro en biblioteca física',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
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
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
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
        book.id,
        titulo: book.title,
        autor: book.authorsString,
        thumbnail: book.thumbnail,
      );

      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.info,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    success
                        ? '¡Préstamo solicitado! Recoge en biblioteca'
                        : 'Ya tienes un préstamo activo de este libro',
                  ),
                ),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            action: success
                ? SnackBarAction(
                    label: 'Ver',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  )
                : SnackBarAction(
                    label: 'Mis Préstamos',
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
      }
    }
  }

  /// Reservar libro
  Future<void> _reservarLibro(BuildContext context) async {
    // Verificar disponibilidad
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final disponibilidad = await ReservasService.verificarDisponibilidad(book.id);

    if (!context.mounted) return;
    Navigator.pop(context); // Cerrar loading

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bookmark_add, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Reservar Libro', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (book.authorsString.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                book.authorsString,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Disponibilidad',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Copias totales', '${disponibilidad['copiasTotales']}'),
                  _buildInfoRow('Disponibles', '${disponibilidad['copiasDisponibles']}'),
                  _buildInfoRow('En cola', '${disponibilidad['reservasActivas']}'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: disponibilidad['disponible']
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          disponibilidad['disponible'] ? Icons.check_circle : Icons.schedule,
                          size: 14,
                          color: disponibilidad['disponible'] ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            disponibilidad['disponible']
                                ? 'Disponible ahora'
                                : 'Estimado: ${disponibilidad['fechaEstimada']?.substring(0, 10) ?? 'Por determinar'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: disponibilidad['disponible'] ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
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
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.bookmark_add, size: 18),
            label: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await ReservasService.crearReserva(
        book.id,
        titulo: book.title,
        autor: book.authorsString,
        thumbnail: book.thumbnail,
      );

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.info,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    success
                        ? '¡Reserva creada! Te notificaremos'
                        : 'Ya tienes una reserva activa de este libro',
                  ),
                ),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            action: success
                ? SnackBarAction(
                    label: 'Ver',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  )
                : SnackBarAction(
                    label: 'Mis Reservas',
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
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
