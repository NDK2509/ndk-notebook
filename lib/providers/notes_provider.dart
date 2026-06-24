import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/note_node.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class NotesProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final Uuid _uuid = const Uuid();

  Map<String, NoteNode> _notes = {};
  String? _selectedNoteId;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isTrashSelected = false;
  Timer? _debounceSaveTimer;
  Timer? _reminderCheckTimer;
  NoteNode? _activeAlarmNote;

  NotesProvider() {
    _startReminderCheckTimer();
  }

  NoteNode? get activeAlarmNote => _activeAlarmNote;

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
  NoteNode createRootNote({
    String title = 'Untitled Note',
    String content = '',
    bool isKanban = false,
  }) {
    final newId = _uuid.v4();
    final position = getRootNotes().length;
    final newNode = NoteNode(
      id: newId,
      title: title,
      content: content,
      parentId: null,
      position: position,
      isKanban: isKanban,
    );

    _notes[newId] = newNode;
    _selectedNoteId = newId;
    _isTrashSelected = false;

    if (isKanban) {
      _createDefaultKanbanColumns(newId);
    }

    _saveAndNotify();
    return newNode;
  }

  // Create a Sub-note under a parent
  NoteNode createSubNote(
    String parentId, {
    String title = 'Untitled Sub-note',
    String content = '',
    bool isKanban = false,
  }) {
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
      isKanban: isKanban,
    );

    _notes[newId] = newNode;
    parentNode.childIds.add(newId);
    parentNode.updatedAt = DateTime.now();
    parentNode.isExpanded = true; // Auto-expand parent when adding child

    _selectedNoteId = newId;
    _isTrashSelected = false;

    if (isKanban) {
      _createDefaultKanbanColumns(newId);
    }

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

  // Helper to create default columns when initializing Kanban board
  void _createDefaultKanbanColumns(String kanbanId) {
    final columns = ['Todo', 'Doing', 'Review', 'Done'];
    for (int i = 0; i < columns.length; i++) {
      final colId = _uuid.v4();
      final colNode = NoteNode(
        id: colId,
        title: columns[i],
        content: '',
        parentId: kanbanId,
        position: i,
      );
      _notes[colId] = colNode;
      _notes[kanbanId]!.childIds.add(colId);
    }
  }

  // Move card to a specific column and optionally position it next to a target card
  void moveCardToColumnAndPosition(String cardId, String targetColumnId, {String? targetCardId}) {
    final card = _notes[cardId];
    final column = _notes[targetColumnId];
    if (card == null || column == null) return;

    // 1. Move to the new column parent
    moveNote(cardId, targetColumnId);

    // 2. If a specific target card is provided, position it right before that card
    if (targetCardId != null && targetCardId != cardId) {
      final siblings = getChildNotes(targetColumnId);
      final oldIndex = siblings.indexWhere((n) => n.id == cardId);
      final targetIndex = siblings.indexWhere((n) => n.id == targetCardId);
      if (oldIndex != -1 && targetIndex != -1) {
        reorderSiblingNotes(targetColumnId, oldIndex, targetIndex);
      }
    }
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
        .where((node) => node != null && !node.isDeleted)
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

  void _startReminderCheckTimer() {
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkReminders();
    });
  }

  void _checkReminders() {
    if (_notes.isEmpty) return;
    
    final now = DateTime.now();
    for (final note in _notes.values) {
      if (!note.isDeleted &&
          note.reminderDateTime != null &&
          !note.isReminderTriggered) {
        if (now.isAfter(note.reminderDateTime!) || now.isAtSameMomentAs(note.reminderDateTime!)) {
          // Trigger reminder
          note.isReminderTriggered = true;
          _activeAlarmNote = note;
          
          _storageService.saveNotes(_notes);
          
          NotificationService.showNotification(
            'Reminder: ${note.title.trim().isEmpty ? "Untitled Note" : note.title}',
            note.content.trim().isEmpty ? 'Reminder scheduled time reached.' : note.content,
          );
          NotificationService.playAlarm();
          
          notifyListeners();
          break;
        }
      }
    }
  }

  void setNoteReminder(String id, DateTime? dateTime) {
    final note = _notes[id];
    if (note != null) {
      note.reminderDateTime = dateTime;
      note.isReminderTriggered = false;
      _saveAndNotify();
    }
  }

  void dismissActiveAlarm() {
    if (_activeAlarmNote != null) {
      _activeAlarmNote = null;
      NotificationService.stopAlarm();
      notifyListeners();
    }
  }

  void snoozeActiveAlarm(int minutes) {
    if (_activeAlarmNote != null) {
      final note = _activeAlarmNote!;
      final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
      note.reminderDateTime = snoozeTime;
      note.isReminderTriggered = false;
      
      _activeAlarmNote = null;
      NotificationService.stopAlarm();
      _saveAndNotify();
    }
  }

  // Reorder sibling notes via drag-and-drop
  void reorderSiblingNotes(String? parentId, int oldIndex, int newIndex) {
    // Get the sibling list sorted by position
    final siblings = parentId == null ? getRootNotes() : getChildNotes(parentId);
    if (oldIndex < 0 || oldIndex >= siblings.length) return;

    // ReorderableListView passes newIndex adjusted for removal,
    // so adjust if moving downward
    if (newIndex > oldIndex) newIndex--;
    if (newIndex == oldIndex) return;
    if (newIndex < 0 || newIndex >= siblings.length) return;

    // Remove the dragged node and insert at new position
    final movedNode = siblings.removeAt(oldIndex);
    siblings.insert(newIndex, movedNode);

    // Re-assign position values to all siblings
    for (int i = 0; i < siblings.length; i++) {
      siblings[i].position = i;
    }

    _saveAndNotify();
  }

  // Move a note up among its siblings
  void moveNoteUp(String id) {
    final note = _notes[id];
    if (note == null) return;

    final siblings = note.parentId == null ? getRootNotes() : getChildNotes(note.parentId!);
    
    // Normalize positions to guarantee consecutive ordering
    for (int i = 0; i < siblings.length; i++) {
      siblings[i].position = i;
    }

    final index = siblings.indexWhere((n) => n.id == id);
    if (index > 0) {
      final prevNote = siblings[index - 1];
      note.position = index - 1;
      prevNote.position = index;
      _saveAndNotify();
    }
  }

  // Move a note down among its siblings
  void moveNoteDown(String id) {
    final note = _notes[id];
    if (note == null) return;

    final siblings = note.parentId == null ? getRootNotes() : getChildNotes(note.parentId!);
    
    // Normalize positions to guarantee consecutive ordering
    for (int i = 0; i < siblings.length; i++) {
      siblings[i].position = i;
    }

    final index = siblings.indexWhere((n) => n.id == id);
    if (index != -1 && index < siblings.length - 1) {
      final nextNote = siblings[index + 1];
      note.position = index + 1;
      nextNote.position = index;
      _saveAndNotify();
    }
  }

  // Sort notes globally (all root levels and child levels)
  void sortAllNotes(String sortBy) {
    // Helper to sort a list of nodes and update their position values
    void sortList(List<NoteNode> list) {
      if (sortBy == 'title_asc') {
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      } else if (sortBy == 'title_desc') {
        list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      } else if (sortBy == 'created_newest') {
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else if (sortBy == 'created_oldest') {
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else if (sortBy == 'updated') {
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
      
      // Assign new consecutive position IDs based on sorting
      for (int i = 0; i < list.length; i++) {
        list[i].position = i;
      }
    }

    // 1. Sort root notes
    final roots = getRootNotes();
    sortList(roots);

    // 2. Sort children of each note recursively
    for (final note in _notes.values) {
      if (note.childIds.isNotEmpty) {
        final children = getChildNotes(note.id);
        sortList(children);
      }
    }

    _saveAndNotify();
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
    _reminderCheckTimer?.cancel();
    super.dispose();
  }
}
