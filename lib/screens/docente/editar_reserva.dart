import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/reserva_service.dart';
import '../../services/recurso_service.dart';
import '../../services/auth_service.dart';
import '../../services/grado_service.dart';
import '../../services/asignatura_service.dart';
import '../../services/usuario_service.dart';
import '../../utils/responsive.dart';

class EditarReservaScreen extends StatefulWidget {
  final String reservaId;

  const EditarReservaScreen({
    super.key,
    required this.reservaId,
  });

  @override
  State<EditarReservaScreen> createState() => _EditarReservaScreenState();
}

class _EditarReservaScreenState extends State<EditarReservaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _cargandoDatos = true;

  // Campos del formulario
  DateTime? _fechaUso;
  String? _hora;
  String? _asignatura;
  String? _docente;
  String? _grado;
  String? _recursoID;
  String? _recursoNombre;

  // Horas y bloques disponibles
  final List<String> _horasYBloques = [
    '1ª Hora',
    '2ª Hora',
    '3ª Hora',
    '4ª Hora',
    '5ª Hora',
    '6ª Hora',
    'Bloque 1 (1ª+2ª)',
    'Bloque 2 (3ª+4ª)',
    'Bloque 3 (5ª+6ª)',
  ];

  // Grados por defecto
  final List<String> _gradosPorDefecto = [
    '7A', '7B', '8A', '8B', '9A', '9B',
    '10A', '10B', '11A', '11B', '12A', '12B',
  ];

  // Asignaturas por defecto (para compatibilidad si no hay datos en Firestore)
  final List<String> _asignaturasPorDefecto = [
    'Lengua y Literatura',
    'Matemática',
    'Inglés',
    'Ciencias Sociales',
    'Ciencias Naturales',
    'Física',
    'Química',
    'Biología',
    'Creciendo en Valores',
    'AEP',
    'TAC',
    'Educación Física',
  ];

  @override
  void initState() {
    super.initState();
    _cargarReserva();
  }

  Future<void> _cargarReserva() async {
    try {
      final reservaService = Provider.of<ReservaService>(context, listen: false);
      final doc = await reservaService.reservasCollection.doc(widget.reservaId).get();
      
      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserva no encontrada'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      
      setState(() {
        _fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
        _hora = data['hora'] as String?;
        _asignatura = data['asignatura'] as String?;
        _docente = data['docente'] ?? data['usuarioNombre'] as String?;
        _grado = data['grado'] as String?;
        _recursoID = data['recursoID'] as String?;
        _recursoNombre = data['recursoNombre'] as String?;
        _cargandoDatos = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final reservaService = Provider.of<ReservaService>(context, listen: false);
      
      // Verificar disponibilidad si cambió la fecha u hora
      if (_fechaUso != null && _hora != null && _recursoID != null) {
        final resultadoDisponibilidad = await reservaService.verificarDisponibilidadPorFechaConDetalles(
          _fechaUso!,
          _hora!,
          _recursoID!,
        );

        // Excluir la reserva actual de la verificación
        final reservasDelDia = await reservaService.getReservasPorFecha(_fechaUso!);
        final reservasDelRecurso = reservasDelDia.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['recursoID'] == _recursoID && doc.id != widget.reservaId;
        }).toList();

        // Verificar conflictos con otras reservas (excluyendo la actual)
        bool hayConflicto = false;
        List<String> horasOcupadas = [];
        
        if (_hora!.startsWith('Bloque')) {
          if (_hora!.contains('Bloque 1')) {
            horasOcupadas = ['1ª Hora', '2ª Hora'];
          } else if (_hora!.contains('Bloque 2')) {
            horasOcupadas = ['3ª Hora', '4ª Hora'];
          } else if (_hora!.contains('Bloque 3')) {
            horasOcupadas = ['5ª Hora', '6ª Hora'];
          }
        } else {
          horasOcupadas = [_hora!];
        }

        for (var doc in reservasDelRecurso) {
          final reservaData = doc.data() as Map<String, dynamic>;
          final horaReservada = reservaData['hora'] as String?;
          
          if (horaReservada == null) continue;

          bool conflicto = false;
          
          if (horaReservada.startsWith('Bloque')) {
            List<String> horasDelBloqueExistente = [];
            if (horaReservada.contains('Bloque 1')) {
              horasDelBloqueExistente = ['1ª Hora', '2ª Hora'];
            } else if (horaReservada.contains('Bloque 2')) {
              horasDelBloqueExistente = ['3ª Hora', '4ª Hora'];
            } else if (horaReservada.contains('Bloque 3')) {
              horasDelBloqueExistente = ['5ª Hora', '6ª Hora'];
            }
            
            conflicto = horasOcupadas.any((h) => horasDelBloqueExistente.contains(h));
          } else {
            conflicto = horasOcupadas.contains(horaReservada);
          }

          if (conflicto) {
            hayConflicto = true;
            break;
          }
        }

        if (hayConflicto) {
          throw 'Este horario o bloque ya está ocupado';
        }
      }

      // Actualizar la reserva
      final diaSemana = _fechaUso != null ? _getDiaSemana(_fechaUso!) : null;
      
      await reservaService.actualizarReserva(widget.reservaId, {
        if (_fechaUso != null) 'fechaUso': Timestamp.fromDate(_fechaUso!),
        if (diaSemana != null) 'dia': diaSemana,
        if (_hora != null) 'hora': _hora!,
        if (_asignatura != null) 'asignatura': _asignatura!,
        if (_docente != null) 'docente': _docente!,
        if (_grado != null) 'grado': _grado!,
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getDiaSemana(DateTime fecha) {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dias[fecha.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final esAdmin = authService.isAdmin;

    if (_cargandoDatos) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editar Reserva'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Reserva'),
      ),
      body: SingleChildScrollView(
        padding: Responsive.padding(context).copyWith(
          bottom: Responsive.padding(context).bottom + 96,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Información del recurso (solo lectura)
                  if (_recursoNombre != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.book_online, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Recurso: $_recursoNombre',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Fecha de uso
                  InkWell(
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: _fechaUso ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2055, 12, 31), // Permitir hasta 2055 (aproximadamente 20 años más)
                        locale: const Locale('es', 'ES'),
                      );
                      if (fecha != null) {
                        setState(() {
                          _fechaUso = fecha;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Uso *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        suffixIcon: Icon(Icons.edit_calendar),
                      ),
                      child: Text(
                        _fechaUso != null
                            ? DateFormat('EEEE, dd/MM/yyyy', 'es_ES').format(_fechaUso!)
                            : 'Selecciona una fecha',
                        style: TextStyle(
                          color: _fechaUso != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hora/bloque
                  DropdownButtonFormField<String>(
                    value: _hora,
                    decoration: const InputDecoration(
                      labelText: 'Hora o Bloque *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    items: _horasYBloques.map((hora) {
                      return DropdownMenuItem(
                        value: hora,
                        child: Text(hora),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _hora = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona una hora o bloque';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Docente
                  Builder(
                    builder: (context) {
                      final usuarioService = Provider.of<UsuarioService>(context);
                      
                      if (esAdmin) {
                        // Si es admin, mostrar todos los docentes disponibles
                        return StreamBuilder(
                          stream: usuarioService.getUsuariosPorRol('docente'),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return DropdownButtonFormField<String>(
                                value: _docente,
                                decoration: const InputDecoration(
                                  labelText: 'Docente *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                  helperText: 'Cargando docentes...',
                                ),
                                items: _docente != null
                                    ? [
                                        DropdownMenuItem(
                                          value: _docente,
                                          child: Text(_docente!),
                                        ),
                                      ]
                                    : [],
                                onChanged: null,
                              );
                            }
                            
                            // Función para normalizar nombres
                            String normalizarNombre(String nombre) {
                              return nombre
                                  .toLowerCase()
                                  .replaceAll(' ', '')
                                  .replaceAll('_', '')
                                  .replaceAll('-', '')
                                  .trim();
                            }
                            
                            // Función para verificar si un nombre ya está en la lista
                            bool nombreYaExiste(List<String> lista, String nombre) {
                              final nombreNormalizado = normalizarNombre(nombre);
                              return lista.any((n) => normalizarNombre(n) == nombreNormalizado);
                            }
                            
                            // Lista de docentes
                            List<String> listaDocentes = [];
                            
                            if (snapshot.hasData) {
                              for (var doc in snapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final nombre = data['nombre'] as String?;
                                if (nombre != null && nombre.isNotEmpty) {
                                  if (!nombreYaExiste(listaDocentes, nombre)) {
                                    listaDocentes.add(nombre);
                                  }
                                }
                              }
                            }
                            
                            // Agregar el docente actual si no está en la lista
                            if (_docente != null && !nombreYaExiste(listaDocentes, _docente!)) {
                              listaDocentes.add(_docente!);
                            }
                            
                            // Ordenar alfabéticamente
                            listaDocentes.sort();
                            
                            return DropdownButtonFormField<String>(
                              value: _docente,
                              decoration: const InputDecoration(
                                labelText: 'Docente *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                                helperText: 'Selecciona el docente para la reserva',
                              ),
                              items: listaDocentes.map((docente) {
                                return DropdownMenuItem(
                                  value: docente,
                                  child: Text(docente),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _docente = value);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El docente es requerido';
                                }
                                return null;
                              },
                            );
                          },
                        );
                      } else {
                        // Si no es admin, mostrar solo el nombre del usuario actual (actualizado en tiempo real)
                        return StreamBuilder(
                          stream: usuarioService.getUsuarioActualStream(),
                          builder: (context, snapshot) {
                            String? nombreActualizado = _docente;
                            
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              final nombre = data?['nombre'] as String?;
                              if (nombre != null && nombre.isNotEmpty) {
                                nombreActualizado = nombre;
                                // Actualizar _docente si cambió el nombre
                                if (_docente != nombreActualizado) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) {
                                      setState(() {
                                        _docente = nombreActualizado;
                                      });
                                    }
                                  });
                                }
                              }
                            }
                            
                            // Si no hay nombre en Firestore, usar el valor inicial
                            if (nombreActualizado == null || nombreActualizado.isEmpty) {
                              nombreActualizado = _docente;
                            }
                            
                            // Asegurar que el valor siempre esté actualizado
                            final valorMostrar = nombreActualizado ?? _docente;
                            
                            return DropdownButtonFormField<String>(
                              value: valorMostrar,
                              decoration: InputDecoration(
                                labelText: 'Docente *',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.person),
                                helperText: valorMostrar != null
                                    ? 'Tu nombre: $valorMostrar'
                                    : 'Cargando...',
                              ),
                              items: valorMostrar != null
                                  ? [
                                      DropdownMenuItem(
                                        value: valorMostrar,
                                        child: Text(valorMostrar),
                                      ),
                                    ]
                                  : [],
                              onChanged: null, // No editable para docentes, pero habilitado para mostrar
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El docente es requerido';
                                }
                                return null;
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Grado/aula
                  Builder(
                    builder: (context) {
                      final gradoService = Provider.of<GradoService>(context);
                      return StreamBuilder(
                        stream: gradoService.getTodosLosGrados(), // Obtener todos para verificar inactivos
                        builder: (context, snapshot) {
                          // Lista para almacenar grados activos de Firestore con su orden
                          final List<Map<String, dynamic>> gradosActivosFirestore = [];
                          // Conjunto para almacenar todos los nombres de grados en Firestore (activos e inactivos)
                          final Set<String> todosLosGradosFirestore = {};

                          // Primero, obtener todos los grados de Firestore para verificar cuáles están activos
                          if (snapshot.hasData && snapshot.data != null) {
                            for (final doc in snapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final nombre = (data['nombre'] as String?)?.trim();
                              if (nombre != null && nombre.isNotEmpty) {
                                todosLosGradosFirestore.add(nombre);
                                // Solo agregar si está activo
                                final activo = data['activo'];
                                if (activo == true) {
                                  gradosActivosFirestore.add({
                                    'nombre': nombre,
                                    'orden': data['orden'] as int? ?? 9999,
                                  });
                                }
                              }
                            }
                          }

                          // Construir la lista final manteniendo el orden definido en administración
                          final List<String> listaGrados = [];

                          // 1. Agregar grados activos de Firestore, ordenados por "orden" y luego por nombre
                          gradosActivosFirestore.sort((a, b) {
                            final ordenA = (a['orden'] as int?) ?? 9999;
                            final ordenB = (b['orden'] as int?) ?? 9999;
                            if (ordenA != ordenB) {
                              return ordenA.compareTo(ordenB);
                            }
                            final nombreA = (a['nombre'] as String?) ?? '';
                            final nombreB = (b['nombre'] as String?) ?? '';
                            return nombreA.compareTo(nombreB);
                          });
                          listaGrados.addAll(
                            gradosActivosFirestore.map((g) => g['nombre'] as String),
                          );

                          // 2. Agregar grados por defecto SOLO si no existen en Firestore.
                          //    Si ya existen en Firestore (activos o inactivos), el admin
                          //    controla completamente su visibilidad desde la pantalla de administración.
                          for (final gradoPorDefecto in _gradosPorDefecto) {
                            if (!todosLosGradosFirestore.contains(gradoPorDefecto)) {
                              listaGrados.add(gradoPorDefecto);
                            }
                          }

                          // Si hay error, mostrar mensaje pero seguir con grados por defecto
                          if (snapshot.hasError) {
                            print('Error al cargar grados: ${snapshot.error}');
                          }

                          // Si está cargando y no hay grados por defecto, mostrar cargando
                          if (snapshot.connectionState == ConnectionState.waiting && listaGrados.isEmpty) {
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Grado/Aula *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.class_),
                              ),
                              items: const [],
                              hint: const Text('Cargando...'),
                              onChanged: (value) {},
                            );
                          }

                          return DropdownButtonFormField<String>(
                            value: _grado,
                            decoration: const InputDecoration(
                              labelText: 'Grado/Aula *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.class_),
                            ),
                            items: listaGrados.map((grado) {
                              return DropdownMenuItem(
                                value: grado,
                                child: Text(grado),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _grado = value);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecciona un grado/aula';
                              }
                              return null;
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Asignatura
                  Builder(
                    builder: (context) {
                      final asignaturaService = Provider.of<AsignaturaService>(context);
                      return StreamBuilder(
                        stream: asignaturaService.getTodasLasAsignaturas(), // Obtener todas para verificar inactivas
                        builder: (context, snapshot) {
                          // Lista para almacenar asignaturas activas de Firestore con su orden
                          final List<Map<String, dynamic>> asignaturasActivasFirestore = [];
                          // Conjunto para almacenar todas las asignaturas en Firestore (activas e inactivas)
                          final Set<String> todasLasAsignaturasFirestore = {};

                          // Primero, obtener todas las asignaturas de Firestore para verificar cuáles están activas
                          if (snapshot.hasData && snapshot.data != null) {
                            for (final doc in snapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final nombre = (data['nombre'] as String?)?.trim();
                              if (nombre != null && nombre.isNotEmpty) {
                                todasLasAsignaturasFirestore.add(nombre);
                                // Solo agregar si está activa
                                final activo = data['activo'];
                                if (activo == true) {
                                  asignaturasActivasFirestore.add({
                                    'nombre': nombre,
                                    'orden': data['orden'] as int? ?? 9999,
                                  });
                                }
                              }
                            }
                          }

                          // Construir la lista final de asignaturas disponibles respetando el orden definido en administración
                          final List<String> listaAsignaturas = [];

                          // 1. Agregar TODAS las asignaturas activas de Firestore (incluye las creadas por admin),
                          //    ordenadas por el campo "orden" y luego por nombre
                          asignaturasActivasFirestore.sort((a, b) {
                            final ordenA = (a['orden'] as int?) ?? 9999;
                            final ordenB = (b['orden'] as int?) ?? 9999;
                            if (ordenA != ordenB) {
                              return ordenA.compareTo(ordenB);
                            }
                            final nombreA = (a['nombre'] as String?) ?? '';
                            final nombreB = (b['nombre'] as String?) ?? '';
                            return nombreA.compareTo(nombreB);
                          });
                          listaAsignaturas.addAll(
                            asignaturasActivasFirestore.map((a) => a['nombre'] as String),
                          );

                          // 2. Agregar asignaturas por defecto SOLO si no existen en Firestore.
                          //    Si ya existen en Firestore (activas o inactivas), el admin
                          //    controla completamente su visibilidad desde la pantalla de administración.
                          for (final asignaturaPorDefecto in _asignaturasPorDefecto) {
                            if (!todasLasAsignaturasFirestore.contains(asignaturaPorDefecto)) {
                              listaAsignaturas.add(asignaturaPorDefecto);
                            }
                          }

                          // Si hay error, mostrar mensaje pero seguir con asignaturas por defecto
                          if (snapshot.hasError) {
                            print('Error al cargar asignaturas: ${snapshot.error}');
                          }

                          // Si está cargando y no hay asignaturas por defecto, mostrar cargando
                          if (snapshot.connectionState == ConnectionState.waiting && listaAsignaturas.isEmpty) {
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Asignatura *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.book),
                              ),
                              items: const [],
                              hint: const Text('Cargando...'),
                              onChanged: (value) {},
                            );
                          }

                          return DropdownButtonFormField<String>(
                            value: _asignatura,
                            decoration: const InputDecoration(
                              labelText: 'Asignatura *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.book),
                            ),
                            items: listaAsignaturas.map((asignatura) {
                              return DropdownMenuItem(
                                value: asignatura,
                                child: Text(asignatura),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _asignatura = value);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecciona una asignatura';
                              }
                              return null;
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botón guardar
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _guardarCambios,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Guardando...' : 'Guardar Cambios'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
