import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/reserva_service.dart';
import '../../widgets/card_reserva.dart';
import '../../utils/responsive.dart';
import '../../routes/app_routes.dart';
import 'editar_reserva.dart';

class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({super.key});

  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  @override
  void initState() {
    super.initState();
    // Verificar autenticación después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.loginMain,
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reservaService = Provider.of<ReservaService>(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Reservas'),
      ),
      body: StreamBuilder(
        stream: reservaService.getReservasUsuario(user.uid),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_online, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes reservas',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filtrar solo las reservas del usuario actual (doble verificación de seguridad)
          final reservasDelUsuario = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Verificar que la reserva pertenece al usuario actual
            return data['usuarioID'] == user.uid && data['eliminada'] != true;
          }).toList();

          if (reservasDelUsuario.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_online, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes reservas',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
          
          return ListView.builder(
            padding: isLandscape
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                : Responsive.padding(context),
            itemCount: reservasDelUsuario.length,
            itemBuilder: (context, index) {
              final doc = reservasDelUsuario[index];
              final data = doc.data() as Map<String, dynamic>;
              
              // Verificación adicional de seguridad: asegurar que la reserva pertenece al usuario
              if (data['usuarioID'] != user.uid) {
                return const SizedBox.shrink(); // No mostrar reservas de otros usuarios
              }
              
              // Formatear fecha de uso
              String? fechaUsoFormateada;
              final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
              if (fechaUso != null) {
                fechaUsoFormateada = DateFormat('dd/MM/yyyy').format(fechaUso);
              }

              return CardReserva(
                reservaId: doc.id,
                recursoNombre: data['recursoNombre'] ?? 'Recurso',
                dia: data['dia'] ?? '',
                hora: data['hora'] ?? '',
                asignatura: data['asignatura'] ?? '',
                usuarioNombre: data['usuarioNombre'] ?? '',
                docente: data['docente'] as String?,
                grado: data['grado'] as String?,
                fechaUso: fechaUsoFormateada,
                observacion: data['observacion'] as String?,
                onEdit: () async {
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditarReservaScreen(
                        reservaId: doc.id,
                      ),
                    ),
                  );
                  
                  if (resultado == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reserva actualizada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                // Los docentes solo pueden editar, no eliminar
                // La eliminación solo está disponible para admins
                onDelete: null,
              );
            },
          );
        },
      ),
    );
  }
}
