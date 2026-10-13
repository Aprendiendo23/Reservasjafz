import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import '../services/reserva_service.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import '../utils/responsive.dart';
import 'zoomable_widget.dart';
import 'tabla_disponibilidad.dart'; // Para usar NombreUsuarioActualizado

class TablaReservas extends StatefulWidget {
  final String? recursoID;
  final String? recursoNombre;
  final bool mostrarExportar;

  const TablaReservas({
    super.key,
    this.recursoID,
    this.recursoNombre,
    this.mostrarExportar = false,
  });

  @override
  State<TablaReservas> createState() => _TablaReservasState();
}

class _TablaReservasState extends State<TablaReservas> {
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();
  bool _isSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    // Sincronizar scrolls horizontal
    _headerScrollController.addListener(_syncHeaderScroll);
    _bodyScrollController.addListener(_syncBodyScroll);
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

  Map<int, TableColumnWidth> _getColumnWidths(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (isMobile) {
      // Móvil - anchos mínimos más generosos para evitar cortes
      return {
        0: FixedColumnWidth((screenWidth * 0.20).clamp(90.0, double.infinity)),   // Maestro Solicitante
        1: FixedColumnWidth((screenWidth * 0.18).clamp(80.0, double.infinity)),   // Recurso
        2: FixedColumnWidth((screenWidth * 0.22).clamp(120.0, double.infinity)),   // Fecha Solicitud
        3: FixedColumnWidth((screenWidth * 0.22).clamp(120.0, double.infinity)),    // Fecha de Uso
        4: FixedColumnWidth((screenWidth * 0.25).clamp(140.0, double.infinity)),    // Horario
        5: FixedColumnWidth((screenWidth * 0.11).clamp(55.0, double.infinity)),     // Grado
        6: FixedColumnWidth((screenWidth * 0.20).clamp(90.0, double.infinity)),     // Asignatura
        7: FixedColumnWidth((screenWidth * 0.25).clamp(140.0, double.infinity)),     // Observación
      };
    } else if (isTablet) {
      return {
        0: FixedColumnWidth(160),
        1: FixedColumnWidth(130),
        2: FixedColumnWidth(150),
        3: FixedColumnWidth(150),
        4: FixedColumnWidth(180),
        5: FixedColumnWidth(90),
        6: FixedColumnWidth(160),
        7: FixedColumnWidth(200),
      };
    } else {
      // Desktop/Web - ocupar todo el ancho disponible
      final padding = Responsive.isMobile(context) || Responsive.isTablet(context)
          ? Responsive.padding(context)
          : const EdgeInsets.symmetric(horizontal: 4, vertical: 8);
      final availableWidth = screenWidth - (padding.horizontal * 2) - 20; // 20px para bordes y scrollbar

      // Distribuir proporcionalmente el ancho entre las 8 columnas con anchos mínimos adecuados
      return {
        0: FixedColumnWidth((availableWidth * 0.13).clamp(130.0, double.infinity)),  // Maestro Solicitante
        1: FixedColumnWidth((availableWidth * 0.16).clamp(160.0, double.infinity)),   // Recurso
        2: FixedColumnWidth((availableWidth * 0.16).clamp(180.0, double.infinity)),   // Fecha Solicitud
        3: FixedColumnWidth((availableWidth * 0.16).clamp(180.0, double.infinity)),    // Fecha de Uso
        4: FixedColumnWidth((availableWidth * 0.18).clamp(200.0, double.infinity)),    // Horario
        5: FixedColumnWidth((availableWidth * 0.05).clamp(60.0, double.infinity)),     // Grado
        6: FixedColumnWidth((availableWidth * 0.13).clamp(130.0, double.infinity)),     // Asignatura
        7: FixedColumnWidth((availableWidth * 0.17).clamp(180.0, double.infinity)),     // Observación
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservaService = Provider.of<ReservaService>(context);
    final authService = Provider.of<AuthService>(context);
    final esAdmin = authService.isAdmin;

    // Crear el stream directamente en el build para asegurar que siempre esté actualizado
    // IMPORTANTE: No cachear el stream, siempre crear uno nuevo para forzar actualización
    final stream = widget.recursoID != null
        ? reservaService.getReservasPorRecurso(widget.recursoID!, incluirEliminadas: false)
        : reservaService.getReservas(incluirEliminadas: false);
    
    // Crear una key única que incluya el recursoID y recursoNombre para forzar reconstrucción completa
    final streamKey = 'tabla_reservas_stream_${widget.recursoID ?? 'todos'}_${widget.recursoNombre ?? ''}';
    
    print('🔄 TablaReservas.build: recursoID=${widget.recursoID}, recursoNombre=${widget.recursoNombre}, key=$streamKey');
    
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey(streamKey), // Key único para forzar reconstrucción completa cuando cambian los parámetros
      stream: stream,
      builder: (context, snapshot) {
        print('📊 TablaReservas.StreamBuilder: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, docs=${snapshot.hasData ? snapshot.data!.docs.length : 0}');
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_chart, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No hay reservas registradas',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.recursoNombre != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'para ${widget.recursoNombre}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        var reservas = snapshot.data!.docs;

        // Filtrar reservas eliminadas para todos (admin y no admin)
        reservas = reservas.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['eliminada'] == true) return false;
          
          // Si hay un recursoID específico, verificar que la reserva corresponda
          // Esto es importante para recursos por defecto que usan el nombre como ID
          if (widget.recursoID != null) {
            final reservaRecursoID = data['recursoID'] as String? ?? '';
            final reservaRecursoNombre = data['recursoNombre'] as String? ?? '';
            // Verificar si coincide por ID o por nombre (para recursos por defecto)
            if (reservaRecursoID != widget.recursoID && reservaRecursoNombre != widget.recursoID) {
              return false;
            }
          }
          
          return true;
        }).toList();

        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            if (widget.recursoNombre != null)
              Padding(
                padding: isLandscape
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
                    : const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isLandscape 
                            ? 'Reservas: ${widget.recursoNombre}'
                            : 'Reservas del Recurso: ${widget.recursoNombre}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (widget.mostrarExportar && esAdmin)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.file_download, size: isLandscape ? 20 : 24),
                        tooltip: 'Exportar tabla',
                        onSelected: (value) => _exportarTabla(context, value, reservas, widget.recursoNombre),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'PDF',
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Exportar a PDF'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'Excel',
                            child: Row(
                              children: [
                                Icon(Icons.table_chart, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Exportar a Excel'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'CSV',
                            child: Row(
                              children: [
                                Icon(Icons.description, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Exportar a CSV'),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              )
            else if (widget.recursoID == null)
              Padding(
                padding: isLandscape
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
                    : const EdgeInsets.all(16),
                child: Text(
                  'Todas las Reservas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: Container(
                margin: isLandscape
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                    : (Responsive.isMobile(context) || Responsive.isTablet(context)
                        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                        : const EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildTabla(reservas),
                ),
              ),
            ),
            Padding(
              padding: isLandscape
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
                  : const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${reservas.length}',
                    style: TextStyle(
                      fontSize: isLandscape ? 11 : 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (reservas.isNotEmpty && !isLandscape)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'Todas las reservas visibles',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabla(List<QueryDocumentSnapshot> reservas) {
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      return _buildTablaMobile(reservas);
    } else {
      return _buildTablaDesktop(reservas);
    }
  }

  Widget _buildTablaDesktop(List<QueryDocumentSnapshot> reservas) {
    // Calcular el ancho total de la tabla
    final columnWidths = _getColumnWidths(context);
    double totalWidth = 0;
    columnWidths.forEach((index, width) {
      if (width is FixedColumnWidth) {
        totalWidth += width.value;
      }
    });

    // Para desktop/tablet, usar el mismo zoom con gestos que en móvil
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
                border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
                columnWidths: columnWidths,
                children: [
                  TableRow(
                    children: [
                      _buildHeaderCell('MAESTRO SOLICITANTE'),
                      _buildHeaderCell('RECURSO'),
                      _buildHeaderCell('FECHA SOLICITUD'),
                      _buildHeaderCell('FECHA DE USO'),
                      _buildHeaderCell('HORARIO QUE SE UTILIZARA'),
                      _buildHeaderCell('GRADO'),
                      _buildHeaderCell('ASIGNATURA'),
                      _buildHeaderCell('OBSERVACIÓN'),
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
              border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
              columnWidths: columnWidths,
              children: _buildTableRows(reservas),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaMobile(List<QueryDocumentSnapshot> reservas) {
    // Calcular el ancho total de la tabla
    final columnWidths = _getColumnWidths(context);
    double totalWidth = 0;
    columnWidths.forEach((index, width) {
      if (width is FixedColumnWidth) {
        totalWidth += width.value;
      }
    });
    
    // Para móvil, usar zoom y desplazamiento mejorado
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
                border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
                columnWidths: columnWidths,
                children: [
                  TableRow(
                    children: [
                      _buildHeaderCell('MAESTRO SOLICITANTE'),
                      _buildHeaderCell('RECURSO'),
                      _buildHeaderCell('FECHA SOLICITUD'),
                      _buildHeaderCell('FECHA DE USO'),
                      _buildHeaderCell('HORARIO QUE SE UTILIZARA'),
                      _buildHeaderCell('GRADO'),
                      _buildHeaderCell('ASIGNATURA'),
                      _buildHeaderCell('OBSERVACIÓN'),
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
              border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
              columnWidths: columnWidths,
              children: _buildTableRows(reservas),
            ),
          ),
        ],
      ),
    );
  }

  List<TableRow> _buildTableRows(List<QueryDocumentSnapshot> reservas) {
    return reservas.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final creado = (data['creado'] as Timestamp?)?.toDate();
      final docenteNombreReserva = data['docente'] ?? data['usuarioNombre'] ?? 'N/A';
      final usuarioID = data['usuarioID'] as String?;
      final recurso = data['recursoNombre'] ?? 'N/A';
      final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
      final dia = fechaUso != null 
          ? DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(fechaUso)
          : (data['dia'] ?? 'N/A');
      final hora = data['hora'] ?? 'N/A';
      final asignatura = data['asignatura'] ?? 'N/A';
      final grado = data['grado'] ?? 'N/A';
      final observacion = data['observacion'] ?? '';
      final eliminada = data['eliminada'] == true;

      return TableRow(
        decoration: BoxDecoration(
          color: eliminada
              ? Colors.red.shade50
              : (reservas.indexOf(doc) % 2 == 0
                  ? Colors.white
                  : Colors.grey.shade100),
        ),
        children: [
          _buildDataCellWithWidget(
            child: eliminada 
                ? Text('${docenteNombreReserva} (ELIMINADA)')
                : NombreUsuarioActualizado(
                    usuarioID: usuarioID,
                    nombreReserva: docenteNombreReserva,
                  ),
            eliminada: eliminada,
          ),
          _buildDataCell(recurso, eliminada: eliminada),
          _buildDataCell(
            creado != null
                ? DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(creado)
                : 'N/A',
            eliminada: eliminada,
            esFecha: true,
          ),
          _buildDataCell(dia, eliminada: eliminada, esFecha: true),
          _buildDataCell(hora, eliminada: eliminada),
          _buildDataCell(grado, eliminada: eliminada, isCentered: true),
          _buildDataCell(asignatura, eliminada: eliminada),
          _buildDataCell(observacion, eliminada: eliminada),
        ],
      );
    }).toList();
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
          maxLines: isLandscape ? 1 : (isDesktop ? null : 3),
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool eliminada = false, bool esFecha = false, bool isCentered = false}) {
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
            fontWeight: eliminada ? FontWeight.normal : FontWeight.w400,
            height: isLandscape ? 1.1 : (isDesktop ? 1.4 : 1.2),
          ),
          textAlign: isCentered ? TextAlign.center : TextAlign.left,
          maxLines: esFecha ? (isLandscape ? 2 : (isDesktop ? null : 3)) : (isLandscape ? 1 : (isDesktop ? null : 2)),
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      ),
    );
  }

  Widget _buildDataCellWithWidget({required Widget child, bool eliminada = false}) {
    final isMobile = Responsive.isMobile(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDesktop = !isMobile && !Responsive.isTablet(context);
    final padding = isLandscape ? 4.0 : (isMobile ? 6.0 : (isDesktop ? 12.0 : 10.0));
    
    return TableCell(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: isLandscape ? 6.0 : (isDesktop ? 20.0 : 10.0),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: isLandscape ? 8.0 : (isMobile ? 9.0 : (isDesktop ? 18.0 : 12.0)),
            color: eliminada ? Colors.red.shade700 : Colors.black87,
            decoration: eliminada ? TextDecoration.lineThrough : null,
            fontStyle: eliminada ? FontStyle.italic : null,
            fontWeight: eliminada ? FontWeight.normal : FontWeight.w400,
            height: isLandscape ? 1.1 : (isDesktop ? 1.4 : 1.2),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> _exportarTabla(BuildContext context, String formato, List<QueryDocumentSnapshot> reservas, String? nombreRecurso) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final esAdmin = authService.isAdmin;
    
    DateTime? fechaInicio;
    DateTime? fechaFin;
    if (esAdmin) {
      fechaInicio = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2055, 12, 31), // Permitir hasta 2055 (aproximadamente 20 años más)
        locale: const Locale('es', 'ES'),
        helpText: 'Selecciona la fecha de inicio',
      );
      
      if (fechaInicio == null) return;
      
      fechaFin = await showDatePicker(
        context: context,
        initialDate: fechaInicio.isAfter(DateTime.now()) ? fechaInicio : DateTime.now(),
        firstDate: fechaInicio,
        lastDate: DateTime(2055, 12, 31), // Permitir hasta 2055 (aproximadamente 20 años más)
        locale: const Locale('es', 'ES'),
        helpText: 'Selecciona la fecha de fin',
      );
      
      if (fechaFin == null) return;
      
      fechaFin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59);
    }

    try {
      final exportService = ExportService();
      
      List<QueryDocumentSnapshot> reservasFiltradas = reservas;
      if (fechaInicio != null && fechaFin != null) {
        final inicioDia = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
        reservasFiltradas = reservas.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
          if (fechaUso == null) return false;
          final fechaUsoDia = DateTime(fechaUso.year, fechaUso.month, fechaUso.day);
          return fechaUsoDia.isAfter(inicioDia.subtract(const Duration(days: 1))) &&
                 fechaUsoDia.isBefore(fechaFin!.add(const Duration(days: 1)));
        }).toList();
      }
      
      PdfPageFormat? pageFormat;
      
      if (esAdmin && formato == 'PDF') {
        pageFormat = await exportService.showPageFormatDialog(context);
        if (pageFormat == null) return;
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generando exportación en formato $formato...')),
        );
      }
      
      switch (formato) {
        case 'PDF':
          await exportService.exportReservasToPDFFromList(
            reservasFiltradas, 
            nombreRecurso, 
            isAdmin: esAdmin,
            pageFormat: pageFormat,
          );
          break;
        case 'Excel':
          final savedPath = await exportService.exportReservasToExcelFromList(reservasFiltradas, nombreRecurso, isAdmin: esAdmin);
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
                        'Archivo guardado correctamente',
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
          }
          break;
        case 'CSV':
          await exportService.exportReservasToCSVFromList(reservasFiltradas, nombreRecurso, isAdmin: esAdmin);
          break;
      }

      // El mensaje de éxito para Excel ya se muestra en el diálogo centrado
      // Solo mostrar SnackBar para PDF y CSV
      if (context.mounted && formato != 'Excel') {
        final dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');
        String fechaTexto = '';
        if (fechaInicio != null && fechaFin != null) {
          if (fechaInicio.year == fechaFin.year && 
              fechaInicio.month == fechaFin.month && 
              fechaInicio.day == fechaFin.day) {
            fechaTexto = ' (${dateFormat.format(fechaInicio)})';
          } else {
            fechaTexto = ' (${dateFormat.format(fechaInicio)} - ${dateFormat.format(fechaFin)})';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cronograma exportado a $formato exitosamente$fechaTexto'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}