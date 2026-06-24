class NoteNode {
  final String id;
  String title;
  String content;
  String? parentId;
  List<String> childIds;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? lastOpenedAt;
  bool isDeleted;
  DateTime? deletedAt;
  int position;
  bool isExpanded; // Persists sidebar expand/collapse state
  DateTime? reminderDateTime;
  bool isReminderTriggered;
  bool isKanban;

  NoteNode({
    required this.id,
    this.title = '',
    this.content = '',
    this.parentId,
    List<String>? childIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastOpenedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.position = 0,
    this.isExpanded = false,
    this.reminderDateTime,
    this.isReminderTriggered = false,
    this.isKanban = false,
  })  : childIds = childIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    lastOpenedAt ??= createdAt;
  }

  // Create a copy with modified values
  NoteNode copyWith({
    String? id,
    String? title,
    String? content,
    String? parentId,
    List<String>? childIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastOpenedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    int? position,
    bool? isExpanded,
    DateTime? reminderDateTime,
    bool? isReminderTriggered,
    bool? isKanban,
  }) {
    return NoteNode(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      childIds: childIds ?? List.from(this.childIds),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      position: position ?? this.position,
      isExpanded: isExpanded ?? this.isExpanded,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      isReminderTriggered: isReminderTriggered ?? this.isReminderTriggered,
      isKanban: isKanban ?? this.isKanban,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'parentId': parentId,
      'childIds': childIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'position': position,
      'isExpanded': isExpanded,
      'reminderDateTime': reminderDateTime?.toIso8601String(),
      'isReminderTriggered': isReminderTriggered,
      'isKanban': isKanban,
    };
  }

  // From JSON
  factory NoteNode.fromJson(Map<String, dynamic> json) {
    return NoteNode(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      parentId: json['parentId'] as String?,
      childIds: (json['childIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      lastOpenedAt: json['lastOpenedAt'] != null ? DateTime.parse(json['lastOpenedAt'] as String) : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
      position: json['position'] as int? ?? 0,
      isExpanded: json['isExpanded'] as bool? ?? false,
      reminderDateTime: json['reminderDateTime'] != null ? DateTime.parse(json['reminderDateTime'] as String) : null,
      isReminderTriggered: json['isReminderTriggered'] as bool? ?? false,
      isKanban: json['isKanban'] as bool? ?? false,
    );
  }
}
