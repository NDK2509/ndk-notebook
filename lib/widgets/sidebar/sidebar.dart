import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import 'note_tree_view.dart';
import 'note_card_view.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isCardView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final isSearching = notesProvider.searchQuery.trim().isNotEmpty;
    final rootNotes = notesProvider.getRootNotes();
    final searchResults = notesProvider.getFilteredNotes();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.brightness == Brightness.dark
            ? const Color(0xFF131317)
            : const Color(0xFFF1F3F5),
        border: Border(
          right: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Sidebar Header (App Name & Action Buttons)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.account_tree_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'NDK Notebook',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.5,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Sort menu button
                  PopupMenuButton<String>(
                    tooltip: 'Sort Notes',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    icon: Icon(
                      Icons.sort_rounded,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      size: 18,
                    ),
                    iconSize: 18,
                    onSelected: (String value) {
                      notesProvider.sortAllNotes(value);
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'title_asc',
                        child: Row(
                          children: [
                            Icon(Icons.sort_by_alpha_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Alphabetical (A-Z)', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'title_desc',
                        child: Row(
                          children: [
                            Icon(Icons.sort_by_alpha_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Alphabetical (Z-A)', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'created_newest',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Created (Newest First)', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'created_oldest',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Created (Oldest First)', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'updated',
                        child: Row(
                          children: [
                            Icon(Icons.edit_calendar_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Recently Updated', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // View mode toggle
                  IconButton(
                    tooltip: _isCardView ? 'Tree View' : 'Card View',
                    onPressed: () {
                      setState(() => _isCardView = !_isCardView);
                    },
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                          child: FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: Icon(
                        _isCardView
                            ? Icons.account_tree_rounded
                            : Icons.dashboard_rounded,
                        key: ValueKey(_isCardView),
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        size: 17,
                      ),
                    ),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  ),
                  // Create Root Note button (Note/Kanban)
                  PopupMenuButton<String>(
                    tooltip: 'New Node',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    iconSize: 20,
                    onSelected: (String value) {
                      if (value == 'note') {
                        notesProvider.createRootNote();
                      } else if (value == 'kanban') {
                        notesProvider.createRootNote(
                          title: 'New Kanban Board',
                          isKanban: true,
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'note',
                        child: Row(
                          children: [
                            Icon(Icons.description_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('New Note', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'kanban',
                        child: Row(
                          children: [
                            Icon(Icons.view_kanban_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('New Kanban Board', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.brightness == Brightness.dark
                      ? const Color(0xFF1E1E24)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    notesProvider.setSearchQuery(val);
                  },
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search notes...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              notesProvider.setSearchQuery('');
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // View mode label
            if (!isSearching)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 6.0),
                child: Row(
                  children: [
                    Icon(
                      _isCardView ? Icons.dashboard_rounded : Icons.account_tree_rounded,
                      size: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isCardView ? 'Card View' : 'Tree View',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),

            // Note tree / card contents / Search results
            Expanded(
              child: SingleChildScrollView(
                child: isSearching
                    ? _buildSearchResults(context, searchResults, notesProvider)
                    : (_isCardView
                        ? const NoteCardView()
                        : _buildTreeNotes(rootNotes)),
              ),
            ),

            const Divider(),

            // Trash Section
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  notesProvider.selectTrash();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: notesProvider.isTrashSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: notesProvider.isTrashSelected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: notesProvider.isTrashSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Trash',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: notesProvider.isTrashSelected ? FontWeight.w600 : FontWeight.normal,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                        ),
                      ),
                      const Spacer(),
                      // Count of items in trash
                      if (notesProvider.getTrashNotesCount() > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${notesProvider.getTrashNotesCount()}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Sidebar Footer
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 15,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${notesProvider.notes.length} notes total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const Spacer(),
                  // Simple dark/light indicator or generic settings icon
                  Icon(
                    Icons.settings_suggest_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeNotes(List<dynamic> rootNotes) {
    if (rootNotes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          children: [
            Icon(
              Icons.drive_file_rename_outline_rounded,
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

    return NoteTreeView(nodes: rootNotes.cast());
  }

  Widget _buildSearchResults(BuildContext context, List<dynamic> results, NotesProvider provider) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
            ),
            const SizedBox(height: 12),
            Text(
              'No matches found',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 4.0),
          child: Text(
            'Search Results',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final node = results[index];
            final title = node.title.trim().isEmpty ? 'Untitled Note' : node.title;
            final isSelected = provider.selectedNoteId == node.id;
            
            // Build the parent hierarchy path for context
            final pathNodes = provider.getBreadcrumbs(node.id);
            final pathText = pathNodes.length > 1
                ? pathNodes.sublist(0, pathNodes.length - 1).map((n) => n.title.isEmpty ? 'Untitled' : n.title).join(' › ')
                : 'Root';

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  provider.selectNote(node.id);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                        : Colors.transparent,
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
                      Icon(
                        Icons.description_outlined,
                        size: 15,
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pathText,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
