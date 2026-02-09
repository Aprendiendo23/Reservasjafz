import 'package:flutter/material.dart';
import '../screens/login/login_main.dart';
import '../screens/login/login_admin.dart';
import '../screens/login/forgot_password.dart';
import '../screens/docente/home_docente.dart';
import '../screens/docente/tabla_cronograma.dart';
import '../screens/docente/crear_reserva.dart';
import '../screens/docente/mis_reservas.dart';
import '../screens/docente/perfil_docente.dart';
import '../screens/admin/admin_home.dart';
import '../screens/admin/admin_recursos.dart';
import '../screens/admin/admin_reservas.dart';
import '../screens/admin/admin_usuarios.dart';
import '../screens/admin/admin_exportar.dart';
import '../screens/admin/auditoria_reservas.dart';
import '../screens/admin/admin_grados.dart';
import '../screens/admin/admin_asignaturas.dart';
import '../screens/docente/editar_reserva.dart';

class AppRoutes {
  // Login
  static const String loginMain = '/login';
  static const String loginAdmin = '/login-admin';
  static const String forgotPassword = '/forgot-password';

  // Docente
  static const String homeDocente = '/home-docente';
  static const String tablaCronograma = '/tabla-cronograma';
  static const String crearReserva = '/crear-reserva';
  static const String misReservas = '/mis-reservas';
  static const String perfilDocente = '/perfil-docente';
  static const String editarReserva = '/editar-reserva';

  // Admin
  static const String adminHome = '/admin-home';
  static const String adminRecursos = '/admin-recursos';
  static const String adminReservas = '/admin-reservas';
  static const String adminUsuarios = '/admin-usuarios';
  static const String adminExportar = '/admin-exportar';
  static const String auditoriaReservas = '/auditoria-reservas';
  static const String adminGrados = '/admin-grados';
  static const String adminAsignaturas = '/admin-asignaturas';

  static Map<String, WidgetBuilder> get routes {
    return {
      loginMain: (context) => const LoginMainScreen(),
      loginAdmin: (context) => const LoginAdminScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      homeDocente: (context) => const HomeDocenteScreen(),
      tablaCronograma: (context) => const TablaCronogramaScreen(),
      crearReserva: (context) => const CrearReservaScreen(),
      misReservas: (context) => const MisReservasScreen(),
      perfilDocente: (context) => const PerfilDocenteScreen(),
      adminHome: (context) => const AdminHomeScreen(),
      adminRecursos: (context) => const AdminRecursosScreen(),
      adminReservas: (context) => const AdminReservasScreen(),
      adminUsuarios: (context) => const AdminUsuariosScreen(),
      adminExportar: (context) => const AdminExportarScreen(),
      auditoriaReservas: (context) => const AuditoriaReservasScreen(),
      adminGrados: (context) => const AdminGradosScreen(),
      adminAsignaturas: (context) => const AdminAsignaturasScreen(),
      editarReserva: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final reservaId = args is String ? args : (args as Map<String, dynamic>?)?['reservaId'] as String?;
        if (reservaId == null) {
          return const Scaffold(
            body: Center(child: Text('Error: ID de reserva no proporcionado')),
          );
        }
        return EditarReservaScreen(reservaId: reservaId);
      },
    };
  }
}
