import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/reserva_service.dart';
import '../../services/recurso_service.dart';
import '../../services/auth_service.dart';
import '../../services/export_service.dart';

class AllBookingsScreen extends StatefulWidget {
  const AllBookingsScreen({super.key});

  @override
  State<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends State<AllBookingsScreen> {
  DateTime? _filterDate;
  String? _filterDocente;
  String? _filterRecurso;
  final List<Map<String, dynamic>> _docentes = [];
  final List<Map<String, dynamic>> _recursos = [];

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    final reservaService = Provider.of<ReservaService>(context, listen: false);
    final recursoService = Provider.of<RecursoService>(context, listen: false);
    
    // Cargar recursos
    final recursosSnapshot = await recursoService.getRecursos().first;
    setState(() {
      _recursos.clear();
      for (var doc in recursosSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _recursos.add({
          'id': doc.id,
          'nombre': data['nombre'] ?? 'Sin nombre',
        });
      }
    });

    // Cargar docentes (usuarios que tienen reservas)
    final reservasSnapshot = await reservaService.getReservas().first;
    final docentesSet = <String, String>{};
    for (var doc in reservasSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final email = data['usuarioEmail'] as String?;
      final userId = data['usuarioID'] as String?;
      if (email != null && userId != null) {
        docentesSet[userId] = email;
      }
    }
    setState(() {
      _docentes.clear();
      docentesSet.forEach((id, email) {
        _docentes.add({'id': id, 'email': email});
      });
    });
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
        title: const Text('Todas las Reservas'),
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
        stream: reservaService.getReservas(),
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

          // Aplicar filtros
          var filteredDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Filtro por fecha
            if (_filterDate != null) {
              final fechaInicio = (data['fechaInicio'] as Timestamp?)?.toDate();
              if (fechaInicio == null ||
                  fechaInicio.year != _filterDate!.year ||
                  fechaInicio.month != _filterDate!.month ||
                  fechaInicio.day != _filterDate!.day) {
                return false;
              }
            }

            // Filtro por docente
            if (_filterDocente != null) {
              if (data['usuarioID'] != _filterDocente) {
                return false;
              }
            }

            // Filtro por recurso
            if (_filterRecurso != null) {
              if (data['recursoID'] != _filterRecurso) {
                return false;
              }
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
                        _filterDate = null;
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

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(Icons.book_online, size: 40),
                  title: Text(
                    data['recursoNombre'] ?? 'Recurso',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Docente: ${data['usuarioEmail'] ?? 'N/A'}'),
                      if (data['fechaInicio'] != null)
                        Text(
                          'Inicio: ${_formatDate(data['fechaInicio'])}',
                        ),
                      if (data['fechaFin'] != null)
                        Text(
                          'Fin: ${_formatDate(data['fechaFin'])}',
                        ),
                      Text(
                        'Estado: ${data['estado'] ?? 'Activa'}',
                        style: TextStyle(
                          color: (data['estado'] == 'activa')
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmDialog(
                      context,
                      reservaService,
                      doc.id,
                    ),
                  ),
                ),
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
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Fecha'),
                  subtitle: Text(
                    _filterDate != null
                        ? DateFormat('dd/MM/yyyy').format(_filterDate!)
                        : 'Todas las fechas',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_filterDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _filterDate = null);
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_calendar),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _filterDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() => _filterDate = date);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                DropdownButtonFormField<String>(
                  value: _filterDocente,
                  decoration: const InputDecoration(
                    labelText: 'Docente',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todos los docentes'),
                    ),
                    ..._docentes.map((d) => DropdownMenuItem(
                          value: d['id'],
                          child: Text(d['email']),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _filterDocente = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _filterRecurso,
                  decoration: const InputDecoration(
                    labelText: 'Recurso',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todos los recursos'),
                    ),
                    ..._recursos.map((r) => DropdownMenuItem(
                          value: r['id'],
                          child: Text(r['nombre']),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _filterRecurso = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterDate = null;
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

  void _showDeleteConfirmDialog(
    BuildContext context,
    ReservaService service,
    String reservaId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Reserva'),
        content: const Text('¿Estás seguro de eliminar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final reservaService = Provider.of<ReservaService>(context, listen: false);
                await reservaService.eliminarReserva(reservaId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reserva eliminada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF(
    BuildContext context,
    ReservaService service,
  ) async {
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

  Future<void> _exportToExcel(
    BuildContext context,
    ReservaService service,
  ) async {
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Fecha no disponible';
    try {
      final date = timestamp.toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return 'Fecha inválida';
    }
  }
}

