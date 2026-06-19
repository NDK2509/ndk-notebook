import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_desktop_demo/models/note_node.dart';

void main() {
  group('NoteNode Tests', () {
    test('NoteNode serialization and deserialization', () {
      final node = NoteNode(
        id: 'test-id-123',
        title: 'Parent Note',
        content: '# Description',
        parentId: null,
        childIds: ['child-1', 'child-2'],
        position: 1,
        isExpanded: true,
      );

      final json = node.toJson();
      expect(json['id'], 'test-id-123');
      expect(json['title'], 'Parent Note');
      expect(json['content'], '# Description');
      expect(json['parentId'], isNull);
      expect(json['childIds'], ['child-1', 'child-2']);
      expect(json['position'], 1);
      expect(json['isExpanded'], true);

      final decoded = NoteNode.fromJson(json);
      expect(decoded.id, node.id);
      expect(decoded.title, node.title);
      expect(decoded.content, node.content);
      expect(decoded.parentId, node.parentId);
      expect(decoded.childIds, node.childIds);
      expect(decoded.position, node.position);
      expect(decoded.isExpanded, node.isExpanded);
    });

    test('NoteNode copyWith modification check', () {
      final node = NoteNode(id: 'original-id', title: 'Original Title');
      final updatedNode = node.copyWith(title: 'New Title', isExpanded: true);

      expect(updatedNode.id, 'original-id');
      expect(updatedNode.title, 'New Title');
      expect(updatedNode.isExpanded, true);
      // Verify original is untouched
      expect(node.title, 'Original Title');
      expect(node.isExpanded, false);
    });
  });
}
