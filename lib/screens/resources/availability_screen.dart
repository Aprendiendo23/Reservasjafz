import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedResourceId;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disponibilidad de Recursos'),
      ),
      body: Column(
        children: [
          // Selector de fecha
          Card(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              trailing: IconButton(
                icon: const Icon(Icons.edit_calendar),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
            ),
          ),
          // Lista de recursos con disponibilidad
          Expanded(
            child: StreamBuilder(
              stream: firestoreService.getRecursos(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay recursos disponibles'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final resourceId = doc.id;

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
                            const SizedBox(height: 8),
                            FutureBuilder<bool>(
                              future: _checkAvailability(
                                firestoreService,
                                resourceId,
                                _selectedDate,
                              ),
                              builder: (context, availabilitySnapshot) {
                                if (availabilitySnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                }

                                final isAvailable =
                                    availabilitySnapshot.data ?? false;

                                return Row(
                                  children: [
                                    Icon(
                                      isAvailable
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: isAvailable
                                          ? Colors.green
                                          : Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAvailable
                                          ? 'Disponible'
                                          : 'No disponible',
                                      style: TextStyle(
                                        color: isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // TODO: Mostrar horarios disponibles
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkAvailability(
    FirestoreService service,
    String resourceId,
    DateTime date,
  ) async {
    try {
      // Obtener todas las reservas del recurso para la fecha seleccionada
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final reservas = await service.reservasCollection
          .where('recursoID', isEqualTo: resourceId)
          .where('estado', isEqualTo: 'activa')
          .where('fechaInicio',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('fechaInicio', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      // Si no hay reservas, está disponible
      return reservas.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }
}




