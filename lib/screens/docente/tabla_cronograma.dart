import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/recurso_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/tabla_disponibilidad.dart';
import '../../widgets/tabla_reservas.dart';
import '../../routes/app_routes.dart';
import '../../utils/responsive.dart';

class TablaCronogramaScreen extends StatefulWidget {
  const TablaCronogramaScreen({super.key});

  @override
  State<TablaCronogramaScreen> createState() => _TablaCronogramaScreenState();
}

class _TablaCronogramaScreenState extends State<TablaCronogramaScreen> {
  String? _recursoSeleccionado;
  String? _recursoNombre;
  bool _vistaTabla = true; // true = vista tabla (por defecto), false = vista calendario

  // Recursos por defecto disponibles (debe coincidir con crear_reserva.dart)
  final List<String> _recursosPorDefecto = [
    'Laptop',
    'Laptop y Proyector',
    'Tablet, laptop y Proyector',
    'Tablet',
    'Proyector',
  ];

  @override
  void initState() {
    super.initState();
    // Por defecto seleccionar "Todos" para mostrar todas las reservas
    _recursoSeleccionado = 'todos';
    _recursoNombre = null;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final esAdmin = authService.isAdmin;
    final recursoService = Provider.of<RecursoService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronograma de Disponibilidad'),
        actions: [
          IconButton(
            icon: Icon(_vistaTabla ? Icons.calendar_view_week : Icons.table_chart),
            tooltip: _vistaTabla ? 'Vista Calendario' : 'Vista Tabla',
            onPressed: () {
              setState(() {
                final vistaAnterior = _vistaTabla;
                _vistaTabla = !_vistaTabla;

                // Solo cambiamos la vista; el recurso seleccionado se mantiene.
                // En vista calendario, si está seleccionado "Todos", internamente
                // usaremos un recurso por defecto para mostrar la disponibilidad,
                // pero el dropdown puede seguir mostrando "Todos" sin problemas.
                print(
                    '🔄 Cambio de vista: ${vistaAnterior ? "Tabla" : "Calendario"} -> ${_vistaTabla ? "Tabla" : "Calendario"}, Recurso: $_recursoSeleccionado');
              });
            },
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          // Reconstruir el selector y la tabla cuando cambian los parámetros
          final selector = _buildSelectorCard(recursoService, isLandscape);
          final tabla = _buildTablaContenido(esAdmin);

          if (orientation == Orientation.portrait) {
            return Column(
              children: [
                // Selector de recursos - siempre visible en la parte superior
                selector,
                const SizedBox(height: 8),
                // Tabla - ocupa el resto del espacio disponible
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: tabla,
                  ),
                ),
              ],
            );
          }

          // Modo landscape - usar padding compacto como en auditoría
          return Column(
            children: [
              // Selector de recursos - siempre visible en la parte superior
              selector,
              const SizedBox(height: 4),
              // Tabla - ocupa el resto del espacio disponible
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: tabla,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectorCard(RecursoService recursoService, bool isLandscape) {
    return Container(
      margin: isLandscape
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : Responsive.padding(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isLandscape ? 8 : 16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isLandscape ? 4 : 8,
            offset: Offset(0, isLandscape ? 2 : 4),
          ),
        ],
      ),
      child: Padding(
        padding: isLandscape
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
            : Responsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isLandscape ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: Theme.of(context).primaryColor,
                    size: isLandscape ? 18 : 20,
                  ),
                ),
                SizedBox(width: isLandscape ? 6 : 12),
                Text(
                  'Seleccionar Recurso',
                  style: TextStyle(
                    fontSize: isLandscape ? 12 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isLandscape ? 6 : 16),
            StreamBuilder(
              stream: recursoService.getRecursos(),
              builder: (context, snapshot) {
                List<DropdownMenuItem<String>> items = [
                  const DropdownMenuItem(
                    value: 'todos',
                    child: Row(
                      children: [
                        Icon(Icons.all_inclusive, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Todos',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ];

                // Crear un mapa de recursos de Firestore por nombre para verificar estado
                final Map<String, Map<String, dynamic>> recursosFirestore = {};
                if (snapshot.hasData && snapshot.data != null) {
                  try {
                    for (final doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nombre = data['nombre'] ?? 'Sin nombre';
                      recursosFirestore[nombre] = {
                        'id': doc.id,
                        'estado': data['estado'] ?? 'inactivo',
                        'data': data,
                      };
                    }
                  } catch (e) {
                    print('Error al procesar recursos de Firestore: $e');
                  }
                }

                // Agregar recursos por defecto solo si están activos o no existen en Firestore
                for (final recurso in _recursosPorDefecto) {
                  final recursoEnFirestore = recursosFirestore[recurso];
                  // Mostrar si no existe en Firestore O si existe y está activo
                  if (recursoEnFirestore == null || recursoEnFirestore['estado'] == 'activo') {
                    items.add(
                      DropdownMenuItem(
                        value: recursoEnFirestore != null 
                            ? recursoEnFirestore['id'] 
                            : 'default_$recurso',
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              recurso,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }

                // Agregar recursos de Firestore activos que no son recursos por defecto
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  try {
                    for (final doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nombre = data['nombre'] ?? 'Sin nombre';
                      final estado = data['estado'] ?? 'inactivo';
                      // Solo agregar si no es un recurso por defecto Y está activo
                      if (!_recursosPorDefecto.contains(nombre) && estado == 'activo') {
                        items.add(
                          DropdownMenuItem(
                            value: doc.id,
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  nombre,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print('Error al procesar recursos de Firestore: $e');
                  }
                }

                if (snapshot.hasError) {
                  print('Error al cargar recursos: ${snapshot.error}');
                }

                // Función auxiliar para obtener el texto a mostrar según el valor
                String? obtenerTextoRecurso(String? valor) {
                  if (valor == null) return null;
                  if (valor == 'todos') return 'Todos';
                  if (valor.startsWith('default_')) {
                    return valor.replaceFirst('default_', '');
                  }
                  // Buscar en Firestore
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    try {
                      final doc = snapshot.data!.docs.firstWhere((d) => d.id == valor);
                      final data = doc.data() as Map<String, dynamic>;
                      return data['nombre'] ?? 'Recurso';
                    } catch (_) {
                      return 'Recurso';
                    }
                  }
                  return 'Recurso';
                }

                return DropdownButtonFormField<String>(
                  value: _recursoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Recurso',
                    labelStyle: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 12 : 16,
                      vertical: isLandscape ? 12 : 20,
                    ),
                    prefixIcon: Icon(
                      Icons.inventory_2,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  dropdownColor: Colors.white,
                  style: TextStyle(
                    fontSize: isLandscape ? 13 : 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return items.map<Widget>((DropdownMenuItem<String> item) {
                      final texto = obtenerTextoRecurso(item.value);
                      if (item.value == 'todos') {
                        return Row(
                          children: [
                            Icon(Icons.all_inclusive, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              texto ?? 'Todos',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              texto ?? 'Recurso',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        );
                      }
                    }).toList();
                  },
                  items: items,
                  onChanged: (value) {
                    print('🔄 Cambio de recurso seleccionado: $_recursoSeleccionado -> $value');
                    setState(() {
                      _recursoSeleccionado = value;
                      if (value == null) {
                        _recursoNombre = null;
                      } else if (value == 'todos') {
                        _recursoNombre = null;
                      } else if (value.startsWith('default_')) {
                        // Recurso por defecto que no existe en Firestore
                        _recursoNombre = value.replaceFirst('default_', '');
                      } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        try {
                          // Recurso de Firestore (puede ser un recurso por defecto o uno nuevo)
                          final doc = snapshot.data!.docs.firstWhere((d) => d.id == value);
                          final data = doc.data() as Map<String, dynamic>;
                          _recursoNombre = data['nombre'] ?? 'Recurso';
                        } catch (_) {
                          _recursoNombre = 'Recurso';
                        }
                      } else {
                        _recursoNombre = 'Recurso';
                      }
                    });
                    print('✅ Recurso actualizado: seleccionado=$_recursoSeleccionado, nombre=$_recursoNombre');
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaContenido(bool esAdmin) {
    // Calcular el recursoID seleccionado correctamente
    String? recursoIdSeleccionado;
    if (_recursoSeleccionado != null && _recursoSeleccionado != 'todos') {
      if (_recursoSeleccionado!.startsWith('default_')) {
        // Recurso por defecto: usar el nombre como ID
        recursoIdSeleccionado = _recursoSeleccionado!.replaceFirst('default_', '');
      } else {
        // Recurso de Firestore: usar el ID directamente
        recursoIdSeleccionado = _recursoSeleccionado!;
      }
    }

    // Vista TABLA: siempre mostrar TablaReservas (si es "Todos", muestra todas)
    if (_vistaTabla) {
      // Crear key único que incluya todos los parámetros relevantes
      final widgetKey = 'tabla_reservas_${_recursoSeleccionado}_${recursoIdSeleccionado ?? 'null'}_${_recursoNombre ?? 'null'}_${_vistaTabla}';
      print('🔑 Creando TablaReservas con key: $widgetKey');
      return TablaReservas(
        key: ValueKey(widgetKey), // Key único para forzar reconstrucción completa
        recursoID: recursoIdSeleccionado,
        recursoNombre: _recursoNombre,
        mostrarExportar: esAdmin, // Mostrar exportar solo si es admin
      );
    }

    // Vista calendario: mostrar TablaDisponibilidad
    final recursoID = recursoIdSeleccionado ?? (_recursosPorDefecto.isNotEmpty ? _recursosPorDefecto[0] : 'Laptop');
    final recursoNombre = _recursoNombre ?? (_recursosPorDefecto.isNotEmpty ? _recursosPorDefecto[0] : 'Recurso');

    return TablaDisponibilidad(
      key: ValueKey('tabla_disponibilidad_${recursoID}_${_vistaTabla}'), // Key único para forzar reconstrucción
      recursoID: recursoID,
      recursoNombre: recursoNombre,
      onCellTap: esAdmin
          ? (dia, hora) {
              final recursoArgID = _recursoSeleccionado != null && _recursoSeleccionado!.startsWith('default_')
                  ? null
                  : _recursoSeleccionado;
              final recursoArgNombre =
                  _recursoSeleccionado != null && _recursoSeleccionado!.startsWith('default_') ? _recursoNombre : null;

              Navigator.pushNamed(
                context,
                AppRoutes.crearReserva,
                arguments: {
                  'recursoID': recursoArgID,
                  'recursoNombre': recursoArgNombre,
                  'dia': dia,
                  'hora': hora,
                },
              );
            }
          : null,
    );
  }
}




