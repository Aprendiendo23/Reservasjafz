import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../utils/responsive.dart';
import 'zoomable_widget.dart';

class TablaAuditoria extends StatelessWidget {
  final List<QueryDocumentSnapshot> reservas;
  /// Id de la fila seleccionada (resaltada). Toca la fila para elegirla.
  final String? filaSeleccionadaId;
  /// Al tocar una fila: si ya estaba seleccionada se deselecciona.
  final ValueChanged<String>? onFilaSeleccionada;

  const TablaAuditoria({
    super.key,
    required this.reservas,
    this.filaSeleccionadaId,
    this.onFilaSeleccionada,
  });

  Map<int, TableColumnWidth> _getColumnWidthsBase(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;

    if (isMobile) {
      if (isLandscape) {
        return {
          0: FixedColumnWidth((screenWidth * 0.14).clamp(100.0, double.infinity)),
          1: FixedColumnWidth((screenWidth * 0.12).clamp(80.0, double.infinity)),
          2: FixedColumnWidth((screenWidth * 0.15).clamp(100.0, double.infinity)),
          3: FixedColumnWidth((screenWidth * 0.15).clamp(100.0, double.infinity)),
          4: FixedColumnWidth((screenWidth * 0.15).clamp(100.0, double.infinity)),
          5: FixedColumnWidth((screenWidth * 0.12).clamp(80.0, double.infinity)),
          6: FixedColumnWidth((screenWidth * 0.12).clamp(70.0, double.infinity)),
        };
      } else {
        return {
          0: FixedColumnWidth((screenWidth * 0.20).clamp(90.0, double.infinity)),
          1: FixedColumnWidth((screenWidth * 0.18).clamp(80.0, double.infinity)),
          2: FixedColumnWidth((screenWidth * 0.22).clamp(120.0, double.infinity)),
          3: FixedColumnWidth((screenWidth * 0.22).clamp(120.0, double.infinity)),
          4: FixedColumnWidth((screenWidth * 0.22).clamp(120.0, double.infinity)),
          5: FixedColumnWidth((screenWidth * 0.18).clamp(90.0, double.infinity)),
          6: FixedColumnWidth((screenWidth * 0.18).clamp(80.0, double.infinity)),
        };
      }
    } else if (isTablet) {
      if (isLandscape) {
        return {
          0: const FixedColumnWidth(180),
          1: const FixedColumnWidth(150),
          2: const FixedColumnWidth(160),
          3: const FixedColumnWidth(160),
          4: const FixedColumnWidth(160),
          5: const FixedColumnWidth(140),
          6: const FixedColumnWidth(120),
        };
      } else {
        return {
          0: const FixedColumnWidth(170),
          1: const FixedColumnWidth(140),
          2: const FixedColumnWidth(150),
          3: const FixedColumnWidth(150),
          4: const FixedColumnWidth(150),
          5: const FixedColumnWidth(130),
          6: const FixedColumnWidth(110),
        };
      }
    } else {
      final padding = Responsive.isMobile(context) || Responsive.isTablet(context)
          ? Responsive.padding(context)
          : const EdgeInsets.symmetric(horizontal: 4, vertical: 8);
      final availableWidth = screenWidth - (padding.horizontal * 2) - 20;
      return {
        0: FixedColumnWidth((availableWidth * 0.16).clamp(160.0, double.infinity)),
        1: FixedColumnWidth((availableWidth * 0.16).clamp(150.0, double.infinity)),
        2: FixedColumnWidth((availableWidth * 0.16).clamp(170.0, double.infinity)),
        3: FixedColumnWidth((availableWidth * 0.16).clamp(170.0, double.infinity)),
        4: FixedColumnWidth((availableWidth * 0.16).clamp(150.0, double.infinity)),
        5: FixedColumnWidth((availableWidth * 0.14).clamp(130.0, double.infinity)),
        6: FixedColumnWidth((availableWidth * 0.08).clamp(100.0, double.infinity)),
      };
    }
  }

  Map<int, TableColumnWidth> _getColumnWidths(BuildContext context) {
    return _getColumnWidthsBase(context);
  }

  @override
  Widget build(BuildContext context) {
    // Calcular el ancho total de la tabla
    final columnWidths = _getColumnWidths(context);
    double totalWidth = 0;
    columnWidths.forEach((index, width) {
      if (width is FixedColumnWidth) {
        totalWidth += width.value;
      }
    });

    // Tabla base – igual para móvil y desktop
    final tabla = Column(
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
              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
              columnWidths: columnWidths,
              children: [
                TableRow(
                  children: [
                    _buildHeaderCell(context, 'MAESTRO SOLICITANTE'),
                    _buildHeaderCell(context, 'RECURSO'),
                    _buildHeaderCell(context, 'FECHA SOLICITUD'),
                    _buildHeaderCell(context, 'FECHA DE USO'),
                    _buildHeaderCell(context, 'FECHA ELIMINACIÓN'),
                    _buildHeaderCell(context, 'HORARIO'),
                    _buildHeaderCell(context, 'ESTADO'),
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
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            columnWidths: columnWidths,
            children: reservas
                .map((d) => _buildRow(context, d))
                .toList(),
          ),
        ),
      ],
    );

    // Usar ZoomableWidget: permite zoom (pellizco) y desplazamiento (pan) en ambas direcciones,
    // igual que las otras tablas (cronograma, reservas).
    return ZoomableWidget(
      minScale: 0.5,
      maxScale: 3.0,
      initialScale: 1.0,
      child: tabla,
    );
  }

  TableRow _buildRow(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final creado = (data['creado'] as Timestamp?)?.toDate();
    final eliminada = data['eliminada'] == true;
    final seleccionada = filaSeleccionadaId == doc.id;
    final fechaEliminacion = (data['fechaEliminacion'] as Timestamp?)?.toDate();
    final docente = data['docente'] ?? data['usuarioNombre'] ?? 'N/A';
    final recurso = data['recursoNombre'] ?? 'N/A';
    final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
    final dia = fechaUso != null
        ? DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(fechaUso)
        : (data['dia'] ?? 'N/A');
    final hora = data['hora'] ?? 'N/A';

    String infoEliminacion = '';
    if (eliminada) {
      final eliminadoPorAdmin = data['eliminadoPorAdmin'] == true;
      final usuarioEliminacionNombre = data['usuarioEliminacionNombre'] as String?;
      final fechaEliminacionStr =
          fechaEliminacion != null ? DateFormat('dd/MM/yy').format(fechaEliminacion) : '';

      if (usuarioEliminacionNombre != null) {
        infoEliminacion = eliminadoPorAdmin
            ? 'Eliminada por Admin\n$usuarioEliminacionNombre\n$fechaEliminacionStr'
            : 'Eliminada por Docente\n$usuarioEliminacionNombre\n$fechaEliminacionStr';
      } else {
        infoEliminacion = 'Eliminada\n$fechaEliminacionStr';
      }
    }

    void onTapFila() {
      if (onFilaSeleccionada != null) {
        onFilaSeleccionada!(doc.id);
      }
    }

    return TableRow(
      decoration: BoxDecoration(
        color: seleccionada
            ? Colors.blue.shade100
            : (eliminada ? Colors.red.shade50 : Colors.white),
      ),
      children: [
        _buildDataCell(docente, eliminada: eliminada, onTapFila: onTapFila),
        _buildDataCell(recurso, eliminada: eliminada, onTapFila: onTapFila),
        _buildDataCell(
          creado != null
              ? DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(creado)
              : 'N/A',
          eliminada: eliminada,
          esFecha: true,
          onTapFila: onTapFila,
        ),
        _buildDataCell(dia, eliminada: eliminada, esFecha: true, onTapFila: onTapFila),
        _buildDataCell(
          fechaEliminacion != null
              ? DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(fechaEliminacion)
              : '-',
          eliminada: eliminada,
          esFecha: true,
          onTapFila: onTapFila,
        ),
        _buildDataCell(hora, eliminada: eliminada, onTapFila: onTapFila),
        _buildDataCell(
          eliminada
              ? (infoEliminacion.isNotEmpty ? infoEliminacion : 'Eliminada')
              : 'Activa',
          eliminada: eliminada,
          isEstado: true,
          onTapFila: onTapFila,
        ),
      ],
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
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

  Widget _buildDataCell(
    String text, {
    bool eliminada = false,
    bool isEstado = false,
    bool esFecha = false,
    VoidCallback? onTapFila,
  }) {
    return Builder(
      builder: (context) {
        final isMobile = Responsive.isMobile(context);
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final isDesktop = !isMobile && !Responsive.isTablet(context);
        final baseFontSize = isLandscape
            ? (esFecha ? 7.0 : 8.0)
            : (isMobile
                ? (esFecha ? 8.0 : 9.0)
                : (isDesktop ? (esFecha ? 18.0 : 18.0) : (esFecha ? 11.0 : 12.0)));
        final padding = isLandscape ? 4.0 : (isMobile ? 6.0 : (isDesktop ? 12.0 : 10.0));

        final child = Container(
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
            textAlign: isEstado ? TextAlign.center : TextAlign.left,
            maxLines: esFecha
                ? (isLandscape ? 2 : (isDesktop ? null : 3))
                : (isLandscape ? 1 : (isDesktop ? null : 2)),
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
        );

        return TableCell(
          child: onTapFila == null
              ? child
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTapFila,
                    child: child,
                  ),
                ),
        );
      },
    );
  }
}

