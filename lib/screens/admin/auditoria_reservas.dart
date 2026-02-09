import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../../services/reserva_service.dart';
import '../../services/auth_service.dart';
import '../../services/export_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/zoomable_widget.dart';

class AuditoriaReservasScreen extends StatefulWidget {
  const AuditoriaReservasScreen({super.key});

  @override
  State<AuditoriaReservasScreen> createState() => _AuditoriaReservasScreenState();
}

class _AuditoriaReservasScreenState extends State<AuditoriaReservasScreen> {
  // ScrollControllers para sincronizar el scroll horizontal del encabezado y cuerpo
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();
  bool _isSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    // Sincronizar scrolls
    _headerScrollController.addListener(_syncHeaderScroll);
    _bodyScrollController.addListener(_syncBodyScroll);
  }

  // Exportar las reservas de auditoría (incluye activas y eliminadas)
  Future<void> _exportarAuditoria(
    BuildContext context,
    List<QueryDocumentSnapshot> reservas,
    String formato,
  ) async {
    if (reservas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos para exportar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final exportService = ExportService();
      PdfPageFormat? pageFormat;

      if (formato == 'PDF') {
        pageFormat = await exportService.showPageFormatDialog(context);
        if (pageFormat == null) return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generando auditoría en formato $formato...')),
        );
      }

      switch (formato) {
        case 'PDF':
          await exportService.exportReservasToPDFFromList(
            reservas,
            'auditoria',
            isAdmin: true,
            pageFormat: pageFormat,
          );
          break;
        case 'Excel':
          await exportService.exportReservasToExcelFromList(
            reservas,
            'auditoria',
            isAdmin: true,
          );
          break;
        case 'CSV':
          await exportService.exportReservasToCSVFromList(
            reservas,
            'auditoria',
            isAdmin: true,
          );
          break;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auditoría exportada a $formato exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar auditoría: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _syncHeaderScroll() {
    if (!_isSyncingScroll && _bodyScrollController.hasClients) {
      _isSyncingScroll = true;
      final offset = _headerScrollController.offset;
      if ((_bodyScrollController.offset - offset).abs() > 1.0) {
        _bodyScrollController.jumpTo(offset);
      }
      _isSyncingScroll = false;
    }
  }

  void _syncBodyScroll() {
    if (!_isSyncingScroll && _headerScrollController.hasClients) {
      _isSyncingScroll = true;
      final offset = _bodyScrollController.offset;
      if ((_headerScrollController.offset - offset).abs() > 1.0) {
        _headerScrollController.jumpTo(offset);
      }
      _isSyncingScroll = false;
    }
  }

  @override
  void dispose() {
    _headerScrollController.removeListener(_syncHeaderScroll);
    _bodyScrollController.removeListener(_syncBodyScroll);
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  // Obtener anchos de columnas responsive
  Map<int, TableColumnWidth> _getColumnWidths(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (isMobile) {
      // Móvil - anchos mínimos para 7 columnas
      return {
        0: FixedColumnWidth((screenWidth * 0.20).clamp(90.0, double.infinity)), // Maestro Solicitante
        1: FixedColumnWidth((screenWidth * 0.18).clamp(80.0, double.infinity)), // Recurso
        2: FixedColumnWidth((screenWidth * 0.22).clamp(120.0, double.infinity)), // Fecha Solicitud
        3: FixedColumnWidth((screenWidth * 0.22).clamp(120.0, double.infinity)), // Fecha de Uso
        4: FixedColumnWidth((screenWidth * 0.22).clamp(120.0, double.infinity)), // Fecha Eliminación
        5: FixedColumnWidth((screenWidth * 0.18).clamp(90.0, double.infinity)),  // Horario
        6: FixedColumnWidth((screenWidth * 0.18).clamp(80.0, double.infinity)),  // Estado
      };
    } else if (isTablet) {
      return {
        0: FixedColumnWidth(170), // Maestro Solicitante
        1: FixedColumnWidth(140), // Recurso
        2: FixedColumnWidth(150), // Fecha Solicitud
        3: FixedColumnWidth(150), // Fecha de Uso
        4: FixedColumnWidth(150), // Fecha Eliminación
        5: FixedColumnWidth(130), // Horario
        6: FixedColumnWidth(110), // Estado
      };
    } else {
      // Desktop/Web - ocupar todo el ancho disponible (7 columnas)
      final padding = Responsive.isMobile(context) || Responsive.isTablet(context)
          ? Responsive.padding(context)
          : const EdgeInsets.symmetric(horizontal: 4, vertical: 8);
      final availableWidth = screenWidth - (padding.horizontal * 2) - 20; // 20px para bordes y scrollbar
      // Distribuir proporcionalmente el ancho entre las 7 columnas con anchos mínimos adecuados
      return {
        0: FixedColumnWidth((availableWidth * 0.16).clamp(160.0, double.infinity)), // Maestro Solicitante
        1: FixedColumnWidth((availableWidth * 0.16).clamp(150.0, double.infinity)), // Recurso
        2: FixedColumnWidth((availableWidth * 0.16).clamp(170.0, double.infinity)), // Fecha Solicitud
        3: FixedColumnWidth((availableWidth * 0.16).clamp(170.0, double.infinity)), // Fecha de Uso
        4: FixedColumnWidth((availableWidth * 0.16).clamp(150.0, double.infinity)), // Fecha Eliminación
        5: FixedColumnWidth((availableWidth * 0.14).clamp(130.0, double.infinity)), // Horario
        6: FixedColumnWidth((availableWidth * 0.08).clamp(100.0, double.infinity)), // Estado
      };
    }
  }

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
        title: const Text('Auditoría de Reservas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Vista de auditoría - Incluye reservas eliminadas',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Auditoría de Reservas'),
                  content: const Text(
                    'Esta vista muestra TODAS las reservas, incluyendo las eliminadas.\n\n'
                    'Las reservas eliminadas se marcan en rojo y muestran:\n'
                    '• Quién eliminó la reserva (Admin o Docente)\n'
                    '• Nombre del usuario que eliminó\n'
                    '• Fecha de eliminación\n\n'
                    'Las reservas eliminadas no son visibles para los usuarios normales.\n\n'
                    'Esto permite mantener un registro completo para auditoría.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: reservaService.getReservasAuditoria(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No hay reservas registradas',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final reservas = snapshot.data!.docs;
          final reservasActivas = reservas.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['eliminada'] != true;
          }).toList();
          final reservasEliminadas = reservas.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['eliminada'] == true;
          }).toList();

          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Estadísticas
              Padding(
                padding: isLandscape
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                    : Responsive.padding(context),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 2,
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: EdgeInsets.all(isLandscape ? 12.0 : 16.0),
                          child: Column(
                            children: [
                              Text(
                                '${reservasActivas.length}',
                                style: TextStyle(
                                  fontSize: isLandscape ? 24 : 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reservas Activas',
                                style: TextStyle(
                                  fontSize: isLandscape ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isLandscape ? 8 : 16),
                    Expanded(
                      child: Card(
                        elevation: 2,
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: EdgeInsets.all(isLandscape ? 12.0 : 16.0),
                          child: Column(
                            children: [
                              Text(
                                '${reservasEliminadas.length}',
                                style: TextStyle(
                                  fontSize: isLandscape ? 24 : 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reservas Eliminadas',
                                style: TextStyle(
                                  fontSize: isLandscape ? 11 : 12,
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
              ),
              // Botones de exportación (usa los mismos datos que la tabla)
              Padding(
                padding: isLandscape
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                    : Responsive.padding(context),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _exportarAuditoria(context, reservas, 'PDF'),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Exportar PDF'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _exportarAuditoria(context, reservas, 'Excel'),
                      icon: const Icon(Icons.table_chart, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Exportar Excel'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _exportarAuditoria(context, reservas, 'CSV'),
                      icon: const Icon(Icons.description, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Exportar CSV'),
                    ),
                  ],
                ),
              ),
              // Tabla de reservas
              Expanded(
                child: Container(
                  margin: isLandscape
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                      : Responsive.padding(context),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Builder(
                      builder: (context) {
                        final columnWidths = _getColumnWidths(context);
                        double totalWidth = 0;
                        columnWidths.forEach((index, width) {
                          if (width is FixedColumnWidth) {
                            totalWidth += width.value;
                          }
                        });
                        
                        return ZoomableWidget(
                          minScale: 0.5,
                          maxScale: 3.0,
                          initialScale: 1.0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Encabezado
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: SizedBox(
                                  width: totalWidth,
                                  child: Table(
                                    border: TableBorder.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    columnWidths: columnWidths,
                                    children: [
                                      TableRow(
                                        children: [
                                          _buildHeaderCell('MAESTRO SOLICITANTE'),
                                          _buildHeaderCell('RECURSO'),
                                          _buildHeaderCell('FECHA SOLICITUD'),
                                          _buildHeaderCell('FECHA DE USO'),
                                          _buildHeaderCell('FECHA ELIMINACIÓN'),
                                          _buildHeaderCell('HORARIO'),
                                          _buildHeaderCell('ESTADO'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Cuerpo de la tabla
                              SizedBox(
                                width: totalWidth,
                                child: Table(
                                  border: TableBorder.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  columnWidths: columnWidths,
                                  children: [
                                    // Filas de datos
                                    ...reservas.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      final creado = (data['creado'] as Timestamp?)?.toDate();
                                      final eliminada = data['eliminada'] == true;
                                      final fechaEliminacion = (data['fechaEliminacion'] as Timestamp?)?.toDate();
                                      final docente = data['docente'] ?? data['usuarioNombre'] ?? 'N/A';
                                      final recurso = data['recursoNombre'] ?? 'N/A';
                                      final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
                                      final dia = fechaUso != null 
                                          ? DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(fechaUso)
                                          : (data['dia'] ?? 'N/A');
                                      final hora = data['hora'] ?? 'N/A';
                                      
                                      // Información sobre quién eliminó la reserva
                                      String infoEliminacion = '';
                                      if (eliminada) {
                                        final eliminadoPorAdmin = data['eliminadoPorAdmin'] == true;
                                        final usuarioEliminacionNombre = data['usuarioEliminacionNombre'] as String?;
                                        final fechaEliminacionStr = fechaEliminacion != null 
                                            ? DateFormat('dd/MM/yy').format(fechaEliminacion)
                                            : '';
                                        
                                        if (usuarioEliminacionNombre != null) {
                                          infoEliminacion = eliminadoPorAdmin 
                                              ? 'Eliminada por Admin\n$usuarioEliminacionNombre\n$fechaEliminacionStr'
                                              : 'Eliminada por Docente\n$usuarioEliminacionNombre\n$fechaEliminacionStr';
                                        } else {
                                          infoEliminacion = 'Eliminada\n$fechaEliminacionStr';
                                        }
                                      }

                                      return TableRow(
                                        decoration: BoxDecoration(
                                          color: eliminada
                                              ? Colors.red.shade50
                                              : (reservas.indexOf(doc) % 2 == 0
                                                  ? Colors.white
                                                  : Colors.grey.shade50),
                                        ),
                                        children: [
                                          _buildDataCell(docente, eliminada),
                                          _buildDataCell(recurso, eliminada),
                                          _buildDataCell(
                                            creado != null
                                                ? DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(creado)
                                                : 'N/A',
                                            eliminada,
                                            esFecha: true,
                                          ),
                                          _buildDataCell(dia, eliminada, esFecha: true),
                                          _buildDataCell(
                                            fechaEliminacion != null
                                                ? DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES')
                                                    .format(fechaEliminacion)
                                                : '-',
                                            eliminada,
                                            esFecha: true,
                                          ),
                                          _buildDataCell(hora, eliminada),
                                          _buildDataCell(
                                            eliminada
                                                ? (infoEliminacion.isNotEmpty ? infoEliminacion : 'Eliminada')
                                                : 'Activa',
                                            eliminada,
                                            isEstado: true,
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Pie de página
              Padding(
                padding: isLandscape
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                    : Responsive.padding(context),
                child: Text(
                  'Total: ${reservas.length} reservas (${reservasActivas.length} activas, ${reservasEliminadas.length} eliminadas)',
                  style: TextStyle(
                    fontSize: isLandscape ? 11 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    final isMobile = Responsive.isMobile(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDesktop = !isMobile && !Responsive.isTablet(context);
    
    return TableCell(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 6.0 : (isMobile ? 8.0 : (isDesktop ? 12.0 : 12.0)),
          vertical: isLandscape ? 8.0 : (isMobile ? 10.0 : (isDesktop ? 24.0 : 12.0)),
        ),
        decoration: BoxDecoration(
          color: Colors.blue.shade900,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isLandscape ? 8.0 : (isMobile ? 9.0 : (isDesktop ? 18.0 : 13.0)),
            height: isLandscape ? 1.1 : (isDesktop ? 1.3 : 1.2),
          ),
          textAlign: TextAlign.center,
          maxLines: isLandscape ? 1 : (isDesktop ? null : 2),
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, bool eliminada, {bool isEstado = false, bool esFecha = false}) {
    final isMobile = Responsive.isMobile(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDesktop = !isMobile && !Responsive.isTablet(context);
    final baseFontSize = isLandscape 
        ? (esFecha ? 7.0 : 8.0) 
        : (isMobile 
            ? (esFecha ? 8.0 : 9.0) 
            : (isDesktop 
                ? (esFecha ? 18.0 : 18.0) 
                : (esFecha ? 11.0 : 12.0)));
    final padding = isLandscape ? 4.0 : (isMobile ? 6.0 : (isDesktop ? 12.0 : 10.0));
    
    return TableCell(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: isLandscape ? 6.0 : (isDesktop ? 20.0 : 10.0),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: baseFontSize,
            color: eliminada ? Colors.red.shade700 : Colors.black87,
            decoration: eliminada ? TextDecoration.lineThrough : null,
            fontStyle: eliminada ? FontStyle.italic : null,
            fontWeight: isEstado && eliminada ? FontWeight.bold : FontWeight.normal,
            height: isLandscape ? 1.1 : (isDesktop ? 1.4 : 1.2),
          ),
          textAlign: TextAlign.center,
          maxLines: esFecha ? (isLandscape ? 2 : (isDesktop ? null : 3)) : (isLandscape ? 1 : (isDesktop ? null : 2)),
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      ),
    );
  }
}
