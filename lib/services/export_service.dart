import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reserva_service.dart';
import 'analytics_service.dart';

// Conditional import: web por defecto, io para móvil/desktop
import 'export_service_web.dart' if (dart.library.io) 'export_service_io.dart' as platform;

class ExportService {
  // Exportar reservas a PDF (versión admin con opciones)
  Future<void> exportReservasToPDF(ReservaService service, {
    PdfPageFormat? pageFormat,
    bool isAdmin = false,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? periodoInfo,
  }) async {
    try {
      // Obtener todas las reservas (sin incluir eliminadas)
      final reservasSnapshot = await service.getReservas(incluirEliminadas: false).first;
      
      // Filtrar por fechas si se proporcionan y excluir eliminadas
      List<QueryDocumentSnapshot> reservasFiltradas = reservasSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Excluir reservas eliminadas
        if (data['eliminada'] == true) {
          return false;
        }
        return true;
      }).toList();
      
      if (fechaInicio != null && fechaFin != null) {
        final inicioDia = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
        reservasFiltradas = reservasFiltradas.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Asegurar que no esté eliminada
          if (data['eliminada'] == true) {
            return false;
          }
          final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
          if (fechaUso == null) return false;
          final fechaUsoDia = DateTime(fechaUso.year, fechaUso.month, fechaUso.day);
          return fechaUsoDia.isAfter(inicioDia.subtract(const Duration(days: 1))) &&
                 fechaUsoDia.isBefore(fechaFin.add(const Duration(days: 1)));
        }).toList();
      }
      
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy');
      
      // Usar formato proporcionado o A4 por defecto
      final format = pageFormat ?? PdfPageFormat.a4;
      
      // Ajustar tamaño de fuente según orientación
      final isLandscape = format.width > format.height;
      final fontSize = isLandscape ? 10.0 : 9.0;
      final headerFontSize = isLandscape ? 20.0 : 18.0;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          build: (context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Reporte de Reservas',
                      style: pw.TextStyle(
                        fontSize: headerFontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (periodoInfo != null && periodoInfo.isNotEmpty && fechaInicio != null && fechaFin != null) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        _formatearPeriodoLegible(periodoInfo, fechaInicio, fechaFin),
                        style: pw.TextStyle(
                          fontSize: fontSize + 1,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                    if (fechaInicio != null && fechaFin != null) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '${dateFormat.format(fechaInicio)} - ${dateFormat.format(fechaFin)}',
                        style: pw.TextStyle(
                          fontSize: fontSize,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  // Ajustar ancho de columnas según orientación (ahora 8 columnas si es admin, 7 si no)
                  for (int i = 0; i < (isAdmin ? 8 : 7); i++)
                    i: isLandscape 
                      ? const pw.FlexColumnWidth(1)
                      : pw.FixedColumnWidth(isLandscape ? 80 : 70),
                },
                children: [
                  // Encabezados (todos los campos de la tabla)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Maestro Solicitante',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Recurso',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Fecha Solicitud',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Fecha de Uso',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Horario que se Utilizará',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      if (isAdmin)
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            'Grado',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Asignatura',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Observación',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Datos (todos los campos de la tabla)
                  ...reservasFiltradas.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final creado = (data['creado'] as Timestamp?)?.toDate();
                    final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
                    final docente = data['docente'] ?? data['usuarioNombre'] ?? 'N/A';
                    final recurso = data['recursoNombre'] ?? 'N/A';
                    final dia = fechaUso != null 
                        ? DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(fechaUso)
                        : (data['dia'] ?? 'N/A');
                    final hora = data['hora'] ?? 'N/A';
                    final asignatura = data['asignatura'] ?? 'N/A';
                    final grado = data['grado'] ?? 'N/A';
                    final observacion = data['observacion'] ?? '';

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            docente,
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            recurso,
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            creado != null
                                ? DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(creado)
                                : 'N/A',
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            dia,
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            hora,
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                        if (isAdmin)
                          pw.Padding(
                            padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                            child: pw.Text(
                              grado,
                              style: pw.TextStyle(fontSize: fontSize),
                            ),
                          ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            asignatura,
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            observacion,
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total de reservas: ${reservasFiltradas.length}',
                style: pw.TextStyle(fontSize: 12),
              ),
              // Estadísticas de maestros (solo admin)
              if (isAdmin) ...[
                pw.SizedBox(height: 30),
                ..._buildEstadisticasMaestrosPDFFromList(context, reservasFiltradas, fontSize, headerFontSize),
              ],
            ];
          },
        ),
      );

      // Mostrar diálogo de impresión/compartir con opciones
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        format: format,
      );
    } catch (e) {
      throw 'Error al generar PDF: $e';
    }
  }

  // Exportar reservas a Excel
  Future<String?> exportReservasToExcel(ReservaService service, {
    bool isAdmin = false,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? periodoInfo,
  }) async {
    try {
      // Obtener todas las reservas (sin incluir eliminadas)
      final reservasSnapshot = await service.getReservas(incluirEliminadas: false).first;
      
      // Filtrar por fechas si se proporcionan y excluir eliminadas
      List<QueryDocumentSnapshot> reservasFiltradas = reservasSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Excluir reservas eliminadas
        if (data['eliminada'] == true) {
          return false;
        }
        return true;
      }).toList();
      
      if (fechaInicio != null && fechaFin != null) {
        final inicioDia = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
        reservasFiltradas = reservasFiltradas.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Asegurar que no esté eliminada
          if (data['eliminada'] == true) {
            return false;
          }
          final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
          if (fechaUso == null) return false;
          final fechaUsoDia = DateTime(fechaUso.year, fechaUso.month, fechaUso.day);
          return fechaUsoDia.isAfter(inicioDia.subtract(const Duration(days: 1))) &&
                 fechaUsoDia.isBefore(fechaFin.add(const Duration(days: 1)));
        }).toList();
      }
      
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Reservas'];
      
      final dateFormatFull = DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES');
      final dateFormat = DateFormat('dd/MM/yyyy');

      // Agregar información del período si está disponible
      if (periodoInfo != null && periodoInfo.isNotEmpty) {
        sheet.appendRow([TextCellValue('Período: $periodoInfo')]);
        if (fechaInicio != null && fechaFin != null) {
          sheet.appendRow([TextCellValue('${dateFormat.format(fechaInicio)} - ${dateFormat.format(fechaFin)}')]);
        }
        sheet.appendRow([]); // Línea en blanco
      }

      // Encabezados (todos los campos de la tabla)
      final headers = [
        'Maestro Solicitante',
        'Recurso',
        'Fecha Solicitud',
        'Fecha de Uso',
        'Horario que se Utilizará',
      ];
      if (isAdmin) {
        headers.add('Grado');
      }
      headers.add('Asignatura');
      headers.add('Observación');
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Estilo para encabezados
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('FF4472C4') as ExcelColor,
        fontColorHex: ExcelColor.fromHexString('FFFFFFFF') as ExcelColor,
      );
      
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      // Datos (todos los campos de la tabla)
      for (var doc in reservasFiltradas) {
        final data = doc.data() as Map<String, dynamic>;
        final creado = (data['creado'] as Timestamp?)?.toDate();
        final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
        final docente = data['docente'] ?? data['usuarioNombre'] ?? 'N/A';
        final recurso = data['recursoNombre'] ?? 'N/A';
        final dia = fechaUso != null 
            ? dateFormatFull.format(fechaUso)
            : (data['dia'] ?? 'N/A');
        final hora = data['hora'] ?? 'N/A';
        final asignatura = data['asignatura'] ?? 'N/A';
        final grado = data['grado'] ?? 'N/A';
        final observacion = data['observacion'] ?? '-';

        final row = [
          TextCellValue(docente),
          TextCellValue(recurso),
          TextCellValue(creado != null ? dateFormatFull.format(creado) : 'N/A'),
          TextCellValue(dia),
          TextCellValue(hora),
        ];
        if (isAdmin) {
          row.add(TextCellValue(grado));
        }
        row.add(TextCellValue(asignatura));
        row.add(TextCellValue(observacion));
        sheet.appendRow(row);
      }

      // Agregar estadísticas de maestros (solo admin)
      if (isAdmin) {
        _agregarEstadisticasMaestrosExcel(excel, reservasFiltradas);
      }

      // Generar bytes del archivo Excel
      final bytesList = excel.encode()!;
      final bytes = Uint8List.fromList(bytesList);
      
      // Generar nombre de archivo con período si está disponible
      String fileName;
      if (periodoInfo != null && periodoInfo.isNotEmpty) {
        fileName = 'reservas_$periodoInfo.xlsx';
      } else {
        fileName = 'reservas_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      }

      // Guardar archivo según la plataforma
      final savedPath = await platform.saveExcelFile(bytes, fileName);
      return savedPath;
    } catch (e) {
      throw 'Error al generar Excel: $e';
    }
  }

  // Exportar reservas a CSV
  Future<String?> exportReservasToCSV(ReservaService service, {
    bool isAdmin = false,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? periodoInfo,
  }) async {
    try {
      // Obtener todas las reservas (sin incluir eliminadas)
      final reservasSnapshot = await service.getReservas(incluirEliminadas: false).first;
      
      // Filtrar por fechas si se proporcionan y excluir eliminadas
      List<QueryDocumentSnapshot> reservasFiltradas = reservasSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Excluir reservas eliminadas
        if (data['eliminada'] == true) {
          return false;
        }
        return true;
      }).toList();
      
      if (fechaInicio != null && fechaFin != null) {
        final inicioDia = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
        reservasFiltradas = reservasFiltradas.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Asegurar que no esté eliminada
          if (data['eliminada'] == true) {
            return false;
          }
          final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
          if (fechaUso == null) return false;
          final fechaUsoDia = DateTime(fechaUso.year, fechaUso.month, fechaUso.day);
          return fechaUsoDia.isAfter(inicioDia.subtract(const Duration(days: 1))) &&
                 fechaUsoDia.isBefore(fechaFin.add(const Duration(days: 1)));
        }).toList();
      }
      
      final dateFormatFull = DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES');
      final dateFormat = DateFormat('dd/MM/yyyy');
      final buffer = StringBuffer();
      
      // Agregar información del período si está disponible
      if (periodoInfo != null && periodoInfo.isNotEmpty) {
        // Formatear período de manera legible
        String periodoLegible = periodoInfo;
        if (fechaInicio != null && fechaFin != null) {
          final mesNombre = DateFormat('MMMM', 'es_ES').format(fechaInicio!);
          if (periodoInfo.contains('-')) {
            // Es semana: "05-09_01_2025" -> "05-09 de Enero 2025"
            final partes = periodoInfo.split('_');
            periodoLegible = '${partes[0]} de $mesNombre ${fechaInicio!.year}';
          } else {
            // Es mes: "01_2025" -> "Enero 2025"
            periodoLegible = '$mesNombre ${fechaInicio!.year}';
          }
        }
        buffer.writeln('Período: $periodoLegible');
        if (fechaInicio != null && fechaFin != null) {
          buffer.writeln('${dateFormat.format(fechaInicio)} - ${dateFormat.format(fechaFin)}');
        }
        buffer.writeln(''); // Línea en blanco
      }
      
      // Encabezados (todos los campos de la tabla)
      final headers = [
        'Maestro Solicitante',
        'Recurso',
        'Fecha Solicitud',
        'Fecha de Uso',
        'Horario que se Utilizará',
      ];
      if (isAdmin) {
        headers.add('Grado');
      }
      headers.add('Asignatura');
      headers.add('Observación');
      buffer.writeln(headers.join(','));
      
      // Datos (todos los campos de la tabla)
      for (var doc in reservasFiltradas) {
        final data = doc.data() as Map<String, dynamic>;
        final creado = (data['creado'] as Timestamp?)?.toDate();
        final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
        final docente = data['docente'] ?? data['usuarioNombre'] ?? 'N/A';
        final recurso = data['recursoNombre'] ?? 'N/A';
        final dia = fechaUso != null 
            ? dateFormatFull.format(fechaUso)
            : (data['dia'] ?? 'N/A');
        final hora = data['hora'] ?? 'N/A';
        final asignatura = data['asignatura'] ?? 'N/A';
        final grado = data['grado'] ?? 'N/A';
        final observacion = data['observacion'] ?? '-';
        
        final row = [
          _escapeCsv(docente),
          _escapeCsv(recurso),
          _escapeCsv(creado != null ? dateFormatFull.format(creado) : 'N/A'),
          _escapeCsv(dia),
          _escapeCsv(hora),
        ];
        if (isAdmin) {
          row.add(_escapeCsv(grado));
        }
        row.add(_escapeCsv(asignatura));
        row.add(_escapeCsv(observacion));
        buffer.writeln(row.join(','));
      }
      
      // Agregar estadísticas de maestros (solo admin)
      if (isAdmin) {
        buffer.writeln('');
        buffer.writeln('=== ESTADÍSTICAS DE MAESTROS ===');
        _agregarEstadisticasMaestrosCSV(buffer, reservasFiltradas);
      }

      // Generar contenido CSV
      final csvContent = buffer.toString();
      
      // Generar nombre de archivo con período si está disponible
      String fileName;
      if (periodoInfo != null && periodoInfo.isNotEmpty) {
        fileName = 'reservas_$periodoInfo.csv';
      } else {
        fileName = 'reservas_${DateTime.now().millisecondsSinceEpoch}.csv';
      }

      // Guardar archivo según la plataforma
      final savedPath = await platform.saveCsvFile(csvContent, fileName);
      return savedPath; // Retornar la ruta donde se guardó
    } catch (e) {
      throw 'Error al generar CSV: $e';
    }
  }

  // Exportar reservas a PDF desde una lista (versión admin con opciones)
  Future<void> exportReservasToPDFFromList(
    List<QueryDocumentSnapshot> reservas,
    String? nombreRecurso, {
    bool isAdmin = false,
    PdfPageFormat? pageFormat,
  }) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy');
      
      // Usar formato proporcionado o A4 por defecto
      final format = pageFormat ?? PdfPageFormat.a4;
      
      // Ajustar tamaño de fuente según orientación
      final isLandscape = format.width > format.height;
      final fontSize = isLandscape ? 10.0 : 9.0;
      final headerFontSize = isLandscape ? 20.0 : 18.0;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          build: (context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  nombreRecurso != null 
                    ? 'Reporte de Reservas - $nombreRecurso'
                    : 'Reporte de Reservas',
                  style: pw.TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  // Ajustar ancho de columnas según orientación (ahora 8 columnas si es admin, 7 si no)
                  for (int i = 0; i < (isAdmin ? 8 : 7); i++)
                    i: isLandscape 
                      ? const pw.FlexColumnWidth(1)
                      : pw.FixedColumnWidth(isLandscape ? 80 : 70),
                },
                children: [
                  // Encabezados (todos los campos de la tabla)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Maestro Solicitante',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Recurso',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Fecha Solicitud',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Fecha de Uso',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Horario que se Utilizará',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      if (isAdmin)
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            'Grado',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Asignatura',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                        child: pw.Text(
                          'Observación',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Datos (todos los campos de la tabla)
                  ...reservas.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final creado = (data['creado'] as Timestamp?)?.toDate();
                    final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
                    final docente = data['docente'] ?? data['usuarioNombre'] ?? 'N/A';
                    final recurso = data['recursoNombre'] ?? 'N/A';
                    final dia = fechaUso != null 
                        ? DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(fechaUso)
                        : (data['dia'] ?? 'N/A');
                    final hora = data['hora'] ?? 'N/A';
                    final asignatura = data['asignatura'] ?? 'N/A';
                    final grado = data['grado'] ?? 'N/A';
                    final observacion = data['observacion'] ?? '';

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            docente,
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            recurso,
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            creado != null
                                ? DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES').format(creado)
                                : 'N/A',
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            dia,
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            hora,
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                        if (isAdmin)
                          pw.Padding(
                            padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                            child: pw.Text(
                              grado,
                              style: pw.TextStyle(fontSize: fontSize),
                            ),
                          ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            asignatura,
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(isLandscape ? 6 : 5),
                          child: pw.Text(
                            observacion,
                            style: pw.TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total de reservas: ${reservas.length}',
                style: pw.TextStyle(fontSize: 12),
              ),
            ];
          },
        ),
      );

      // Mostrar diálogo de impresión/compartir con opciones
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        format: format,
      );
    } catch (e) {
      throw 'Error al generar PDF: $e';
    }
  }

  // Exportar reservas a Excel desde una lista
  Future<String?> exportReservasToExcelFromList(
    List<QueryDocumentSnapshot> reservas,
    String? nombreRecurso, {
    bool isAdmin = false,
  }) async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel[nombreRecurso ?? 'Reservas'];
      
      final dateFormat = DateFormat('dd/MM/yyyy');

      // Encabezados (todos los campos de la tabla en el mismo orden)
      final headers = [
        'Maestro Solicitante',
        'Recurso',
        'Fecha Solicitud',
        'Fecha de Uso',
        'Horario que se Utilizará',
      ];
      if (isAdmin) {
        headers.add('Grado');
      }
      headers.add('Asignatura');
      headers.add('Observación');
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Estilo para encabezados
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('FF4472C4') as ExcelColor,
        fontColorHex: ExcelColor.fromHexString('FFFFFFFF') as ExcelColor,
      );
      
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .cellStyle = headerStyle;
      }

      // Datos (todos los campos de la tabla)
      final dateFormatFull = DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES');
      for (var doc in reservas) {
        final data = doc.data() as Map<String, dynamic>;
        final creado = (data['creado'] as Timestamp?)?.toDate();
        final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
        final docente = data['docente'] ?? data['usuarioNombre'] ?? 'N/A';
        final recurso = data['recursoNombre'] ?? 'N/A';
        final dia = fechaUso != null 
            ? dateFormatFull.format(fechaUso)
            : (data['dia'] ?? 'N/A');
        final hora = data['hora'] ?? 'N/A';
        final asignatura = data['asignatura'] ?? 'N/A';
        final grado = data['grado'] ?? 'N/A';
        final observacion = data['observacion'] ?? '-';

        final row = [
          TextCellValue(docente),
          TextCellValue(recurso),
          TextCellValue(creado != null ? dateFormatFull.format(creado) : 'N/A'),
          TextCellValue(dia),
          TextCellValue(hora),
        ];
        if (isAdmin) {
          row.add(TextCellValue(grado));
        }
        row.add(TextCellValue(asignatura));
        row.add(TextCellValue(observacion));
        sheet.appendRow(row);
      }

      // Agregar estadísticas de maestros (solo admin)
      if (isAdmin) {
        _agregarEstadisticasMaestrosExcel(excel, reservas);
      }

      // Generar bytes del archivo Excel
      final bytesList = excel.encode()!;
      final bytes = Uint8List.fromList(bytesList);
      final fileName = nombreRecurso != null 
        ? 'reservas_${nombreRecurso}_${DateTime.now().millisecondsSinceEpoch}.xlsx'
        : 'reservas_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      // Guardar archivo según la plataforma
      final savedPath = await platform.saveExcelFile(bytes, fileName);
      return savedPath; // Retornar la ruta donde se guardó
    } catch (e) {
      throw 'Error al generar Excel: $e';
    }
  }

  // Exportar reservas a CSV desde una lista
  Future<String?> exportReservasToCSVFromList(
    List<QueryDocumentSnapshot> reservas,
    String? nombreRecurso, {
    bool isAdmin = false,
  }) async {
    try {
      final dateFormatFull = DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES');
      final buffer = StringBuffer();
      
      // Encabezados (todos los campos de la tabla en el mismo orden)
      final headers = [
        'Maestro Solicitante',
        'Recurso',
        'Fecha Solicitud',
        'Fecha de Uso',
        'Horario que se Utilizará',
      ];
      if (isAdmin) {
        headers.add('Grado');
      }
      headers.add('Asignatura');
      headers.add('Observación');
      buffer.writeln(headers.join(','));
      
      // Datos (todos los campos de la tabla)
      for (var doc in reservas) {
        final data = doc.data() as Map<String, dynamic>;
        final creado = (data['creado'] as Timestamp?)?.toDate();
        final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
        final docente = data['docente'] ?? data['usuarioNombre'] ?? 'N/A';
        final recurso = data['recursoNombre'] ?? 'N/A';
        final dia = fechaUso != null 
            ? dateFormatFull.format(fechaUso)
            : (data['dia'] ?? 'N/A');
        final hora = data['hora'] ?? 'N/A';
        final asignatura = data['asignatura'] ?? 'N/A';
        final grado = data['grado'] ?? 'N/A';
        final observacion = data['observacion'] ?? '-';
        
        final row = [
          _escapeCsv(docente),
          _escapeCsv(recurso),
          _escapeCsv(creado != null ? dateFormatFull.format(creado) : 'N/A'),
          _escapeCsv(dia),
          _escapeCsv(hora),
        ];
        if (isAdmin) {
          row.add(_escapeCsv(grado));
        }
        row.add(_escapeCsv(asignatura));
        row.add(_escapeCsv(observacion));
        buffer.writeln(row.join(','));
      }
      
      // Agregar estadísticas de maestros (solo admin)
      if (isAdmin) {
        buffer.writeln('');
        buffer.writeln('=== ESTADÍSTICAS DE MAESTROS ===');
        _agregarEstadisticasMaestrosCSV(buffer, reservas);
      }

      // Generar contenido CSV
      final csvContent = buffer.toString();
      final fileName = nombreRecurso != null 
        ? 'reservas_${nombreRecurso}_${DateTime.now().millisecondsSinceEpoch}.csv'
        : 'reservas_${DateTime.now().millisecondsSinceEpoch}.csv';

      // Guardar archivo según la plataforma
      final savedPath = await platform.saveCsvFile(csvContent, fileName);
      return savedPath; // Retornar la ruta donde se guardó
    } catch (e) {
      throw 'Error al generar CSV: $e';
    }
  }

  // Helper para escapar valores CSV
  // Formatear período de manera legible
  String _formatearPeriodoLegible(String periodoInfo, DateTime fechaInicio, DateTime fechaFin) {
    final mesNombre = DateFormat('MMMM', 'es_ES').format(fechaInicio);
    if (periodoInfo.contains('-')) {
      // Es semana: "05-09_01_2025" -> "Semana del 05 al 09 de Enero 2025"
      final partes = periodoInfo.split('_');
      return 'Semana del ${partes[0]} de $mesNombre ${fechaInicio.year}';
    } else {
      // Es mes: "01_2025" -> "Mes de Enero 2025"
      return 'Mes de $mesNombre ${fechaInicio.year}';
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // Obtener estadísticas de maestros desde lista de reservas
  List<Map<String, dynamic>> _obtenerEstadisticasMaestros(List<QueryDocumentSnapshot> reservas) {
    final docentesMap = <String, Map<String, dynamic>>{};

    for (var doc in reservas) {
      final data = doc.data() as Map<String, dynamic>;
      final docenteNombre = data['docente'] ?? data['usuarioNombre'] ?? 'Sin nombre';
      final usuarioID = data['usuarioID'] as String? ?? docenteNombre;

      if (!docentesMap.containsKey(usuarioID)) {
        docentesMap[usuarioID] = {
          'usuarioID': usuarioID,
          'docenteNombre': docenteNombre,
          'cantidad': 0,
        };
      }
      docentesMap[usuarioID]!['cantidad'] = (docentesMap[usuarioID]!['cantidad'] as int) + 1;
    }

    final lista = docentesMap.values.toList();
    lista.sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));
    return lista;
  }


  // Construir estadísticas de maestros para PDF desde lista
  List<pw.Widget> _buildEstadisticasMaestrosPDFFromList(
    pw.Context context,
    List<QueryDocumentSnapshot> reservas,
    double fontSize,
    double headerFontSize,
  ) {
    final docentes = _obtenerEstadisticasMaestros(reservas);
    
    if (docentes.isEmpty) {
      return [];
    }

    final totalReservas = reservas.length;
    final masUsa = docentes.first;
    final menosUsa = docentes.last;

    return [
      pw.Header(
        level: 1,
        child: pw.Text(
          'Estadísticas de Uso por Maestro',
          style: pw.TextStyle(
            fontSize: headerFontSize * 0.8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.SizedBox(height: 15),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Total de Reservas: $totalReservas',
              style: pw.TextStyle(fontSize: fontSize + 1, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Maestro que Más Utiliza: ${masUsa['docenteNombre']} (${masUsa['cantidad']} reservas)',
              style: pw.TextStyle(fontSize: fontSize),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Maestro que Menos Utiliza: ${menosUsa['docenteNombre']} (${menosUsa['cantidad']} reservas)',
              style: pw.TextStyle(fontSize: fontSize),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 15),
      pw.Text(
        'Frecuencia de Uso por Maestro:',
        style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(fontSize * 0.5),
                child: pw.Text(
                  'Maestro',
                  style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(fontSize * 0.5),
                child: pw.Text(
                  'Reservas',
                  style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          ...docentes.map((docente) {
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: pw.EdgeInsets.all(fontSize * 0.5),
                  child: pw.Text(
                    docente['docenteNombre'] ?? 'N/A',
                    style: pw.TextStyle(fontSize: fontSize),
                  ),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(fontSize * 0.5),
                  child: pw.Text(
                    '${docente['cantidad']}',
                    style: pw.TextStyle(fontSize: fontSize),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    ];
  }

  // Agregar estadísticas de maestros a Excel
  void _agregarEstadisticasMaestrosExcel(Excel excel, List<QueryDocumentSnapshot> reservas) {
    final docentes = _obtenerEstadisticasMaestros(reservas);
    if (docentes.isEmpty) return;

    final sheet = excel['Estadísticas Maestros'];
    final totalReservas = reservas.length;
    final masUsa = docentes.first;
    final menosUsa = docentes.last;

    // Encabezado de sección
    sheet.appendRow([TextCellValue('ESTADÍSTICAS DE USO POR MAESTRO')]);
    sheet.appendRow([]);
    
    // Resumen
    sheet.appendRow([TextCellValue('Total de Reservas:'), TextCellValue('$totalReservas')]);
    sheet.appendRow([TextCellValue('Maestro que Más Utiliza:'), TextCellValue('${masUsa['docenteNombre']} (${masUsa['cantidad']} reservas)')]);
    sheet.appendRow([TextCellValue('Maestro que Menos Utiliza:'), TextCellValue('${menosUsa['docenteNombre']} (${menosUsa['cantidad']} reservas)')]);
    sheet.appendRow([]);
    
    // Tabla de frecuencia
    sheet.appendRow([TextCellValue('Maestro'), TextCellValue('Cantidad de Reservas')]);
    
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('FF4472C4') as ExcelColor,
      fontColorHex: ExcelColor.fromHexString('FFFFFFFF') as ExcelColor,
    );
    
    final headerRowIndex = sheet.rows.length - 1;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRowIndex)).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRowIndex)).cellStyle = headerStyle;
    
    for (var docente in docentes) {
      sheet.appendRow([
        TextCellValue(docente['docenteNombre'] ?? 'N/A'),
        TextCellValue('${docente['cantidad']}'),
      ]);
    }
  }

  // Agregar estadísticas de maestros a CSV
  void _agregarEstadisticasMaestrosCSV(StringBuffer buffer, List<QueryDocumentSnapshot> reservas) {
    final docentes = _obtenerEstadisticasMaestros(reservas);
    if (docentes.isEmpty) return;

    final totalReservas = reservas.length;
    final masUsa = docentes.first;
    final menosUsa = docentes.last;

    buffer.writeln('Total de Reservas,$totalReservas');
    buffer.writeln('Maestro que Más Utiliza,${_escapeCsv(masUsa['docenteNombre'] ?? 'N/A')} (${masUsa['cantidad']} reservas)');
    buffer.writeln('Maestro que Menos Utiliza,${_escapeCsv(menosUsa['docenteNombre'] ?? 'N/A')} (${menosUsa['cantidad']} reservas)');
    buffer.writeln('');
    buffer.writeln('Frecuencia de Uso por Maestro:');
    buffer.writeln('Maestro,Cantidad de Reservas');
    for (var docente in docentes) {
      buffer.writeln('${_escapeCsv(docente['docenteNombre'] ?? 'N/A')},${docente['cantidad']}');
    }
  }
  
  // Mostrar diálogo para seleccionar formato de página (solo admin)
  Future<PdfPageFormat?> showPageFormatDialog(BuildContext context) async {
    PdfPageFormat? selectedFormat;
    bool isLandscape = false;
    String selectedSize = 'A4';

    final result = await showDialog<PdfPageFormat>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Configurar Formato de Página'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tamaño de página
                const Text(
                  'Tamaño de Página',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSize,
                  decoration: const InputDecoration(
                    labelText: 'Tamaño',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A4', child: Text('A4')),
                    DropdownMenuItem(value: 'Letter', child: Text('Letter (Carta)')),
                    DropdownMenuItem(value: 'Legal', child: Text('Legal')),
                    DropdownMenuItem(value: 'A3', child: Text('A3')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedSize = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),
                // Orientación
                const Text(
                  'Orientación',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Vertical'),
                        value: false,
                        groupValue: isLandscape,
                        onChanged: (value) {
                          setState(() {
                            isLandscape = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Horizontal'),
                        value: true,
                        groupValue: isLandscape,
                        onChanged: (value) {
                          setState(() {
                            isLandscape = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                PdfPageFormat format;
                switch (selectedSize) {
                  case 'A3':
                    format = isLandscape ? PdfPageFormat.a3.landscape : PdfPageFormat.a3;
                    break;
                  case 'Letter':
                    format = isLandscape ? PdfPageFormat.letter.landscape : PdfPageFormat.letter;
                    break;
                  case 'Legal':
                    format = isLandscape ? PdfPageFormat.legal.landscape : PdfPageFormat.legal;
                    break;
                  default:
                    format = isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
                }
                Navigator.pop(context, format);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
    
    return result;
  }
}

