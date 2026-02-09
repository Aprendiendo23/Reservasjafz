import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/recurso_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/card_recurso.dart';

class AdminRecursosScreen extends StatefulWidget {
  const AdminRecursosScreen({super.key});

  @override
  State<AdminRecursosScreen> createState() => _AdminRecursosScreenState();
}

class _AdminRecursosScreenState extends State<AdminRecursosScreen> {
  Future<void> _inicializarRecursosPorDefecto(BuildContext context) async {
    final recursoService = Provider.of<RecursoService>(context, listen: false);
    
    try {
      // Verificar si existen los recursos por defecto
      final recursos = await recursoService.recursosCollection.get();
      final nombresExistentes = recursos.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['nombre'] as String?)
          .where((nombre) => nombre != null)
          .toSet();
      
      // Lista de recursos por defecto que deben existir (5 recursos)
      final recursosDefault = [
        'Laptop',
        'Laptop y Proyector',
        'Tablet, laptop y Proyector',
        'Tablet',
        'Proyector',
      ];
      final faltanRecursos = recursosDefault.any((nombre) => !nombresExistentes.contains(nombre));
      
      // Si faltan recursos por defecto, crearlos
      if (faltanRecursos) {
        await recursoService.crearRecursosPorDefecto();
      }
    } catch (e) {
      // Si hay error, continuar de todas formas
      print('Error al inicializar recursos por defecto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recursoService = Provider.of<RecursoService>(context);
    final authService = Provider.of<AuthService>(context);

    if (!authService.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: const Center(
          child: Text('No tienes permisos de administrador'),
        ),
      );
    }

    // Inicializar recursos por defecto al construir el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarRecursosPorDefecto(context);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Recursos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddResourceDialog(context, recursoService),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Recurso'),
      ),
      body: StreamBuilder(
        stream: recursoService.getRecursos(),
        builder: (context, snapshot) {
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
                  const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay recursos',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
          
          return ListView.builder(
            padding: isLandscape
                ? const EdgeInsets.fromLTRB(8, 4, 8, 48)
                : const EdgeInsets.fromLTRB(16, 16, 16, 48),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final resourceId = doc.id;

              return CardRecurso(
                recursoId: resourceId,
                nombre: data['nombre'] ?? 'Sin nombre',
                descripcion: data['descripcion'] ?? '',
                estado: data['estado'] ?? 'inactivo',
                onEdit: () => _showEditResourceDialog(
                  context,
                  recursoService,
                  resourceId,
                  data,
                ),
                onDelete: () => _showDeleteConfirmDialog(
                  context,
                  recursoService,
                  resourceId,
                  data['nombre'] ?? 'Recurso',
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddResourceDialog(BuildContext context, RecursoService service) {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    String estado = 'activo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo Recurso'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Recurso *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: estado,
                  decoration: const InputDecoration(
                    labelText: 'Estado *',
                    border: OutlineInputBorder(),
                  ),
                  items: ['activo', 'inactivo']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => estado = value);
                    }
                  },
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
              onPressed: () async {
                if (nombreController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre es requerido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await service.crearRecurso({
                    'nombre': nombreController.text.trim(),
                    'descripcion': descripcionController.text.trim(),
                    'estado': estado,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recurso creado exitosamente'),
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
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditResourceDialog(
    BuildContext context,
    RecursoService service,
    String resourceId,
    Map<String, dynamic> data,
  ) {
    final nombreController = TextEditingController(text: data['nombre'] ?? '');
    final descripcionController =
        TextEditingController(text: data['descripcion'] ?? '');
    String estado = data['estado'] ?? 'activo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Recurso'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Recurso *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: estado,
                  decoration: const InputDecoration(
                    labelText: 'Estado *',
                    border: OutlineInputBorder(),
                  ),
                  items: ['activo', 'inactivo']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => estado = value);
                    }
                  },
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
              onPressed: () async {
                if (nombreController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre es requerido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await service.actualizarRecurso(resourceId, {
                    'nombre': nombreController.text.trim(),
                    'descripcion': descripcionController.text.trim(),
                    'estado': estado,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recurso actualizado exitosamente'),
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
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    RecursoService service,
    String resourceId,
    String nombre,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Recurso'),
        content: Text('¿Estás seguro de eliminar "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await service.eliminarRecurso(resourceId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recurso eliminado exitosamente'),
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

}

