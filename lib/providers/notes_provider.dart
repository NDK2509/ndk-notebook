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
  Timer? _debounceSaveTimer;

  Map<String, NoteNode> get notes => _notes;
  String? get selectedNoteId => _selectedNoteId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  NoteNode? get selectedNote => _selectedNoteId != null ? _notes[_selectedNoteId] : null;

  // Load notes initially
  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    _notes = await _storageService.loadNotes();
    
    // Select first root note if available, otherwise stay null
    if (_notes.isNotEmpty) {
      final roots = getRootNotes();
      if (roots.isNotEmpty) {
        _selectedNoteId = roots.first.id;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Set selected note
  void selectNote(String? id) {
    if (id == null || _notes.containsKey(id)) {
      _selectedNoteId = id;
      notifyListeners();
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

  // Recursive deletion helper
  void _deleteNodeRecursive(String id, Map<String, NoteNode> map) {
    final node = map[id];
    if (node == null) return;

    for (final childId in List.from(node.childIds)) {
      _deleteNodeRecursive(childId, map);
    }
    map.remove(id);
  }

  // Delete a Note and its descendants
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

    // Recursively delete node and all subnodes
    _deleteNodeRecursive(id, _notes);

    // If active note was deleted, fallback to parent, or first root, or null
    if (_selectedNoteId == id) {
      if (parentId != null && _notes.containsKey(parentId)) {
        _selectedNoteId = parentId;
      } else {
        final roots = getRootNotes();
        _selectedNoteId = roots.isNotEmpty ? roots.first.id : null;
      }
    }

    _saveAndNotify();
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
    final roots = _notes.values.where((node) => node.parentId == null).toList();
    roots.sort((a, b) => a.position.compareTo(b.position));
    return roots;
  }

  // Get children of a note
  List<NoteNode> getChildNotes(String parentId) {
    final parent = _notes[parentId];
    if (parent == null) return [];

    final children = parent.childIds
        .map((id) => _notes[id])
        .where((node) => node != null)
        .cast<NoteNode>()
        .toList();
    
    // Sort by custom position
    children.sort((a, b) => a.position.compareTo(b.position));
    return children;
  }

  // Find Breadcrumbs: path from root to node
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
