import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../../services/reserva_service.dart';
import '../../services/auth_service.dart';
import '../../services/export_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/tabla_auditoria.dart';

class AuditoriaReservasScreen extends StatefulWidget {
  const AuditoriaReservasScreen({super.key});

  @override
  State<AuditoriaReservasScreen> createState() => _AuditoriaReservasScreenState();
}

class _AuditoriaReservasScreenState extends State<AuditoriaReservasScreen> {
  // Filtros por fecha para la auditoría
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _estaEliminando = false;
  String _tipoFiltroFecha = 'eliminacion'; // 'creado' o 'eliminacion'

  // Filtros de texto
  String _filtroDocente = '';
  String _filtroRecurso = '';

  /// Fila seleccionada en la tabla (para recuperar con el botón).
  String? _reservaSeleccionadaId;

  // Exportar las reservas de auditoría (solo eliminadas en pantalla)
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
            tooltip: 'Solo reservas eliminadas — recuperar o borrar definitivamente',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Auditoría de Reservas'),
                  content: const Text(
                    'Aquí solo se listan las reservas ELIMINADAS (no las activas).\n\n'
                    'Puedes recuperar una reserva con el botón verde si el horario sigue libre.\n\n'
                    'También puedes borrarlas definitivamente o exportar el listado.',
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
          // Solo reservas eliminadas en esta pantalla
          final soloEliminadas = reservas.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['eliminada'] == true;
          }).toList();

          // Aplicar filtros
          List<QueryDocumentSnapshot> reservasFiltradas = soloEliminadas;
          
          // Filtro por fecha
          if (_fechaInicio != null || _fechaFin != null) {
            reservasFiltradas = reservasFiltradas.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              Timestamp? timestamp;
              
              if (_tipoFiltroFecha == 'eliminacion') {
                timestamp = data['fechaEliminacion'] as Timestamp?;
                if (timestamp == null) return false; // Solo mostrar eliminadas si se filtra por eliminación
              } else {
                timestamp = data['creado'] as Timestamp?;
              }
              
              if (timestamp == null) return false;
              final fecha = timestamp.toDate();
              
              if (_fechaInicio != null && fecha.isBefore(_fechaInicio!)) return false;
              if (_fechaFin != null && fecha.isAfter(_fechaFin!.add(const Duration(days: 1)))) return false;
              
              return true;
            }).toList();
          }
          
          // Filtro por docente
          if (_filtroDocente.isNotEmpty) {
            final filtro = _filtroDocente.toLowerCase();
            reservasFiltradas = reservasFiltradas.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final docente = (data['docente'] ?? data['usuarioNombre'] ?? '').toString().toLowerCase();
              return docente.contains(filtro);
            }).toList();
          }
          
          // Filtro por recurso
          if (_filtroRecurso.isNotEmpty) {
            final filtro = _filtroRecurso.toLowerCase();
            reservasFiltradas = reservasFiltradas.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final recurso = (data['recursoNombre'] ?? '').toString().toLowerCase();
              return recurso.toLowerCase().contains(filtro);
            }).toList();
          }
          
          final totalEliminadasFiltradas = reservasFiltradas.length;

          return OrientationBuilder(
            builder: (context, orientation) {
              final isLandscape = orientation == Orientation.landscape;
              
              if (orientation == Orientation.portrait) {
                return Column(
                  children: [
                    // Solo listado de eliminadas: una tarjeta con el total filtrado
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.isMobile(context) ? 12 : 16,
                        vertical: Responsive.isMobile(context) ? 8 : 12,
                      ),
                      child: Card(
                        elevation: 2,
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: EdgeInsets.all(Responsive.isMobile(context) ? 12.0 : 16.0),
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red.shade700, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$totalEliminadasFiltradas',
                                      style: TextStyle(
                                        fontSize: Responsive.isMobile(context) ? 24 : 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    Text(
                                      'Reservas eliminadas (según filtros)',
                                      style: TextStyle(
                                        fontSize: Responsive.isMobile(context) ? 12 : 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Filtros y botones en un scroll vertical compacto
                    SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFiltros(context, isLandscape, reservasFiltradas),
                          // Botones de exportación - más compactos
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.isMobile(context) ? 12 : 16,
                              vertical: Responsive.isMobile(context) ? 4 : 8,
                            ),
                            child: Wrap(
                              spacing: Responsive.isMobile(context) ? 8 : 12,
                              runSpacing: Responsive.isMobile(context) ? 6 : 8,
                              alignment: WrapAlignment.start,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _exportarAuditoria(context, reservasFiltradas, 'PDF'),
                                  icon: Icon(Icons.picture_as_pdf, color: Colors.white, size: Responsive.isMobile(context) ? 18 : 20),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.isMobile(context) ? 12 : 16,
                                      vertical: Responsive.isMobile(context) ? 8 : 12,
                                    ),
                                  ),
                                  label: Text('Exportar PDF', style: TextStyle(fontSize: Responsive.isMobile(context) ? 12 : 14)),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _exportarAuditoria(context, reservasFiltradas, 'Excel'),
                                  icon: Icon(Icons.table_chart, color: Colors.white, size: Responsive.isMobile(context) ? 18 : 20),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.isMobile(context) ? 12 : 16,
                                      vertical: Responsive.isMobile(context) ? 8 : 12,
                                    ),
                                  ),
                                  label: Text('Exportar Excel', style: TextStyle(fontSize: Responsive.isMobile(context) ? 12 : 14)),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _exportarAuditoria(context, reservasFiltradas, 'CSV'),
                                  icon: Icon(Icons.description, color: Colors.white, size: Responsive.isMobile(context) ? 18 : 20),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.isMobile(context) ? 12 : 16,
                                      vertical: Responsive.isMobile(context) ? 8 : 12,
                                    ),
                                  ),
                                  label: Text('Exportar CSV', style: TextStyle(fontSize: Responsive.isMobile(context) ? 12 : 14)),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _reservaSeleccionadaId == null
                                      ? null
                                      : () => _recuperarReserva(context, _reservaSeleccionadaId!),
                                  icon: Icon(Icons.restore, color: Colors.white, size: Responsive.isMobile(context) ? 18 : 20),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade700,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.isMobile(context) ? 12 : 16,
                                      vertical: Responsive.isMobile(context) ? 8 : 12,
                                    ),
                                  ),
                                  label: Text(
                                    'Recuperar selección',
                                    style: TextStyle(fontSize: Responsive.isMobile(context) ? 12 : 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              left: Responsive.isMobile(context) ? 12 : 16,
                              right: Responsive.isMobile(context) ? 12 : 16,
                              top: 4,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Toca una fila para seleccionarla (azul). Vuelve a tocar la misma fila para quitar la selección.',
                                style: TextStyle(
                                  fontSize: Responsive.isMobile(context) ? 11 : 13,
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tabla - ocupa el resto del espacio disponible con menos padding
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: Responsive.isMobile(context) ? 8 : 12,
                          vertical: Responsive.isMobile(context) ? 4 : 8,
                        ),
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
                          child: TablaAuditoria(
                            reservas: reservasFiltradas,
                            filaSeleccionadaId: _reservaSeleccionadaId,
                            onFilaSeleccionada: (id) {
                              setState(() {
                                if (_reservaSeleccionadaId == id) {
                                  _reservaSeleccionadaId = null;
                                } else {
                                  _reservaSeleccionadaId = id;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    // Pie de página - más compacto
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.isMobile(context) ? 12 : 16,
                        vertical: Responsive.isMobile(context) ? 8 : 12,
                      ),
                      child: Text(
                        'Total (filtrado): $totalEliminadasFiltradas reserva(s) eliminada(s)',
                        style: TextStyle(
                          fontSize: Responsive.isMobile(context) ? 11 : 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Modo landscape
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Card(
                      elevation: 2,
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red.shade700, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              '$totalEliminadasFiltradas eliminadas (filtradas)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Filtros y botones en un scroll horizontal compacto
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFiltros(context, isLandscape, reservasFiltradas),
                          // Botones de exportación - más compactos
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _exportarAuditoria(context, reservasFiltradas, 'PDF'),
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 16),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                label: const Text('Exportar PDF', style: TextStyle(fontSize: 11)),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _exportarAuditoria(context, reservasFiltradas, 'Excel'),
                                icon: const Icon(Icons.table_chart, color: Colors.white, size: 16),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                label: const Text('Exportar Excel', style: TextStyle(fontSize: 11)),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _exportarAuditoria(context, reservasFiltradas, 'CSV'),
                                icon: const Icon(Icons.description, color: Colors.white, size: 16),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                label: const Text('Exportar CSV', style: TextStyle(fontSize: 11)),
                              ),
                              ElevatedButton.icon(
                                onPressed: _reservaSeleccionadaId == null
                                    ? null
                                    : () => _recuperarReserva(context, _reservaSeleccionadaId!),
                                icon: const Icon(Icons.restore, color: Colors.white, size: 16),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                label: const Text('Recuperar selección', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Toca una fila para seleccionarla; «Recuperar selección» restaura esa reserva.',
                              style: TextStyle(fontSize: 9, color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tabla - ocupa el resto del espacio disponible
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Container(
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
                          child: TablaAuditoria(
                            reservas: reservasFiltradas,
                            filaSeleccionadaId: _reservaSeleccionadaId,
                            onFilaSeleccionada: (id) {
                              setState(() {
                                if (_reservaSeleccionadaId == id) {
                                  _reservaSeleccionadaId = null;
                                } else {
                                  _reservaSeleccionadaId = id;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Pie de página - más compacto
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Total (filtrado): $totalEliminadasFiltradas reserva(s) eliminada(s)',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFiltros(BuildContext context, bool isLandscape, List<QueryDocumentSnapshot> reservasFiltradas) {
    return Padding(
      padding: isLandscape
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : EdgeInsets.symmetric(
              horizontal: Responsive.isMobile(context) ? 12 : 16,
              vertical: Responsive.isMobile(context) ? 4 : 8,
            ),
      child: Wrap(
        spacing: Responsive.isMobile(context) ? 8 : 12,
        runSpacing: Responsive.isMobile(context) ? 6 : 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Selector de tipo de fecha para el filtro
          DropdownButton<String>(
            value: _tipoFiltroFecha,
            items: const [
              DropdownMenuItem(
                value: 'eliminacion',
                child: Text('Fecha de eliminación (solo eliminadas)'),
              ),
              DropdownMenuItem(
                value: 'creado',
                child: Text('Fecha de solicitud/creación'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _tipoFiltroFecha = value;
              });
            },
          ),
          OutlinedButton.icon(
            onPressed: () => _seleccionarFechaInicio(context),
            icon: const Icon(Icons.date_range),
            label: Text(
              _fechaInicio != null
                  ? 'Desde: ${DateFormat('dd/MM/yy').format(_fechaInicio!)}'
                  : 'Fecha desde',
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _seleccionarFechaFin(context),
            icon: const Icon(Icons.date_range),
            label: Text(
              _fechaFin != null
                  ? 'Hasta: ${DateFormat('dd/MM/yy').format(_fechaFin!)}'
                  : 'Fecha hasta',
            ),
          ),
          // Filtro por docente
          SizedBox(
            width: Responsive.isMobile(context) ? 180 : 220,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por docente',
                prefixIcon: const Icon(Icons.person_search),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Responsive.isMobile(context) ? 8 : 12,
                  vertical: Responsive.isMobile(context) ? 8 : 12,
                ),
              ),
              style: TextStyle(fontSize: Responsive.isMobile(context) ? 12 : 14),
              onChanged: (value) {
                setState(() {
                  _filtroDocente = value;
                });
              },
            ),
          ),
          // Filtro por recurso
          SizedBox(
            width: Responsive.isMobile(context) ? 180 : 220,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por recurso',
                prefixIcon: const Icon(Icons.computer),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Responsive.isMobile(context) ? 8 : 12,
                  vertical: Responsive.isMobile(context) ? 8 : 12,
                ),
              ),
              style: TextStyle(fontSize: Responsive.isMobile(context) ? 12 : 14),
              onChanged: (value) {
                setState(() {
                  _filtroRecurso = value;
                });
              },
            ),
          ),
          if (_fechaInicio != null || _fechaFin != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _fechaInicio = null;
                  _fechaFin = null;
                });
              },
              child: const Text('Limpiar filtro de fechas'),
            ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _estaEliminando
                ? null
                : () => _confirmarEliminacionPermanente(
                      context,
                      reservasFiltradas,
                      Provider.of<ReservaService>(context, listen: false),
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever),
            label: Text(_estaEliminando
                ? 'Eliminando...'
                : 'Eliminar permanente (eliminadas filtradas)'),
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarFechaInicio(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2055, 12, 31),
      locale: const Locale('es', 'ES'),
    );
    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
      });
    }
  }

  Future<void> _seleccionarFechaFin(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? (_fechaInicio ?? DateTime.now()),
      firstDate: _fechaInicio ?? DateTime(2020),
      lastDate: DateTime(2055, 12, 31),
      locale: const Locale('es', 'ES'),
    );
    if (fecha != null) {
      setState(() {
        _fechaFin = fecha;
      });
    }
  }

  Future<void> _confirmarEliminacionPermanente(
    BuildContext context,
    List<QueryDocumentSnapshot> reservasFiltradas,
    ReservaService reservaService,
  ) async {
    final reservasEliminadas = reservasFiltradas.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['eliminada'] == true;
    }).toList();

    if (reservasEliminadas.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sin reservas eliminadas'),
          content: const Text('No hay reservas eliminadas en los resultados filtrados.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación permanente'),
        content: Text(
          '¿Estás seguro de que deseas eliminar permanentemente ${reservasEliminadas.length} reserva(s)?\n\n'
          'Esta acción NO se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar permanentemente'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _estaEliminando = true;
    });

    try {
      for (final doc in reservasEliminadas) {
        await reservaService.eliminarReservaPermanente(doc.id);
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminación exitosa'),
            content: Text('Se eliminaron permanentemente ${reservasEliminadas.length} reserva(s).'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error al eliminar: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _estaEliminando = false;
        });
      }
    }
  }

  Future<void> _recuperarReserva(BuildContext context, String reservaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar reserva'),
        content: const Text(
          '¿Restaurar esta reserva? Volverá a estar activa y visible como el resto '
          'si el recurso y horario siguen libres.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Recuperar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final reservaService = Provider.of<ReservaService>(context, listen: false);
    try {
      await reservaService.recuperarReserva(reservaId);
      if (!mounted) return;
      setState(() => _reservaSeleccionadaId = null);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Reserva recuperada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
