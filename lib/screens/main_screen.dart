import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../widgets/editor/note_editor.dart';
import '../widgets/sidebar/sidebar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final selectedNote = notesProvider.selectedNote;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            selectedNote == null
                ? 'NDK Notebook'
                : (selectedNote.title.trim().isEmpty ? 'Untitled Note' : selectedNote.title),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(),
          ),
        ),
        drawer: const Drawer(
          child: Sidebar(),
        ),
        body: const NoteEditor(),
      );
    }

    // Desktop/Tablet split pane layout
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Left Panel
          const Sidebar(),
          
          // Main Editor Right Panel
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const NoteEditor(),
            ),
          ),
        ],
      ),
    );
  }
}
