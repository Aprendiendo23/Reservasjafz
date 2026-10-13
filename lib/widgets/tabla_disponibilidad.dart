import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/reserva_service.dart';
import '../services/recurso_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import 'zoomable_widget.dart';

/// Widget que muestra el nombre actualizado del usuario desde Firestore
/// Consulta la colección 'usuarios' usando el usuarioID de la reserva
class NombreUsuarioActualizado extends StatelessWidget {
  final String? usuarioID;
  final String? nombreReserva; // Nombre guardado en la reserva (fallback)
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const NombreUsuarioActualizado({
    super.key,
    required this.usuarioID,
    this.nombreReserva,
    this.style,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay usuarioID, usar el nombre de la reserva como fallback
    if (usuarioID == null || usuarioID!.isEmpty) {
      return Text(
        nombreReserva ?? 'Docente',
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      );
    }

    // Consultar el nombre actualizado desde Firestore
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuarioID)
          .snapshots(),
      builder: (context, snapshot) {
        String nombreMostrar = nombreReserva ?? 'Docente';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final nombreActualizado = data?['nombre'] as String?;
          final reservaPareceEmail =
              nombreReserva != null && nombreReserva!.contains('@');

          // Caso 1: la reserva guarda un nombre "bonito" (no email) elegido por admin → respetar ese nombre.
          if (nombreReserva != null &&
              nombreReserva!.isNotEmpty &&
              !reservaPareceEmail) {
            nombreMostrar = nombreReserva!;
          }
          // Caso 2: la reserva guarda un correo u otro valor feo → usar el nombre del perfil si existe.
          else if (nombreActualizado != null && nombreActualizado.isNotEmpty) {
            nombreMostrar = nombreActualizado;
          }
          // Caso 3: no hay nombre en perfil, usar lo que venga en la reserva (aunque sea email).
          else if (nombreReserva != null && nombreReserva!.isNotEmpty) {
            nombreMostrar = nombreReserva!;
          }
        } else {
          // Si no se encuentra el usuario en Firestore, usar el nombreReserva
          // Esto pasa cuando el docente seleccionado no está registrado en Firestore
          nombreMostrar = nombreReserva ?? 'Docente';
        }

        return Text(
          nombreMostrar,
          style: style,
          maxLines: maxLines,
          overflow: overflow,
          softWrap: softWrap,
        );
      },
    );
  }
}

class TablaDisponibilidad extends StatefulWidget {
  final String recursoID;
  final String recursoNombre;
  final Function(String dia, String hora)? onCellTap;

  const TablaDisponibilidad({
    super.key,
    required this.recursoID,
    required this.recursoNombre,
    this.onCellTap,
  });

  @override
  State<TablaDisponibilidad> createState() => _TablaDisponibilidadState();
}

class _TablaDisponibilidadState extends State<TablaDisponibilidad> {
  DateTime _semanaInicio = _getInicioSemana(DateTime.now());
  String? _lastRecursoID; // Para detectar cambios en el recursoID
  
  // ScrollControllers para sincronizar el scroll horizontal del encabezado y cuerpo
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();
  bool _isSyncingScroll = false;
  
  final List<String> _horas = [
    '1ª Hora',
    '2ª Hora',
    '3ª Hora',
    '4ª Hora',
    '5ª Hora',
    '6ª Hora',
  ];
  
  // Obtener el inicio de la semana (Lunes)
  static DateTime _getInicioSemana(DateTime fecha) {
    int diasDesdeLunes = (fecha.weekday - 1) % 7;
    return fecha.subtract(Duration(days: diasDesdeLunes));
  }
  
  // Obtener los días de la semana actual
  List<DateTime> get _diasSemana {
    // Crear nuevas instancias de DateTime para evitar modificar _semanaInicio
    return List.generate(5, (index) {
      final fecha = DateTime(_semanaInicio.year, _semanaInicio.month, _semanaInicio.day);
      return fecha.add(Duration(days: index));
    });
  }
  
  String _getDiaSemana(DateTime fecha) {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    return dias[fecha.weekday - 1];
  }

  @override
  void initState() {
    super.initState();
    // Sincronizar scrolls
    _headerScrollController.addListener(_syncHeaderScroll);
    _bodyScrollController.addListener(_syncBodyScroll);
    _lastRecursoID = widget.recursoID;
  }

  @override
  void didUpdateWidget(TablaDisponibilidad oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió el recursoID, reiniciar la semana a la actual para mostrar datos frescos
    if (oldWidget.recursoID != widget.recursoID) {
      setState(() {
        _semanaInicio = _getInicioSemana(DateTime.now());
        _lastRecursoID = widget.recursoID;
      });
    }
  }

  void _syncHeaderScroll() {
    if (!_isSyncingScroll && _bodyScrollController.hasClients) {
      _isSyncingScroll = true;
      final offset = _headerScrollController.offset;
      if ((_bodyScrollController.offset - offset).abs() > 1.0) {
        _bodyScrollController.jumpTo(offset);
      }
      _isSyncingScroll = false;
    }
  }

  void _syncBodyScroll() {
    if (!_isSyncingScroll && _headerScrollController.hasClients) {
      _isSyncingScroll = true;
      final offset = _bodyScrollController.offset;
      if ((_headerScrollController.offset - offset).abs() > 1.0) {
        _headerScrollController.jumpTo(offset);
      }
      _isSyncingScroll = false;
    }
  }

  @override
  void dispose() {
    _headerScrollController.removeListener(_syncHeaderScroll);
    _bodyScrollController.removeListener(_syncBodyScroll);
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  // Obtener anchos de columnas responsive
  Map<int, TableColumnWidth> _getColumnWidths(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (isMobile) {
      // Móvil - anchos mínimos más generosos para evitar cortes
      final anchoHora = (screenWidth * 0.20).clamp(80.0, double.infinity);
      final anchoDia = ((screenWidth - anchoHora) / _diasSemana.length).clamp(100.0, double.infinity);
      return {
        0: FixedColumnWidth(anchoHora), // Hora
        for (int i = 1; i <= _diasSemana.length; i++)
          i: FixedColumnWidth(anchoDia), // Días
      };
    } else if (isTablet) {
      return {
        0: const FixedColumnWidth(120), // Hora
        for (int i = 1; i <= _diasSemana.length; i++)
          i: const FixedColumnWidth(160), // Días
      };
    } else {
      // Desktop/Web - ocupar todo el ancho disponible
      final padding = Responsive.isMobile(context) || Responsive.isTablet(context) 
          ? Responsive.padding(context)
          : const EdgeInsets.symmetric(horizontal: 4, vertical: 8);
      final availableWidth = screenWidth - (padding.horizontal * 2) - 20; // 20px para bordes y scrollbar
      
      // Distribuir proporcionalmente: 1 columna de hora + 5 días
      final anchoHora = (availableWidth * 0.10).clamp(120.0, double.infinity);
      final anchoDia = ((availableWidth - anchoHora) / _diasSemana.length).clamp(180.0, double.infinity);
      
      return {
        0: FixedColumnWidth(anchoHora), // Hora
        for (int i = 1; i <= _diasSemana.length; i++)
          i: FixedColumnWidth(anchoDia), // Días
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservaService = Provider.of<ReservaService>(context);
    final authService = Provider.of<AuthService>(context);

    print('📋 TablaDisponibilidad: Buscando reservas para recursoID: ${widget.recursoID}, semana: ${DateFormat('yyyy-MM-dd').format(_semanaInicio)}');
    
    // Crear un stream con key único que incluya la semana para forzar actualización
    final streamKey = 'tabla_disponibilidad_${widget.recursoID}_${DateFormat('yyyy-MM-dd').format(_semanaInicio)}';
    
    return StreamBuilder(
      key: ValueKey(streamKey), // Key único que incluye la semana para forzar reconstrucción
      stream: reservaService.getReservasPorRecurso(
        widget.recursoID,
        incluirEliminadas: false,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('❌ Error en TablaDisponibilidad: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error al cargar reservas: ${snapshot.error}'),
                const SizedBox(height: 8),
                Text('RecursoID: ${widget.recursoID}'),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Crear mapa de reservas por fecha y hora/bloque
        final reservasMap = <String, Map<String, dynamic>>{};
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          // Filtrar reservas eliminadas para todos (admin y no admin)
          // Las reservas eliminadas solo se ven en Auditoría de Reservas
          final reservasFiltradas = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['eliminada'] != true;
          }).toList();
          
          print('📊 TablaDisponibilidad: ${reservasFiltradas.length} reservas encontradas (de ${snapshot.data!.docs.length} totales)');
          print('🔍 RecursoID buscado: ${widget.recursoID}');
          
          for (var doc in reservasFiltradas) {
            final data = doc.data() as Map<String, dynamic>;
            final fechaUso = (data['fechaUso'] as Timestamp?)?.toDate();
            final dia = data['dia'] as String? ?? '';
            final hora = data['hora'] as String? ?? '';
            final reservaRecursoID = data['recursoID'] as String? ?? '';
            final reservaRecursoNombre = data['recursoNombre'] as String? ?? '';
            
            print('   - Reserva: recursoID=$reservaRecursoID, recursoNombre=$reservaRecursoNombre, dia=$dia, hora=$hora, fechaUso=$fechaUso');
            
            // Verificar que la reserva corresponda al recurso buscado
            // Comparar tanto por ID como por nombre (para recursos por defecto)
            final esMismoRecurso = reservaRecursoID == widget.recursoID || 
                                    reservaRecursoNombre == widget.recursoID;
            
            if (!esMismoRecurso) {
              print('   ⚠️ Reserva no corresponde al recurso buscado. Saltando...');
              continue;
            }
            
            // Usar fecha real si existe, sino usar día de la semana
            String fechaKey = '';
            if (fechaUso != null) {
              fechaKey = DateFormat('yyyy-MM-dd').format(fechaUso);
              print('   ✅ Usando fechaUso: $fechaKey');
            } else {
              // Fallback: usar día de la semana
              fechaKey = dia;
              print('   ⚠️ No hay fechaUso, usando dia: $fechaKey');
            }
            
            // Si es un bloque, mapear a todas las horas del bloque
            if (hora.startsWith('Bloque')) {
              List<String> horasDelBloque = [];
              if (hora.contains('Bloque 1')) {
                horasDelBloque = ['1ª Hora', '2ª Hora'];
              } else if (hora.contains('Bloque 2')) {
                horasDelBloque = ['3ª Hora', '4ª Hora'];
              } else if (hora.contains('Bloque 3')) {
                horasDelBloque = ['5ª Hora', '6ª Hora'];
              }
              
              print('   📦 Es un bloque, mapeando a horas: $horasDelBloque');
              for (var h in horasDelBloque) {
                final key = '${fechaKey}_$h';
                reservasMap[key] = data;
                print('     ➕ Agregado al mapa: $key');
              }
            } else {
              // Hora individual
              final key = '${fechaKey}_$hora';
              reservasMap[key] = data;
              print('   ➕ Agregado al mapa: $key');
            }
          }
        } else {
          print('⚠️ TablaDisponibilidad: No se encontraron reservas para recursoID: ${widget.recursoID}');
        }

        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        
        // Debug: verificar que los días de la semana se calculan correctamente
        final diasSemanaActual = _diasSemana;
        print('📅 TablaDisponibilidad: Días de la semana: ${diasSemanaActual.map((d) => DateFormat('yyyy-MM-dd').format(d)).join(', ')}');
        print('📅 TablaDisponibilidad: Total de reservas en mapa: ${reservasMap.length}');
        
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Selector de semana optimizado
            Builder(
              builder: (paddingContext) {
                final isDesktopPadding = !Responsive.isMobile(paddingContext) && !Responsive.isTablet(paddingContext);
                final isLandscapePadding = MediaQuery.of(paddingContext).orientation == Orientation.landscape;
                return Padding(
                  padding: isLandscapePadding
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
                      : (isDesktopPadding 
                          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 8) // Mínimo padding en desktop
                          : Responsive.padding(paddingContext)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLandscape 
                        ? 'Cronograma: ${widget.recursoNombre}'
                        : 'Cronograma: ${widget.recursoNombre}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isLandscape ? 14 : null,
                        ),
                  ),
                  if (!isLandscape) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Selecciona la semana para ver la disponibilidad',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                  SizedBox(height: isLandscape ? 4 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left, size: isLandscape ? 20 : 24),
                        padding: isLandscape ? const EdgeInsets.all(4) : null,
                        constraints: isLandscape ? const BoxConstraints() : null,
                        onPressed: () {
                          setState(() {
                            _semanaInicio = _semanaInicio.subtract(const Duration(days: 7));
                          });
                        },
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final fechaSeleccionada = await showDatePicker(
                              context: context,
                              initialDate: _semanaInicio,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2055, 12, 31), // Permitir hasta 2055
                              locale: const Locale('es', 'ES'),
                            );
                            if (fechaSeleccionada != null) {
                              setState(() {
                                _semanaInicio = _getInicioSemana(fechaSeleccionada);
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: isLandscape ? 6 : 12,
                              horizontal: isLandscape ? 8 : 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today, 
                                  size: isLandscape 
                                    ? 14 
                                    : (Responsive.isMobile(context) ? 16 : 18),
                                ),
                                SizedBox(width: isLandscape ? 4 : 8),
                                Flexible(
                                  child: Text(
                                    isLandscape
                                        ? '${DateFormat('dd/MM').format(_semanaInicio)} - ${DateFormat('dd/MM').format(_semanaInicio.add(const Duration(days: 4)))}'
                                        : 'Semana del ${DateFormat('dd/MM/yyyy').format(_semanaInicio)} al ${DateFormat('dd/MM/yyyy').format(_semanaInicio.add(const Duration(days: 4)))}',
                                    style: TextStyle(
                                      fontSize: isLandscape
                                        ? 10.0
                                        : (Responsive.isMobile(context) 
                                          ? 11.0 
                                          : (Responsive.isTablet(context) ? 13.0 : 14.0)),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right, size: isLandscape ? 20 : 24),
                        padding: isLandscape ? const EdgeInsets.all(4) : null,
                        constraints: isLandscape ? const BoxConstraints() : null,
                        onPressed: () {
                          setState(() {
                            _semanaInicio = _semanaInicio.add(const Duration(days: 7));
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
                );
              },
            ),
            // Tabla con el mismo estilo que TablaReservas
            Expanded(
              child: Container(
                margin: isLandscape
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                    : Responsive.padding(context),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Builder(
                    builder: (context) {
                      final isMobile = Responsive.isMobile(context);
                      // Capturar reservasMap para uso en Builder anidados
                      final reservasMapLocal = reservasMap;
                      // En pantallas grandes (web/desktop), usar la misma estructura que tabla_reservas
                      // En móvil, mantener estructura original con zoom
                      if (!isMobile) {
                        return _buildTablaDesktop(context, reservasMapLocal);
                      } else {
                        // Estructura para móvil (con zoom)
                        return Builder(
                          builder: (context) {
                            final columnWidths = _getColumnWidths(context);
                            double totalWidth = 0;
                            columnWidths.forEach((index, width) {
                              if (width is FixedColumnWidth) {
                                totalWidth += width.value;
                              }
                            });
                            
                            return ZoomableWidget(
                              minScale: 0.5,
                              maxScale: 3.0,
                              initialScale: 1.0,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Encabezado
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade700,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: SizedBox(
                                      width: totalWidth,
                                      child: Table(
                                        border: TableBorder.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                        columnWidths: columnWidths,
                                        children: [
                                          TableRow(
                                            children: [
                                              _buildHeaderCell('HORA'),
                                              ..._diasSemana.map((fecha) => _buildHeaderCell(
                                                    '${_getDiaSemana(fecha)}\n${DateFormat('dd/MM').format(fecha)}',
                                                  )),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Cuerpo de la tabla
                                  SizedBox(
                                    width: totalWidth,
                                    child: Table(
                                      border: TableBorder.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                      columnWidths: columnWidths,
                                      children: [
                                        // Filas de horas
                                        ..._horas.map((hora) {
                                          return TableRow(
                                            decoration: BoxDecoration(
                                              color: (_horas.indexOf(hora) % 2 == 0
                                                  ? Colors.white
                                                  : Colors.grey.shade100),
                                            ),
                                            children: [
                                              _buildHoraCell(hora),
                                              ..._diasSemana.map((fecha) {
                                                final fechaKey = DateFormat('yyyy-MM-dd').format(fecha);
                                                final key = '${fechaKey}_$hora';
                                                final reserva = reservasMapLocal[key];
                                                final dia = _getDiaSemana(fecha);
                                                return _buildDiaCell(dia, hora, reserva);
                                              }),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
            // Leyenda y controles - más compactos en modo horizontal
            if (isLandscape)
              // En modo horizontal: hacer más compacto y desplazable
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLeyendaItem(
                            Colors.green.shade100,
                            Colors.green.shade700,
                            Icons.check_circle,
                            'Disponible',
                            isLandscape,
                          ),
                          const SizedBox(width: 16),
                          _buildLeyendaItem(
                            Colors.orange.shade100,
                            Colors.orange.shade700,
                            Icons.event_busy,
                            'Ocupado',
                            isLandscape,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              // En modo vertical: estructura normal
              Column(
                children: [
                  // Leyenda optimizada
                  Builder(
                    builder: (paddingContext) {
                      final isDesktopPadding = !Responsive.isMobile(paddingContext) && !Responsive.isTablet(paddingContext);
                      return Padding(
                        padding: isDesktopPadding 
                            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 8)
                            : Responsive.padding(paddingContext),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLeyendaItem(
                              Colors.green.shade100,
                              Colors.green.shade700,
                              Icons.check_circle,
                              'Disponible',
                              false,
                            ),
                            const SizedBox(width: 24),
                            _buildLeyendaItem(
                              Colors.orange.shade100,
                              Colors.orange.shade700,
                              Icons.event_busy,
                              'Ocupado',
                              false,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildTablaDesktop(BuildContext context, Map<String, Map<String, dynamic>> reservasMap) {
    final columnWidths = _getColumnWidths(context);
    double totalWidth = 0;
    columnWidths.forEach((index, width) {
      if (width is FixedColumnWidth) {
        totalWidth += width.value;
      }
    });

    // Para desktop/tablet, usar el mismo zoom con gestos que en móvil
    return ZoomableWidget(
      minScale: 0.5,
      maxScale: 3.0,
      initialScale: 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: SizedBox(
              width: totalWidth,
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
                columnWidths: columnWidths,
                children: [
                  TableRow(
                    children: [
                      _buildHeaderCell('HORA'),
                      ..._diasSemana.map((fecha) => _buildHeaderCell(
                            '${_getDiaSemana(fecha)}\n${DateFormat('dd/MM').format(fecha)}',
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Cuerpo de la tabla
          SizedBox(
            width: totalWidth,
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
              columnWidths: columnWidths,
              children: [
                // Filas de horas
                ..._horas.map((hora) {
                  return TableRow(
                    decoration: BoxDecoration(
                      color: (_horas.indexOf(hora) % 2 == 0
                          ? Colors.white
                          : Colors.grey.shade100),
                    ),
                    children: [
                      _buildHoraCell(hora),
                      ..._diasSemana.map((fecha) {
                        final fechaKey = DateFormat('yyyy-MM-dd').format(fecha);
                        final key = '${fechaKey}_$hora';
                        final reserva = reservasMap[key];
                        final dia = _getDiaSemana(fecha);
                        return _buildDiaCell(dia, hora, reserva);
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    final isMobile = Responsive.isMobile(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDesktop = !isMobile && !Responsive.isTablet(context);
    
    return TableCell(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 6.0 : (isMobile ? 8.0 : (isDesktop ? 12.0 : 12.0)),
          vertical: isLandscape ? 8.0 : (isMobile ? 10.0 : (isDesktop ? 24.0 : 12.0)),
        ),
        decoration: BoxDecoration(
          color: Colors.blue.shade900,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isLandscape ? 8.0 : (isMobile ? 9.0 : (isDesktop ? 18.0 : 13.0)),
            height: isLandscape ? 1.1 : (isDesktop ? 1.3 : 1.2),
          ),
          textAlign: TextAlign.center,
          maxLines: isLandscape ? 1 : (isDesktop ? null : 2),
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      ),
    );
  }

  Widget _buildHoraCell(String hora) {
    final isMobile = Responsive.isMobile(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDesktop = !isMobile && !Responsive.isTablet(context);
    
    return TableCell(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 4.0 : (isMobile ? 8.0 : (isDesktop ? 12.0 : 12.0)),
          vertical: isLandscape ? 4.0 : (isMobile ? 8.0 : (isDesktop ? 20.0 : 12.0)),
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border(
            right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: Center(
          child: Text(
            hora,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isLandscape ? 9.0 : (isMobile ? 10.0 : (isDesktop ? 18.0 : 13.0)),
              color: Theme.of(context).primaryColor,
              height: isLandscape ? 1.1 : (isDesktop ? 1.4 : 1.2),
            ),
            textAlign: TextAlign.center,
            maxLines: isDesktop ? null : 1,
            overflow: TextOverflow.visible,
            softWrap: isDesktop ? true : false,
          ),
        ),
      ),
    );
  }

  Widget _buildDiaCell(String dia, String hora, Map<String, dynamic>? reserva) {
    return TableCell(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (widget.onCellTap != null) {
              widget.onCellTap!(dia, hora);
            }
          },
          child: Container(
            padding: EdgeInsets.all(
              MediaQuery.of(context).orientation == Orientation.landscape
                ? 4.0
                : (Responsive.isMobile(context) ? 6.0 : (Responsive.isTablet(context) ? 8.0 : 20.0))
            ),
            decoration: BoxDecoration(
              color: reserva != null ? Colors.red.shade50 : Colors.green.shade50,
            ),
            child: reserva != null
                ? Container(
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).orientation == Orientation.landscape
                        ? 4.0
                        : (Responsive.isMobile(context) ? 6.0 : 8.0)
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person, 
                              size: MediaQuery.of(context).orientation == Orientation.landscape
                                ? 10.0
                                : (Responsive.isMobile(context) ? 12.0 : (Responsive.isTablet(context) ? 14.0 : 16.0)),
                              color: Colors.blue.shade800
                            ),
                            SizedBox(width: MediaQuery.of(context).orientation == Orientation.landscape ? 2.0 : 4.0),
                            Expanded(
                              child: NombreUsuarioActualizado(
                                usuarioID: reserva['usuarioID'] as String?,
                                nombreReserva: reserva['docente'] ?? reserva['usuarioNombre'] as String?,
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).orientation == Orientation.landscape
                                    ? 8.0
                                    : (Responsive.isMobile(context) ? 9.0 : (Responsive.isTablet(context) ? 11.0 : 18.0)),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                  height: MediaQuery.of(context).orientation == Orientation.landscape ? 1.1 : (Responsive.isTablet(context) ? 1.2 : 1.4),
                                ),
                                maxLines: Responsive.isMobile(context) || Responsive.isTablet(context) ? 1 : null,
                                overflow: TextOverflow.visible,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).orientation == Orientation.landscape ? 1.0 : (Responsive.isTablet(context) ? 2.0 : 4.0)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.book, 
                              size: MediaQuery.of(context).orientation == Orientation.landscape
                                ? 8.0
                                : (Responsive.isMobile(context) ? 10.0 : (Responsive.isTablet(context) ? 12.0 : 14.0)), 
                              color: Colors.purple.shade800
                            ),
                            SizedBox(width: MediaQuery.of(context).orientation == Orientation.landscape ? 2.0 : 4.0),
                            Expanded(
                              child: Text(
                                reserva['asignatura'] ?? 'Asignatura',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).orientation == Orientation.landscape
                                    ? 7.0
                                    : (Responsive.isMobile(context) ? 8.0 : (Responsive.isTablet(context) ? 10.0 : 18.0)),
                                  color: Colors.purple.shade900,
                                  fontWeight: FontWeight.w600,
                                  height: MediaQuery.of(context).orientation == Orientation.landscape ? 1.1 : (Responsive.isTablet(context) ? 1.2 : 1.4),
                                ),
                                maxLines: Responsive.isMobile(context) || Responsive.isTablet(context) ? 1 : null,
                                overflow: TextOverflow.visible,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: MediaQuery.of(context).orientation == Orientation.landscape
                            ? 14.0
                            : (Responsive.isMobile(context) ? 16.0 : 18.0),
                        ),
                        SizedBox(height: MediaQuery.of(context).orientation == Orientation.landscape ? 1.0 : 2.0),
                        Text(
                          'Disponible',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).orientation == Orientation.landscape
                              ? 8.0
                              : (Responsive.isMobile(context) ? 9.0 : 11.0),
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w600,
                            height: MediaQuery.of(context).orientation == Orientation.landscape ? 1.1 : 1.2,
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

  Widget _buildLeyendaItem(Color color, Color iconColor, IconData icon, String label, bool isLandscape) {
    final isMobile = Responsive.isMobile(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isLandscape ? 16 : (isMobile ? 20 : 24),
          height: isLandscape ? 16 : (isMobile ? 20 : 24),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: iconColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: isLandscape ? 12 : (isMobile ? 14 : 18),
            color: iconColor,
          ),
        ),
        SizedBox(width: isLandscape ? 4 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isLandscape ? 10 : (isMobile ? 12 : 14),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
