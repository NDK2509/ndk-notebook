import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_node.dart';
import '../../providers/notes_provider.dart';

class NoteTreeView extends StatelessWidget {
  final List<NoteNode> nodes;
  final int depth;

  const NoteTreeView({
    super.key,
    required this.nodes,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        return NoteTreeItem(node: node, depth: depth);
      },
    );
  }
}

class NoteTreeItem extends StatefulWidget {
  final NoteNode node;
  final int depth;

  const NoteTreeItem({
    super.key,
    required this.node,
    required this.depth,
  });

  @override
  State<NoteTreeItem> createState() => _NoteTreeItemState();
}

class _NoteTreeItemState extends State<NoteTreeItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final isSelected = notesProvider.selectedNoteId == widget.node.id;
    final hasChildren = widget.node.childIds.isNotEmpty;
    final title = widget.node.title.trim().isEmpty ? 'Untitled Note' : widget.node.title;

    final childrenNodes = notesProvider.getChildNotes(widget.node.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              notesProvider.selectNote(widget.node.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              padding: EdgeInsets.only(
                left: (widget.depth * 12.0) + 4.0, // Indent by depth
                right: 8.0,
                top: 6.0,
                bottom: 6.0,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                    : (_isHovering
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.03)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Collapse / Expand Arrow Button
                  GestureDetector(
                    onTap: () {
                      notesProvider.toggleNodeExpanded(widget.node.id);
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      child: hasChildren
                          ? AnimatedRotation(
                              turns: widget.node.isExpanded ? 0.25 : 0,
                              duration: const Duration(milliseconds: 150),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              ),
                            )
                          : Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  
                  // Note icon
                  Icon(
                    Icons.description_outlined,
                    size: 15,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),

                  // Title Text
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Hover action buttons (Add Child and Delete)
                  if (_isHovering || isSelected)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Create sub-note inline
                        Tooltip(
                          message: 'Create Sub-note',
                          child: GestureDetector(
                            onTap: () {
                              notesProvider.createSubNote(widget.node.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.add_box_outlined,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        // Delete node inline
                        Tooltip(
                          message: 'Delete Note',
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Note'),
                                  content: Text('Are you sure you want to delete "$title" and all its sub-notes? This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        notesProvider.deleteNote(widget.node.id);
                                        Navigator.of(ctx).pop();
                                      },
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 14,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        
        // Children Notes (Recursion)
        if (widget.node.isExpanded && hasChildren)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: NoteTreeView(
              nodes: childrenNodes,
              depth: widget.depth + 1,
            ),
          ),
      ],
    );
  }
}
