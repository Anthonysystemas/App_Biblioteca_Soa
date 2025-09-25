import 'package:flutter/material.dart';

class TopSection extends StatelessWidget {
  const TopSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded( // Agregado Expanded para evitar overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¡Hola Usuario!',
                    style: TextStyle(
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
                    maxLines: 2, // Limitar líneas
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12), // Espacio entre texto y avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: const Icon(
                Icons.person,
                color: Colors.blue,
                size: 30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // TARJETA DEL LIBRO DESTACADO - CORRECCIÓN PRINCIPAL
        Container(
          width: double.infinity,
          height: 150,
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
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // SECCIÓN DE TEXTO - CORRECCIÓN AQUÍ
                Expanded(
                  flex: 3, // Proporción para el texto
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Importante: tamaño mínimo
                    children: [
                      // Etiqueta "Libro destacado"
                      const Text(
                        'Libro destacado',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12, // Reducido de 14 a 12
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6), // Reducido de 8 a 6
                      // Título del libro
                      Flexible( // Cambio de Text a Flexible
                        child: Text(
                          'El arte de programar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18, // Reducido de 20 a 18
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2, // Máximo 2 líneas
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 10), // Reducido de 12 a 10
                      // Botón "Leer ahora"
                      SizedBox( // Envolver en SizedBox para controlar tamaño
                        height: 32, // Altura fija para el botón
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF667EEA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16), // Reducido de 20 a 16
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, // Reducido de 20 a 16
                              vertical: 6, // Reducido de 8 a 6
                            ),
                            elevation: 0,
                            minimumSize: Size.zero, // Remover tamaño mínimo
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Leer ahora',
                            style: TextStyle(
                              fontSize: 11, // Reducido de 12 a 11
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // ICONO DEL LIBRO
                Flexible( // Cambio de Container fijo a Flexible
                  flex: 1, // Proporción para el icono
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 80,
                      maxHeight: 100,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center( // Centrar el icono
                      child: Icon(
                        Icons.book,
                        color: Colors.white,
                        size: 36, // Reducido de 40 a 36
                      ),
                    ),
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