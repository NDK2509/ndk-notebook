import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';

class Breadcrumbs extends StatelessWidget {
  const Breadcrumbs({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final activeNoteId = notesProvider.selectedNoteId;

    if (activeNoteId == null) {
      return const SizedBox.shrink();
    }

    final breadcrumbs = notesProvider.getBreadcrumbs(activeNoteId);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: breadcrumbs.length,
        separatorBuilder: (context, index) => const Icon(
          Icons.chevron_right_rounded,
          size: 16,
          color: Colors.grey,
        ),
        itemBuilder: (context, index) {
          final note = breadcrumbs[index];
          final isLast = index == breadcrumbs.length - 1;
          final title = note.title.trim().isEmpty ? 'Untitled' : note.title;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                if (!isLast) {
                  notesProvider.selectNote(note.id);
                }
              },
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                    color: isLast
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
