import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/grado_service.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';

class AdminGradosScreen extends StatefulWidget {
  const AdminGradosScreen({super.key});

  @override
  State<AdminGradosScreen> createState() => _AdminGradosScreenState();
}

class _AdminGradosScreenState extends State<AdminGradosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  String? _gradoEditandoId;
  bool _ocultandoInactivos = false; // Por defecto mostrar todos, toggle para ocultar inactivos

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final gradoService = Provider.of<GradoService>(context);

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
        title: const Text('Gestión de Grados/Aulas'),
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
            tooltip: 'Crear nuevo grado/aula',
            onPressed: () => _mostrarDialogoCrearOEditarGrado(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de grados
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: gradoService.getTodosLosGrados(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                // Filtrar grados según el toggle
                final todosLosGrados = snapshot.data?.docs ?? [];
                final gradosFiltrados = _ocultandoInactivos
                    ? todosLosGrados.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['activo'] != false; // Mostrar solo activos
                      }).toList()
                    : todosLosGrados; // Mostrar todos
                
                // Ordenar por "orden" (si existe) y luego por nombre
                final grados = gradosFiltrados..sort((a, b) {
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

                if (grados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.class_, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _ocultandoInactivos
                              ? 'No hay grados/aulas activos'
                              : 'No hay grados/aulas registrados',
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
                  itemCount: grados.length,
                  itemBuilder: (context, index) {
                    final grado = grados[index];
                    final data = grado.data() as Map<String, dynamic>;
                    final nombre = data['nombre'] ?? 'Sin nombre';
                    final activo = data['activo'] ?? true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: activo ? null : Colors.grey.shade200,
                      child: ListTile(
                        leading: Icon(
                          Icons.class_,
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
                            // Botones para mover el grado arriba/abajo en el orden
                            IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              tooltip: 'Mover arriba',
                              onPressed: index == 0
                                  ? null
                                  : () => _moverGrado(index, -1, grados),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward),
                              tooltip: 'Mover abajo',
                              onPressed: index == grados.length - 1
                                  ? null
                                  : () => _moverGrado(index, 1, grados),
                            ),
                            if (activo)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: Colors.blue,
                                onPressed: () => _mostrarDialogoCrearOEditarGrado(
                                  context,
                                  id: grado.id,
                                  nombreInicial: nombre,
                                ),
                              ),
                            IconButton(
                              icon: Icon(activo ? Icons.block : Icons.check_circle),
                              color: activo ? Colors.orange : Colors.green,
                              onPressed: () => activo
                                  ? _desactivarGrado(grado.id, nombre)
                                  : _activarGrado(grado.id, nombre),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _eliminarGrado(grado.id, nombre),
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

  /// Mover un grado en la lista (delta = -1 arriba, +1 abajo) y
  /// actualizar el campo "orden" en Firestore para todos los grados.
  Future<void> _moverGrado(int index, int delta, List<QueryDocumentSnapshot> gradosActuales) async {
    final nuevoIndex = index + delta;
    if (nuevoIndex < 0 || nuevoIndex >= gradosActuales.length) return;

    // Crear una nueva lista con el orden modificado
    final nuevaLista = List<QueryDocumentSnapshot>.from(gradosActuales);
    final item = nuevaLista.removeAt(index);
    nuevaLista.insert(nuevoIndex, item);

    // Construir mapa id -> orden
    final Map<String, int> ordenes = {};
    for (int i = 0; i < nuevaLista.length; i++) {
      ordenes[nuevaLista[i].id] = i;
    }

    try {
      final gradoService = Provider.of<GradoService>(context, listen: false);
      await gradoService.actualizarOrdenes(ordenes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reordenar grados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoCrearOEditarGrado(BuildContext context, {String? id, String? nombreInicial}) {
    if (id == null) {
      // Crear
      _gradoEditandoId = null;
      _nombreController.clear();
    } else {
      // Editar
      _gradoEditandoId = id;
      _nombreController.text = nombreInicial ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Crear Nuevo Grado/Aula' : 'Editar Grado/Aula'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre del Grado/Aula *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.class_),
              hintText: 'Ej: 7A, 8B, 10A',
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
                await _crearGrado();
              } else {
                await _actualizarGrado();
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

  Future<void> _crearGrado() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final gradoService = Provider.of<GradoService>(context, listen: false);
      await gradoService.crearGrado(_nombreController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grado/aula creado exitosamente'),
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

  Future<void> _actualizarGrado() async {
    if (!_formKey.currentState!.validate() || _gradoEditandoId == null) return;

    try {
      final gradoService = Provider.of<GradoService>(context, listen: false);
      await gradoService.actualizarGrado(_gradoEditandoId!, _nombreController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grado/aula actualizado exitosamente'),
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

  void _editarGrado(String id, String nombre) {
    setState(() {
      _gradoEditandoId = id;
      _nombreController.text = nombre;
    });
  }

  void _cancelarEdicion() {
    setState(() {
      _gradoEditandoId = null;
      _nombreController.clear();
    });
  }

  Future<void> _desactivarGrado(String id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar Grado/Aula'),
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
        final gradoService = Provider.of<GradoService>(context, listen: false);
        await gradoService.desactivarGrado(id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grado/aula desactivado'),
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

  Future<void> _activarGrado(String id, String nombre) async {
    try {
      final gradoService = Provider.of<GradoService>(context, listen: false);
      await gradoService.activarGrado(id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grado/aula activado'),
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

  Future<void> _eliminarGrado(String id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Grado/Aula'),
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
        final gradoService = Provider.of<GradoService>(context, listen: false);
        await gradoService.eliminarGrado(id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grado/aula eliminado'),
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

