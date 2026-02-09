import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/reserva_service.dart';
import '../../services/auth_service.dart';
import '../../services/export_service.dart';
import '../../utils/responsive.dart';

class AdminExportarScreen extends StatefulWidget {
  const AdminExportarScreen({super.key});

  @override
  State<AdminExportarScreen> createState() => _AdminExportarScreenState();
}

class _AdminExportarScreenState extends State<AdminExportarScreen> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _periodoSeleccionado = 'mes'; // 'mes' o 'semana'
  bool _incluirEstadisticas = true;

  @override
  Widget build(BuildContext context) {
    final reservaService = Provider.of<ReservaService>(context);
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
        title: const Text('Exportar Datos'),
      ),
      body: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de período
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Período de Análisis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Por Mes'),
                            value: 'mes',
                            groupValue: _periodoSeleccionado,
                            onChanged: (value) {
                              setState(() {
                                _periodoSeleccionado = value!;
                                _fechaInicio = null;
                                _fechaFin = null;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Por Semana'),
                            value: 'semana',
                            groupValue: _periodoSeleccionado,
                            onChanged: (value) {
                              setState(() {
                                _periodoSeleccionado = value!;
                                _fechaInicio = null;
                                _fechaFin = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Selector de fechas
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rango de Fechas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: _fechaInicio ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                locale: const Locale('es', 'ES'),
                                helpText: 'Seleccionar fecha de inicio',
                              );
                              if (fecha != null) {
                                setState(() {
                                  _fechaInicio = fecha;
                                  // Si es por semana, calcular fecha fin automáticamente
                                  if (_periodoSeleccionado == 'semana') {
                                    _fechaFin = fecha.add(const Duration(days: 6));
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha Inicio',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fechaInicio != null
                                        ? DateFormat('dd/MM/yyyy').format(_fechaInicio!)
                                        : 'Seleccionar fecha',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: _fechaFin ?? (_fechaInicio ?? DateTime.now()),
                                firstDate: _fechaInicio ?? DateTime(2020),
                                lastDate: DateTime(2030),
                                locale: const Locale('es', 'ES'),
                                helpText: 'Seleccionar fecha de fin',
                              );
                              if (fecha != null) {
                                setState(() {
                                  _fechaFin = fecha;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha Fin',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fechaFin != null
                                        ? DateFormat('dd/MM/yyyy').format(_fechaFin!)
                                        : 'Seleccionar fecha',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_periodoSeleccionado == 'mes' && _fechaInicio != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              final inicio = DateTime(_fechaInicio!.year, _fechaInicio!.month, 1);
                              final fin = DateTime(_fechaInicio!.year, _fechaInicio!.month + 1, 0);
                              _fechaInicio = inicio;
                              _fechaFin = fin;
                            });
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('Usar todo el mes'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Opciones adicionales
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Opciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Incluir estadísticas de docentes'),
                      subtitle: const Text('Docente que más/menos usa recursos'),
                      value: _incluirEstadisticas,
                      onChanged: (value) {
                        setState(() {
                          _incluirEstadisticas = value ?? true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Exportar a:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildExportCard(
              context,
              'PDF',
              'Exportar a formato PDF con opciones de tamaño',
              Icons.picture_as_pdf,
              Colors.red,
              () => _exportToPDF(context, reservaService),
            ),
            const SizedBox(height: 16),
            _buildExportCard(
              context,
              'Excel',
              'Exportar a formato Excel (.xlsx)',
              Icons.table_chart,
              Colors.green,
              () => _exportToExcel(context, reservaService),
            ),
            const SizedBox(height: 16),
            _buildExportCard(
              context,
              'CSV',
              'Exportar a formato CSV',
              Icons.description,
              Colors.blue,
              () => _exportToCSV(context, reservaService),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Información',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los archivos exportados incluirán:\n'
                    '• Todas las reservas del período seleccionado\n'
                    '• Estadísticas de uso por docente (si está habilitado)\n'
                    '• Docente que más y menos utiliza recursos\n'
                    '• Podrás seleccionar dónde guardar el archivo',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportToPDF(BuildContext context, ReservaService service) async {
    try {
      // Validar fechas
      if (_fechaInicio == null || _fechaFin == null) {
        if (!context.mounted) return;
        // Mostrar diálogo centrado
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selecciona las fechas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Por favor selecciona el rango de fechas',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }

      // Mostrar diálogo de formato de página
      final exportService = ExportService();
      final pageFormat = await exportService.showPageFormatDialog(context);
      if (pageFormat == null) {
        return; // Usuario canceló
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generando PDF...')),
        );
      }

      // Generar información del período para el nombre del archivo
      String periodoInfo = '';
      if (_fechaInicio != null && _fechaFin != null) {
        if (_periodoSeleccionado == 'mes') {
          // Formato: "01_2025" (mes numérico para evitar problemas con acentos)
          periodoInfo = '${_fechaInicio!.month.toString().padLeft(2, '0')}_${_fechaInicio!.year}';
        } else {
          // Formato: "05-09_01_2025" (días-mes_año)
          periodoInfo = '${DateFormat('dd').format(_fechaInicio!)}-${DateFormat('dd').format(_fechaFin!)}_${_fechaInicio!.month.toString().padLeft(2, '0')}_${_fechaInicio!.year}';
        }
      }

      await exportService.exportReservasToPDF(
        service,
        pageFormat: pageFormat,
        isAdmin: _incluirEstadisticas,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        periodoInfo: periodoInfo,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generado exitosamente (${_periodoSeleccionado == 'mes' ? 'Por mes' : 'Por semana'})'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToExcel(BuildContext context, ReservaService service) async {
    try {
      // Validar fechas
      if (_fechaInicio == null || _fechaFin == null) {
        if (!context.mounted) return;
        // Mostrar diálogo centrado
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selecciona las fechas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Por favor selecciona el rango de fechas',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generando Excel...')),
        );
      }

      // Generar información del período para el nombre del archivo
      String periodoInfo = '';
      if (_fechaInicio != null && _fechaFin != null) {
        if (_periodoSeleccionado == 'mes') {
          // Formato: "Enero_2025" o "01_2025"
          final mesNombre = DateFormat('MMMM', 'es_ES').format(_fechaInicio!);
          periodoInfo = '${mesNombre}_${_fechaInicio!.year}';
        } else {
          // Formato: "05-09_Enero_2025" o "05-09_01_2025"
          final mesNombre = DateFormat('MMMM', 'es_ES').format(_fechaInicio!);
          periodoInfo = '${DateFormat('dd').format(_fechaInicio!)}-${DateFormat('dd').format(_fechaFin!)}_${mesNombre}_${_fechaInicio!.year}';
        }
      }

      final exportService = ExportService();
      final savedPath = await exportService.exportReservasToExcel(
        service,
        isAdmin: _incluirEstadisticas,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        periodoInfo: periodoInfo,
      );

      if (context.mounted && savedPath != null) {
        // Mostrar diálogo centrado de éxito
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Guardado con éxito',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Excel generado exitosamente\n(${_periodoSeleccionado == 'mes' ? 'Por mes' : 'Por semana'})',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (context.mounted && savedPath == null) {
        // Error al guardar - mostrar diálogo centrado
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al guardar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToCSV(BuildContext context, ReservaService service) async {
    try {
      // Validar fechas
      if (_fechaInicio == null || _fechaFin == null) {
        if (!context.mounted) return;
        // Mostrar diálogo centrado
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selecciona las fechas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Por favor selecciona el rango de fechas',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando CSV...')),
      );

      // Generar información del período para el nombre del archivo
      String periodoInfo = '';
      if (_fechaInicio != null && _fechaFin != null) {
        if (_periodoSeleccionado == 'mes') {
          // Formato: "Enero_2025" o "01_2025"
          final mesNombre = DateFormat('MMMM', 'es_ES').format(_fechaInicio!);
          periodoInfo = '${mesNombre}_${_fechaInicio!.year}';
        } else {
          // Formato: "05-09_Enero_2025" o "05-09_01_2025"
          final mesNombre = DateFormat('MMMM', 'es_ES').format(_fechaInicio!);
          periodoInfo = '${DateFormat('dd').format(_fechaInicio!)}-${DateFormat('dd').format(_fechaFin!)}_${mesNombre}_${_fechaInicio!.year}';
        }
      }

      final exportService = ExportService();
      final savedPath = await exportService.exportReservasToCSV(
        service,
        isAdmin: _incluirEstadisticas,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        periodoInfo: periodoInfo,
      );

      if (context.mounted && savedPath != null) {
        // Mostrar diálogo centrado de éxito
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Guardado con éxito',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CSV generado exitosamente\n(${_periodoSeleccionado == 'mes' ? 'Por mes' : 'Por semana'})',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (context.mounted && savedPath == null) {
        // Error al guardar - mostrar diálogo centrado
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al guardar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Mostrar diálogo centrado de error
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al guardar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error al generar CSV: $e',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }
}
