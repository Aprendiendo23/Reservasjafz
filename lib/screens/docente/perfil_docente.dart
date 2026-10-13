import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/usuario_service.dart';
import '../../routes/app_routes.dart';

class PerfilDocenteScreen extends StatefulWidget {
  const PerfilDocenteScreen({super.key});

  @override
  State<PerfilDocenteScreen> createState() => _PerfilDocenteScreenState();
}

class _PerfilDocenteScreenState extends State<PerfilDocenteScreen> {
  bool _cargando = false;

  // Mapeo de emails a nombres por defecto (mismo que en crear_reserva.dart)
  final Map<String, String> _emailANombre = {
    'Marlon_Rod@gmail.com': 'Marlon Rodríguez',
    'Marling_Re@gmail.com': 'Marling Requene',
    'Elba_R@gmail.com': 'Elba Ruth Calero',
    'Hollman_N@gmail.com': 'Hollman Ñamendi',
    'Judith_Riv@gmail.com': 'Judith Rivas',
    'Martin_Lo@gmail.com': 'Martin López',
    'Marlon_Rui@gmail.com': 'Marlon Ruiz',
    'Ali_lo@gmail.com': 'Ali López',
    'Director_G@gmail.com': 'Director Guillermo Martinez',
    'Subdirector_E@gmail.com': 'Subdirector Edwin Prado',
    'Yader_Lati@gmail.com': 'Yader Latino',
  };

  // Obtener nombre por defecto basado en el email
  String? _obtenerNombrePorDefecto(String email) {
    // Buscar coincidencia exacta
    if (_emailANombre.containsKey(email)) {
      return _emailANombre[email];
    }
    
    // Buscar coincidencia parcial (por si el email tiene variaciones)
    for (final entry in _emailANombre.entries) {
      if (email.toLowerCase().contains(entry.key.toLowerCase().split('@')[0])) {
        return entry.value;
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final usuarioService = Provider.of<UsuarioService>(context);
    final user = authService.user;

    // Si no hay usuario autenticado, redirigir al login
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.loginMain,
            (route) => false,
          );
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: StreamBuilder(
        stream: usuarioService.getUsuarioActualStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Si el usuario no existe en Firestore, crearlo automáticamente
          if (!snapshot.hasData || !snapshot.data!.exists) {
            // Crear el usuario automáticamente
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted && user != null) {
                try {
                  // Obtener nombre por defecto basado en el email
                  String? nombrePorDefecto = user.email != null 
                      ? _obtenerNombrePorDefecto(user.email!) 
                      : null;
                  
                  // Determinar el nombre a usar
                  String nombre = nombrePorDefecto ?? 
                                  user.displayName ?? 
                                  (user.email?.split('@')[0] ?? 'Usuario');
                  
                  // Crear el usuario en Firestore
                  await usuarioService.guardarUsuario(user.uid, {
                    'nombre': nombre,
                    'email': user.email ?? '',
                    'rol': 'docente',
                    'foto': user.photoURL ?? '',
                    'usuario': user.email ?? '',
                  });
                  
                  // El StreamBuilder se actualizará automáticamente
                } catch (e) {
                  print('Error al crear usuario automáticamente: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al crear perfil: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            });
            
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creando perfil...'),
                ],
              ),
            );
          }

          final usuarioData = snapshot.data!.data() as Map<String, dynamic>?;
          final rol = usuarioData?['rol'] ?? 'docente';
          String? nombreGuardado = usuarioData?['nombre'] as String?;
          
          // Obtener el nombre por defecto basado en el email
          String? nombrePorDefecto = user.email != null ? _obtenerNombrePorDefecto(user.email!) : null;
          
          // Priorizar el nombre guardado en Firestore, luego el nombre por defecto, luego displayName
          String nombre = nombreGuardado ?? nombrePorDefecto ?? user.displayName ?? 'Usuario';
          final nombreInicial = nombre.isNotEmpty ? nombre : 'Usuario';
          
          // Guardar el nombre por defecto para mostrarlo como referencia (solo si hay nombre guardado diferente)
          final nombrePorDefectoMostrar = (nombreGuardado != null && nombrePorDefecto != null && nombreGuardado != nombrePorDefecto)
              ? nombrePorDefecto
              : null;

          // Obtener primera letra de forma segura
          String getInicial(String texto) {
            if (texto.isEmpty) return 'U';
            return texto.trim().substring(0, 1).toUpperCase();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información del usuario (estilo similar al admin)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: (user.photoURL != null && user.photoURL!.isNotEmpty)
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: (user.photoURL == null || user.photoURL!.isEmpty)
                              ? Text(
                                  getInicial(nombreInicial),
                                  style: const TextStyle(fontSize: 24),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombreInicial,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email ?? '',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                              if (rol == 'admin') ...[
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Información del perfil (estilo como admin)
                const Text(
                  'Información del Perfil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  context,
                  'Nombre Completo',
                  nombreInicial,
                  Icons.person,
                  Colors.blue,
                  () => _editarNombre(context, usuarioService, nombreInicial),
                  showEdit: true,
                  subtitleAdicional: nombrePorDefectoMostrar != null
                      ? 'Nombre por defecto: $nombrePorDefectoMostrar'
                      : null,
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  'Email',
                  user.email ?? 'No disponible',
                  Icons.email,
                  Colors.green,
                  null,
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  'Email Verificado',
                  user.emailVerified ? 'Sí' : 'No',
                  Icons.verified_user,
                  user.emailVerified ? Colors.green : Colors.orange,
                  null,
                  trailing: user.emailVerified
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.cancel, color: Colors.red),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  'Rol',
                  rol == 'admin' ? 'Administrador' : 'Docente',
                  Icons.badge,
                  Colors.teal,
                  null,
                ),
                const SizedBox(height: 24),
                // Cerrar sesión
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout, color: Colors.red, size: 28),
                    ),
                    title: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    subtitle: const Text('Salir de tu cuenta'),
                    trailing: const Icon(Icons.arrow_forward_ios),
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
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Salir'),
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
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.loginMain,
                              (route) => false,
                            );
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al cerrar sesión: $e'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            });
                          }
                        }
                      }
                    },
                  ),
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

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    bool showEdit = false,
    String? subtitleAdicional,
    Widget? trailing,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: subtitleAdicional != null && subtitleAdicional.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subtitle),
                  const SizedBox(height: 4),
                  Text(
                    subtitleAdicional,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            : Text(subtitle),
        trailing: trailing ?? (showEdit ? const Icon(Icons.edit) : (onTap != null ? const Icon(Icons.arrow_forward_ios) : null)),
        onTap: onTap,
      ),
    );
  }
}
