import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../models/note_node.dart';
import '../widgets/editor/note_editor.dart';
import '../widgets/sidebar/sidebar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final selectedNote = notesProvider.selectedNote;
    final activeAlarmNote = notesProvider.activeAlarmNote;
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget body;
    if (isMobile) {
      body = Scaffold(
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
    } else {
      // Desktop/Tablet split pane layout
      body = Scaffold(
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

    return Stack(
      children: [
        body,
        if (activeAlarmNote != null)
          _buildAlarmOverlay(context, notesProvider, activeAlarmNote),
      ],
    );
  }

  Widget _buildAlarmOverlay(
      BuildContext context, NotesProvider provider, NoteNode note) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Glassmorphic blurred backdrop
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black.withOpacity(0.65),
                ),
              ),
            ),
            
            // Dialog Center Pane
            Center(
              child: Container(
                width: 420,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E), // Premium dark theme color
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PulsingAlarmIcon(),
                    const SizedBox(height: 24),
                    Text(
                      'REMINDER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      note.title.trim().isEmpty ? 'Untitled Note' : note.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    if (note.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Text(
                          note.content.trim(),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    
                    // Buttons Action Row
                    Row(
                      children: [
                        // Snooze Dropdown Menu Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Show popup menu to choose snooze time
                              _showSnoozeMenu(context, provider);
                            },
                            icon: const Icon(Icons.snooze_rounded, size: 18),
                            label: const Text('Snooze'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.15),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Dismiss Button
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              provider.dismissActiveAlarm();
                            },
                            icon: const Icon(Icons.done_all_rounded, size: 18),
                            label: const Text('Dismiss'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
          ],
        ),
      ),
    );
  }

  void _showSnoozeMenu(BuildContext context, NotesProvider provider) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final size = button.size;
    final offset = button.localToGlobal(Offset.zero);

    showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + size.width / 4,
        offset.dy + size.height / 2,
        offset.dx + size.width / 2,
        offset.dy + size.height / 2,
      ),
      items: const [
        PopupMenuItem(value: 5, child: Text('Snooze for 5 minutes')),
        PopupMenuItem(value: 15, child: Text('Snooze for 15 minutes')),
        PopupMenuItem(value: 30, child: Text('Snooze for 30 minutes')),
        PopupMenuItem(value: 60, child: Text('Snooze for 1 hour')),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        provider.snoozeActiveAlarm(value);
      }
    });
  }
}

class PulsingAlarmIcon extends StatefulWidget {
  const PulsingAlarmIcon({super.key});

  @override
  State<PulsingAlarmIcon> createState() => _PulsingAlarmIconState();
}

class _PulsingAlarmIconState extends State<PulsingAlarmIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08 + (_controller.value * 0.08)),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.amber.withOpacity(0.2 + (_controller.value * 0.35)),
                width: 2.5,
              ),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              size: 44,
              color: Colors.amber[300],
            ),
          ),
        );
      },
    );
  }
}
