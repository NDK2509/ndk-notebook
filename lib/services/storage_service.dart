import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/note_node.dart';

class StorageService {
  static const String _fileName = 'notes_db.json';

  Future<File> _getDatabaseFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // Load all notes from the local file
  Future<Map<String, NoteNode>> loadNotes() async {
    try {
      final file = await _getDatabaseFile();
      if (!await file.exists()) {
        return {};
      }

      final contents = await file.readAsString();
      if (contents.trim().isEmpty) {
        return {};
      }

      final Map<String, dynamic> decoded = jsonDecode(contents);
      final Map<String, NoteNode> notes = {};
      
      decoded.forEach((key, value) {
        notes[key] = NoteNode.fromJson(value as Map<String, dynamic>);
      });

      return notes;
    } catch (e) {
      // Return empty map on error (e.g. malformed JSON)
      print('Error loading notes: $e');
      return {};
    }
  }

  // Save all notes to the local file
  Future<void> saveNotes(Map<String, NoteNode> notes) async {
    try {
      final file = await _getDatabaseFile();
      final Map<String, dynamic> serialized = {};
      
      notes.forEach((key, value) {
        serialized[key] = value.toJson();
      });

      final jsonString = const JsonEncoder.withIndent('  ').convert(serialized);
      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error saving notes: $e');
    }
  }
}
