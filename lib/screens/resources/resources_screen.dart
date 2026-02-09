import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recursos Disponibles'),
        actions: [
          if (!authService.isAdmin)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Ver disponibilidad',
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.availability);
              },
            ),
        ],
      ),
      floatingActionButton: !authService.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: Navegar a crear reserva
              },
              icon: const Icon(Icons.add),
              label: const Text('Nueva Reserva'),
            )
          : null,
      body: StreamBuilder(
        stream: firestoreService.getRecursos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay recursos disponibles'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(Icons.inventory_2, size: 40),
                  title: Text(
                    data['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['descripcion'] != null)
                        Text(data['descripcion']),
                      const SizedBox(height: 4),
                      Text(
                        'Estado: ${data['estado'] ?? 'Disponible'}',
                        style: TextStyle(
                          color: (data['estado'] == 'Disponible')
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Navegar a detalles del recurso o crear reserva
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

