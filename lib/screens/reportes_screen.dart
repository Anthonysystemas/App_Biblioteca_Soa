import 'package:flutter/material.dart';
import '../services/reportes_service.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  Map<String, dynamic>? _resumen;
  List<Map<String, dynamic>>? _estadisticasCategorias;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportes();
  }

  Future<void> _loadReportes() async {
    setState(() => _isLoading = true);
    
    final resumen = await ReportesService.getResumenUsuario();
    final categorias = await ReportesService.getEstadisticasPorCategoria();
    
    if (mounted) {
      setState(() {
        _resumen = resumen;
        _estadisticasCategorias = categorias;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          'Mis Estadísticas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportes,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildResumenCard(),
                    const SizedBox(height: 20),
                    
                    _buildEstadisticasGrid(),
                    const SizedBox(height: 20),
                    
                    if (_estadisticasCategorias != null && _estadisticasCategorias!.isNotEmpty) ...[
                      const Text(
                        'Lectura por Categoría',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCategoriasChart(),
                      const SizedBox(height: 20),
                    ],
                    
                    _buildAccionesButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildResumenCard() {
    if (_resumen == null) return const SizedBox();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Resumen de Actividad',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildResumenRow(
            Icons.menu_book,
            'Libros Leídos',
            '${_resumen!['libros_leidos']}',
          ),
        ],
      ),
    );
  }

  Widget _buildResumenRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasGrid() {
    if (_resumen == null) return const SizedBox();
    
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          icon: Icons.book_outlined,
          label: 'Activos',
          value: '${_resumen!['libros_activos']}',
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.bookmark,
          label: 'Lista de Espera',
          value: '${_resumen!['reservas_activas']}',
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.history,
          label: 'Historial',
          value: '${_resumen!['historial']}',
          color: Colors.purple,
        ),
        _buildStatCard(
          icon: Icons.auto_stories,
          label: 'Leídos',
          value: '${_resumen!['libros_leidos']}',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriasChart() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: _estadisticasCategorias!.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCategoriaBar(
              categoria: cat['categoria'],
              cantidad: cat['cantidad'],
              porcentaje: cat['porcentaje'],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoriaBar({
    required String categoria,
    required int cantidad,
    required int porcentaje,
  }) {
    final colors = [
      const Color(0xFF667EEA),
      const Color(0xFF764BA2),
      Colors.orange,
      Colors.green,
    ];
    final color = colors[_estadisticasCategorias!.indexOf(
      _estadisticasCategorias!.firstWhere((c) => c['categoria'] == categoria)
    ) % colors.length];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              categoria,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A202C),
              ),
            ),
            Text(
              '$cantidad libros',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: porcentaje / 100,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccionesButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exportar PDF - Próximamente con backend'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar como PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF667EEA),
              side: const BorderSide(color: Color(0xFF667EEA)),
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exportar CSV - Próximamente con backend'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('Exportar como CSV'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF667EEA),
              side: const BorderSide(color: Color(0xFF667EEA)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}