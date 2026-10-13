import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/reserva_service.dart';
import '../../services/recurso_service.dart';
import '../../services/usuario_service.dart';
import '../../services/auth_service.dart';
import '../../services/grado_service.dart';
import '../../services/asignatura_service.dart';
import '../../utils/responsive.dart';

class CrearReservaScreen extends StatefulWidget {
  const CrearReservaScreen({super.key});

  @override
  State<CrearReservaScreen> createState() => _CrearReservaScreenState();
}

class _CrearReservaScreenState extends State<CrearReservaScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _recursoID;
  String? _recursoNombre; // Para recursos por defecto
  DateTime? _fechaUso; // Fecha real de uso
  String? _hora;
  String? _asignatura;
  String? _docente;
  String? _grado;
  String? _observacion; // Campo de observación para notas del maestro
  String? _nombreUsuarioActual; // Nombre del docente que inició sesión
  final TextEditingController _observacionController = TextEditingController(); // Controller para el campo de observación

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

  // Recursos por defecto disponibles
  final List<String> _recursosPorDefecto = [
    'Laptop',
    'Laptop y Proyector',
    'Tablet, laptop y Proyector',
    'Tablet',
     'Proyector',
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

  // Docentes disponibles (lista base)
  final List<String> _docentesBase = [
    'Marlon Rodríguez',
    'Marling Requene',
    'Elba Ruth Calero',
    'Hollman Ñamendi',
    'Judith Rivas',
    'Martin López',
    'Marlon Ruiz',
    'Ali López',
    'Director Guillermo Martinez',
    'Subdirector Edwin Prado',
    'Yader Latino',
  ];

  // Mapeo de emails a nombres por defecto
  final Map<String, String> _emailANombre = {
    'Marlon_Rod@gmail.com': 'Marlon Rodríguez',
    'Marling_Re@gmail.com': 'Marling Requene',
    'Elba_R@gmail.com': 'Elba Ruth Calero',
    'Hollman_N@gmail.com': 'Hollman Ñamendi',
    'Judith_Riv@gmail.com': 'Judith Rivas',
    'Martin_Lo@gmail.com': 'Martin López',
    'Marlon_Rui@gmail.com': 'Marlon Ruiz',
    'Ali_lo@gmail.com': 'Ali López',
    'Director_G@gmail.com': 'Director Guillermo Martinez',
    'Subdirector_E@gmail.com': 'Subdirector Edwin Prado',
    'Yader_Lati@gmail.com': 'Yader Latino',
  };

  // Lista de docentes desde Firestore (se actualiza dinámicamente)
  List<String> _docentesFirestore = [];
  
  // Lista de docentes (combina lista base con docentes de Firestore)
  List<String> get _docentes {
    final lista = List<String>.from(_docentesBase);
    
    // Agregar docentes de Firestore que no estén en la lista base
    for (final docente in _docentesFirestore) {
      if (!lista.contains(docente)) {
        lista.add(docente);
      }
    }
    
    // Si el usuario actual tiene un nombre que no está en la lista, agregarlo
    if (_nombreUsuarioActual != null && !lista.contains(_nombreUsuarioActual)) {
      lista.insert(0, _nombreUsuarioActual!);
    }
    
    // Ordenar alfabéticamente
    lista.sort();
    
    return lista;
  }

  // Grados/Aulas por defecto (se combinan con los de Firestore)
  final List<String> _gradosPorDefecto = [
    '7A',
    '7B',
    '8A',
    '8B',
    '9A',
    '9B',
    '10A',
    '11A',
  ];

  bool _isLoading = false;
  Map<String, Map<String, dynamic>>? _disponibilidadFecha;
  bool _cargandoDisponibilidad = false;
  bool _reservaRecienCreada = false; // Bandera para evitar mostrar mensajes después de crear reserva

  @override
  void initState() {
    super.initState();
    // Cargar el nombre del usuario actual después de que el widget esté completamente construido
    // Usar un pequeño delay para asegurar que el Provider esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // Pequeño delay para asegurar que el contexto esté completamente inicializado
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _cargarNombreUsuarioActual();
          _cargarDocentesFirestore();
        }
      }
    });
  }
  
  // Cargar docentes desde Firestore
  Future<void> _cargarDocentesFirestore() async {
    if (!mounted) return;
    
    try {
      if (!context.mounted) return;
      final usuarioService = Provider.of<UsuarioService>(context, listen: false);
      
      // Obtener todos los usuarios con rol 'docente'
      final snapshot = await usuarioService.getUsuariosPorRol('docente').first;
      
      if (mounted) {
        final docentes = <String>[];
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final nombre = data['nombre'] as String?;
          if (nombre != null && nombre.isNotEmpty) {
            docentes.add(nombre);
          }
        }
        
        setState(() {
          _docentesFirestore = docentes;
        });
      }
    } catch (e) {
      print('Error al cargar docentes desde Firestore: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtener argumentos de navegación
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _recursoID = args['recursoID'] as String?;
      _recursoNombre = args['recursoNombre'] as String?;
      _hora = args['hora'] as String?;
      // Si viene un día de la semana, calcular la fecha del próximo día correspondiente
      if (args['dia'] != null) {
        final diaSemana = args['dia'] as String;
        _fechaUso = _getNextWeekday(diaSemana);
      }
    }
  }

  @override
  void didUpdateWidget(CrearReservaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar el nombre cuando el widget se actualiza (por ejemplo, al regresar de editar perfil)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cargarNombreUsuarioActual(forzarActualizacion: true);
        _cargarDocentesFirestore(); // Recargar docentes también
      }
    });
  }

  // Obtener nombre por defecto basado en el email
  String? _obtenerNombrePorDefecto(String? email) {
    if (email == null) return null;
    
    // Buscar coincidencia exacta
    if (_emailANombre.containsKey(email)) {
      return _emailANombre[email];
    }
    
    // Buscar coincidencia parcial (por si el email tiene variaciones)
    for (final entry in _emailANombre.entries) {
      if (email.toLowerCase().contains(entry.key.toLowerCase().split('@')[0])) {
        return entry.value;
      }
    }
    
    return null;
  }

  Future<void> _cargarNombreUsuarioActual({bool forzarActualizacion = false}) async {
    // Si ya está cargado y no se fuerza actualización, no hacer nada
    if (!forzarActualizacion && _nombreUsuarioActual != null) return;
    
    // Verificar que el widget esté montado antes de continuar
    if (!mounted) return;
    
    try {
      // Verificar que el Provider esté disponible
      if (!context.mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      
      // PRIMERO intentar obtener el nombre actualizado de Firestore
      String? nombre = null;
      if (context.mounted) {
        final usuarioService = Provider.of<UsuarioService>(context, listen: false);
        final usuarioDoc = await usuarioService.getUsuarioActual();
        if (usuarioDoc != null && usuarioDoc.exists) {
          final usuarioData = usuarioDoc.data() as Map<String, dynamic>?;
          nombre = usuarioData?['nombre'] as String?;
        }
      }
      
      // Si no hay nombre en Firestore, usar el nombre por defecto basado en el email
      if ((nombre == null || nombre.isEmpty) && email != null) {
        nombre = _obtenerNombrePorDefecto(email);
      }
      
      // Si no se encontró nombre por defecto, intentar usar displayName de Firebase Auth
      if ((nombre == null || nombre.isEmpty) && user != null && user.displayName != null) {
        nombre = user.displayName;
      }
      
      // Si aún no hay nombre, usar el email como último recurso
      if (nombre == null || nombre.isEmpty) {
        nombre = email?.split('@')[0] ?? 'Usuario';
      }
      
      if (nombre != null && nombre.isNotEmpty && mounted) {
        setState(() {
          _nombreUsuarioActual = nombre;
          // Pre-seleccionar automáticamente el nombre del usuario actual
          // Si el nombre cambió, actualizar también _docente
          if (_docente == null || _docente == _nombreUsuarioActual || forzarActualizacion) {
            _docente = nombre;
          }
        });
      }
    } catch (e) {
      print('Error al cargar nombre del usuario: $e');
      // Si hay error, intentar usar el nombre por defecto basado en el email
      if (mounted) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final email = user.email;
            final nombrePorDefecto = email != null ? _obtenerNombrePorDefecto(email) : null;
            
            if (nombrePorDefecto != null) {
              setState(() {
                _nombreUsuarioActual = nombrePorDefecto;
                if (_docente == null || forzarActualizacion) {
                  _docente = nombrePorDefecto;
                }
              });
            } else if (user.displayName != null) {
              setState(() {
                _nombreUsuarioActual = user.displayName;
                if (_docente == null || forzarActualizacion) {
                  _docente = user.displayName;
                }
              });
            } else {
              setState(() {
                _nombreUsuarioActual = email?.split('@')[0] ?? 'Usuario';
                if (_docente == null || forzarActualizacion) {
                  _docente = _nombreUsuarioActual;
                }
              });
            }
          }
        } catch (e2) {
          print('Error al obtener nombre: $e2');
          // Si todo falla, al menos mostrar un mensaje de error en el campo
          if (mounted) {
            setState(() {
              _nombreUsuarioActual = 'Usuario';
            });
          }
        }
      }
    }
  }


  // Obtener el próximo día de la semana correspondiente
  DateTime _getNextWeekday(String diaSemana) {
    final hoy = DateTime.now();
    final diasSemana = {
      'Lunes': 1,
      'Martes': 2,
      'Miércoles': 3,
      'Jueves': 4,
      'Viernes': 5,
    };
    final diaObjetivo = diasSemana[diaSemana] ?? 1;
    int diasHasta = (diaObjetivo - hoy.weekday) % 7;
    if (diasHasta == 0) diasHasta = 7; // Si es hoy, ir a la próxima semana
    return hoy.add(Duration(days: diasHasta));
  }

  // Obtener el día de la semana en español de una fecha
  String _getDiaSemana(DateTime fecha) {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dias[fecha.weekday - 1];
  }

  // Validar si una fecha ya pasó (considerando horario escolar)
  // Las horas escolares van de 12:40 PM a 5:00 PM (última hora termina a las 5 PM)
  bool _esFechaPasada(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fechaSeleccionada = DateTime(fecha.year, fecha.month, fecha.day);
    
    // Si la fecha es anterior a hoy, definitivamente pasó
    if (fechaSeleccionada.isBefore(hoy)) {
      return true;
    }
    
    // Si es hoy, verificar si ya pasó el horario escolar completo
    // La última hora termina a las 5:00 PM, así que después de las 5 PM
    // consideramos que el día escolar definitivamente pasó
    if (fechaSeleccionada.isAtSameMomentAs(hoy)) {
      // Si es después de las 5 PM, el día escolar definitivamente pasó
      return ahora.hour >= 17 || (ahora.hour == 17 && ahora.minute > 0); // Después de las 5:00 PM
    }
    
    return false;
  }

  // Validar si una hora específica ya pasó para la fecha seleccionada
  bool _esHoraPasada(DateTime fecha, String hora) {
    if (_esFechaPasada(fecha)) {
      return true; // Si la fecha ya pasó, la hora también
    }
    
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fechaSeleccionada = DateTime(fecha.year, fecha.month, fecha.day);
    
    // Si no es hoy, la hora no ha pasado
    if (!fechaSeleccionada.isAtSameMomentAs(hoy)) {
      return false;
    }
    
    // Si es hoy, verificar si la hora ya pasó
    // Para bloques, verificar la hora más tardía del bloque
    DateTime? horaInicioBloque;
    
    if (hora.startsWith('Bloque')) {
      // Para bloques, obtener la hora más tardía de las horas que incluye
      horaInicioBloque = _obtenerHoraMasTardiaBloque(hora);
    } else {
      // Para horas individuales, obtener la hora de inicio directamente
      final horaMinutosBloque = _obtenerHoraMinutosBloque(hora);
      if (horaMinutosBloque == null) {
        return false; // Si no se puede determinar, permitir
      }
      horaInicioBloque = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        horaMinutosBloque['hora']!,
        horaMinutosBloque['minutos']!,
      );
    }
    
    if (horaInicioBloque == null) {
      return false; // Si no se puede determinar, permitir
    }
    
    // Si la hora actual es igual o posterior a la hora de inicio del bloque/hora, ya pasó
    // Pero permitimos si la diferencia es muy pequeña (menos de 5 minutos antes)
    // para dar un margen de tiempo
    return ahora.isAfter(horaInicioBloque.subtract(const Duration(minutes: 5)));
  }

  // Obtener la hora más tardía de un bloque (útil para validar si el bloque aún es válido)
  DateTime? _obtenerHoraMasTardiaBloque(String bloque) {
    final ahora = DateTime.now();
    List<DateTime> horasDelBloque = [];
    
    if (bloque.contains('Bloque 1')) {
      // Bloque 1 (1ª+2ª): 12:40 PM y 1:20 PM
      horasDelBloque = [
        DateTime(ahora.year, ahora.month, ahora.day, 12, 40),
        DateTime(ahora.year, ahora.month, ahora.day, 13, 20),
      ];
    } else if (bloque.contains('Bloque 2')) {
      // Bloque 2 (3ª+4ª): 2:00 PM y 2:40 PM
      horasDelBloque = [
        DateTime(ahora.year, ahora.month, ahora.day, 14, 0),
        DateTime(ahora.year, ahora.month, ahora.day, 14, 40),
      ];
    } else if (bloque.contains('Bloque 3')) {
      // Bloque 3 (5ª+6ª): 3:40 PM y 4:20 PM
      horasDelBloque = [
        DateTime(ahora.year, ahora.month, ahora.day, 15, 40),
        DateTime(ahora.year, ahora.month, ahora.day, 16, 20),
      ];
    } else {
      return null;
    }
    
    // Retornar la hora más tardía del bloque
    horasDelBloque.sort((a, b) => b.compareTo(a));
    return horasDelBloque.first;
  }

  // Obtener la hora y minutos de inicio de un bloque/hora
  // Retorna un Map con 'hora' y 'minutos', o null si no se encuentra
  Map<String, int>? _obtenerHoraMinutosBloque(String horaBloque) {
    final mapaHoras = {
      '1ª Hora': {'hora': 12, 'minutos': 40},    // 12:40 PM
      '2ª Hora': {'hora': 13, 'minutos': 20},   // 1:20 PM
      '3ª Hora': {'hora': 14, 'minutos': 0},    // 2:00 PM
      '4ª Hora': {'hora': 14, 'minutos': 40},   // 2:40 PM
      '5ª Hora': {'hora': 15, 'minutos': 40},   // 3:40 PM
      '6ª Hora': {'hora': 16, 'minutos': 20},   // 4:20 PM
      'Bloque 1 (1ª+2ª)': {'hora': 12, 'minutos': 40},  // 12:40 PM (inicio del bloque)
      'Bloque 2 (3ª+4ª)': {'hora': 14, 'minutos': 0},   // 2:00 PM (inicio del bloque)
      'Bloque 3 (5ª+6ª)': {'hora': 15, 'minutos': 40},  // 3:40 PM (inicio del bloque)
    };
    
    final resultado = mapaHoras[horaBloque];
    if (resultado == null) return null;
    
    return {'hora': resultado['hora']!, 'minutos': resultado['minutos']!};
  }

  // Obtener la hora de inicio de un bloque/hora (método legacy para compatibilidad)
  int? _obtenerHoraBloque(String horaBloque) {
    final resultado = _obtenerHoraMinutosBloque(horaBloque);
    return resultado?['hora'];
  }

  // Mostrar mensaje de fecha/hora pasada
  Future<void> _mostrarMensajeFechaPasada(bool esFecha, {String? hora}) async {
    if (!mounted) return;
    
    String mensaje;
    if (esFecha) {
      final ahora = DateTime.now();
      if (ahora.hour >= 17) {
        mensaje = 'No puedes crear una reserva para hoy porque el horario escolar ya pasó.\n\n'
            'El horario escolar termina después de las 5 PM. Por favor selecciona una fecha a partir de mañana.';
      } else {
        mensaje = 'No puedes crear una reserva para una fecha que ya pasó.\n\n'
            'Por favor selecciona una fecha futura.';
      }
    } else {
      mensaje = 'No puedes crear una reserva para un horario que ya pasó.\n\n'
          'La hora seleccionada ya ocurrió hoy. Por favor selecciona una hora futura.\n\n'
          'Nota: Las horas se pueden reservar hasta 5 minutos antes de que comiencen.';
    }
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Fecha/Hora Inválida'),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // Limpiar todos los campos del formulario
  void _limpiarFormulario() {
    // Guardar el docente actual antes de limpiar
    final docentePorDefecto = _nombreUsuarioActual;
    
    // Limpiar el controller de observación primero
    _observacionController.clear();
    
    // Resetear el formulario primero (esto limpia los validadores)
    _formKey.currentState?.reset();
    
    // Limpiar todos los campos del estado, manteniendo solo el docente por defecto
    setState(() {
      _recursoID = null;
      _recursoNombre = null;
      _fechaUso = null;
      _hora = null;
      _asignatura = null;
      _grado = null;
      _observacion = null;
      _disponibilidadFecha = null;
      _cargandoDisponibilidad = false;
      // Mantener el docente por defecto seleccionado
      _docente = docentePorDefecto;
    });
    
    // Asegurar que el controller esté completamente limpio después del setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _observacionController.text.isNotEmpty) {
        _observacionController.clear();
      }
    });
  }

  // Mostrar mensaje flotante centrado y esperar a que se cierre
  Future<void> _mostrarMensajeExito() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Solicitud realizada',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Cargar disponibilidad cuando se selecciona la fecha
  Future<void> _cargarDisponibilidadFecha() async {
    if (_fechaUso == null) {
      setState(() {
        _disponibilidadFecha = null;
      });
      return;
    }

    setState(() {
      _cargandoDisponibilidad = true;
    });

    try {
      final reservaService = Provider.of<ReservaService>(context, listen: false);
      final disponibilidad = await reservaService.getDisponibilidadPorFecha(_fechaUso!);
      
      if (mounted) {
        setState(() {
          _disponibilidadFecha = disponibilidad;
          _cargandoDisponibilidad = false;
        });
      }
    } catch (e) {
      print('Error al cargar disponibilidad: $e');
      if (mounted) {
        setState(() {
          _cargandoDisponibilidad = false;
        });
      }
    }
  }

  // Verificar disponibilidad cuando se selecciona hora/bloque
  Future<void> _verificarDisponibilidadHora() async {
    if (_fechaUso == null || _hora == null) {
      return;
    }

    String? recursoIDFinal;
    if (_recursoID != null) {
      recursoIDFinal = _recursoID;
    } else if (_recursoNombre != null) {
      recursoIDFinal = _recursoNombre;
    } else {
      return; // No hay recurso seleccionado
    }

    try {
      final reservaService = Provider.of<ReservaService>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      final authService = Provider.of<AuthService>(context, listen: false);
      final esAdmin = authService.isAdmin;
      
      // Determinar qué usuarioID excluir:
      // - Si es admin y hay un docente seleccionado, necesitamos excluir el usuarioID del docente
      // - Si no es admin o no hay docente seleccionado, excluir el usuarioID del usuario actual
      String? usuarioIDExcluir = user?.uid;
      
      if (esAdmin && _docente != null) {
        // Si es admin, intentar obtener el usuarioID del docente seleccionado
        try {
          final usuarioService = Provider.of<UsuarioService>(context, listen: false);
          final docentesSnapshot = await usuarioService.getUsuariosPorRol('docente').first;
          
          String normalizarNombre(String nombre) {
            return nombre
                .toLowerCase()
                .replaceAll(' ', '')
                .replaceAll('_', '')
                .replaceAll('-', '')
                .trim();
          }
          
          final nombreDocenteNormalizado = normalizarNombre(_docente!);
          for (var doc in docentesSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final nombre = data['nombre'] as String?;
            if (nombre != null && normalizarNombre(nombre) == nombreDocenteNormalizado) {
              usuarioIDExcluir = doc.id;
              break;
            }
          }
        } catch (e) {
          print('⚠️ Error al buscar usuarioID del docente para exclusión: $e');
          // Si hay error, usar el usuarioID del admin como fallback
        }
      }
      
      // Excluir las reservas del usuario correspondiente para evitar que vea conflictos con sus propias reservas
      final resultado = await reservaService.verificarDisponibilidadPorFechaConDetalles(
        _fechaUso!,
        _hora!,
        recursoIDFinal!,
        excluirUsuarioID: usuarioIDExcluir, // Excluir reservas del usuario correspondiente
      );

      // No mostrar el mensaje si la reserva se acaba de crear exitosamente
      if (!resultado['disponible'] && mounted && !_reservaRecienCreada) {
        final reservaOcupada = resultado['reservaOcupada'] as Map<String, dynamic>?;
        if (reservaOcupada != null) {
          final docenteNombre = reservaOcupada['usuarioNombre'] ?? 'Docente';
          final asignatura = reservaOcupada['asignatura'] ?? 'Sin asignatura';
          final grado = reservaOcupada['grado'] ?? 'Sin grado';
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Recurso ya asignado'),
                ],
              ),
              content: Text(
                'El recurso ya está asignado en esta hora o bloque por:\n\n'
                'Docente: $docenteNombre\n'
                'Asignatura: $asignatura\n'
                'Grado: $grado',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('Error al verificar disponibilidad: $e');
    }
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _crearReserva() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if ((_recursoID == null && _recursoNombre == null) || _fechaUso == null || _hora == null || _asignatura == null || _docente == null || _grado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar que la fecha no haya pasado
    if (_esFechaPasada(_fechaUso!)) {
      await _mostrarMensajeFechaPasada(true);
      setState(() => _isLoading = false);
      return;
    }

    // Validar que la hora no haya pasado
    if (_esHoraPasada(_fechaUso!, _hora!)) {
      await _mostrarMensajeFechaPasada(false, hora: _hora);
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reservaService = Provider.of<ReservaService>(context, listen: false);
      final recursoService = Provider.of<RecursoService>(context, listen: false);
      final usuarioService = Provider.of<UsuarioService>(context, listen: false);

      // Obtener datos del recurso
      String recursoNombreFinal;
      String recursoIDFinal;
      
      if (_recursoID != null) {
        // Recurso de Firestore
        final recursoDoc = await recursoService.getRecurso(_recursoID!);
        final recursoData = recursoDoc.data() as Map<String, dynamic>;
        recursoNombreFinal = recursoData['nombre'] ?? 'Recurso';
        recursoIDFinal = _recursoID!;
      } else {
        // Recurso por defecto (usar el nombre como ID)
        recursoNombreFinal = _recursoNombre!;
        recursoIDFinal = _recursoNombre!; // Usar el nombre como identificador
      }

      // Obtener datos del usuario
      final usuarioDoc = await usuarioService.getUsuarioActual();
      final usuarioData = usuarioDoc?.data() as Map<String, dynamic>?;

      // Obtener el día de la semana de la fecha seleccionada
      final diaSemana = _getDiaSemana(_fechaUso!);
      
      // Obtener el usuarioID del docente seleccionado si es admin (necesario para la verificación)
      String? docenteUsuarioIDParaVerificacion;
      final authService = Provider.of<AuthService>(context, listen: false);
      final esAdmin = authService.isAdmin;
      
      if (esAdmin && _docente != null) {
        // Buscar el usuarioID del docente seleccionado para excluirlo de la verificación
        try {
          final docentesSnapshot = await usuarioService.getUsuariosPorRol('docente').first;
          
          String normalizarNombre(String nombre) {
            return nombre
                .toLowerCase()
                .replaceAll(' ', '')
                .replaceAll('_', '')
                .replaceAll('-', '')
                .trim();
          }
          
          final nombreDocenteNormalizado = normalizarNombre(_docente!);
          for (var doc in docentesSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final nombre = data['nombre'] as String?;
            if (nombre != null && normalizarNombre(nombre) == nombreDocenteNormalizado) {
              docenteUsuarioIDParaVerificacion = doc.id;
              break;
            }
          }
        } catch (e) {
          print('⚠️ Error al buscar usuarioID del docente para verificación: $e');
        }
      }
      
      // Verificar disponibilidad por fecha específica (más preciso)
      // Usar try-catch para manejar errores de Firestore
      Map<String, dynamic> resultadoDisponibilidad;
      try {
        final user = FirebaseAuth.instance.currentUser;
        // Si es admin y se encontró el usuarioID del docente, excluir ese usuarioID
        // De lo contrario, excluir el usuarioID del usuario actual
        final usuarioIDExcluir = (esAdmin && docenteUsuarioIDParaVerificacion != null)
            ? docenteUsuarioIDParaVerificacion
            : user?.uid;
            
        resultadoDisponibilidad = await reservaService.verificarDisponibilidadPorFechaConDetalles(
          _fechaUso!,
          _hora!,
          recursoIDFinal,
          excluirUsuarioID: usuarioIDExcluir, // Excluir reservas del usuario correspondiente
        );
      } catch (e) {
        print('Error al verificar disponibilidad: $e');
        // Si hay error al verificar, mostrar advertencia pero permitir crear la reserva
        // (el sistema verificará al guardar)
        resultadoDisponibilidad = {'disponible': true, 'error': e.toString()};
        
        // Mostrar advertencia al usuario
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Advertencia: No se pudo verificar la disponibilidad. La reserva se creará de todas formas.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      if (!resultadoDisponibilidad['disponible']) {
        final reservaOcupada = resultadoDisponibilidad['reservaOcupada'] as Map<String, dynamic>?;
        String mensaje = 'Este horario o bloque ya está ocupado';
        
        if (reservaOcupada != null) {
          final docenteNombre = reservaOcupada['usuarioNombre'] ?? 'Docente';
          final asignatura = reservaOcupada['asignatura'] ?? 'Sin asignatura';
          final grado = reservaOcupada['grado'] ?? 'Sin grado';
          mensaje = 'Este horario o bloque ya está ocupado por $docenteNombre en la asignatura "$asignatura" del grado $grado';
        }
        
        throw mensaje;
      }

      // Obtener el usuarioID del docente seleccionado si es admin
      String? docenteUsuarioID;
      
      if (esAdmin && _docente != null) {
        // Buscar el usuarioID del docente seleccionado
        try {
          print('🔍 Buscando usuarioID para docente: $_docente');
          final docentesSnapshot = await usuarioService.getUsuariosPorRol('docente').first;
          print('📊 Total de docentes encontrados: ${docentesSnapshot.docs.length}');
          
          // Función para normalizar nombres
          String normalizarNombre(String nombre) {
            return nombre
                .toLowerCase()
                .replaceAll(' ', '')
                .replaceAll('_', '')
                .replaceAll('-', '')
                .trim();
          }
          
          final nombreDocenteNormalizado = normalizarNombre(_docente!);
          print('🔍 Nombre docente normalizado: "$nombreDocenteNormalizado"');
          
          for (var doc in docentesSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final nombre = data['nombre'] as String?;
            final email = data['email'] as String?;
            
            if (nombre != null) {
              final nombreNormalizado = normalizarNombre(nombre);
              print('   - Comparando: "$nombreNormalizado" (${doc.id})');
              
              if (nombreNormalizado == nombreDocenteNormalizado) {
                docenteUsuarioID = doc.id;
                print('✅ UsuarioID del docente seleccionado encontrado: $docenteUsuarioID para "$_docente" (nombre en Firestore: "$nombre", email: $email)');
                break;
              }
            }
          }
          
          if (docenteUsuarioID == null) {
            print('⚠️ No se encontró usuarioID para el docente: $_docente');
            print('   Intentando buscar por email...');
            // Intentar buscar por email si el nombre no coincide
            final user = FirebaseAuth.instance.currentUser;
            if (user != null && user.email != null) {
              // Buscar en el mapeo de emails
              final emailDocente = _emailANombre.entries.firstWhere(
                (entry) => normalizarNombre(entry.value) == nombreDocenteNormalizado,
                orElse: () => MapEntry('', ''),
              );
              if (emailDocente.key.isNotEmpty) {
                // Buscar usuario por email
                for (var doc in docentesSnapshot.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final email = data['email'] as String?;
                  if (email != null && email.toLowerCase() == emailDocente.key.toLowerCase()) {
                    docenteUsuarioID = doc.id;
                    print('✅ UsuarioID encontrado por email: $docenteUsuarioID');
                    break;
                  }
                }
              }
            }
          }
        } catch (e) {
          print('⚠️ Error al buscar usuarioID del docente: $e');
        }
      }

      // Crear la reserva
      await reservaService.crearReserva({
        'recursoID': recursoIDFinal,
        'recursoNombre': recursoNombreFinal,
        'dia': diaSemana, // Día de la semana para compatibilidad
        'fechaUso': Timestamp.fromDate(_fechaUso!), // Convertir DateTime a Timestamp
        'hora': _hora!,
        'asignatura': _asignatura!,
        'docente': _docente!,
        'grado': _grado!,
        'observacion': _observacion, // Campo opcional de observación
        // Usar siempre el nombre por defecto basado en el email para identificar al docente
        // Esto asegura que el nombre en las reservas sea consistente según el email/contraseña
        'usuarioNombre': _docente ?? 
            _nombreUsuarioActual ?? 
            FirebaseAuth.instance.currentUser?.displayName ?? 
            'Usuario',
        // Si es admin y se encontró el usuarioID del docente, usarlo
        'docenteUsuarioID': docenteUsuarioID, // UsuarioID del docente seleccionado (solo cuando es admin)
        'estado': 'activa',
        'eliminada': false, // Para auditoría
      });
      
      print('✅ Reserva creada exitosamente');
      print('   - Recurso: $recursoNombreFinal');
      print('   - Fecha de Uso: ${DateFormat('dd-MM-yyyy').format(_fechaUso!)}');
      print('   - Fecha de Solicitud: ${DateFormat('dd-MM-yyyy').format(DateTime.now())} (se guardará como serverTimestamp)');
      print('   - Día: $diaSemana');
      print('   - Hora: ${_hora!}');
      print('   - Asignatura: ${_asignatura!}');
      print('   - Docente: ${_docente!}');
      print('   - Grado: ${_grado!}');

      if (mounted) {
        // Marcar que la reserva se acaba de crear para evitar mensajes de conflicto
        setState(() {
          _reservaRecienCreada = true;
        });
        
        // Mostrar mensaje flotante centrado "Solicitud realizada" y esperar a que se cierre
        await _mostrarMensajeExito();
        
        if (mounted) {
          // Limpiar todos los campos del formulario después de cerrar el diálogo
          _limpiarFormulario();
          // Resetear la bandera después de limpiar
          setState(() {
            _reservaRecienCreada = false;
          });
        }
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

  @override
  Widget build(BuildContext context) {
    final recursoService = Provider.of<RecursoService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Reserva'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final basePadding = Responsive.padding(context);
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            padding: basePadding.copyWith(
              // Padding extra inferior para que nada se tape con la barra del sistema/teclado.
              // Se aumenta bastante para asegurar espacio incluso en pantallas pequeñas.
              bottom: basePadding.bottom + bottomInset + 96,
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
              // 1. Selector de fecha (calendario)
              InkWell(
                onTap: () async {
                  final ahora = DateTime.now();
                  // Si es después de las 5 PM (fin del horario escolar completo), mínimo mañana
                  // Si es antes de las 5 PM, puede ser hoy (el horario empieza a las 12:40 PM)
                  final fechaMinima = (ahora.hour >= 17 || (ahora.hour == 17 && ahora.minute > 0))
                      ? ahora.add(const Duration(days: 1)) // Después de las 5 PM, mínimo mañana
                      : ahora; // Antes de las 5 PM, puede ser hoy
                  
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: _fechaUso ?? fechaMinima,
                    firstDate: fechaMinima,
                    lastDate: DateTime(2055, 12, 31), // Permitir hasta 2055 (aproximadamente 20 años más)
                    locale: const Locale('es', 'ES'),
                  );
                  if (fecha != null) {
                    // Validar si la fecha ya pasó
                    if (_esFechaPasada(fecha)) {
                      await _mostrarMensajeFechaPasada(true);
                      return;
                    }
                    
                    setState(() {
                      _fechaUso = fecha;
                      _hora = null; // Resetear hora al cambiar fecha
                    });
                    _cargarDisponibilidadFecha();
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
              if (_fechaUso != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Día: ${_getDiaSemana(_fechaUso!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Mostrar disponibilidad de horas
                if (_cargandoDisponibilidad)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_disponibilidadFecha != null)
                  _buildDisponibilidadHoras(),
              ],
              const SizedBox(height: 16),
              // 2. Selector de hora/bloque
              DropdownButtonFormField<String>(
                value: _hora,
                decoration: const InputDecoration(
                  labelText: 'Hora o Bloque *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                  hintText: 'Selecciona una hora o bloque',
                ),
                items: _horasYBloques.map((hora) {
                  return DropdownMenuItem(
                    value: hora,
                    child: Text(hora),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value != null && _fechaUso != null) {
                    // Validar si la hora ya pasó
                    if (_esHoraPasada(_fechaUso!, value)) {
                      await _mostrarMensajeFechaPasada(false, hora: value);
                      setState(() => _hora = null); // Limpiar la hora seleccionada
                      return;
                    }
                  }
                  
                  setState(() => _hora = value);
                  // Verificar disponibilidad cuando se selecciona hora/bloque
                  if (value != null) {
                    await _verificarDisponibilidadHora();
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecciona una hora o bloque';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              // 3. Selector de docente
              // Si aún no se ha cargado el nombre, mostrar campo temporal
              Builder(
                builder: (context) {
                  final authService = Provider.of<AuthService>(context);
                  final usuarioService = Provider.of<UsuarioService>(context);
                  final esAdmin = authService.isAdmin;
                  
                  if (_nombreUsuarioActual == null && !esAdmin) {
                    return DropdownButtonFormField<String>(
                      value: null,
                      decoration: const InputDecoration(
                        labelText: 'Docente *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                        helperText: 'Cargando información del docente...',
                      ),
                      items: const [],
                      onChanged: null,
                    );
                  }
                  
                  // Usar StreamBuilder para cargar docentes desde Firestore en tiempo real
                  return StreamBuilder(
                    stream: usuarioService.getUsuariosPorRol('docente'),
                    builder: (context, snapshot) {
                      // Mapa de emails normalizados a nombres actualizados de Firestore
                      final Map<String, String> emailANombreFirestore = {};
                      
                      // Función para normalizar emails (minúsculas, sin espacios)
                      String normalizarEmail(String email) => email.toLowerCase().trim();
                      
                      // Función para normalizar nombres (minúsculas, sin espacios, sin underscores, sin guiones)
                      // Esto permite comparar "Judith Rivas" con "Judith_Rivas" o "judith-rivas"
                      String normalizarNombre(String nombre) {
                        return nombre
                            .toLowerCase()
                            .replaceAll(' ', '')
                            .replaceAll('_', '')
                            .replaceAll('-', '')
                            .trim();
                      }
                      
                      // Función para verificar si un nombre ya está en la lista (comparación normalizada)
                      bool nombreYaExiste(List<String> lista, String nombre) {
                        final nombreNormalizado = normalizarNombre(nombre);
                        return lista.any((n) => normalizarNombre(n) == nombreNormalizado);
                      }
                      
                      // Obtener nombres actualizados de Firestore mapeados por email normalizado
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final email = data['email'] as String?;
                          final nombre = data['nombre'] as String?;
                          if (email != null && nombre != null && nombre.isNotEmpty) {
                            emailANombreFirestore[normalizarEmail(email)] = nombre;
                          }
                        }
                      }
                      
                      // Actualizar el nombre del usuario actual desde Firestore si está disponible
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null && user.email != null && snapshot.hasData) {
                        final emailUsuario = normalizarEmail(user.email!);
                        if (emailANombreFirestore.containsKey(emailUsuario)) {
                          final nombreActualizado = emailANombreFirestore[emailUsuario]!;
                          // Actualizar solo si el nombre cambió
                          if (_nombreUsuarioActual != nombreActualizado) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  final nombreAnterior = _nombreUsuarioActual;
                                  _nombreUsuarioActual = nombreActualizado;
                                  
                                  // Si el docente seleccionado es el usuario actual, actualizar también al nuevo nombre
                                  // Esto es importante cuando el usuario cambia su nombre en el perfil
                                  if (_docente != null && nombreAnterior != null) {
                                    // Si el docente seleccionado coincide con el nombre anterior (usando normalización), actualizarlo al nuevo nombre
                                    final docenteNormalizado = normalizarNombre(_docente!);
                                    final nombreAnteriorNormalizado = normalizarNombre(nombreAnterior);
                                    if (docenteNormalizado == nombreAnteriorNormalizado) {
                                      // El docente seleccionado es el usuario actual, actualizar al nuevo nombre
                                      _docente = nombreActualizado;
                                    }
                                  } else if (_docente == null) {
                                    // Si no hay docente seleccionado, usar el nuevo nombre del usuario actual
                                    _docente = nombreActualizado;
                                  } else if (nombreAnterior != null) {
                                    // Si hay docente seleccionado pero no coincide con el nombre anterior, verificar si coincide con el nuevo
                                    final docenteNormalizado = normalizarNombre(_docente!);
                                    final nombreNuevoNormalizado = normalizarNombre(nombreActualizado);
                                    if (docenteNormalizado == nombreNuevoNormalizado) {
                                      // Ya coincide con el nuevo nombre, no hacer nada
                                    } else {
                                      // No coincide, actualizar al nuevo nombre si es el usuario actual
                                      _docente = nombreActualizado;
                                    }
                                  }
                                });
                              }
                            });
                          }
                        }
                      }
                      
                      // Lista combinada de docentes
                      List<String> listaDocentes = [];
                      
                      // Primero, agregar nombres de la lista base, pero reemplazar con nombres actualizados de Firestore
                      for (final nombreBase in _docentesBase) {
                        // Buscar si este nombre corresponde a algún email en el mapeo
                        String? emailCorrespondiente;
                        for (final entry in _emailANombre.entries) {
                          if (entry.value == nombreBase) {
                            emailCorrespondiente = entry.key;
                            break;
                          }
                        }
                        
                        // Si encontramos el email y hay un nombre actualizado en Firestore, usar ese
                        if (emailCorrespondiente != null) {
                          final emailNormalizado = normalizarEmail(emailCorrespondiente);
                          if (emailANombreFirestore.containsKey(emailNormalizado)) {
                            final nombreActualizado = emailANombreFirestore[emailNormalizado]!;
                            if (!nombreYaExiste(listaDocentes, nombreActualizado)) {
                              listaDocentes.add(nombreActualizado);
                            }
                            continue; // Ya agregamos el nombre actualizado, saltar al siguiente
                          }
                        }
                        
                        // Si no hay actualización, usar el nombre de la lista base
                        if (!nombreYaExiste(listaDocentes, nombreBase)) {
                          listaDocentes.add(nombreBase);
                        }
                      }
                      
                      // Agregar docentes de Firestore que no están en la lista base (nuevos usuarios)
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final email = data['email'] as String?;
                          final nombre = data['nombre'] as String?;
                          if (email != null && nombre != null && nombre.isNotEmpty) {
                            final emailNormalizado = normalizarEmail(email);
                            // Solo agregar si no está en la lista base (no está en el mapeo de emails)
                            bool estaEnListaBase = false;
                            for (final entry in _emailANombre.entries) {
                              if (normalizarEmail(entry.key) == emailNormalizado) {
                                estaEnListaBase = true;
                                break;
                              }
                            }
                            // Verificar que no exista ya en la lista (comparación normalizada)
                            if (!estaEnListaBase && !nombreYaExiste(listaDocentes, nombre)) {
                              listaDocentes.add(nombre);
                            }
                          }
                        }
                      }
                      
                      // Agregar el nombre del usuario actual si no está en la lista
                      if (_nombreUsuarioActual != null && !nombreYaExiste(listaDocentes, _nombreUsuarioActual!)) {
                        listaDocentes.insert(0, _nombreUsuarioActual!);
                      }
                      
                      // Eliminar duplicados usando normalización (por si acaso)
                      final nombresNormalizados = <String>{};
                      listaDocentes = listaDocentes.where((nombre) {
                        final normalizado = normalizarNombre(nombre);
                        if (nombresNormalizados.contains(normalizado)) {
                          return false; // Duplicado
                        }
                        nombresNormalizados.add(normalizado);
                        return true;
                      }).toList();
                      
                      // Ordenar alfabéticamente
                      listaDocentes.sort();
                      
                      // Encontrar el valor correcto que coincida exactamente con un item de la lista
                      String? valorSeleccionado;
                      if (listaDocentes.isNotEmpty) {
                        // Primero intentar con _docente si existe
                        if (_docente != null) {
                          // Buscar el valor exacto primero
                          if (listaDocentes.contains(_docente)) {
                            valorSeleccionado = _docente;
                          } else {
                            // Si no está exacto, buscar por normalización
                            final docenteNormalizado = normalizarNombre(_docente!);
                            final encontrado = listaDocentes.where(
                              (docente) => normalizarNombre(docente) == docenteNormalizado,
                            ).toList();
                            if (encontrado.isNotEmpty) {
                              // Usar el primer valor encontrado (debería ser único después de eliminar duplicados)
                              valorSeleccionado = encontrado.first;
                            } else {
                              // Si no se encuentra, usar null
                              valorSeleccionado = null;
                            }
                          }
                        } 
                        // Si no hay _docente y no es admin, buscar por _nombreUsuarioActual
                        else if (!esAdmin && _nombreUsuarioActual != null) {
                          // Buscar el nombre del usuario actual en la lista
                          if (listaDocentes.contains(_nombreUsuarioActual!)) {
                            valorSeleccionado = _nombreUsuarioActual;
                          } else {
                            final nombreNormalizado = normalizarNombre(_nombreUsuarioActual!);
                            final encontrado = listaDocentes.where(
                              (docente) => normalizarNombre(docente) == nombreNormalizado,
                            ).toList();
                            if (encontrado.isNotEmpty) {
                              valorSeleccionado = encontrado.first;
                            } else {
                              valorSeleccionado = null;
                            }
                          }
                        }
                        // Si es admin y no hay _docente, dejar null para que seleccione
                        else if (esAdmin) {
                          valorSeleccionado = null;
                        }
                      } else {
                        // Si la lista está vacía, usar null
                        valorSeleccionado = null;
                      }
                      
                      // Verificar que no haya valores duplicados en los items (seguridad adicional)
                      final valoresUnicos = <String>{};
                      final itemsSinDuplicados = listaDocentes.where((docente) {
                        if (valoresUnicos.contains(docente)) {
                          return false; // Duplicado exacto
                        }
                        valoresUnicos.add(docente);
                        return true;
                      }).toList();
                      
                      // Verificar que el valor seleccionado esté realmente en la lista sin duplicados (seguridad adicional)
                      if (valorSeleccionado != null && !itemsSinDuplicados.contains(valorSeleccionado)) {
                        valorSeleccionado = null;
                      }
                  
                  return DropdownButtonFormField<String>(
                    value: valorSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Docente *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                      helperText: esAdmin
                          ? 'Selecciona el docente para la reserva'
                          : (_nombreUsuarioActual != null
                              ? 'Solo puedes seleccionar tu nombre: $_nombreUsuarioActual'
                              : 'Cargando...'),
                    ),
                    items: itemsSinDuplicados.map((docente) {
                      // Comparar usando normalización para detectar el nombre del usuario actual
                      // incluso si hay diferencias de formato (espacios, underscores, etc.)
                      final esUsuarioActual = _nombreUsuarioActual != null &&
                          normalizarNombre(docente) == normalizarNombre(_nombreUsuarioActual!);
                      // Si es admin, todos los docentes están habilitados
                      // Si es docente, solo su nombre está habilitado
                      final habilitado = esAdmin || esUsuarioActual;
                      
                      return DropdownMenuItem(
                        value: docente,
                        enabled: habilitado,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (habilitado)
                              Icon(
                                esUsuarioActual ? Icons.check_circle : Icons.person,
                                color: esUsuarioActual ? Colors.green : Colors.blue,
                                size: 18,
                              )
                            else
                              const Icon(Icons.block, color: Colors.grey, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                docente,
                                style: TextStyle(
                                  color: habilitado ? Colors.black : Colors.grey,
                                  fontWeight: esUsuarioActual ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        // Si es admin, puede seleccionar cualquier docente
                        // Si es docente, verificar usando normalización
                        if (esAdmin) {
                          setState(() => _docente = value);
                        } else if (_nombreUsuarioActual != null) {
                          // Comparar usando normalización para manejar diferencias de formato
                          if (normalizarNombre(value) == normalizarNombre(_nombreUsuarioActual!)) {
                            setState(() => _docente = value);
                          }
                        }
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona un docente';
                      }
                      // Si es docente (no admin), validar que sea su propio nombre usando normalización
                      if (!esAdmin && _nombreUsuarioActual != null) {
                        if (normalizarNombre(value) != normalizarNombre(_nombreUsuarioActual!)) {
                          return 'Solo puedes seleccionar tu propio nombre';
                        }
                      }
                      return null;
                    },
                  );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // 4. Selector de recurso
              StreamBuilder(
                stream: recursoService.getRecursos(),
                builder: (context, snapshot) {
                  // Lista de recursos disponibles (por defecto + Firestore)
                  List<DropdownMenuItem<String>> itemsRecursos = [];
                  
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
                      itemsRecursos.add(
                        DropdownMenuItem(
                          value: recursoEnFirestore != null 
                              ? recursoEnFirestore['id'] 
                              : 'default_$recurso',
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(recurso),
                            ],
                          ),
                        ),
                      );
                    }
                  }
                  
                  // Agregar recursos de Firestore activos que no son recursos por defecto
                  if (snapshot.hasData && snapshot.data != null && snapshot.data!.docs.isNotEmpty) {
                    try {
                      final recursos = snapshot.data!.docs;
                      for (final doc in recursos) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nombre = data['nombre'] ?? 'Sin nombre';
                        final estado = data['estado'] ?? 'inactivo';
                        // Solo agregar si no es un recurso por defecto Y está activo
                        if (!_recursosPorDefecto.contains(nombre) && estado == 'activo') {
                          itemsRecursos.add(
                            DropdownMenuItem(
                              value: doc.id,
                              child: Row(
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(nombre),
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

                  // Si hay error, solo registrar
                  if (snapshot.hasError) {
                    print('Error al cargar recursos: ${snapshot.error}');
                  }

                  // Determinar el valor inicial del dropdown
                  String? valorInicial;
                  if (_recursoID != null) {
                    valorInicial = _recursoID;
                  } else if (_recursoNombre != null) {
                    // Si es un recurso por defecto, verificar si existe en Firestore
                    final recursoEnFirestore = recursosFirestore[_recursoNombre];
                    if (recursoEnFirestore != null) {
                      valorInicial = recursoEnFirestore['id'];
                    } else {
                      valorInicial = 'default_$_recursoNombre';
                    }
                  }

                  // Mostrar selector con recursos activos
                  return DropdownButtonFormField<String>(
                    value: valorInicial,
                    decoration: const InputDecoration(
                      labelText: 'Recurso *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                      helperText: 'Selecciona el recurso que deseas reservar',
                    ),
                    items: itemsRecursos,
                    onChanged: (value) async {
                      setState(() {
                        if (value != null && value.startsWith('default_')) {
                          // Recurso por defecto que no existe en Firestore
                          _recursoNombre = value.replaceFirst('default_', '');
                          _recursoID = null;
                        } else if (value != null) {
                          // Recurso de Firestore (puede ser un recurso por defecto o uno nuevo)
                          _recursoID = value;
                          // Verificar si es un recurso por defecto para mantener el nombre
                          final recursoEnFirestore = recursosFirestore.values
                              .firstWhere((r) => r['id'] == value, orElse: () => {});
                          if (recursoEnFirestore.isNotEmpty) {
                            final nombre = recursoEnFirestore['data']['nombre'] ?? '';
                            if (_recursosPorDefecto.contains(nombre)) {
                              _recursoNombre = nombre;
                            } else {
                              _recursoNombre = null;
                            }
                          } else {
                            _recursoNombre = null;
                          }
                        }
                      });
                      // Si ya hay hora seleccionada, verificar disponibilidad
                      if (_hora != null) {
                        await _verificarDisponibilidadHora();
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona un recurso';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // 5. Selector de grado/aula
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

                      // Construir la lista final de grados disponibles manteniendo el orden definido en administración
                      final List<String> listaGrados = [];

                      // 1. Agregar TODOS los grados activos de Firestore (incluye los creados por admin),
                      //    ordenados por el campo "orden" y luego por nombre
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
                        alignment: Alignment.centerLeft,
                        items: listaGrados.map((grado) {
                          return DropdownMenuItem(
                            value: grado,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              grado,
                              textAlign: TextAlign.left,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _grado = value);
                        },
                        validator: (value) {
                          if (value == null) {
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
              // 6. Selector de asignatura
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
                      //    ordenadas por el campo \"orden\" y luego por nombre
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
                        alignment: Alignment.centerLeft,
                        items: listaAsignaturas.map((asignatura) {
                          return DropdownMenuItem(
                            value: asignatura,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              asignatura,
                              textAlign: TextAlign.left,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _asignatura = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecciona una asignatura';
                          }
                          return null;
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // 7. Campo de observación
              Builder(
                builder: (context) {
                  // Calcular si el dispositivo es pequeño para ajustar el helperText
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isSmallScreen = screenWidth < 400;
                  
                  return TextFormField(
                    controller: _observacionController,
                    maxLines: null, // Permite expandirse automáticamente
                    minLines: 3, // Mínimo 3 líneas
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: 'Observación',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.note),
                      helperText: isSmallScreen
                          ? 'Ej: Nombre de aplicación o\nlink para descargar en tablets'
                          : 'Ej: Nombre de aplicación o link para descargar en tablets',
                      helperMaxLines: isSmallScreen ? 2 : 1, // 2 líneas en pantallas pequeñas
                      helperStyle: TextStyle(
                        fontSize: Responsive.isMobile(context) ? 12 : 13,
                      ),
                      alignLabelWithHint: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _observacion = value.trim().isEmpty ? null : value.trim();
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              // Botón de crear
              ElevatedButton(
                onPressed: _isLoading ? null : _crearReserva,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Crear Reserva',
                        style: TextStyle(fontSize: 16),
                      ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
        },
      ),
    );
  }

  // Widget para mostrar disponibilidad de horas
  Widget _buildDisponibilidadHoras() {
    if (_disponibilidadFecha == null || _disponibilidadFecha!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Todas las horas están disponibles para esta fecha',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    // Agrupar por recurso
    final recursosMap = <String, List<Map<String, dynamic>>>{};
    _disponibilidadFecha!.forEach((key, value) {
      final recursoID = value['recursoID'] as String? ?? '';
      if (!recursosMap.containsKey(recursoID)) {
        recursosMap[recursoID] = [];
      }
      recursosMap[recursoID]!.add(value);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Horas ocupadas en esta fecha:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recursosMap.entries.map((entry) {
            final recursoNombre = entry.value.isNotEmpty
                ? entry.value.first['recursoNombre'] as String? ?? 'Recurso'
                : 'Recurso';
            final horasOcupadas = entry.value
                .where((v) => v['ocupada'] == true)
                .map((v) => v['hora'] as String)
                .toList();

            if (horasOcupadas.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recursoNombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: horasOcupadas.map((hora) {
                      final info = entry.value.firstWhere(
                        (v) => v['hora'] == hora,
                        orElse: () => <String, dynamic>{},
                      );
                      return Chip(
                        label: Text(
                          '$hora\n${info['docente'] ?? ''}',
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                        backgroundColor: Colors.orange.shade100,
                        labelStyle: const TextStyle(color: Colors.orange),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
