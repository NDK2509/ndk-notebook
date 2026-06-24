import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_node.dart';
import '../../providers/notes_provider.dart';

class KanbanView extends StatefulWidget {
  final NoteNode kanbanNode;

  const KanbanView({super.key, required this.kanbanNode});

  @override
  State<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends State<KanbanView> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.kanbanNode.title);
  }

  @override
  void didUpdateWidget(covariant KanbanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kanbanNode.id != widget.kanbanNode.id) {
      _titleController.text = widget.kanbanNode.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addNewColumn(BuildContext context) {
    final notesProvider = context.read<NotesProvider>();
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Column'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter column name...',
            labelText: 'Column Title',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                notesProvider.createSubNote(
                  widget.kanbanNode.id,
                  title: title,
                );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final columns = notesProvider.getChildNotes(widget.kanbanNode.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kanban Board Title Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    onChanged: (val) {
                      notesProvider.updateNoteTitle(widget.kanbanNode.id, val);
                    },
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                    decoration: InputDecoration(
                      hintText: 'Untitled Kanban Board',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.18),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => _addNewColumn(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Column'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal Column View Area
          Expanded(
            child: columns.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.view_kanban_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Columns Found',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a column to start organizing tasks.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => _addNewColumn(context),
                          child: const Text('Add Default / Custom Column'),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: columns.length,
                    onReorder: (oldIndex, newIndex) {
                      notesProvider.reorderSiblingNotes(
                        widget.kanbanNode.id,
                        oldIndex,
                        newIndex,
                      );
                    },
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final elevation = Tween<double>(begin: 0, end: 8).evaluate(animation);
                          return Material(
                            elevation: elevation,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final col = columns[index];
                      return KanbanColumnWidget(
                        key: ValueKey(col.id),
                        columnNode: col,
                        kanbanNode: widget.kanbanNode,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class KanbanColumnWidget extends StatefulWidget {
  final NoteNode columnNode;
  final NoteNode kanbanNode;

  const KanbanColumnWidget({
    super.key,
    required this.columnNode,
    required this.kanbanNode,
  });

  @override
  State<KanbanColumnWidget> createState() => _KanbanColumnWidgetState();
}

class _KanbanColumnWidgetState extends State<KanbanColumnWidget> {
  bool _isEditingTitle = false;
  late TextEditingController _titleController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.columnNode.title);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditingTitle) {
        _saveTitle();
      }
    });
  }

  @override
  void didUpdateWidget(covariant KanbanColumnWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.columnNode.title != widget.columnNode.title) {
      _titleController.text = widget.columnNode.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveTitle() {
    final title = _titleController.text.trim();
    if (title.isNotEmpty) {
      context.read<NotesProvider>().updateNoteTitle(widget.columnNode.id, title);
    }
    setState(() {
      _isEditingTitle = false;
    });
  }

  void _deleteColumn(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Column'),
        content: Text('Are you sure you want to delete column "${widget.columnNode.title}" and all its task cards? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<NotesProvider>().deleteNote(widget.columnNode.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addNewCard(BuildContext context) {
    final notesProvider = context.read<NotesProvider>();
    notesProvider.createSubNote(
      widget.columnNode.id,
      title: 'New Task Card',
      content: 'Double-click this card or click to open the markdown editor.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final cards = notesProvider.getChildNotes(widget.columnNode.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final columnBgColor = isDark
        ? const Color(0xFF1E1E24)
        : const Color(0xFFF1F3F5);

    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: columnBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
        ),
      ),
      child: DragTarget<String>(
        onWillAccept: (cardId) {
          // Accept card drops if it's a valid card (not the column itself or some unrelated node)
          return cardId != null && cardId != widget.columnNode.id;
        },
        onAccept: (cardId) {
          notesProvider.moveCardToColumnAndPosition(cardId, widget.columnNode.id);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovered = candidateData.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Column drag handle
                    ReorderableDragStartListener(
                      index: notesProvider
                          .getChildNotes(widget.kanbanNode.id)
                          .indexWhere((n) => n.id == widget.columnNode.id),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                          ),
                        ),
                      ),
                    ),

                    // Title edit or display
                    Expanded(
                      child: _isEditingTitle
                          ? TextField(
                              controller: _titleController,
                              focusNode: _focusNode,
                              onSubmitted: (_) => _saveTitle(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            )
                          : GestureDetector(
                              onDoubleTap: () {
                                setState(() {
                                  _isEditingTitle = true;
                                });
                                _focusNode.requestFocus();
                              },
                              child: Text(
                                widget.columnNode.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),

                    // Card Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${cards.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),

                    // Actions Menu Button
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      onSelected: (val) {
                        if (val == 'rename') {
                          setState(() {
                            _isEditingTitle = true;
                          });
                          _focusNode.requestFocus();
                        } else if (val == 'delete') {
                          _deleteColumn(context);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename Column', style: TextStyle(fontSize: 12)),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Column', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Cards Area (Scrollable Vertically)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  color: isHovered
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.04)
                      : Colors.transparent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: cards.length,
                    itemBuilder: (context, cardIndex) {
                      final card = cards[cardIndex];
                      return KanbanCardWidget(
                        key: ValueKey(card.id),
                        cardNode: card,
                        columnNode: widget.columnNode,
                      );
                    },
                  ),
                ),
              ),

              // Add Card Button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton.icon(
                  onPressed: () => _addNewCard(context),
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text('Add Card', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class KanbanCardWidget extends StatefulWidget {
  final NoteNode cardNode;
  final NoteNode columnNode;

  const KanbanCardWidget({
    super.key,
    required this.cardNode,
    required this.columnNode,
  });

  @override
  State<KanbanCardWidget> createState() => _KanbanCardWidgetState();
}

class _KanbanCardWidgetState extends State<KanbanCardWidget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = isDark
        ? const Color(0xFF131317)
        : Colors.white;

    final title = widget.cardNode.title.trim().isEmpty
        ? 'Untitled Task'
        : widget.cardNode.title;

    final content = widget.cardNode.content.trim();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: DragTarget<String>(
        onWillAccept: (incomingId) => incomingId != null && incomingId != widget.cardNode.id,
        onAccept: (incomingId) {
          notesProvider.moveCardToColumnAndPosition(
            incomingId,
            widget.columnNode.id,
            targetCardId: widget.cardNode.id,
          );
        },
        builder: (context, candidateData, rejectedData) {
          final isTargetHovered = candidateData.isNotEmpty;

          final cardContent = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isTargetHovered)
                Container(
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Draggable<String>(
                data: widget.cardNode.id,
                feedback: Material(
                  elevation: 6,
                  color: Colors.transparent,
                  child: Container(
                    width: 270,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBgColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.35,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    height: 60,
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    // Open in full editor
                    notesProvider.selectNote(widget.cardNode.id);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isHovering
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                            : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isHovering) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Task Card'),
                                      content: Text('Are you sure you want to delete task "$title"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            notesProvider.deleteNote(widget.cardNode.id);
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
                        if (content.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            content,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );

          return cardContent;
        },
      ),
    );
  }
}
