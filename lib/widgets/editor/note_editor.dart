import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../models/note_node.dart';
import 'breadcrumbs.dart';
import 'subnodes_grid.dart';

import 'trash_view.dart';

class NoteEditor extends StatefulWidget {
  const NoteEditor({super.key});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _lastNoteId;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Inject Markdown helpers at the cursor position
  void _injectMarkdown(String tagToInsert) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    int start = selection.start;
    int end = selection.end;
    
    if (start < 0 || end < 0) {
      start = text.length;
      end = text.length;
    }

    final newText = text.replaceRange(start, end, tagToInsert);
    _contentController.text = newText;
    
    // Set selection right after the inserted text
    _contentController.selection = TextSelection.collapsed(
      offset: start + tagToInsert.length,
    );
    
    // Update state provider
    final notesProvider = context.read<NotesProvider>();
    final note = notesProvider.selectedNote;
    if (note != null) {
      notesProvider.updateNoteContent(note.id, newText);
    }
  }

  Widget _buildFormatButton(IconData icon, String tag, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _injectMarkdown(tag),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeBgColor = Theme.of(context).colorScheme.primary;
    final activeFgColor = Colors.white;
    final inactiveFgColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? activeFgColor : inactiveFgColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? activeFgColor : inactiveFgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final note = notesProvider.selectedNote;

    if (notesProvider.isTrashSelected) {
      return const TrashView();
    }

    if (note == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
            ),
            const SizedBox(height: 16),
            Text(
              'No Note Selected',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a note in the sidebar to start writing.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                notesProvider.createRootNote();
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New Note'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    }

    // Sync input fields when changing note selections
    if (_lastNoteId != note.id) {
      _lastNoteId = note.id;
      _titleController.text = note.title;
      _contentController.text = note.content;
    }

    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(note.updatedAt);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs and Top Actions bar
          const Breadcrumbs(),
          const Divider(),

          // Editor Workspace
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Metadata & Edit/Preview Switch Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last edited $formattedDate',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      const Spacer(),
                      
                      // Add Sub-note button
                      OutlinedButton.icon(
                        onPressed: () {
                          notesProvider.createSubNote(note.id);
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Sub-note', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildReminderButton(context, notesProvider, note),
                      const SizedBox(width: 12),

                      // Edit / Preview Toggle Buttons
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildToggleButton(
                              icon: Icons.edit_rounded,
                              label: 'Edit',
                              isSelected: !_isPreview,
                              onTap: () => setState(() => _isPreview = false),
                            ),
                            _buildToggleButton(
                              icon: Icons.menu_book_rounded,
                              label: 'Preview',
                              isSelected: _isPreview,
                              onTap: () => setState(() => _isPreview = true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Auto-saved',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Note Title Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _titleController,
                    onChanged: (val) {
                      notesProvider.updateNoteTitle(note.id, val);
                    },
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                    decoration: InputDecoration(
                      hintText: 'Untitled Note',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.18),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Markdown Formatting Toolbar (Only in Edit mode)
                if (!_isPreview) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFormatButton(Icons.format_bold_rounded, '**bold**', 'Bold'),
                            _buildFormatButton(Icons.format_italic_rounded, '*italic*', 'Italic'),
                            _buildFormatButton(Icons.format_underlined_rounded, '<u>underline</u>', 'Underline'),
                            _buildFormatButton(Icons.code_rounded, '`code`', 'Code block'),
                            _buildFormatButton(
                              Icons.grid_on_rounded,
                              '\n| Column 1 | Column 2 |\n|---|---|\n| Cell 1 | Cell 2 |\n',
                              'Table',
                            ),
                            _buildFormatButton(Icons.format_list_bulleted_rounded, '\n- Bullet Item\n', 'Bullet List'),
                            _buildFormatButton(Icons.format_list_numbered_rounded, '\n1. Numbered Item\n', 'Numbered List'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Note Body Editor / Rendered Markdown Preview
                if (_isPreview)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: MarkdownBody(
                      data: note.content.isEmpty ? '*No content written yet.*' : note.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: TextStyle(fontSize: 14.5, height: 1.6, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9)),
                        h1: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, height: 1.8),
                        h2: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, height: 1.6),
                        h3: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, height: 1.5),
                        code: TextStyle(
                          backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.6)),
                        ),
                        tableBody: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                        tableBorder: TableBorder.all(color: Theme.of(context).colorScheme.outline, width: 1),
                        tableCellsPadding: const EdgeInsets.all(8),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: _contentController,
                      onChanged: (val) {
                        notesProvider.updateNoteContent(note.id, val);
                      },
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 14.5,
                            height: 1.6,
                          ),
                      decoration: InputDecoration(
                        hintText: 'Start writing notes...\nUse the formatting bar above to write tables, code, and lists.',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SubnodesGrid(),
        ],
      ),
    );
  }

  Widget _buildReminderButton(BuildContext context, NotesProvider provider, NoteNode note) {
    final hasReminder = note.reminderDateTime != null;
    final isPast = hasReminder && note.reminderDateTime!.isBefore(DateTime.now());
    
    String label = 'Set Reminder';
    if (hasReminder) {
      label = DateFormat('MMM dd, hh:mm a').format(note.reminderDateTime!);
      if (note.isReminderTriggered) {
        label = 'Triggered';
      }
    }

    final Color buttonColor = hasReminder 
        ? (note.isReminderTriggered ? Colors.grey : Colors.amber)
        : Theme.of(context).colorScheme.primary;

    return OutlinedButton.icon(
      onPressed: () {
        if (hasReminder) {
          _showReminderOptionsMenu(context, provider, note);
        } else {
          _selectReminderDateTime(context, provider, note);
        }
      },
      icon: Icon(
        hasReminder 
            ? (note.isReminderTriggered ? Icons.notifications_none_rounded : Icons.notifications_active_rounded)
            : Icons.notifications_none_rounded,
        size: 16,
        color: buttonColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13, 
          fontWeight: FontWeight.w600,
          color: buttonColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(
          color: buttonColor.withOpacity(0.5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _selectReminderDateTime(BuildContext context, NotesProvider provider, NoteNode note) async {
    final now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final reminderTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (reminderTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot set reminder in the past!')),
      );
      return;
    }

    provider.setNoteReminder(note.id, reminderTime);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set for ${DateFormat('MMM dd, hh:mm a').format(reminderTime)}'),
      ),
    );
  }

  void _showReminderOptionsMenu(BuildContext context, NotesProvider provider, NoteNode note) {
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    if (button == null) return;
    
    final size = button.size;
    final offset = button.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + size.width / 2,
        offset.dy + size.height * 2.5,
        offset.dx + size.width,
        offset.dy + size.height * 3.5,
      ),
      items: const [
        PopupMenuItem(value: 'edit', child: Text('Change Reminder')),
        PopupMenuItem(value: 'delete', child: Text('Delete Reminder')),
      ],
      elevation: 8,
    ).then((value) {
      if (value == 'edit') {
        _selectReminderDateTime(context, provider, note);
      } else if (value == 'delete') {
        provider.setNoteReminder(note.id, null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder deleted.')),
        );
      }
    });
  }
}
