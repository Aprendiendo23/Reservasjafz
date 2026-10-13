import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/recurso_service.dart';
import '../../services/reserva_service.dart';
import '../../services/usuario_service.dart';
import '../../routes/app_routes.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final recursoService = Provider.of<RecursoService>(context);
    final reservaService = Provider.of<ReservaService>(context);
    final usuarioService = Provider.of<UsuarioService>(context);

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
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.perfilDocente);
          },
          tooltip: 'Mi Perfil',
        ),
        title: const Text('Panel de Administración'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard con estadísticas
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Docentes',
                    Icons.people,
                    Colors.blue,
                    StreamBuilder(
                      stream: usuarioService.getUsuariosPorRol('docente'),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            '${snapshot.data!.docs.length}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return const Text('0');
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Recursos Activos',
                    Icons.inventory_2,
                    Colors.green,
                    StreamBuilder(
                      stream: recursoService.getRecursosActivos(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            '${snapshot.data!.docs.length}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return const Text('0');
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              'Total Reservas',
              Icons.book_online,
              Colors.orange,
              StreamBuilder<QuerySnapshot>(
                stream: reservaService.getReservas(incluirEliminadas: false),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final totalActivas = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['eliminada'] != true;
                    }).length;
                    return Text(
                      '$totalActivas',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return const Text('0');
                },
              ),
            ),
            const SizedBox(height: 32),
            // Menú de opciones
            const Text(
              'Gestión',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              context,
              'Gestión de Recursos',
              'Crear, editar y eliminar recursos',
              Icons.inventory_2,
              Colors.blue,
              () => Navigator.pushNamed(context, AppRoutes.adminRecursos),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              'Cronograma',
              'Ver cronograma de reservas por recurso',
              Icons.calendar_view_week,
              Colors.indigo,
              () => Navigator.pushNamed(context, AppRoutes.tablaCronograma),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              'Crear Reserva',
              'Crear una nueva reserva de recurso',
              Icons.add_circle,
              Colors.green,
              () => Navigator.pushNamed(context, AppRoutes.crearReserva),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              'Gestión de Reservas',
              'Ver, filtrar y gestionar reservas',
              Icons.book_online,
              Colors.orange,
              () => Navigator.pushNamed(context, AppRoutes.adminReservas),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              'Gestión de Grados/Aulas',
              'Crear, editar y eliminar grados o aulas',
              Icons.class_,
              Colors.indigo,
              () => Navigator.pushNamed(context, AppRoutes.adminGrados),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              'Gestión de Asignaturas',
              'Crear, editar y eliminar asignaturas',
              Icons.book,
              Colors.purple,
              () => Navigator.pushNamed(context, AppRoutes.adminAsignaturas),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              'Gestión de Usuarios',
              'Ver todos los docentes',
              Icons.people,
              Colors.teal,
              () => Navigator.pushNamed(context, AppRoutes.adminUsuarios),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              'Auditoría de Reservas',
              'Ver todas las reservas incluyendo eliminadas',
              Icons.audiotrack,
              Colors.red,
              () => Navigator.pushNamed(context, AppRoutes.auditoriaReservas),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              'Exportar Datos',
              'Exportar reservas a PDF o Excel',
              Icons.file_download,
              Colors.purple,
              () => Navigator.pushNamed(context, AppRoutes.adminExportar),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget value,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            DefaultTextStyle(
              style: TextStyle(color: color),
              child: value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
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
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

