import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/boton.dart';
import '../../widgets/campo.dart';
import '../../utils/responsive.dart';

class LoginMainScreen extends StatefulWidget {
  const LoginMainScreen({super.key});

  @override
  State<LoginMainScreen> createState() => _LoginMainScreenState();
}

class _LoginMainScreenState extends State<LoginMainScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _recordarUsuario = false;

  @override
  void initState() {
    super.initState();
    _cargarUsuarioGuardado();
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Cargar usuario y contraseña guardados al iniciar
  Future<void> _cargarUsuarioGuardado() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioGuardado = prefs.getString('usuario_guardado');
      final passwordGuardado = prefs.getString('password_guardado');
      final recordarUsuario = prefs.getBool('recordar_usuario') ?? false;
      
      if (usuarioGuardado != null && recordarUsuario) {
        setState(() {
          _usuarioController.text = usuarioGuardado;
          if (passwordGuardado != null) {
            _passwordController.text = passwordGuardado;
          }
          _recordarUsuario = true;
        });
      }
    } catch (e) {
      print('Error al cargar usuario guardado: $e');
    }
  }

  // Guardar o eliminar usuario y contraseña guardados
  Future<void> _guardarUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_recordarUsuario) {
        await prefs.setString('usuario_guardado', _usuarioController.text.trim());
        await prefs.setString('password_guardado', _passwordController.text);
        await prefs.setBool('recordar_usuario', true);
      } else {
        await prefs.remove('usuario_guardado');
        await prefs.remove('password_guardado');
        await prefs.setBool('recordar_usuario', false);
      }
    } catch (e) {
      print('Error al guardar usuario: $e');
    }
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    // Verificar que Firebase esté inicializado
    try {
      final app = Firebase.app();
      // Si llegamos aquí, Firebase está inicializado
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se puede conectar a Firebase. Por favor verifica tu conexión a internet.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Autenticar con username y contraseña
      await authService.signInWithUsernameAndPassword(
        _usuarioController.text.trim(),
        _passwordController.text,
      );

      final user = authService.user;
      if (user != null) {
        // Guardar usuario si está marcado recordar
        await _guardarUsuario();
        
        if (mounted) {
          // Esperar un momento para que AuthService actualice el estado
          await Future.delayed(const Duration(milliseconds: 300));
          
          // Redirigir según el rol (admin o docente)
          if (authService.isAdmin) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.adminHome);
          } else {
            Navigator.of(context).pushReplacementNamed(AppRoutes.homeDocente);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Limpiar el mensaje de error
        if (errorMessage.contains('Usuario no encontrado')) {
          errorMessage = 'Usuario no encontrado';
        } else if (errorMessage.contains('wrong-password') || errorMessage.contains('Contraseña incorrecta')) {
          errorMessage = 'Contraseña incorrecta';
        } else if (errorMessage.contains('network') || 
            errorMessage.contains('connection') ||
            errorMessage.contains('internet') ||
            errorMessage.contains('Firebase')) {
          errorMessage = 'No se puede conectar a Firebase. Por favor verifica tu conexión a internet.';
        } else if (errorMessage.contains('user-not-found')) {
          errorMessage = 'Usuario no encontrado';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.secondary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: Responsive.padding(context),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.isMobile(context) 
                      ? double.infinity 
                      : Responsive.maxContentWidth(context),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Icono con fondo decorativo
                      Container(
                        padding: EdgeInsets.all(
                          Responsive.isMobile(context) ? 20 : 24,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.event_available,
                          size: Responsive.iconSize(context, 64),
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: Responsive.isMobile(context) ? 24 : 32),
                      Text(
                        'Iniciar Sesión',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              letterSpacing: -0.5,
                              fontSize: Responsive.fontSize(context, 28),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: Responsive.isMobile(context) ? 6 : 8),
                      Text(
                        'Ingresa tus credenciales para acceder',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey.shade600,
                              fontSize: Responsive.fontSize(context, 16),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: Responsive.isMobile(context) ? 24 : 40),
                      Campo(
                        label: 'Usuario',
                        controller: _usuarioController,
                        keyboardType: TextInputType.text,
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu usuario';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Campo(
                        label: 'Contraseña',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Checkbox para recordar usuario
                      Row(
                        children: [
                          Checkbox(
                            value: _recordarUsuario,
                            onChanged: (value) {
                              setState(() {
                                _recordarUsuario = value ?? false;
                              });
                            },
                          ),
                          const Text(
                            'Recordar usuario',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Boton(
                        texto: 'Acceder',
                        onPressed: _handleAuth,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
