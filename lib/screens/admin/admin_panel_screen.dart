import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Verificar que es admin
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
        title: const Text('Panel de Administración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Gestión de Recursos'),
          _buildMenuItem(
            context,
            'Gestionar Recursos',
            'Crear, editar y eliminar recursos',
            Icons.inventory_2,
            Colors.blue,
            () => Navigator.pushNamed(context, AppRoutes.adminRecursos),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Gestión de Reservas'),
          _buildMenuItem(
            context,
            'Todas las Reservas',
            'Ver, filtrar y gestionar todas las reservas',
            Icons.list_alt,
            Colors.purple,
            () => Navigator.pushNamed(context, AppRoutes.adminReservas),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Usuarios'),
          _buildMenuItem(
            context,
            'Lista de Usuarios',
            'Ver todos los usuarios registrados',
            Icons.people,
            Colors.teal,
            () => Navigator.pushNamed(context, AppRoutes.adminUsuarios),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
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

