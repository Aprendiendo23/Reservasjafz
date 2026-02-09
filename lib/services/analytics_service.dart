import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'reserva_service.dart';

class AnalyticsService {
  final ReservaService _reservaService;

  AnalyticsService(this._reservaService);

  // Obtener recursos más utilizados
  Future<List<Map<String, dynamic>>> getRecursosMasUtilizados({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final reservasSnapshot = await _reservaService.getReservas(incluirEliminadas: false).first;
    
    final recursosMap = <String, Map<String, dynamic>>{};

    for (var doc in reservasSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Filtrar por fecha si se especifica
      if (fechaInicio != null || fechaFin != null) {
        final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
        if (fechaUso != null) {
          if (fechaInicio != null && fechaUso.isBefore(fechaInicio)) continue;
          if (fechaFin != null && fechaUso.isAfter(fechaFin)) continue;
        }
      }

      final recursoID = data['recursoID'] as String? ?? '';
      final recursoNombre = data['recursoNombre'] as String? ?? 'Sin nombre';

      if (recursoID.isNotEmpty) {
        if (!recursosMap.containsKey(recursoID)) {
          recursosMap[recursoID] = {
            'recursoID': recursoID,
            'recursoNombre': recursoNombre,
            'cantidad': 0,
          };
        }
        recursosMap[recursoID]!['cantidad'] = (recursosMap[recursoID]!['cantidad'] as int) + 1;
      }
    }

    final lista = recursosMap.values.toList();
    lista.sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));
    
    return lista;
  }

  // Obtener docentes que más reservan
  Future<List<Map<String, dynamic>>> getDocentesQueMasReservan({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final reservasSnapshot = await _reservaService.getReservas(incluirEliminadas: false).first;
    
    final docentesMap = <String, Map<String, dynamic>>{};

    for (var doc in reservasSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Filtrar por fecha si se especifica
      if (fechaInicio != null || fechaFin != null) {
        final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
        if (fechaUso != null) {
          if (fechaInicio != null && fechaUso.isBefore(fechaInicio)) continue;
          if (fechaFin != null && fechaUso.isAfter(fechaFin)) continue;
        }
      }

      final docenteNombre = data['usuarioNombre'] as String? ?? 
                           data['docente'] as String? ?? 
                           'Sin nombre';
      final usuarioID = data['usuarioID'] as String? ?? '';

      if (usuarioID.isNotEmpty) {
        if (!docentesMap.containsKey(usuarioID)) {
          docentesMap[usuarioID] = {
            'usuarioID': usuarioID,
            'docenteNombre': docenteNombre,
            'cantidad': 0,
          };
        }
        docentesMap[usuarioID]!['cantidad'] = (docentesMap[usuarioID]!['cantidad'] as int) + 1;
      }
    }

    final lista = docentesMap.values.toList();
    lista.sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));
    
    return lista;
  }

  // Obtener horarios de mayor demanda
  Future<List<Map<String, dynamic>>> getHorariosMayorDemanda({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final reservasSnapshot = await _reservaService.getReservas(incluirEliminadas: false).first;
    
    final horariosMap = <String, int>{};

    for (var doc in reservasSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Filtrar por fecha si se especifica
      if (fechaInicio != null || fechaFin != null) {
        final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
        if (fechaUso != null) {
          if (fechaInicio != null && fechaUso.isBefore(fechaInicio)) continue;
          if (fechaFin != null && fechaUso.isAfter(fechaFin)) continue;
        }
      }

      final hora = data['hora'] as String? ?? 'Sin hora';
      horariosMap[hora] = (horariosMap[hora] ?? 0) + 1;
    }

    final lista = horariosMap.entries.map((entry) => {
      'hora': entry.key,
      'cantidad': entry.value,
    }).toList();
    
    lista.sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));
    
    return lista;
  }

  // Obtener historial de uso por semana
  Future<List<Map<String, dynamic>>> getHistorialPorSemana({
    int semanasAtras = 8,
  }) async {
    final reservasSnapshot = await _reservaService.getReservas(incluirEliminadas: false).first;
    
    final semanasMap = <String, int>{};
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (var doc in reservasSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
      
      if (fechaUso != null) {
        // Obtener el inicio de la semana (lunes)
        final inicioSemana = fechaUso.subtract(Duration(days: fechaUso.weekday - 1));
        final semanaKey = dateFormat.format(inicioSemana);
        
        semanasMap[semanaKey] = (semanasMap[semanaKey] ?? 0) + 1;
      }
    }

    final lista = semanasMap.entries.map((entry) => {
      'semana': entry.key,
      'cantidad': entry.value,
    }).toList();
    
    lista.sort((a, b) => a['semana'].toString().compareTo(b['semana'].toString()));
    
    return lista;
  }

  // Obtener historial de uso por mes
  Future<List<Map<String, dynamic>>> getHistorialPorMes({
    int mesesAtras = 12,
  }) async {
    final reservasSnapshot = await _reservaService.getReservas(incluirEliminadas: false).first;
    
    final mesesMap = <String, int>{};
    final dateFormat = DateFormat('yyyy-MM');

    for (var doc in reservasSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
      
      if (fechaUso != null) {
        final mesKey = dateFormat.format(fechaUso);
        mesesMap[mesKey] = (mesesMap[mesKey] ?? 0) + 1;
      }
    }

    final lista = mesesMap.entries.map((entry) => {
      'mes': entry.key,
      'cantidad': entry.value,
    }).toList();
    
    lista.sort((a, b) => a['mes'].toString().compareTo(b['mes'].toString()));
    
    return lista;
  }

  // Obtener estadísticas generales
  Future<Map<String, dynamic>> getEstadisticasGenerales() async {
    final reservasSnapshot = await _reservaService.getReservas(incluirEliminadas: false).first;
    
    int totalReservas = reservasSnapshot.docs.length;
    int reservasEstaSemana = 0;
    int reservasEsteMes = 0;
    
    final ahora = DateTime.now();
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final inicioMes = DateTime(ahora.year, ahora.month, 1);

    for (var doc in reservasSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
      
      if (fechaUso != null) {
        if (fechaUso.isAfter(inicioSemana.subtract(const Duration(days: 1)))) {
          reservasEstaSemana++;
        }
        if (fechaUso.isAfter(inicioMes.subtract(const Duration(days: 1)))) {
          reservasEsteMes++;
        }
      }
    }

    return {
      'totalReservas': totalReservas,
      'reservasEstaSemana': reservasEstaSemana,
      'reservasEsteMes': reservasEsteMes,
    };
  }
}



