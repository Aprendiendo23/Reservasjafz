import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLogin = true; // true para login, false para registro

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (_isLogin) {
        await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        // Redirigir según el rol del usuario
        if (authService.isAdmin) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.adminHome);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.homeDocente);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        final lower = errorMessage.toLowerCase();
        if (lower.contains('client is offline') ||
            lower.contains('cloud_firestore/unavailable') ||
            lower.contains('[cloud_firestore/unavailable]') ||
            lower.contains('unavailable') ||
            lower.contains('offline') ||
            lower.contains('network') ||
            lower.contains('connection') ||
            lower.contains('internet')) {
          errorMessage =
              'Sin conexión a Internet. Revisa tu red y vuelve a intentar.';
        }

        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error de autenticación'),
              content: Text(
                errorMessage,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithGoogle();

      if (mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        // Redirigir según el rol del usuario
        if (authService.isAdmin) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.adminHome);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.homeDocente);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        final lower = errorMessage.toLowerCase();
        if (lower.contains('client is offline') ||
            lower.contains('cloud_firestore/unavailable') ||
            lower.contains('[cloud_firestore/unavailable]') ||
            lower.contains('unavailable') ||
            lower.contains('offline') ||
            lower.contains('network') ||
            lower.contains('connection') ||
            lower.contains('internet')) {
          errorMessage =
              'Sin conexión a Internet. Revisa tu red y vuelve a intentar.';
        }

        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error al iniciar sesión con Google'),
              content: Text(
                errorMessage,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu email primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_emailController.text.trim().contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un email válido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Correo enviado'),
              content: const Text(
                'Se ha enviado un email para recuperar tu contraseña.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error al recuperar contraseña'),
              content: Text(
                e.toString(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu email';
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
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse'),
                  ),
                  if (_isLogin) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_isLogin) ...[
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('O'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.login, size: 20);
                        },
                      ),
                      label: const Text('Continuar con Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextButton(
                    onPressed: () {
                      setState(() => _isLogin = !_isLogin);
                    },
                    child: Text(
                      _isLogin
                          ? '¿No tienes cuenta? Regístrate'
                          : '¿Ya tienes cuenta? Inicia sesión',
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.loginAdmin);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.admin_panel_settings, size: 20),
                        SizedBox(width: 8),
                        Text('Entrar como administrador'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

