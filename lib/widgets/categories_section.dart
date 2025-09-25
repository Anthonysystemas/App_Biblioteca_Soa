import 'package:flutter/material.dart';
import 'circle_item.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Categorías',
            style: TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // CORRECCIÓN: Contenedor con altura fija
        SizedBox(
          height: 120, // Altura suficiente para círculo + texto en 2 líneas
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleItem(
                  icon: Icons.code,
                  label: 'Programación',
                  color: Colors.blue,
                  onTap: () {
                    print('Programación seleccionada');
                  },
                ),
                CircleItem(
                  icon: Icons.science,
                  label: 'Ciencias',
                  color: Colors.green,
                  onTap: () {
                    print('Ciencias seleccionada');
                  },
                ),
                CircleItem(
                  icon: Icons.history_edu,
                  label: 'Historia',
                  color: Colors.orange,
                  onTap: () {
                    print('Historia seleccionada');
                  },
                ),
                CircleItem(
                  icon: Icons.psychology,
                  label: 'Filosofía',
                  color: Colors.purple,
                  onTap: () {
                    print('Filosofía seleccionada');
                  },
                ),
                CircleItem(
                  icon: Icons.theater_comedy,
                  label: 'Literatura',
                  color: Colors.red,
                  onTap: () {
                    print('Literatura seleccionada');
                  },
                ),
                CircleItem(
                  icon: Icons.calculate,
                  label: 'Matemáticas',
                  color: Colors.teal,
                  onTap: () {
                    print('Matemáticas seleccionada');
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

