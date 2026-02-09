import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/asignatura_service.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';

class AdminAsignaturasScreen extends StatefulWidget {
  const AdminAsignaturasScreen({super.key});

  @override
  State<AdminAsignaturasScreen> createState() => _AdminAsignaturasScreenState();
}

class _AdminAsignaturasScreenState extends State<AdminAsignaturasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  String? _asignaturaEditandoId;
  bool _ocultandoInactivos = false; // Por defecto mostrar todos, toggle para ocultar inactivos

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Inicializar asignaturas por defecto cuando se carga la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarAsignaturasPorDefecto();
    });
  }

  Future<void> _inicializarAsignaturasPorDefecto() async {
    final asignaturaService = Provider.of<AsignaturaService>(context, listen: false);
    
    try {
      // Crear asignaturas por defecto si no existen
      final resultado = await asignaturaService.crearAsignaturasPorDefecto();
      if (mounted && resultado['creadas']! > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${resultado['creadas']} asignaturas por defecto creadas'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Si hay error, continuar de todas formas
      print('Error al inicializar asignaturas por defecto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final asignaturaService = Provider.of<AsignaturaService>(context);

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
        title: const Text('Gestión de Asignaturas'),
        actions: [
          IconButton(
            icon: Icon(_ocultandoInactivos ? Icons.visibility_off : Icons.visibility),
            tooltip: _ocultandoInactivos ? 'Mostrar inactivos' : 'Ocultar inactivos',
            onPressed: () {
              setState(() {
                _ocultandoInactivos = !_ocultandoInactivos;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Crear nueva asignatura',
            onPressed: () => _mostrarDialogoCrearOEditarAsignatura(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de asignaturas
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: asignaturaService.getTodasLasAsignaturas(),
              builder: (context, snapshot) {
                // Debug: imprimir estado del snapshot
                print('📊 Estado del StreamBuilder de asignaturas:');
                print('   - ConnectionState: ${snapshot.connectionState}');
                print('   - hasData: ${snapshot.hasData}');
                print('   - hasError: ${snapshot.hasError}');
                if (snapshot.hasData) {
                  print('   - Número de documentos: ${snapshot.data?.docs.length ?? 0}');
                }
                if (snapshot.hasError) {
                  print('   - Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar asignaturas',
                          style: TextStyle(fontSize: 18, color: Colors.red.shade700),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrar asignaturas según el toggle
                final todasLasAsignaturas = snapshot.data?.docs ?? [];
                print('📚 Total de asignaturas encontradas: ${todasLasAsignaturas.length}');
                
                final asignaturasFiltradas = _ocultandoInactivos
                    ? todasLasAsignaturas.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final activo = data['activo'];
                        return activo != false && activo != null; // Mostrar solo activos
                      }).toList()
                    : todasLasAsignaturas; // Mostrar todos
                
                print('📋 Asignaturas después del filtro: ${asignaturasFiltradas.length}');
                
                // Ordenar primero por "orden" (si existe) y luego por nombre
                asignaturasFiltradas.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final ordenA = (dataA['orden'] as int?) ?? 9999;
                  final ordenB = (dataB['orden'] as int?) ?? 9999;
                  if (ordenA != ordenB) {
                    return ordenA.compareTo(ordenB);
                  }
                  final nombreA = (dataA['nombre'] as String?) ?? '';
                  final nombreB = (dataB['nombre'] as String?) ?? '';
                  return nombreA.compareTo(nombreB);
                });

                if (asignaturasFiltradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _ocultandoInactivos
                              ? 'No hay asignaturas activas'
                              : 'No hay asignaturas registradas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                
                return ListView.builder(
                  padding: isLandscape
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                      : Responsive.padding(context),
                  itemCount: asignaturasFiltradas.length,
                  itemBuilder: (context, index) {
                    final asignatura = asignaturasFiltradas[index];
                    final data = asignatura.data() as Map<String, dynamic>;
                    final nombre = data['nombre'] ?? 'Sin nombre';
                    final activo = data['activo'] ?? true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: activo ? null : Colors.grey.shade200,
                      child: ListTile(
                        leading: Icon(
                          Icons.book,
                          color: activo ? Colors.blue : Colors.grey,
                        ),
                        title: Text(
                          nombre,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            decoration: activo ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text(
                          activo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: activo ? Colors.green : Colors.red,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (activo)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: Colors.blue,
                                onPressed: () => _mostrarDialogoCrearOEditarAsignatura(
                                  context,
                                  id: asignatura.id,
                                  nombreInicial: nombre,
                                ),
                              ),
                            IconButton(
                              icon: Icon(activo ? Icons.block : Icons.check_circle),
                              color: activo ? Colors.orange : Colors.green,
                              onPressed: () => activo
                                  ? _desactivarAsignatura(asignatura.id, nombre)
                                  : _activarAsignatura(asignatura.id, nombre),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _eliminarAsignatura(asignatura.id, nombre),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _crearAsignatura() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final asignaturaService = Provider.of<AsignaturaService>(context, listen: false);
      await asignaturaService.crearAsignatura(_nombreController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asignatura creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _nombreController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _actualizarAsignatura() async {
    if (!_formKey.currentState!.validate() || _asignaturaEditandoId == null) return;

    try {
      final asignaturaService = Provider.of<AsignaturaService>(context, listen: false);
      await asignaturaService.actualizarAsignatura(_asignaturaEditandoId!, _nombreController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asignatura actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _cancelarEdicion();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editarAsignatura(String id, String nombre) {
    setState(() {
      _asignaturaEditandoId = id;
      _nombreController.text = nombre;
    });
  }

  void _cancelarEdicion() {
    setState(() {
      _asignaturaEditandoId = null;
      _nombreController.clear();
    });
  }

  Future<void> _desactivarAsignatura(String id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar Asignatura'),
        content: Text('¿Estás seguro de desactivar "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final asignaturaService = Provider.of<AsignaturaService>(context, listen: false);
        await asignaturaService.desactivarAsignatura(id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asignatura desactivada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _activarAsignatura(String id, String nombre) async {
    try {
      final asignaturaService = Provider.of<AsignaturaService>(context, listen: false);
      await asignaturaService.activarAsignatura(id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asignatura activada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoCrearOEditarAsignatura(BuildContext context, {String? id, String? nombreInicial}) {
    if (id == null) {
      // Crear
      _asignaturaEditandoId = null;
      _nombreController.clear();
    } else {
      // Editar
      _asignaturaEditandoId = id;
      _nombreController.text = nombreInicial ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Crear Nueva Asignatura' : 'Editar Asignatura'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Asignatura *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.book),
              hintText: 'Ej: Matemática, Lengua y Literatura',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa un nombre';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelarEdicion();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              if (id == null) {
                await _crearAsignatura();
              } else {
                await _actualizarAsignatura();
              }
              if (mounted) {
                Navigator.of(context).pop();
                _cancelarEdicion();
              }
            },
            child: Text(id == null ? 'Crear' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarAsignatura(String id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Asignatura'),
        content: Text('¿Estás seguro de eliminar permanentemente "$nombre"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final asignaturaService = Provider.of<AsignaturaService>(context, listen: false);
        await asignaturaService.eliminarAsignatura(id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asignatura eliminada'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
