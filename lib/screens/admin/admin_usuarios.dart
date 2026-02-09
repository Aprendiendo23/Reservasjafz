import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/usuario_service.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rolController = TextEditingController();
  String _rolSeleccionado = 'docente';
  bool _mostrarPassword = false; // Para mostrar/ocultar contraseña

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuarioService = Provider.of<UsuarioService>(context);
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
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar nuevo usuario',
            onPressed: () => _mostrarDialogoCrearUsuario(context, authService),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: usuarioService.getUsuarios(),
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
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No hay usuarios registrados',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _mostrarDialogoCrearUsuario(context, authService),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Primer Usuario'),
                  ),
                ],
              ),
            );
          }

          final usuarios = snapshot.data!.docs;

          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
          
          return ListView.builder(
            padding: isLandscape
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                : Responsive.padding(context),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final doc = usuarios[index];
              final data = doc.data() as Map<String, dynamic>;
              final nombre = data['nombre'] ?? 'Usuario';
              final email = data['email'] ?? '';
              final foto = data['foto'] as String?;
              final creado = data['creado'] as Timestamp?;
              final rol = data['rol'] ?? 'docente';
              final userId = doc.id;

              // Corregir el error del substring
              final inicial = nombre.isNotEmpty 
                  ? nombre.substring(0, nombre.length > 1 ? 1 : nombre.length).toUpperCase()
                  : 'U';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: foto != null && foto.isNotEmpty
                        ? NetworkImage(foto)
                        : null,
                    backgroundColor: foto == null || foto.isEmpty
                        ? Theme.of(context).primaryColor
                        : null,
                    child: foto == null || foto.isEmpty
                        ? Text(
                            inicial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(email),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: rol == 'admin' 
                                  ? Colors.red.shade100 
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              rol.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: rol == 'admin' 
                                    ? Colors.red.shade900 
                                    : Colors.blue.shade900,
                              ),
                            ),
                          ),
                          if (creado != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Registrado: ${DateFormat('dd/MM/yyyy').format(creado.toDate())}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'editar':
                          _mostrarDialogoEditarUsuario(
                            context,
                            authService,
                            usuarioService,
                            userId,
                            nombre,
                            email,
                            rol,
                          );
                          break;
                        case 'cambiar_password':
                          _mostrarDialogoCambiarPassword(context, email);
                          break;
                        case 'cambiar_email':
                          _mostrarDialogoCambiarEmail(
                            context,
                            authService,
                            usuarioService,
                            userId,
                            email,
                          );
                          break;
                        case 'eliminar':
                          _mostrarDialogoEliminarUsuario(
                            context,
                            authService,
                            usuarioService,
                            userId,
                            nombre,
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'cambiar_password',
                        child: Row(
                          children: [
                            Icon(Icons.lock_reset, size: 20),
                            SizedBox(width: 8),
                            Text('Cambiar Contraseña'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'cambiar_email',
                        child: Row(
                          children: [
                            Icon(Icons.email, size: 20),
                            SizedBox(width: 8),
                            Text('Cambiar Email'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _mostrarDialogoCrearUsuario(BuildContext context, AuthService authService) {
    _nombreController.clear();
    _emailController.clear();
    _passwordController.clear();
    _rolSeleccionado = 'docente';
    _mostrarPassword = false; // Resetear el estado de mostrar contraseña

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Crear Nuevo Usuario'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El email es requerido';
                    }
                    if (!value.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          _mostrarPassword = !_mostrarPassword;
                        });
                      },
                      tooltip: _mostrarPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                    ),
                  ),
                  obscureText: !_mostrarPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es requerida';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _rolSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'docente', child: Text('Docente')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      _rolSeleccionado = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  // Guardar información del admin actual
                  final adminEmail = authService.user?.email;
                  
                  // Crear el nuevo usuario
                  await authService.crearUsuarioAdmin(
                    email: _emailController.text.trim(),
                    password: _passwordController.text,
                    nombre: _nombreController.text.trim(),
                    rol: _rolSeleccionado,
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    
                    // Mostrar diálogo con la información del usuario creado
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title: const Text('Usuario Creado Exitosamente'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('El usuario ha sido creado. Información:'),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Nombre: ${_nombreController.text.trim()}'),
                                    const SizedBox(height: 8),
                                    Text('Email: ${_emailController.text.trim()}'),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Text('Contraseña: '),
                                        Expanded(
                                          child: SelectableText(
                                            _passwordController.text,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Rol: ${_rolSeleccionado == 'admin' ? 'Administrador' : 'Docente'}'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Nota: Deberás volver a iniciar sesión como administrador.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login-admin',
                                (route) => false,
                              );
                            },
                            child: const Text('Ir a Login'),
                          ),
                        ],
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
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
      ),
    );
  }

  void _mostrarDialogoEditarUsuario(
    BuildContext context,
    AuthService authService,
    UsuarioService usuarioService,
    String userId,
    String nombreActual,
    String emailActual,
    String rolActual,
  ) {
    final nombreController = TextEditingController(text: nombreActual);
    String rolSeleccionado = rolActual;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: rolSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'docente', child: Text('Docente')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      rolSeleccionado = value!;
                    });
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
                try {
                  await usuarioService.actualizarNombreUsuario(
                    userId,
                    nombreController.text.trim(),
                  );
                  await usuarioService.guardarUsuario(userId, {
                    'rol': rolSeleccionado,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Usuario actualizado exitosamente'),
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

  void _mostrarDialogoCambiarPassword(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se enviará un email de recuperación de contraseña a:'),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El usuario recibirá un email para restablecer su contraseña',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.resetPassword(email);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Se envió un email de recuperación a $email'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
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
            child: const Text('Enviar Email'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCambiarEmail(
    BuildContext context,
    AuthService authService,
    UsuarioService usuarioService,
    String userId,
    String emailActual,
  ) {
    final emailController = TextEditingController(text: emailActual);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email actual: $emailActual'),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Nuevo email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await authService.cambiarEmailUsuario(
                  emailActual,
                  emailController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email cambiado exitosamente'),
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
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEliminarUsuario(
    BuildContext context,
    AuthService authService,
    UsuarioService usuarioService,
    String userId,
    String nombre,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de eliminar al usuario "$nombre"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await authService.eliminarUsuario(userId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Usuario eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e\nNota: Para eliminar usuarios de Firebase Auth, se requiere Firebase Admin SDK en el backend.'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
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
