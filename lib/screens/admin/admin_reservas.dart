import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/reserva_service.dart';
import '../../services/auth_service.dart';
import '../../services/export_service.dart';
import '../../widgets/card_reserva.dart';
import '../../routes/app_routes.dart';

class AdminReservasScreen extends StatefulWidget {
  const AdminReservasScreen({super.key});

  @override
  State<AdminReservasScreen> createState() => _AdminReservasScreenState();
}

class _AdminReservasScreenState extends State<AdminReservasScreen> {
  String? _filterDia;
  String? _filterDocente;
  String? _filterRecurso;

  final List<String> _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];

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
        title: const Text('Gestión de Reservas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Exportar a PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Exportar a Excel'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'export_pdf') {
                await _exportToPDF(context, reservaService);
              } else if (value == 'export_excel') {
                await _exportToExcel(context, reservaService);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: reservaService.getReservas(incluirEliminadas: false), // No mostrar reservas eliminadas
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay reservas'));
          }

          // Aplicar filtros (excluir reservas eliminadas)
          var filteredDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            // Excluir reservas eliminadas
            if (data['eliminada'] == true) {
              return false;
            }

            if (_filterDia != null && data['dia'] != _filterDia) {
              return false;
            }
            if (_filterDocente != null && data['usuarioID'] != _filterDocente) {
              return false;
            }
            if (_filterRecurso != null && data['recursoID'] != _filterRecurso) {
              return false;
            }

            return true;
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.filter_alt_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay reservas con los filtros aplicados'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterDia = null;
                        _filterDocente = null;
                        _filterRecurso = null;
                      });
                    },
                    child: const Text('Limpiar Filtros'),
                  ),
                ],
              ),
            );
          }

          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
          
          return ListView.builder(
            padding: isLandscape
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                : const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
              final grado = data['grado'] as String?;

              return CardReserva(
                reservaId: doc.id,
                recursoNombre: data['recursoNombre'] ?? 'Recurso',
                dia: data['dia'] ?? '',
                hora: data['hora'] ?? '',
                asignatura: data['asignatura'] ?? '',
                usuarioNombre: data['usuarioNombre'] ?? '',
                docente: data['docente'] as String?,
                fechaUso: fechaUso != null ? DateFormat('dd-MM-yyyy').format(fechaUso) : null,
                grado: grado,
                observacion: data['observacion'] as String?,
                onEdit: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.editarReserva,
                    arguments: doc.id,
                  ).then((actualizado) {
                    if (actualizado == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reserva actualizada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  });
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Eliminar Reserva'),
                      content: const Text('¿Estás seguro de eliminar esta reserva?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await reservaService.eliminarReserva(doc.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reserva eliminada exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filtrar Reservas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _filterDia,
                  decoration: const InputDecoration(
                    labelText: 'Día',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todos los días'),
                    ),
                    ..._dias.map((dia) => DropdownMenuItem(
                          value: dia,
                          child: Text(dia),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _filterDia = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterDia = null;
                  _filterDocente = null;
                  _filterRecurso = null;
                });
                Navigator.pop(context);
                this.setState(() {});
              },
              child: const Text('Limpiar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                this.setState(() {});
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPDF(BuildContext context, ReservaService service) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando PDF...')),
      );

      final exportService = ExportService();
      await exportService.exportReservasToPDF(service);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generado exitosamente'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando Excel...')),
      );

      final exportService = ExportService();
      final savedPath = await exportService.exportReservasToExcel(service);

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
      } else if (context.mounted && savedPath == null) {
        // Usuario canceló - mostrar diálogo centrado
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
                    Icons.cancel,
                    color: Colors.orange,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Guardado cancelado',
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
}

