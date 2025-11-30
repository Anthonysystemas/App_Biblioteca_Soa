import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/prestamos_service.dart';
import '../../services/stock_service.dart';
import '../../services/ejemplares_digitales_service.dart';
import '../../screens/profile_screen.dart';

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
      return SizedBox(
        width: double.infinity,
        child: _buildCompactButton(
          context,
          icon: Icons.auto_stories,
          label: 'Leer Ahora',
          color: const Color(0xFF667EEA),
          onPressed: () => _solicitarPrestamo(context),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
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
        icon: const Icon(Icons.auto_stories, size: 16),
        label: const Text(
          'Leer Ahora',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
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

  Future<void> _solicitarPrestamo(BuildContext context) async {
    final stockDisponible = await StockService.getStockDisponible(book.id);
    final disponibilidadDigital = await EjemplaresDigitalesService.consultarDisponibilidad(book.id);
    
    if (!context.mounted) return;
    
    final todosEnUso = disponibilidadDigital.ejemplaresTotales > 0 && !disponibilidadDigital.disponible;
    
    if (stockDisponible == 0 || todosEnUso) {
      final unirseListaEspera = await showDialog<bool>(
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
                disponibilidadDigital.ejemplaresTotales > 0
                    ? 'El libro "${book.title}" tiene ${disponibilidadDigital.ejemplaresTotales} ejemplar${disponibilidadDigital.ejemplaresTotales == 1 ? '' : 'es'}, pero todos están en uso.'
                    : 'El libro "${book.title}" está siendo leído por otros usuarios.',
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
                        Icon(Icons.hourglass_empty, size: 16, color: Colors.orange),
                        SizedBox(width: 6),
                        Text(
                          '¿Deseas unirte a la lista de espera?',
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
                      'Te notificaremos cuando esté disponible para leer.',
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
              icon: const Icon(Icons.hourglass_empty, size: 18),
              label: const Text('Lista de Espera'),
            ),
          ],
        ),
      );
      
      if (unirseListaEspera == true && context.mounted) {
        await _unirseAListaEspera(context);
      }
      return;
    }
    
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
              child: const Icon(Icons.auto_stories, color: Color(0xFF667EEA), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Leer Libro Digital',
                style: TextStyle(fontSize: 16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF667EEA), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Préstamo Digital',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• Duración: 14 días', style: TextStyle(fontSize: 11)),
                  const Text('• Acceso inmediato', style: TextStyle(fontSize: 11)),
                  const Text('• Renovable: 1 vez', style: TextStyle(fontSize: 11)),
                  const SizedBox(height: 8),
                  Text(
                    stockDisponible == 1
                        ? '⚠️ Última copia disponible'
                        : '✓ $stockDisponible copias disponibles',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: stockDisponible == 1 ? Colors.orange : Colors.green,
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      bool success = false;
      String? errorType;
      
      try {
        success = await PrestamosService.solicitarPrestamo(
          book.id,
          titulo: book.title,
          autor: book.authorsString,
          thumbnail: book.thumbnail,
        );
      } catch (e) {
        final errorMsg = e.toString();
        debugPrint('🚨 ERROR CAPTURADO (Quick Action): $errorMsg');
        
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

      if (context.mounted) {
        Navigator.pop(context);

        String errorMessage;
        Color backgroundColor;
        int duration;
        
        if (errorType == 'LIMITE_PRESTAMOS') {
          errorMessage = '⚠️ Límite Alcanzado\n\nYa tienes 5 préstamos activos (máximo permitido).\n\n💡 Devuelve un libro para solicitar uno nuevo.';
          backgroundColor = Colors.red;
          duration = 5;
        } else if (errorType == 'LIBRO_YA_PRESTADO') {
          errorMessage = '📚 Libro Ya Prestado\n\nYa tienes este libro en tus préstamos activos.';
          backgroundColor = Colors.orange;
          duration = 3;
        } else if (errorType == 'LIBRO_YA_RESERVADO') {
          errorMessage = '🔖 Libro en Lista de Espera\n\nEste libro ya está en tu lista de espera.';
          backgroundColor = Colors.orange;
          duration = 3;
        } else {
          errorMessage = 'No se pudo crear el préstamo.';
          backgroundColor = Colors.orange;
          duration = 3;
        }

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
                        ? '¡Préstamo creado! Tienes 14 días de acceso'
                        : errorMessage,
                  ),
                ),
              ],
            ),
            backgroundColor: success ? Colors.green : backgroundColor,
            duration: Duration(seconds: success ? 3 : duration),
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
                : null,
          ),
        );
      }
    }
  }

  Future<void> _unirseAListaEspera(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final disponibilidad = await EjemplaresDigitalesService.consultarDisponibilidad(book.id);
    final cantidadEnEspera = await EjemplaresDigitalesService.obtenerCantidadEnEspera(book.id);

    if (!context.mounted) return;
    Navigator.pop(context);

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
              child: const Icon(Icons.hourglass_empty, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Lista de Espera', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Todas las copias están en uso',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Te notificaremos cuando el libro esté disponible para leer.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disponibilidad:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow('Copias digitales', '${disponibilidad.ejemplaresTotales}'),
                    _buildInfoRow('En uso ahora', '${disponibilidad.ejemplaresEnUso}'),
                    _buildInfoRow('Usuarios en cola', '$cantidadEnEspera'),
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
            icon: const Icon(Icons.hourglass_empty, size: 18),
            label: const Text('Unirse a Lista de Espera'),
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

      final success = await EjemplaresDigitalesService.unirseAListaEspera(
        book.id,
        titulo: book.title,
        autor: book.authorsString,
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
                        ? '¡Te uniste a la lista de espera! Te notificaremos cuando esté disponible'
                        : 'Ya estás en la lista de espera de este libro',
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