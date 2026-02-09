import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class CardReserva extends StatelessWidget {
  final String reservaId;
  final String recursoNombre;
  final String dia;
  final String hora;
  final String asignatura;
  final String usuarioNombre;
  final String? docente; // Campo opcional para el docente que reserva
  final String? grado; // Grado/Aula
  final String? fechaUso; // Fecha de uso formateada
  final String? observacion; // Observación de la reserva
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const CardReserva({
    super.key,
    required this.reservaId,
    required this.recursoNombre,
    required this.dia,
    required this.hora,
    required this.asignatura,
    required this.usuarioNombre,
    this.docente,
    this.grado,
    this.fechaUso,
    this.observacion,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(
        bottom: Responsive.isMobile(context) ? 12 : 16,
      ),
      elevation: 2,
      child: Padding(
        padding: Responsive.isMobile(context) 
            ? const EdgeInsets.all(12.0) 
            : const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.book_online, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recursoNombre,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: onEdit,
                    tooltip: 'Editar reserva',
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Eliminar reserva',
                  ),
              ],
            ),
            const Divider(),
            if (fechaUso != null) ...[
              _buildInfoRow(context, Icons.calendar_today, 'Fecha de Uso', fechaUso!),
              const SizedBox(height: 8),
            ],
            _buildInfoRow(context, Icons.calendar_today, 'Día', dia),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.access_time, 'Hora', hora),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.book, 'Asignatura', asignatura),
            const SizedBox(height: 8),
            if (grado != null) ...[
              _buildInfoRow(context, Icons.class_, 'Grado/Aula', grado!),
              const SizedBox(height: 8),
            ],
            if (observacion != null && observacion!.isNotEmpty) ...[
              _buildInfoRow(context, Icons.note, 'Observación', observacion!),
              const SizedBox(height: 8),
            ],
            _buildInfoRow(context, Icons.person, 'Docente', docente ?? usuarioNombre),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon, 
          size: Responsive.iconSize(context, 20), 
          color: Colors.grey.shade600,
        ),
        SizedBox(width: Responsive.isMobile(context) ? 6 : 8),
        Flexible(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
