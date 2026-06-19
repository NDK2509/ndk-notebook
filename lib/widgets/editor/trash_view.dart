import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';

class TrashView extends StatelessWidget {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final trashNotes = notesProvider.getTrashNotes();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Actions Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.delete_sweep_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                ),
                const SizedBox(width: 10),
                Text(
                  'Trash Bin',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                ),
                const Spacer(),
                if (trashNotes.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Empty Trash'),
                          content: const Text(
                            'Are you sure you want to permanently delete all notes in the trash? This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                notesProvider.emptyTrash();
                                Navigator.of(ctx).pop();
                              },
                              child: const Text(
                                'Empty Trash',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_forever_rounded, size: 16),
                    label: const Text('Empty Trash', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),

          // Trash list / Empty state
          Expanded(
            child: trashNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_forever_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Trash is Empty',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Deleted notes will be permanently removed after 30 days.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24.0),
                    itemCount: trashNotes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final note = trashNotes[index];
                      final title = note.title.trim().isEmpty ? 'Untitled Note' : note.title;

                      // Calculate remaining days
                      final deletedTime = note.deletedAt ?? note.updatedAt;
                      final difference = DateTime.now().difference(deletedTime);
                      final daysLeft = (30 - difference.inDays).clamp(0, 30);
                      final String remainingText = daysLeft == 0
                          ? 'Will be deleted soon'
                          : '$daysLeft days left before permanent deletion';

                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.description_outlined,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.error.withOpacity(0.15),
                                      ),
                                    ),
                                    child: Text(
                                      remainingText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Action Buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: 'Restore Note',
                                  child: IconButton(
                                    onPressed: () {
                                      notesProvider.restoreNote(note.id);
                                    },
                                    icon: const Icon(Icons.restore_from_trash_rounded),
                                    color: Theme.of(context).colorScheme.primary,
                                    padding: const EdgeInsets.all(10),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'Delete Permanently',
                                  child: IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Permanently Delete Note'),
                                          content: Text(
                                            'Are you sure you want to permanently delete "$title" and all its sub-notes? This action cannot be undone.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                notesProvider.permanentlyDeleteNote(note.id);
                                                Navigator.of(ctx).pop();
                                              },
                                              child: const Text(
                                                'Delete Permanently',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.delete_forever_rounded),
                                    color: Colors.redAccent,
                                    padding: const EdgeInsets.all(10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
