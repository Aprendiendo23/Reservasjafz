import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'fcm_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  User? _user;
  bool _isAdmin = false;
  bool _isCheckingAdmin = false; // Flag para evitar mostrar estado incorrecto

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _isAdmin;
  bool get isCheckingAdmin => _isCheckingAdmin; // Para mostrar loading si es necesario

  AuthService() {
    // Obtener usuario actual inmediatamente
    _user = _auth.currentUser;
    
    // Escuchar cambios en el estado de autenticación
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        try {
          _isCheckingAdmin = true;
          notifyListeners(); // Notificar que estamos verificando
          await _checkAdminStatus(user.uid);
          
          // Inicializar FCM cuando el usuario inicia sesión
          try {
            final fcmService = FCMService();
            await fcmService.initialize();
            print('✅ FCM inicializado para usuario: ${user.uid}');
          } catch (e) {
            print('⚠️ Error al inicializar FCM: $e');
          }
        } catch (e) {
          print('Error al verificar admin status: $e');
          _isAdmin = false;
        } finally {
          _isCheckingAdmin = false;
          notifyListeners();
        }
      } else {
        _isAdmin = false;
        _isCheckingAdmin = false;
        notifyListeners();
      }
    });
    
    // Si hay usuario actual, verificar su estado INMEDIATAMENTE y esperar
    if (_user != null) {
      _isCheckingAdmin = true;
      _checkAdminStatus(_user!.uid).then((_) {
        _isCheckingAdmin = false;
        notifyListeners();
      }).catchError((e) {
        print('Error al verificar admin status inicial: $e');
        _isAdmin = false;
        _isCheckingAdmin = false;
        notifyListeners();
      });
    }
  }

  // Verificar si el usuario es administrador (nueva estructura con usuarios/rol)
  Future<void> _checkAdminStatus(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final nuevoEstadoAdmin = data?['rol'] == 'admin';
        // Solo actualizar si el estado cambió para evitar notificaciones innecesarias
        if (_isAdmin != nuevoEstadoAdmin) {
          _isAdmin = nuevoEstadoAdmin;
          notifyListeners();
        } else {
          _isAdmin = nuevoEstadoAdmin;
        }
      } else {
        // Si el usuario no existe en usuarios, crearlo como docente
        if (_user != null) {
          await _firestore.collection('usuarios').doc(uid).set({
            'nombre': _user!.displayName ?? _user!.email ?? 'Usuario',
            'email': _user!.email ?? '',
            'rol': 'docente',
            'foto': _user!.photoURL ?? '',
            'creado': FieldValue.serverTimestamp(),
          });
        }
        if (_isAdmin != false) {
          _isAdmin = false;
          notifyListeners();
        } else {
          _isAdmin = false;
        }
      }
    } catch (e) {
      print('Error en _checkAdminStatus: $e');
      if (_isAdmin != false) {
        _isAdmin = false;
        notifyListeners();
      } else {
        _isAdmin = false;
      }
    }
  }

  // Verificar si un email es administrador (para login admin)
  Future<bool> verificarAdmin(String email) async {
    try {
      final query = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .where('rol', isEqualTo: 'admin')
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Buscar usuario por username o email y obtener su email
  Future<Map<String, dynamic>?> buscarUsuarioPorUsername(String username) async {
    try {
      // Primero intentar buscar por el campo 'usuario'
      var query = await _firestore
          .collection('usuarios')
          .where('usuario', isEqualTo: username)
          .limit(1)
          .get();
      
      // Si no se encuentra, intentar buscar por email
      if (query.docs.isEmpty) {
        query = await _firestore
            .collection('usuarios')
            .where('email', isEqualTo: username)
            .limit(1)
            .get();
      }
      
      if (query.docs.isEmpty) {
        return null;
      }
      
      final doc = query.docs.first;
      final data = doc.data();
      return {
        'email': data['email'] as String?,
        'rol': data['rol'] as String?,
        'nombre': data['nombre'] as String?,
        'usuario': data['usuario'] as String?,
      };
    } catch (e) {
      print('Error al buscar usuario por username: $e');
      return null;
    }
  }

  // Iniciar sesión con username y contraseña (unificado para admin y docentes)
  Future<UserCredential?> signInWithUsernameAndPassword(
    String username,
    String password,
  ) async {
    try {
      String email = username;
      
      // Primero intentar buscar el usuario en Firestore por username
      final usuarioData = await buscarUsuarioPorUsername(username);
      
      // Si se encuentra en Firestore, usar ese email
      if (usuarioData != null && usuarioData['email'] != null) {
        email = usuarioData['email'] as String;
      }
      // Si no se encuentra en Firestore pero el username parece un email, intentar autenticarse directamente
      else if (username.contains('@')) {
        email = username;
      }
      // Si no es un email y no está en Firestore, no se puede autenticar
      else {
        throw 'Usuario no encontrado';
      }
      
      // Autenticar con Firebase Auth usando el email
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Después de autenticarse exitosamente, asegurar que existe en Firestore
      if (credential.user != null) {
        final user = credential.user!;
        final userDoc = await _firestore.collection('usuarios').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // Si no existe en Firestore, crearlo
          // Determinar el rol: admin si el email contiene "admin" o es admin@gmail.com, docente para los demás
          final emailLower = email.toLowerCase();
          final rol = (emailLower == 'admin@gmail.com' || 
                      emailLower.contains('admin@') ||
                      emailLower.startsWith('admin')) 
                      ? 'admin' : 'docente';
          
          // Extraer nombre del email (parte antes del @)
          final nombre = user.displayName ?? 
                        email.split('@')[0].replaceAll('_', ' ').replaceAll('.', ' ');
          
          await _firestore.collection('usuarios').doc(user.uid).set({
            'nombre': nombre,
            'email': email,
            'usuario': email, // Usar el email como usuario también
            'rol': rol,
            'foto': user.photoURL ?? '',
            'creado': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          // Si existe, actualizar el campo 'usuario' si no está presente
          final data = userDoc.data() as Map<String, dynamic>?;
          if (data != null && !data.containsKey('usuario')) {
            await _firestore.collection('usuarios').doc(user.uid).update({
              'usuario': email,
            });
          }
        }
        
        // Verificar estado de admin después del login
        await _checkAdminStatus(user.uid);
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e.toString().contains('Usuario no encontrado')) {
        throw 'Usuario no encontrado';
      }
      throw 'Error inesperado: $e';
    }
  }

  // Iniciar sesión con email y contraseña (para docentes)
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Verificar estado de admin después del login
      if (credential.user != null) {
        await _checkAdminStatus(credential.user!.uid);
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  // Iniciar sesión como administrador (con validación)
  Future<UserCredential?> signInAsAdmin(
    String email,
    String password,
  ) async {
    try {
      // Primero verificar que el email es de un administrador
      final esAdmin = await verificarAdmin(email);
      if (!esAdmin) {
        throw 'Este correo no está autorizado como administrador';
      }

      // Si es admin, proceder con el login
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verificar nuevamente después del login
      if (credential.user != null) {
        await _checkAdminStatus(credential.user!.uid);
        if (!_isAdmin) {
          await _auth.signOut();
          throw 'No tienes permisos de administrador';
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Iniciar sesión con Google (para docentes)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Iniciar el flujo de autenticación de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw 'Se canceló el inicio de sesión con Google';
      }

      // Obtener los detalles de autenticación del usuario de Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Crear una nueva credencial
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase con la credencial de Google
      final userCredential = await _auth.signInWithCredential(credential);

      // Crear o actualizar usuario en Firestore
      if (userCredential.user != null) {
        final user = userCredential.user!;
        await _firestore.collection('usuarios').doc(user.uid).set({
          'nombre': user.displayName ?? user.email!.split('@')[0],
          'email': user.email ?? '',
          'rol': 'docente',
          'foto': user.photoURL ?? '',
          'creado': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await _checkAdminStatus(user.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al iniciar sesión con Google: $e';
    }
  }

  // Recuperar contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al enviar el email de recuperación: $e';
    }
  }

  // Registrar nuevo usuario
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Crear usuario en Firestore
      if (credential.user != null) {
        await _firestore.collection('usuarios').doc(credential.user!.uid).set({
          'nombre': credential.user!.displayName ?? email.split('@')[0],
          'email': email,
          'rol': 'docente',
          'foto': credential.user!.photoURL ?? '',
          'creado': FieldValue.serverTimestamp(),
        });
        await _checkAdminStatus(credential.user!.uid);
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    // Limpiar estado local primero para evitar bucles
    _user = null;
    _isAdmin = false;
    notifyListeners();
    
    try {
      // Eliminar token FCM antes de cerrar sesión
      try {
        final fcmService = FCMService();
        await fcmService.eliminarToken();
      } catch (e) {
        print('Error al eliminar token FCM: $e');
        // Continuar con el cierre de sesión aunque falle esto
      }

      // Intentar cerrar sesión de Google Sign-In (puede fallar si no se usó)
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        // Ignorar errores de Google Sign-In si no se usó
        print('Google Sign-In no disponible o no se usó: $e');
      }
      
      // Cerrar sesión de Firebase Auth (siempre necesario)
      await _auth.signOut();
    } catch (e) {
      // Si falla, el estado ya está limpio, solo registrar el error
      print('Error al cerrar sesión de Firebase: $e');
      // No lanzar excepción para evitar bucles, el estado ya está limpio
    }
  }

  // Obtener usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Cambiar contraseña de un usuario (solo admin) - Envía email de recuperación
  Future<void> cambiarContrasenaUsuario(String email, String nuevaContrasena) async {
    try {
      // Verificar que el usuario existe
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      if (signInMethods.isEmpty) {
        throw 'Usuario no encontrado';
      }

      // Enviar email de recuperación de contraseña
      // Nota: Para cambiar contraseña directamente, se requiere Firebase Admin SDK
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al cambiar contraseña: $e';
    }
  }

  // Cambiar email de un usuario (solo admin) - Actualiza en Firestore
  Future<void> cambiarEmailUsuario(String emailActual, String nuevoEmail) async {
    try {
      // Verificar que el usuario existe
      final signInMethods = await _auth.fetchSignInMethodsForEmail(emailActual);
      if (signInMethods.isEmpty) {
        throw 'Usuario no encontrado';
      }

      // Actualizar en Firestore
      final userDoc = await _firestore.collection('usuarios').where('email', isEqualTo: emailActual).limit(1).get();
      if (userDoc.docs.isNotEmpty) {
        await _firestore.collection('usuarios').doc(userDoc.docs.first.id).update({
          'email': nuevoEmail,
        });
      } else {
        throw 'Usuario no encontrado en Firestore';
      }
      
      // Nota: Para cambiar el email en Firebase Auth, se requiere que el usuario esté autenticado
      // o usar Firebase Admin SDK en el backend
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al cambiar email: $e';
    }
  }

  // Crear nuevo usuario (solo admin)
  Future<UserCredential?> crearUsuarioAdmin({
    required String email,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      // Nota: createUserWithEmailAndPassword automáticamente inicia sesión con el nuevo usuario
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Crear usuario en Firestore
      if (credential.user != null) {
        await _firestore.collection('usuarios').doc(credential.user!.uid).set({
          'nombre': nombre,
          'email': email,
          'rol': rol,
          'foto': '',
          'creado': FieldValue.serverTimestamp(),
        });
      }
      
      // Cerrar sesión del nuevo usuario creado
      // Esto es necesario porque Firebase Auth automáticamente inicia sesión con el nuevo usuario
      await _auth.signOut();
      
      // Nota: En una implementación ideal, se usaría Firebase Admin SDK para crear usuarios
      // sin iniciar sesión automáticamente, pero eso requiere configuración del backend.
      // Por ahora, cerramos sesión y el admin deberá volver a iniciar sesión.
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al crear usuario: $e';
    }
  }

  // Eliminar usuario (solo admin) - Elimina de Firestore
  // Nota: Para eliminar de Firebase Auth, se requiere Firebase Admin SDK
  Future<void> eliminarUsuario(String userId) async {
    try {
      // Eliminar de Firestore
      await _firestore.collection('usuarios').doc(userId).delete();
      
      // Nota: Para eliminar de Firebase Auth, se requiere Firebase Admin SDK en el backend
      // Por ahora solo eliminamos de Firestore
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al eliminar usuario: $e';
    }
  }

  // Manejo de excepciones de Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'email-already-in-use':
        return 'Este email ya está registrado';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuario deshabilitado';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}

