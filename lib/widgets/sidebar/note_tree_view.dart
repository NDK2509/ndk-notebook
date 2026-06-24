import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_node.dart';
import '../../providers/notes_provider.dart';

class NoteTreeView extends StatelessWidget {
  final List<NoteNode> nodes;
  final int depth;
  final String? parentId;

  const NoteTreeView({
    super.key,
    required this.nodes,
    this.depth = 0,
    this.parentId,
  });

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();

    final notesProvider = context.read<NotesProvider>();

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevation = Tween<double>(begin: 0, end: 6).evaluate(animation);
            final scale = Tween<double>(begin: 1.0, end: 1.02).evaluate(animation);
            return Transform.scale(
              scale: scale,
              child: Material(
                elevation: elevation,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        notesProvider.reorderSiblingNotes(parentId, oldIndex, newIndex);
      },
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        return NoteTreeItem(
          key: ValueKey(node.id),
          node: node,
          depth: depth,
          dragIndex: index,
        );
      },
    );
  }
}

class NoteTreeItem extends StatefulWidget {
  final NoteNode node;
  final int depth;
  final int dragIndex;

  const NoteTreeItem({
    super.key,
    required this.node,
    required this.depth,
    required this.dragIndex,
  });

  @override
  State<NoteTreeItem> createState() => _NoteTreeItemState();
}

class _NoteTreeItemState extends State<NoteTreeItem> {
  bool _isHovering = false;

  bool get _isFreeze {
    final lastTime = widget.node.lastOpenedAt ?? widget.node.createdAt;
    return DateTime.now().difference(lastTime).inMinutes >= 15;
  }

  bool get _isAncient {
    return widget.node.childIds.length >= 3;
  }

  bool get _isSprout {
    final isNew = DateTime.now().difference(widget.node.createdAt).inHours < 1;
    final isShort = widget.node.content.length <= 50;
    return isNew && isShort;
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final isSelected = notesProvider.selectedNoteId == widget.node.id;
    final hasChildren = widget.node.childIds.isNotEmpty;
    final title = widget.node.title.trim().isEmpty ? 'Untitled Note' : widget.node.title;

    final childrenNodes = notesProvider.getChildNotes(widget.node.id);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Lifecycle classification
    final freeze = _isFreeze;
    final ancient = _isAncient;
    final sprout = _isSprout;

    IconData noteIcon = Icons.description_outlined;
    Color iconColor;
    
    if (widget.node.isKanban) {
      noteIcon = Icons.view_kanban_rounded;
      iconColor = isSelected
          ? Theme.of(context).colorScheme.primary
          : (isDark ? Colors.amberAccent : Colors.amber.shade700);
    } else if (freeze) {
      noteIcon = Icons.ac_unit_rounded;
      iconColor = isDark ? Colors.lightBlueAccent : Colors.blue;
    } else if (ancient) {
      noteIcon = Icons.park_rounded;
      iconColor = isDark ? Colors.tealAccent : Colors.teal;
    } else if (sprout) {
      noteIcon = Icons.eco_rounded;
      iconColor = isDark ? Colors.lightGreenAccent : Colors.green;
    } else {
      iconColor = isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    }

    final double opacity = freeze ? 0.55 : 1.0;
    final double paddingVertical = freeze ? 3.0 : 6.0;
    final double fontSize = freeze ? 11.5 : 13.0;
    final double iconSize = freeze ? 13.0 : 15.0;
    final double arrowIconSize = freeze ? 13.0 : 16.0;

    return Opacity(
      opacity: opacity,
      child: Column(
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
                  top: paddingVertical,
                  bottom: paddingVertical,
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
                    // Drag handle — visible on hover
                    if (_isHovering || isSelected)
                      ReorderableDragStartListener(
                        index: widget.dragIndex,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),

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
                                  size: arrowIconSize,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                ),
                              )
                            : Container(
                                width: freeze ? 3 : 4,
                                height: freeze ? 3 : 4,
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
                      noteIcon,
                      size: iconSize,
                      color: iconColor,
                    ),
                    const SizedBox(width: 8),
  
                    // Title Text
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: fontSize,
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
                          message: 'Create Sub-note / Kanban',
                          child: GestureDetector(
                            onTapDown: (details) {
                              final offset = details.globalPosition;
                              showMenu<String>(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                  offset.dx,
                                  offset.dy,
                                  offset.dx + 40,
                                  offset.dy + 40,
                                ),
                                items: const [
                                  PopupMenuItem(
                                    value: 'note',
                                    child: Row(
                                      children: [
                                        Icon(Icons.description_outlined, size: 16),
                                        SizedBox(width: 8),
                                        Text('Add Sub-note', style: TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'kanban',
                                    child: Row(
                                      children: [
                                        Icon(Icons.view_kanban_outlined, size: 16),
                                        SizedBox(width: 8),
                                        Text('Add Kanban Board', style: TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ).then((value) {
                                if (value == 'note') {
                                  notesProvider.createSubNote(widget.node.id);
                                } else if (value == 'kanban') {
                                  notesProvider.createSubNote(
                                    widget.node.id,
                                    title: 'New Kanban Board',
                                    isKanban: true,
                                  );
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
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
                              padding: EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
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
              parentId: widget.node.id,
            ),
          ),
      ],
    ),
  );
}
}
