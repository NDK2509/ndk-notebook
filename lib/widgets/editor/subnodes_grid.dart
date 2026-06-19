import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_node.dart';
import '../../providers/notes_provider.dart';

class SubnodesGrid extends StatefulWidget {
  const SubnodesGrid({super.key});

  @override
  State<SubnodesGrid> createState() => _SubnodesGridState();
}

class _SubnodesGridState extends State<SubnodesGrid> {
  double _height = 200.0;

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final activeNoteId = notesProvider.selectedNoteId;

    if (activeNoteId == null) {
      return const SizedBox.shrink();
    }

    final children = notesProvider.getChildNotes(activeNoteId);

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) {
            setState(() {
              _height = (_height - details.delta.dy).clamp(80.0, 450.0);
            });
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeUpDown,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Divider(
                height: 1,
                thickness: 1,
              ),
            ),
          ),
        ),
        SizedBox(
          height: _height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Row(
                  children: [
                    Text(
                      'Sub-notes',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${children.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Inline compact button to add sub-note
                    TextButton.icon(
                      onPressed: () {
                        notesProvider.createSubNote(activeNoteId);
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text(
                        'Add',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: children.map((child) => _SubnoteChip(child: child)).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubnoteChip extends StatefulWidget {
  final NoteNode child;

  const _SubnoteChip({required this.child});

  @override
  State<_SubnoteChip> createState() => _SubnoteChipState();
}

class _SubnoteChipState extends State<_SubnoteChip> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.read<NotesProvider>();
    final title = widget.child.title.trim().isEmpty ? 'Untitled' : widget.child.title;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          notesProvider.selectNote(widget.child.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovering
                ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isHovering
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                  : Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.subdirectory_arrow_right_rounded,
                size: 13,
                color: _isHovering
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                ),
              ),
              if (_isHovering) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Note'),
                        content: Text('Are you sure you want to delete "$title" and all its sub-notes?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              notesProvider.deleteNote(widget.child.id);
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
