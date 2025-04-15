import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';

class BackupService {
  static final _log = Logger('BackupService');

  static Future<bool> backupNotes(List<Map<String, String>> notes) async {
    _log.info("Starting notes backup process...");
    if (notes.isEmpty) {
      _log.warning("No notes available to backup.");
      return false; // No need to backup when no notes
    }

    try {
      final String jsonString = jsonEncode(notes);
      final Uint8List fileBytes = utf8.encode(jsonString);

      final String suggestedFileName = 'notes_backup_${DateTime.now().toIso8601String().split('T')[0]}.json';

      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Notes Backup',
        fileName: suggestedFileName,
        allowedExtensions: ['json'],
        type: FileType.custom,
        bytes: fileBytes,
      );

      if (outputFile == null) {
        _log.info("Backup cancelled by user.");
        return false;
      }

      _log.info("Backup successful. Notes saved to: $outputFile");
      return true;

    } catch (e, stackTrace) {
      _log.severe("Error during backup process", e, stackTrace);
      return false;
    }
  }
}