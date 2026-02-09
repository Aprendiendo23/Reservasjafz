import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/usuario_service.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final usuarioService = Provider.of<UsuarioService>(context);
    final user = authService.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: user == null
          ? const Center(child: Text('Usuario no autenticado'))
          : StreamBuilder(
              stream: usuarioService.getUsuarioActualStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Usuario no encontrado'));
                }

                final usuarioData = snapshot.data!.data() as Map<String, dynamic>?;
                final nombre = usuarioData?['nombre'] ?? user.displayName ?? 'Usuario';
                final nombreInicial = nombre.isNotEmpty ? nombre : 'Usuario';

                // Obtener inicial de forma segura
                String getInicial(String texto) {
                  if (texto.isEmpty) return 'U';
                  return texto.trim().substring(0, 1).toUpperCase();
                }

                // Obtener inicial del email si no hay nombre
                String inicialAvatar = getInicial(nombreInicial);
                if (nombreInicial == 'Usuario' && user.email != null && user.email!.isNotEmpty) {
                  inicialAvatar = getInicial(user.email!);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                backgroundImage: (user.photoURL != null && user.photoURL!.isNotEmpty)
                                    ? NetworkImage(user.photoURL!)
                                    : null,
                                child: (user.photoURL == null || user.photoURL!.isEmpty)
                                    ? Text(
                                        inicialAvatar,
                                        style: const TextStyle(fontSize: 32),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                nombreInicial,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user.email ?? '',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                              if (authService.isAdmin) ...[
                                const SizedBox(height: 8),
                                Chip(
                                  label: const Text('Administrador'),
                                  backgroundColor: Colors.red.shade100,
                                  labelStyle: TextStyle(color: Colors.red.shade900),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Nombre Completo'),
                        subtitle: Text(nombreInicial),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editarNombre(context, usuarioService, nombreInicial),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(user.email ?? 'No disponible'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.verified_user),
                        title: const Text('Email Verificado'),
                        subtitle: Text(user.emailVerified ? 'Sí' : 'No'),
                        trailing: user.emailVerified
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.cancel, color: Colors.red),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cerrar Sesión'),
                              content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Cerrar Sesión'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            try {
                              await authService.signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRoutes.loginMain,
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al cerrar sesión: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _editarNombre(
    BuildContext context,
    UsuarioService usuarioService,
    String nombreActual,
  ) async {
    final controller = TextEditingController(text: nombreActual);

    final nuevoNombre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Nombre Completo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre Completo',
            hintText: 'Ingresa tu nombre completo',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nombre = controller.text.trim();
              if (nombre.isNotEmpty) {
                Navigator.pop(context, nombre);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El nombre no puede estar vacío'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevoNombre != null && nuevoNombre != nombreActual) {
      setState(() => _cargando = true);

      try {
        await usuarioService.actualizarNombre(nuevoNombre);
        if (context.mounted) {
          setState(() => _cargando = false);
          // Mostrar diálogo flotante centrado
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
                      'Nombre actualizado correctamente',
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
          // No es necesario recargar manualmente, el StreamBuilder se actualizará automáticamente
        }
      } catch (e) {
        if (context.mounted) {
          setState(() => _cargando = false);
          // Mostrar diálogo de error centrado
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
                      Icons.error,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al actualizar nombre: $e',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
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
      }
    }
  }
}




