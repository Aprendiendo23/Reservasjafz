import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Guarda un archivo Excel permitiendo al usuario elegir la ubicación
/// mediante el diálogo nativo de \"Guardar como\". Retorna la ruta del archivo
/// o null si el usuario cancela.
Future<String?> saveExcelFile(Uint8List bytes, String fileName) async {
  try {
    // Diálogo nativo para elegir dónde guardar el archivo
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo Excel',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      lockParentWindow: true,
      bytes: bytes, // En móviles, FilePicker escribe el archivo por nosotros
    );

    // Si es null, el usuario canceló
    if (outputPath == null) {
      return null;
    }

    // Si devuelve una ruta no vacía, la usamos
    if (outputPath.isNotEmpty) {
      return outputPath;
    }

    // Si por alguna razón la ruta viene vacía, usamos un fallback
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  } catch (e) {
    // Fallback final: guardar en documentos de la app
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e2) {
      throw 'Error al guardar archivo: $e2';
    }
  }
}

/// Guarda un archivo CSV permitiendo al usuario elegir la ubicación
/// mediante el diálogo nativo de \"Guardar como\". Retorna la ruta del archivo
/// o null si el usuario cancela.
Future<String?> saveCsvFile(String content, String fileName) async {
  try {
    final bytes = Uint8List.fromList(utf8.encode(content));

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo CSV',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      lockParentWindow: true,
      bytes: bytes,
    );

    // Si es null, el usuario canceló
    if (outputPath == null) {
      return null;
    }

    if (outputPath.isNotEmpty) {
      return outputPath;
    }

    // Fallback: guardar en documentos de la app
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  } catch (e) {
    // Fallback final
    try {
      final bytes = Uint8List.fromList(utf8.encode(content));
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e2) {
      throw 'Error al guardar archivo: $e2';
    }
  }
}
