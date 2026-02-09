import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/recurso_service.dart';
import 'services/reserva_service.dart';
import 'services/usuario_service.dart';
import 'services/grado_service.dart';
import 'services/asignatura_service.dart';
import 'services/fcm_service.dart';
import 'routes/app_routes.dart';
import 'screens/login/login_main.dart';
import 'screens/docente/home_docente.dart';
import 'screens/admin/admin_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase con las opciones de la plataforma actual
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Verificar que Firebase se inicializó correctamente
    final app = Firebase.app();
    print('✅ Firebase inicializado correctamente');
    print('📦 Proyecto: ${app.options.projectId}');
    print('🔗 App ID: ${app.options.appId}');

    // Inicializar FCM (Firebase Cloud Messaging) para notificaciones push
    try {
      final fcmService = FCMService();
      await fcmService.initialize();
      print('✅ FCM inicializado correctamente');
    } catch (e) {
      print('⚠️ Error al inicializar FCM: $e');
      print('   Las notificaciones push pueden no funcionar correctamente');
    }

  } catch (e) {
    print('❌ Error al inicializar Firebase: $e');
    print('⚠️ La aplicación continuará pero algunas funciones pueden no estar disponibles');
    // Aún así ejecutamos la app para que el usuario vea el error
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => RecursoService()),
        Provider(create: (_) => ReservaService()),
        Provider(create: (_) => UsuarioService()),
        Provider(create: (_) => GradoService()),
        Provider(create: (_) => AsignaturaService()),
        Provider(create: (_) => FCMService()),
      ],
      child: MaterialApp(
        title: 'Reservas de Recursos',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'), // Español
          Locale('en', 'US'), // Inglés
        ],
        locale: const Locale('es', 'ES'),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A90E2), // Azul más suave y amigable
            brightness: Brightness.light,
            primary: const Color(0xFF4A90E2), // Azul suave y cálido
            secondary: const Color(0xFF5BA3E8), // Azul secundario más claro
            tertiary: const Color(0xFF6BB6F0), // Azul terciario muy suave
            error: const Color(0xFFE53935),
            surface: Colors.white,
            surfaceContainerHighest: const Color(0xFFE8F2F8), // Color para contenedores superiores
          ),
          scaffoldBackgroundColor: const Color(0xFFF0F4F8), // Azul muy suave y cálido
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: const Color(0xFFE8F2F8), // Azul muy claro y amigable
            foregroundColor: const Color(0xFF1A365D), // Texto oscuro para contraste
            iconTheme: const IconThemeData(
              color: Color(0xFF1A365D), // Iconos oscuros
            ),
            titleTextStyle: const TextStyle(
              color: Color(0xFF1A365D), // Título oscuro
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2), // Usar el nuevo color primario más amigable
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE53935)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
          ),
        ),
        home: const AuthWrapper(),
        routes: AppRoutes.routes,
      ),
    );
  }
}

// Widget que verifica el estado de autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Siempre mostrar login primero si no hay usuario
    if (authService.user == null) {
      return const LoginMainScreen();
    }

    // Si estamos verificando el rol, mostrar un loading
    if (authService.isCheckingAdmin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si hay usuario autenticado, verificar rol y redirigir
    // Usar el estado de AuthService directamente (más eficiente)
    if (authService.isAdmin) {
      return const AdminHomeScreen();
    } else {
      // Si no es admin, mostrar pantalla de docente
      // AuthService ya verificó el rol automáticamente
      return const HomeDocenteScreen();
    }
  }
}
