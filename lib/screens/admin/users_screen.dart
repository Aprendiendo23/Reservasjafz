import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
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
        title: const Text('Lista de Usuarios'),
      ),
      body: StreamBuilder(
        stream: firestoreService.getReservas(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados'));
          }

          // Obtener usuarios únicos de las reservas
          final usuariosMap = <String, Map<String, dynamic>>{};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = data['usuarioID'] as String?;
            final userEmail = data['usuarioEmail'] as String?;

            if (userId != null && userEmail != null) {
              if (!usuariosMap.containsKey(userId)) {
                usuariosMap[userId] = {
                  'id': userId,
                  'email': userEmail,
                  'reservasCount': 0,
                };
              }
              usuariosMap[userId]!['reservasCount'] =
                  (usuariosMap[userId]!['reservasCount'] as int) + 1;
            }
          }

          final usuarios = usuariosMap.values.toList();

          if (usuarios.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];

              // Obtener inicial de forma segura
              String getInicial(String texto) {
                if (texto.isEmpty) return 'U';
                return texto.trim().substring(0, 1).toUpperCase();
              }

              final emailUsuario = usuario['email'] as String? ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      getInicial(emailUsuario),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    emailUsuario,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${usuario['reservasCount']} reserva(s)',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Mostrar detalles del usuario
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

