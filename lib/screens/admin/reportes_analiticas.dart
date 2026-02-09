import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/reserva_service.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../services/export_service.dart';
import '../../utils/responsive.dart';

class ReportesAnaliticasScreen extends StatefulWidget {
  const ReportesAnaliticasScreen({super.key});

  @override
  State<ReportesAnaliticasScreen> createState() => _ReportesAnaliticasScreenState();
}

class _ReportesAnaliticasScreenState extends State<ReportesAnaliticasScreen> {
  final AnalyticsService _analyticsService = AnalyticsService(ReservaService());
  bool _cargando = false;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: const Center(
          child: Text('No tienes permisos de administrador'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Analíticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Filtrar por fecha',
            onPressed: _mostrarFiltroFecha,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: Responsive.padding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Estadísticas Generales
                  _buildEstadisticasGenerales(),
                  const SizedBox(height: 24),
                  
                  // Recursos Más Utilizados
                  _buildRecursosMasUtilizados(),
                  const SizedBox(height: 24),
                  
                  // Docentes Que Más Reservan
                  _buildDocentesQueMasReservan(),
                  const SizedBox(height: 24),
                  
                  // Horarios de Mayor Demanda
                  _buildHorariosMayorDemanda(),
                  const SizedBox(height: 24),
                  
                  // Historial por Mes
                  _buildHistorialPorMes(),
                  const SizedBox(height: 24),
                  
                  // Botones de Exportación
                  _buildBotonesExportacion(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Future<void> _mostrarFiltroFecha() async {
    final resultado = await showDialog<Map<String, DateTime?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por Fecha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Fecha Inicio'),
              subtitle: Text(_fechaInicio != null 
                  ? DateFormat('dd/MM/yyyy').format(_fechaInicio!)
                  : 'No seleccionada'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _fechaInicio ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (fecha != null && context.mounted) {
                  Navigator.pop(context);
                  _fechaInicio = fecha;
                  _mostrarFiltroFecha();
                }
              },
            ),
            ListTile(
              title: const Text('Fecha Fin'),
              subtitle: Text(_fechaFin != null 
                  ? DateFormat('dd/MM/yyyy').format(_fechaFin!)
                  : 'No seleccionada'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _fechaFin ?? DateTime.now(),
                  firstDate: _fechaInicio ?? DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (fecha != null && context.mounted) {
                  Navigator.pop(context);
                  _fechaFin = fecha;
                  _mostrarFiltroFecha();
                }
              },
            ),
            if (_fechaInicio != null || _fechaFin != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _fechaInicio = null;
                    _fechaFin = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Limpiar Filtros'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasGenerales() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _analyticsService.getEstadisticasGenerales(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ));
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final stats = snapshot.data ?? {};

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Estadísticas Generales',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total Reservas',
                        '${stats['totalReservas'] ?? 0}',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        'Esta Semana',
                        '${stats['reservasEstaSemana'] ?? 0}',
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        'Este Mes',
                        '${stats['reservasEsteMes'] ?? 0}',
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecursosMasUtilizados() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Recursos Más Utilizados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _analyticsService.getRecursosMasUtilizados(
                fechaInicio: _fechaInicio,
                fechaFin: _fechaFin,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final recursos = snapshot.data ?? [];

                if (recursos.isEmpty) {
                  return const Text('No hay datos disponibles');
                }

                return Column(
                  children: recursos.take(10).map((item) {
                    return _buildListItem(
                      item['recursoNombre'] ?? 'N/A',
                      '${item['cantidad']} reservas',
                      Colors.purple,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocentesQueMasReservan() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Docentes Que Más Reservan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _analyticsService.getDocentesQueMasReservan(
                fechaInicio: _fechaInicio,
                fechaFin: _fechaFin,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final docentes = snapshot.data ?? [];

                if (docentes.isEmpty) {
                  return const Text('No hay datos disponibles');
                }

                return Column(
                  children: docentes.take(10).map((item) {
                    return _buildListItem(
                      item['docenteNombre'] ?? 'N/A',
                      '${item['cantidad']} reservas',
                      Colors.teal,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorariosMayorDemanda() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Horarios de Mayor Demanda',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _analyticsService.getHorariosMayorDemanda(
                fechaInicio: _fechaInicio,
                fechaFin: _fechaFin,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final horarios = snapshot.data ?? [];

                if (horarios.isEmpty) {
                  return const Text('No hay datos disponibles');
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: horarios.map((item) {
                    return Chip(
                      label: Text('${item['hora']}: ${item['cantidad']}'),
                      backgroundColor: Colors.orange.shade100,
                      labelStyle: TextStyle(color: Colors.orange.shade900),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialPorMes() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.indigo.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Historial de Uso por Mes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _analyticsService.getHistorialPorMes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final meses = snapshot.data ?? [];

                if (meses.isEmpty) {
                  return const Text('No hay datos disponibles');
                }

                return Column(
                  children: meses.map((item) {
                    return _buildListItem(
                      item['mes'] ?? 'N/A',
                      '${item['cantidad']} reservas',
                      Colors.indigo,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesExportacion() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.file_download, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Exportar Reportes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Exportar Reporte Analítico:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildExportButton(
                    'PDF',
                    Icons.picture_as_pdf,
                    Colors.red,
                    () => _exportarReporteAnalitico('PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportButton(
                    'Excel',
                    Icons.table_chart,
                    Colors.green,
                    () => _exportarReporteAnalitico('Excel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportButton(
                    'CSV',
                    Icons.description,
                    Colors.blue,
                    () => _exportarReporteAnalitico('CSV'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Future<void> _exportarReporteAnalitico(String formato) async {
    setState(() => _cargando = true);

    try {
      final exportService = ExportService();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generando reporte en formato $formato...')),
      );

      switch (formato) {
        case 'PDF':
          await exportService.exportReporteAnaliticoToPDF(_analyticsService);
          break;
        case 'Excel':
          await exportService.exportReporteAnaliticoToExcel(_analyticsService);
          break;
        case 'CSV':
          await exportService.exportReporteAnaliticoToCSV(_analyticsService);
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte $formato generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }
}



