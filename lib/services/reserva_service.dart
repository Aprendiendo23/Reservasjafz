import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'notificacion_service.dart';

class ReservaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificacionService _notificacionService = NotificacionService();

  CollectionReference get reservasCollection =>
      _firestore.collection('reservas');

  // Obtener todas las reservas (solo activas para usuarios normales)
  Stream<QuerySnapshot> getReservas({bool incluirEliminadas = false}) {
    if (incluirEliminadas) {
      // Admins pueden ver todas incluyendo eliminadas
      return reservasCollection.orderBy('creado', descending: true).snapshots();
    } else {
      // Usuarios normales solo ven reservas activas (no eliminadas)
      return reservasCollection
          .where('eliminada', isEqualTo: false)
          .orderBy('creado', descending: true)
          .snapshots();
    }
  }

  // Obtener reservas de un usuario (solo activas)
  Stream<QuerySnapshot> getReservasUsuario(String usuarioID) {
    print('🔍 Buscando reservas para usuarioID: $usuarioID');
    final stream = reservasCollection
        .where('usuarioID', isEqualTo: usuarioID)
        .where('eliminada', isEqualTo: false)
        .orderBy('creado', descending: true)
        .snapshots();
    
    // Escuchar el stream para debug
    stream.listen(
      (snapshot) {
        print('📊 Reservas encontradas: ${snapshot.docs.length}');
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          print('   - Reserva ${doc.id}: ${data['recursoNombre']} - ${data['dia']} ${data['hora']}');
        }
      },
      onError: (error) {
        print('❌ Error al obtener reservas: $error');
      },
    );
    
    return stream;
  }

  // Obtener reservas por día y hora
  // Nota: Para verificación de disponibilidad con bloques, usar verificarDisponibilidadConDetalles
  Future<QuerySnapshot> getReservasPorDiaYHora(
    String dia,
    String hora,
    String recursoID,
  ) async {
    // Obtener todas las reservas del recurso en ese día (solo activas)
    return await reservasCollection
        .where('dia', isEqualTo: dia)
        .where('recursoID', isEqualTo: recursoID)
        .where('eliminada', isEqualTo: false)
        .get();
  }

  // Verificar disponibilidad (lógica anti-choques)
  Future<bool> verificarDisponibilidad(
    String dia,
    String hora,
    String recursoID,
  ) async {
    final resultado = await verificarDisponibilidadConDetalles(dia, hora, recursoID);
    return resultado['disponible'] as bool;
  }

  // Verificar disponibilidad con detalles (incluye información de conflicto)
  Future<Map<String, dynamic>> verificarDisponibilidadConDetalles(
    String dia,
    String hora,
    String recursoID,
  ) async {
    // Obtener todas las reservas del recurso en ese día (solo activas, no eliminadas)
    final reservasDelDia = await reservasCollection
        .where('dia', isEqualTo: dia)
        .where('recursoID', isEqualTo: recursoID)
        .where('eliminada', isEqualTo: false)
        .get();

    // Determinar qué horas están ocupadas por la reserva seleccionada
    List<String> horasOcupadas = [];
    
    if (hora.startsWith('Bloque')) {
      // Si es un bloque, verificar todas las horas del bloque
      if (hora.contains('Bloque 1')) {
        horasOcupadas = ['1ª Hora', '2ª Hora'];
      } else if (hora.contains('Bloque 2')) {
        horasOcupadas = ['3ª Hora', '4ª Hora'];
      } else if (hora.contains('Bloque 3')) {
        horasOcupadas = ['5ª Hora', '6ª Hora'];
      }
    } else {
      // Si es una hora individual
      horasOcupadas = [hora];
    }

    // Verificar conflictos con reservas existentes
    for (var doc in reservasDelDia.docs) {
      final reservaData = doc.data() as Map<String, dynamic>;
      final horaReservada = reservaData['hora'] as String?;
      
      if (horaReservada == null) continue;

      // Verificar si hay conflicto
      bool hayConflicto = false;
      
      if (horaReservada.startsWith('Bloque')) {
        // Si la reserva existente es un bloque
        List<String> horasDelBloqueExistente = [];
        if (horaReservada.contains('Bloque 1')) {
          horasDelBloqueExistente = ['1ª Hora', '2ª Hora'];
        } else if (horaReservada.contains('Bloque 2')) {
          horasDelBloqueExistente = ['3ª Hora', '4ª Hora'];
        } else if (horaReservada.contains('Bloque 3')) {
          horasDelBloqueExistente = ['5ª Hora', '6ª Hora'];
        }
        
        // Verificar si hay solapamiento
        hayConflicto = horasOcupadas.any((h) => horasDelBloqueExistente.contains(h));
      } else {
        // Si la reserva existente es una hora individual
        hayConflicto = horasOcupadas.contains(horaReservada);
      }

      if (hayConflicto) {
        // Retornar información del conflicto
        return {
          'disponible': false,
          'reservaOcupada': {
            'usuarioNombre': reservaData['usuarioNombre'] ?? 'Docente',
            'asignatura': reservaData['asignatura'] ?? 'Sin asignatura',
            'hora': horaReservada,
          },
        };
      }
    }

    return {'disponible': true};
  }

  // Crear reserva
  Future<void> crearReserva(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'Usuario no autenticado';
    }

    // Verificar disponibilidad con detalles antes de crear
    final resultado = await verificarDisponibilidadConDetalles(
      data['dia'] as String,
      data['hora'] as String,
      data['recursoID'] as String,
    );

    if (!resultado['disponible']) {
      final reservaOcupada = resultado['reservaOcupada'] as Map<String, dynamic>?;
      String mensaje = 'Este horario o bloque ya está ocupado';
      
      if (reservaOcupada != null) {
        final docenteNombre = reservaOcupada['usuarioNombre'] ?? 'Docente';
        final asignatura = reservaOcupada['asignatura'] ?? 'Sin asignatura';
        mensaje = 'Este horario o bloque ya está ocupado por $docenteNombre en la asignatura "$asignatura"';
      }
      
      throw mensaje;
    }

    // Agregar datos del usuario (solo si no existen)
    data['usuarioID'] = user.uid; // Siempre usar el UID del usuario autenticado
    data['usuarioEmail'] = data['usuarioEmail'] ?? user.email ?? 'N/A';
    // Preservar usuarioNombre si ya viene en los datos, sino usar el del usuario autenticado
    data['usuarioNombre'] = data['usuarioNombre'] ?? user.displayName ?? user.email ?? 'Usuario';
    data['creado'] = FieldValue.serverTimestamp();
    data['estado'] = data['estado'] ?? 'activa';
    data['eliminada'] = false; // Por defecto no está eliminada (para auditoría)

    // Debug: imprimir datos antes de guardar
    print('📝 Creando reserva con datos:');
    print('   - usuarioID: ${data['usuarioID']}');
    print('   - usuarioNombre: ${data['usuarioNombre']}');
    print('   - recursoID: ${data['recursoID']}');
    print('   - recursoNombre: ${data['recursoNombre']}');
    print('   - dia: ${data['dia']}');
    print('   - hora: ${data['hora']}');
    print('   - asignatura: ${data['asignatura']}');
    print('   - fechaUso: ${data['fechaUso']}');
    print('   - creado: ${data['creado']} (serverTimestamp)');

    final docRef = await reservasCollection.add(data);
    print('✅ Reserva creada con ID: ${docRef.id}');

    // Enviar notificaciones a todos los usuarios sobre la nueva reserva
    try {
      // Obtener fecha de uso si está disponible
      DateTime? fechaUso;
      if (data['fechaUso'] != null) {
        if (data['fechaUso'] is Timestamp) {
          fechaUso = (data['fechaUso'] as Timestamp).toDate();
        } else if (data['fechaUso'] is DateTime) {
          fechaUso = data['fechaUso'] as DateTime;
        }
      }

      await _notificacionService.notificarNuevaReserva(
        docenteNombre: data['usuarioNombre'] as String? ?? 'Docente',
        docenteUsuarioID: user.uid, // ID del docente que creó la reserva
        dia: data['dia'] as String? ?? '',
        hora: data['hora'] as String? ?? '',
        recursoNombre: data['recursoNombre'] as String? ?? '',
        grado: data['grado'] as String? ?? '',
        fechaUso: fechaUso,
        asignatura: data['asignatura'] as String?,
        reservaID: docRef.id,
      );
    } catch (e) {
      // No lanzar excepción para no interrumpir la creación de la reserva
      print('⚠️ Error al enviar notificaciones (la reserva se creó correctamente): $e');
    }
  }

  // Verificar que el usuario es dueño de la reserva
  Future<bool> esDuenoReserva(String reservaId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    final doc = await reservasCollection.doc(reservaId).get();
    if (!doc.exists) {
      return false;
    }

    final data = doc.data() as Map<String, dynamic>;
    final usuarioID = data['usuarioID'] as String?;
    return usuarioID == user.uid;
  }

  // Verificar si el usuario actual es admin
  Future<bool> esAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    try {
      final userDoc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (!userDoc.exists) {
        return false;
      }

      final data = userDoc.data() as Map<String, dynamic>?;
      final rol = data?['rol'] as String?;
      return rol == 'admin';
    } catch (e) {
      print('Error al verificar admin: $e');
      return false;
    }
  }

  // Actualizar reserva (el dueño o admin puede actualizar)
  Future<void> actualizarReserva(String id, Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'Usuario no autenticado';
    }

    // Verificar que el usuario es dueño de la reserva o es admin
    final esDueno = await esDuenoReserva(id);
    final esAdminUser = await esAdmin();
    
    if (!esDueno && !esAdminUser) {
      throw 'No tienes permiso para modificar esta reserva. Solo puedes modificar tus propias reservas.';
    }

    // Agregar timestamp de actualización
    data['actualizado'] = FieldValue.serverTimestamp();
    
    await reservasCollection.doc(id).update(data);
    print('✅ Reserva actualizada: $id');
  }

  // Eliminar reserva (marcar como eliminada para auditoría) - el dueño o admin puede eliminar
  Future<void> eliminarReserva(String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'Usuario no autenticado';
    }

    // Verificar que el usuario es dueño de la reserva o es admin
    final esDueno = await esDuenoReserva(id);
    final esAdminUser = await esAdmin();
    
    if (!esDueno && !esAdminUser) {
      throw 'No tienes permiso para eliminar esta reserva. Solo puedes eliminar tus propias reservas.';
    }

    // Obtener información del usuario que elimina
    final userDoc = _auth.currentUser;
    final usuarioEliminacionID = userDoc?.uid;
    final usuarioEliminacionNombre = userDoc?.displayName ?? userDoc?.email ?? 'Usuario desconocido';

    await reservasCollection.doc(id).update({
      'eliminada': true,
      'fechaEliminacion': FieldValue.serverTimestamp(),
      'estado': 'eliminada',
      'usuarioEliminacionID': usuarioEliminacionID, // ID del usuario que eliminó
      'usuarioEliminacionNombre': usuarioEliminacionNombre, // Nombre del usuario que eliminó
      'eliminadoPorAdmin': esAdminUser, // Indica si fue eliminado por admin o por el docente
    });
    print('✅ Reserva eliminada: $id por ${esAdminUser ? "admin" : "docente"}');
  }

  // Eliminar reserva permanentemente (solo para admins en casos especiales)
  Future<void> eliminarReservaPermanente(String id) async {
    await reservasCollection.doc(id).delete();
  }

  // Obtener reservas por día (solo activas)
  Stream<QuerySnapshot> getReservasPorDia(String dia) {
    return reservasCollection
        .where('dia', isEqualTo: dia)
        .where('eliminada', isEqualTo: false)
        .orderBy('hora')
        .snapshots();
  }

  // Obtener reservas por recurso (TODAS las reservas de TODOS los docentes)
  // Solo filtra por recursoID y estado eliminada, NO filtra por usuario
  Stream<QuerySnapshot> getReservasPorRecurso(String recursoID, {bool incluirEliminadas = false}) {
    // Simplificar la consulta: solo filtrar por recursoID (sin filtro de eliminada ni orderBy)
    // para evitar problemas con índices compuestos. El filtrado de eliminadas se hará en memoria
    // en el widget que consume el stream.
    // Esta consulta simple solo requiere un índice simple en 'recursoID', no un índice compuesto
    return reservasCollection
        .where('recursoID', isEqualTo: recursoID)
        .snapshots();
  }
  
  // Obtener todas las reservas para auditoría (admin)
  Stream<QuerySnapshot> getReservasAuditoria() {
    return reservasCollection
        .orderBy('creado', descending: true)
        .snapshots();
  }

  // Obtener reservas por docente
  Stream<QuerySnapshot> getReservasPorDocente(String usuarioID) {
    return reservasCollection
        .where('usuarioID', isEqualTo: usuarioID)
        .orderBy('dia')
        .orderBy('hora')
        .snapshots();
  }

  // Contar total de reservas
  Future<int> contarReservas() async {
    final snapshot = await reservasCollection.get();
    return snapshot.docs.length;
  }

  // Obtener reservas por fecha específica (fechaUso)
  // Usar consulta simple para evitar problemas con índices compuestos
  Future<QuerySnapshot> getReservasPorFecha(DateTime fecha) async {
    try {
      // Usar una consulta simple: obtener todas las reservas no eliminadas recientes
      // y filtrar por fecha en memoria (más seguro y no requiere índices compuestos)
      // Ordenar por creado para obtener las más recientes primero
      final snapshot = await reservasCollection
          .where('eliminada', isEqualTo: false)
          .orderBy('creado', descending: true)
          .limit(500) // Limitar para evitar cargar demasiados datos
          .get();
      
      // El filtrado por fecha se hace en memoria donde se usa este método
      // Esto evita problemas con índices compuestos en Firestore
      return snapshot;
    } catch (e) {
      print('Error en getReservasPorFecha: $e');
      // Si hay error con la consulta, usar una consulta aún más simple
      try {
        // Consulta básica sin filtros complejos
        final snapshot = await reservasCollection
            .limit(500)
            .get();
        return snapshot;
      } catch (e2) {
        print('Error crítico en getReservasPorFecha: $e2');
        // En caso de error total, retornar un snapshot vacío
        // Esto evitará que la app se rompa completamente
        try {
          return await reservasCollection.limit(0).get();
        } catch (e3) {
          // Si todo falla, crear un QuerySnapshot vacío manualmente
          print('Error fatal en getReservasPorFecha: $e3');
          // Retornar un snapshot vacío de forma segura
          return await reservasCollection.where('eliminada', isEqualTo: false).limit(0).get();
        }
      }
    }
  }

  // Verificar disponibilidad por fecha específica y hora con detalles
  Future<Map<String, dynamic>> verificarDisponibilidadPorFechaConDetalles(
    DateTime fecha,
    String hora,
    String recursoID, {
    String? excluirUsuarioID, // Opcional: excluir reservas de este usuario (útil para edición)
  }) async {
    try {
      final reservasDelDia = await getReservasPorFecha(fecha);
      
      // Preparar rango de fechas para filtrar
      final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
      final finDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
      
      // Filtrar en memoria: solo reservas no eliminadas del recurso específico y del día correcto
      final reservasDelRecurso = reservasDelDia.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Verificar que no esté eliminada
        if (data['eliminada'] == true) return false;
        
        // Excluir reservas del usuario actual si se especifica (para evitar conflictos con sus propias reservas)
        if (excluirUsuarioID != null) {
          final reservaUsuarioID = data['usuarioID'] as String?;
          if (reservaUsuarioID == excluirUsuarioID) {
            return false; // Excluir reservas del usuario actual
          }
        }
        
        // Verificar que sea del recurso correcto
        // Comparar tanto por recursoID como por recursoNombre para manejar recursos por defecto
        final reservaRecursoID = data['recursoID'] as String? ?? '';
        final reservaRecursoNombre = data['recursoNombre'] as String? ?? '';
        
        // Verificar si es el mismo recurso:
        // 1. Por ID directo
        // 2. Por nombre (cuando el recursoID pasado es un nombre de recurso por defecto)
        final esMismoRecurso = reservaRecursoID == recursoID || 
                                reservaRecursoNombre == recursoID;
        
        if (!esMismoRecurso) {
          return false;
        }
        
        // Verificar que la fecha coincida
        final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
        if (fechaUso != null) {
          final fechaUsoDia = DateTime(fechaUso.year, fechaUso.month, fechaUso.day);
          final inicioDiaComparar = DateTime(inicioDia.year, inicioDia.month, inicioDia.day);
          final finDiaComparar = DateTime(finDia.year, finDia.month, finDia.day);
          
          // Verificar si la fecha está en el mismo día
          if (fechaUsoDia.year != inicioDiaComparar.year ||
              fechaUsoDia.month != inicioDiaComparar.month ||
              fechaUsoDia.day != inicioDiaComparar.day) {
            return false;
          }
        }
        
        return true;
      }).toList();

    // Determinar qué horas están ocupadas por la reserva seleccionada
    List<String> horasOcupadas = [];
    
    if (hora.startsWith('Bloque')) {
      if (hora.contains('Bloque 1')) {
        horasOcupadas = ['1ª Hora', '2ª Hora'];
      } else if (hora.contains('Bloque 2')) {
        horasOcupadas = ['3ª Hora', '4ª Hora'];
      } else if (hora.contains('Bloque 3')) {
        horasOcupadas = ['5ª Hora', '6ª Hora'];
      }
    } else {
      horasOcupadas = [hora];
    }

    // Verificar conflictos con reservas existentes
    for (var doc in reservasDelRecurso) {
      final reservaData = doc.data() as Map<String, dynamic>;
      final horaReservada = reservaData['hora'] as String?;
      
      if (horaReservada == null) continue;

      bool hayConflicto = false;
      
      if (horaReservada.startsWith('Bloque')) {
        List<String> horasDelBloqueExistente = [];
        if (horaReservada.contains('Bloque 1')) {
          horasDelBloqueExistente = ['1ª Hora', '2ª Hora'];
        } else if (horaReservada.contains('Bloque 2')) {
          horasDelBloqueExistente = ['3ª Hora', '4ª Hora'];
        } else if (horaReservada.contains('Bloque 3')) {
          horasDelBloqueExistente = ['5ª Hora', '6ª Hora'];
        }
        
        hayConflicto = horasOcupadas.any((h) => horasDelBloqueExistente.contains(h));
      } else {
        hayConflicto = horasOcupadas.contains(horaReservada);
      }

      if (hayConflicto) {
        return {
          'disponible': false,
          'reservaOcupada': {
            'usuarioNombre': reservaData['usuarioNombre'] ?? reservaData['docente'] ?? 'Docente',
            'asignatura': reservaData['asignatura'] ?? 'Sin asignatura',
            'grado': reservaData['grado'] ?? 'Sin grado',
            'hora': horaReservada,
          },
        };
      }
    }

      return {'disponible': true};
    } catch (e) {
      print('Error en verificarDisponibilidadPorFechaConDetalles: $e');
      // Si hay error, asumir que está disponible para no bloquear la creación
      // pero registrar el error
      return {'disponible': true, 'error': e.toString()};
    }
  }

  // Obtener disponibilidad de todas las horas para una fecha específica
  Future<Map<String, Map<String, dynamic>>> getDisponibilidadPorFecha(DateTime fecha) async {
    try {
      final reservasDelDia = await getReservasPorFecha(fecha);
      
      // Preparar rango de fechas para filtrar
      final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
      final finDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
      
      // Todas las horas y bloques posibles
      final todasLasHoras = [
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

      // Mapa para almacenar disponibilidad por recurso y hora
      final disponibilidad = <String, Map<String, dynamic>>{};

      // Filtrar reservas del día específico en memoria
      final reservasDelDiaFiltradas = reservasDelDia.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Verificar que no esté eliminada
        if (data['eliminada'] == true) return false;
        
        // Verificar que la fecha coincida
        final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
        if (fechaUso != null) {
          final fechaUsoDia = DateTime(fechaUso.year, fechaUso.month, fechaUso.day);
          final inicioDiaComparar = DateTime(inicioDia.year, inicioDia.month, inicioDia.day);
          
          // Verificar si la fecha está en el mismo día
          if (fechaUsoDia.year != inicioDiaComparar.year ||
              fechaUsoDia.month != inicioDiaComparar.month ||
              fechaUsoDia.day != inicioDiaComparar.day) {
            return false;
          }
        }
        
        return true;
      }).toList();

      // Para cada reserva, marcar las horas ocupadas
      for (var doc in reservasDelDiaFiltradas) {
      final data = doc.data() as Map<String, dynamic>;
      final recursoID = data['recursoID'] as String? ?? '';
      final horaReservada = data['hora'] as String? ?? '';
      
      if (recursoID.isEmpty || horaReservada.isEmpty) continue;

      // Determinar qué horas están ocupadas
      List<String> horasOcupadas = [];
      if (horaReservada.startsWith('Bloque')) {
        if (horaReservada.contains('Bloque 1')) {
          horasOcupadas = ['1ª Hora', '2ª Hora'];
        } else if (horaReservada.contains('Bloque 2')) {
          horasOcupadas = ['3ª Hora', '4ª Hora'];
        } else if (horaReservada.contains('Bloque 3')) {
          horasOcupadas = ['5ª Hora', '6ª Hora'];
        }
      } else {
        horasOcupadas = [horaReservada];
      }

      // Marcar horas ocupadas para este recurso
      for (var hora in horasOcupadas) {
        final key = '${recursoID}_$hora';
        if (!disponibilidad.containsKey(key)) {
          disponibilidad[key] = {
            'recursoID': recursoID,
            'recursoNombre': data['recursoNombre'] ?? recursoID,
            'hora': hora,
            'ocupada': true,
            'docente': data['usuarioNombre'] ?? data['docente'] ?? 'Docente',
            'asignatura': data['asignatura'] ?? 'Sin asignatura',
            'grado': data['grado'] ?? 'Sin grado',
          };
        }
      }
    }

      return disponibilidad;
    } catch (e) {
      print('Error en getDisponibilidadPorFecha: $e');
      // Si hay error, retornar un mapa vacío (todas las horas disponibles)
      // Esto evita que la app se rompa
      return <String, Map<String, dynamic>>{};
    }
  }
}
