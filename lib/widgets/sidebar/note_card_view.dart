import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/note_node.dart';
import '../../providers/notes_provider.dart';

class NoteCardView extends StatelessWidget {
  const NoteCardView({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final allNotes = notesProvider.notes.values
        .where((n) => !n.isDeleted)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (allNotes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
            ),
            const SizedBox(height: 12),
            Text(
              'No notes yet',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Click the plus button to add your first note.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: allNotes.length,
      itemBuilder: (context, index) {
        return _NoteCard(note: allNotes[index]);
      },
    );
  }
}

class _NoteCard extends StatefulWidget {
  final NoteNode note;

  const _NoteCard({required this.note});

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final isSelected = notesProvider.selectedNoteId == widget.note.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = widget.note.title.trim().isEmpty
        ? 'Untitled Note'
        : widget.note.title;

    // Get a content preview — strip leading whitespace and limit length
    final rawContent = widget.note.content.trim();
    final contentPreview = rawContent.length > 120
        ? '${rawContent.substring(0, 120)}…'
        : rawContent;

    // Build breadcrumb path
    final pathNodes = notesProvider.getBreadcrumbs(widget.note.id);
    final pathText = pathNodes.length > 1
        ? pathNodes
            .sublist(0, pathNodes.length - 1)
            .map((n) => n.title.isEmpty ? 'Untitled' : n.title)
            .join(' › ')
        : null;

    // Lifecycle badge
    final hasChildren = widget.note.childIds.isNotEmpty;
    final childCount = widget.note.childIds.length;

    // Date formatting
    final dateFormat = DateFormat('MMM d');
    final updatedStr = dateFormat.format(widget.note.updatedAt);

    // Card colors
    final cardBg = isSelected
        ? (isDark
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).colorScheme.primary.withOpacity(0.06))
        : (isDark ? const Color(0xFF1A1A22) : Colors.white);

    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
        : (_isHovering
            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.12)
            : (isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06)));

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            notesProvider.selectNote(widget.note.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: _isHovering
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row
                Row(
                  children: [
                    Icon(
                      widget.note.isKanban
                          ? Icons.view_kanban_outlined
                          : (hasChildren
                              ? Icons.folder_outlined
                              : Icons.description_outlined),
                      size: 14,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.45),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.9),
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Hover action: delete
                    if (_isHovering)
                      GestureDetector(
                        onTap: () {
                          notesProvider.deleteNote(widget.note.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.35),
                          ),
                        ),
                      ),
                  ],
                ),

                // Content preview
                if (contentPreview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    contentPreview,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.55),
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),

                // Bottom meta row: path, child count, date
                Row(
                  children: [
                    // Breadcrumb path
                    if (pathText != null) ...[
                      Flexible(
                        child: Text(
                          pathText,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Child count badge
                    if (hasChildren)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$childCount sub',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.7),
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Updated date
                    Text(
                      updatedStr,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
