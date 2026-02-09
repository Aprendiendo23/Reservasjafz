import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/usuario_service.dart';
import '../../routes/app_routes.dart';
import '../../utils/responsive.dart';

class HomeDocenteScreen extends StatelessWidget {
  const HomeDocenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final usuarioService = Provider.of<UsuarioService>(context);
    final user = authService.user;
    final isAdmin = authService.isAdmin;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.perfilDocente);
          },
          tooltip: 'Mi Perfil',
        ),
        title: const Text('Reservas de Recursos'),
        actions: [
          // Botón para regresar al panel admin (solo visible para admins)
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Regresar al Panel Admin',
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
              },
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: Responsive.padding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null) ...[
                  StreamBuilder(
                    stream: usuarioService.getUsuarioActualStream(),
                    builder: (context, snapshot) {
                      // Mientras carga, mostrar solo el email o un indicador
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          'Bienvenid@, ${user.email?.split('@')[0] ?? 'Usuario'}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: Responsive.fontSize(context, 20),
                              ),
                        );
                      }
                      
                      // Una vez que los datos están disponibles, usar el nombre de Firestore
                      String nombreMostrar = user.email?.split('@')[0] ?? 'Usuario';
                      
                      if (snapshot.hasData && snapshot.data != null) {
                        final usuarioData = snapshot.data!.data() as Map<String, dynamic>?;
                        if (usuarioData != null) {
                          final nombreGuardado = usuarioData['nombre'] as String?;
                          
                          if (nombreGuardado != null && nombreGuardado.isNotEmpty) {
                            nombreMostrar = nombreGuardado;
                          }
                        }
                      }
                      
                      return Text(
                        'Bienvenid@, $nombreMostrar',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: Responsive.fontSize(context, 20),
                            ),
                      );
                    },
                  ),
                  SizedBox(height: Responsive.isMobile(context) ? 16 : 24),
                ],
                Expanded(
                  child: GridView.count(
                    crossAxisCount: Responsive.menuGridColumns(context),
                    crossAxisSpacing: Responsive.isMobile(context) ? 12 : 16,
                    mainAxisSpacing: Responsive.isMobile(context) ? 12 : 16,
                    childAspectRatio: Responsive.isMobile(context) ? 1.1 : 1.0,
                    children: [
                  _buildMenuCard(
                    context,
                    'Cronograma',
                    'Ver disponibilidad',
                    Icons.calendar_view_week,
                    Colors.blue,
                    () => Navigator.pushNamed(context, AppRoutes.tablaCronograma),
                  ),
                  _buildMenuCard(
                    context,
                    'Crear Reserva',
                    'Nueva reserva',
                    Icons.add_circle,
                    Colors.green,
                    () => Navigator.pushNamed(context, AppRoutes.crearReserva),
                  ),
                  _buildMenuCard(
                    context,
                    'Gestión de Reservas',
                    'Ver y editar mis reservas',
                    Icons.book_online,
                    Colors.orange,
                    () => Navigator.pushNamed(context, AppRoutes.misReservas),
                  ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: Responsive.isMobile(context) 
              ? const EdgeInsets.all(12) 
              : const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                size: Responsive.iconSize(context, 48), 
                color: color,
              ),
              SizedBox(height: Responsive.isMobile(context) ? 12 : 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.fontSize(context, 16),
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: Responsive.isMobile(context) ? 2 : 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: Responsive.fontSize(context, 12),
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
