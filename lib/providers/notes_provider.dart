import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/note_node.dart';
import '../services/storage_service.dart';

class NotesProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final Uuid _uuid = const Uuid();

  Map<String, NoteNode> _notes = {};
  String? _selectedNoteId;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isTrashSelected = false;
  Timer? _debounceSaveTimer;

  Map<String, NoteNode> get notes => _notes;
  String? get selectedNoteId => _selectedNoteId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isTrashSelected => _isTrashSelected;

  NoteNode? get selectedNote => _selectedNoteId != null ? _notes[_selectedNoteId] : null;

  // Load notes initially
  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    _notes = await _storageService.loadNotes();
    
    // Auto-clean up expired notes from trash
    _cleanExpiredTrashNotes();
    
    // Select first root note if available, otherwise stay null
    if (_notes.isNotEmpty) {
      final roots = getRootNotes();
      if (roots.isNotEmpty) {
        _selectedNoteId = roots.first.id;
        final note = _notes[_selectedNoteId];
        if (note != null) {
          note.lastOpenedAt = DateTime.now();
          await _storageService.saveNotes(_notes);
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Set selected note
  void selectNote(String? id) {
    if (id == null || _notes.containsKey(id)) {
      _selectedNoteId = id;
      _isTrashSelected = false;
      if (id != null) {
        final note = _notes[id];
        if (note != null) {
          note.lastOpenedAt = DateTime.now();
          _saveAndNotify();
        }
      } else {
        notifyListeners();
      }
    }
  }

  // Create a new Root Note
  NoteNode createRootNote({String title = 'Untitled Note', String content = ''}) {
    final newId = _uuid.v4();
    final position = getRootNotes().length;
    final newNode = NoteNode(
      id: newId,
      title: title,
      content: content,
      parentId: null,
      position: position,
    );

    _notes[newId] = newNode;
    _selectedNoteId = newId;
    _isTrashSelected = false;

    _saveAndNotify();
    return newNode;
  }

  // Create a Sub-note under a parent
  NoteNode createSubNote(String parentId, {String title = 'Untitled Sub-note', String content = ''}) {
    if (!_notes.containsKey(parentId)) {
      throw Exception('Parent note not found');
    }

    final newId = _uuid.v4();
    final parentNode = _notes[parentId]!;
    final position = parentNode.childIds.length;

    final newNode = NoteNode(
      id: newId,
      title: title,
      content: content,
      parentId: parentId,
      position: position,
    );

    _notes[newId] = newNode;
    parentNode.childIds.add(newId);
    parentNode.updatedAt = DateTime.now();
    parentNode.isExpanded = true; // Auto-expand parent when adding child

    _selectedNoteId = newId;
    _isTrashSelected = false;
    _saveAndNotify();
    return newNode;
  }


  // Update Note Title
  void updateNoteTitle(String id, String title) {
    final note = _notes[id];
    if (note != null) {
      note.title = title;
      note.updatedAt = DateTime.now();
      _saveAndNotify(debounced: true);
    }
  }

  // Update Note Content
  void updateNoteContent(String id, String content) {
    final note = _notes[id];
    if (note != null) {
      note.content = content;
      note.updatedAt = DateTime.now();
      _saveAndNotify(debounced: true);
    }
  }

  // Soft delete a note and its descendants
  void deleteNote(String id) {
    final note = _notes[id];
    if (note == null) return;

    final parentId = note.parentId;
    
    // Remove reference from parent
    if (parentId != null && _notes.containsKey(parentId)) {
      final parent = _notes[parentId]!;
      parent.childIds.remove(id);
      parent.updatedAt = DateTime.now();
    }

    // Recursively soft-delete node and all subnodes
    _softDeleteNodeRecursive(id);

    // If active note was deleted, fallback to parent, or first root, or null
    if (_selectedNoteId == id) {
      if (parentId != null && _notes.containsKey(parentId) && !_notes[parentId]!.isDeleted) {
        _selectedNoteId = parentId;
      } else {
        final roots = getRootNotes();
        _selectedNoteId = roots.isNotEmpty ? roots.first.id : null;
      }
    }

    _saveAndNotify();
  }

  void _softDeleteNodeRecursive(String id) {
    final note = _notes[id];
    if (note == null) return;

    note.isDeleted = true;
    note.deletedAt = DateTime.now();

    for (final childId in note.childIds) {
      _softDeleteNodeRecursive(childId);
    }
  }

  // Restore a note from Trash
  void restoreNote(String id) {
    final note = _notes[id];
    if (note == null) return;

    final parentId = note.parentId;
    if (parentId != null) {
      if (_notes.containsKey(parentId) && !_notes[parentId]!.isDeleted) {
        final parent = _notes[parentId]!;
        if (!parent.childIds.contains(id)) {
          parent.childIds.add(id);
          parent.updatedAt = DateTime.now();
        }
      } else {
        note.parentId = null; // parent was permanently deleted or is still in trash
      }
    }

    _restoreNodeRecursive(id);
    
    // Select the restored note
    _selectedNoteId = id;
    _isTrashSelected = false;

    _saveAndNotify();
  }

  void _restoreNodeRecursive(String id) {
    final note = _notes[id];
    if (note == null) return;

    note.isDeleted = false;
    note.deletedAt = null;

    for (final childId in note.childIds) {
      _restoreNodeRecursive(childId);
    }
  }

  // Recursive deletion helper
  void _deleteNodeRecursive(String id, Map<String, NoteNode> map) {
    final node = map[id];
    if (node == null) return;

    for (final childId in List.from(node.childIds)) {
      _deleteNodeRecursive(childId, map);
    }
    map.remove(id);
  }

  // Delete a note permanently (hard delete)
  void permanentlyDeleteNote(String id) {
    final note = _notes[id];
    if (note == null) return;

    final parentId = note.parentId;
    
    // Remove reference from parent if parent is still alive and active
    if (parentId != null && _notes.containsKey(parentId)) {
      _notes[parentId]!.childIds.remove(id);
      _notes[parentId]!.updatedAt = DateTime.now();
    }

    // Recursively delete node and all subnodes from memory map
    _deleteNodeRecursive(id, _notes);

    _saveAndNotify();
  }

  // Empty the Trash
  void emptyTrash() {
    _notes.removeWhere((key, note) => note.isDeleted);
    _saveAndNotify();
  }

  // Select Trash category
  void selectTrash() {
    _isTrashSelected = true;
    _selectedNoteId = null;
    notifyListeners();
  }

  // Retrieve trash notes
  List<NoteNode> getTrashNotes() {
    return _notes.values.where((note) {
      if (!note.isDeleted) return false;
      if (note.parentId == null) return true;
      final parent = _notes[note.parentId];
      return parent == null || !parent.isDeleted;
    }).toList()
      ..sort((a, b) => (b.deletedAt ?? b.updatedAt).compareTo(a.deletedAt ?? a.updatedAt));
  }

  int getTrashNotesCount() {
    return _notes.values.where((note) => note.isDeleted && (note.parentId == null || _notes[note.parentId]?.isDeleted != true)).length;
  }

  // Auto-clean up deleted notes older than 30 days
  void _cleanExpiredTrashNotes() {
    final now = DateTime.now();
    final toRemove = <String>[];

    _notes.forEach((id, note) {
      if (note.isDeleted) {
        final deletedTime = note.deletedAt ?? note.updatedAt;
        if (now.difference(deletedTime).inDays >= 30) {
          toRemove.add(id);
        }
      }
    });

    if (toRemove.isNotEmpty) {
      for (final id in toRemove) {
        _notes.remove(id);
      }
      _storageService.saveNotes(_notes);
    }
  }

  // Move / Re-parent a Note in the hierarchy
  void moveNote(String noteId, String? newParentId) {
    // Avoid cyclic moves (moving a node inside its own descendants)
    if (newParentId != null && _isDescendant(noteId, newParentId)) {
      return;
    }

    final note = _notes[noteId];
    if (note == null) return;

    // Remove from old parent
    final oldParentId = note.parentId;
    if (oldParentId != null && _notes.containsKey(oldParentId)) {
      _notes[oldParentId]!.childIds.remove(noteId);
      _notes[oldParentId]!.updatedAt = DateTime.now();
    }

    // Assign new parent
    note.parentId = newParentId;
    note.updatedAt = DateTime.now();

    if (newParentId != null && _notes.containsKey(newParentId)) {
      final newParent = _notes[newParentId]!;
      newParent.childIds.add(noteId);
      newParent.updatedAt = DateTime.now();
      newParent.isExpanded = true;
    }

    _saveAndNotify();
  }

  // Check if a node is a descendant of another node
  bool _isDescendant(String parentId, String checkId) {
    if (parentId == checkId) return true;
    final parent = _notes[parentId];
    if (parent == null) return false;

    for (final childId in parent.childIds) {
      if (_isDescendant(childId, checkId)) {
        return true;
      }
    }
    return false;
  }

  // Toggle tree sidebar expanded status
  void toggleNodeExpanded(String id) {
    final note = _notes[id];
    if (note != null) {
      note.isExpanded = !note.isExpanded;
      _saveAndNotify();
    }
  }

  // Get only top-level (root) notes
  List<NoteNode> getRootNotes() {
    final roots = _notes.values.where((node) => node.parentId == null && !node.isDeleted).toList();
    roots.sort((a, b) => a.position.compareTo(b.position));
    return roots;
  }

  // Get children of a note
  List<NoteNode> getChildNotes(String parentId) {
    final parent = _notes[parentId];
    if (parent == null) return [];

    final children = parent.childIds
        .map((id) => _notes[id])
        .where((node) => node != null && !node!.isDeleted)
        .cast<NoteNode>()
        .toList();
    
    // Sort by custom position
    children.sort((a, b) => a.position.compareTo(b.position));
    return children;
  }

  // Find Breadcrumbs: path from root to note
  List<NoteNode> getBreadcrumbs(String noteId) {
    final path = <NoteNode>[];
    String? currentId = noteId;

    while (currentId != null && _notes.containsKey(currentId)) {
      final node = _notes[currentId]!;
      path.insert(0, node); // Insert at start to build root -> leaf path
      currentId = node.parentId;
    }

    return path;
  }

  // Update search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Return flat list of notes matching query
  List<NoteNode> getFilteredNotes() {
    if (_searchQuery.trim().isEmpty) {
      return [];
    }

    final query = _searchQuery.toLowerCase();
    return _notes.values.where((node) {
      if (node.isDeleted) return false;
      return node.title.toLowerCase().contains(query) ||
             node.content.toLowerCase().contains(query);
    }).toList();
  }

  // Debounce saving notes to disk
  void _saveAndNotify({bool debounced = false}) {
    notifyListeners();

    if (debounced) {
      _debounceSaveTimer?.cancel();
      _debounceSaveTimer = Timer(const Duration(milliseconds: 800), () {
        _storageService.saveNotes(_notes);
      });
    } else {
      _storageService.saveNotes(_notes);
    }
  }

  @override
  void dispose() {
    _debounceSaveTimer?.cancel();
    super.dispose();
  }
}
