class ConversationMessage {
  final String id;
  final String original;
  final String translated;
  final String sourceLang;
  final String targetLang;
  final bool isLeftSpeaker;
  final DateTime timestamp;

  ConversationMessage({
    required this.id,
    required this.original,
    required this.translated,
    required this.sourceLang,
    required this.targetLang,
    required this.isLeftSpeaker,
    required this.timestamp,
  });

  ConversationMessage copyWith({
    String? id,
    String? original,
    String? translated,
    String? sourceLang,
    String? targetLang,
    bool? isLeftSpeaker,
    DateTime? timestamp,
  }) => ConversationMessage(
    id: id ?? this.id,
    original: original ?? this.original,
    translated: translated ?? this.translated,
    sourceLang: sourceLang ?? this.sourceLang,
    targetLang: targetLang ?? this.targetLang,
    isLeftSpeaker: isLeftSpeaker ?? this.isLeftSpeaker,
    timestamp: timestamp ?? this.timestamp,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'original': original,
    'translated': translated,
    'sourceLang': sourceLang,
    'targetLang': targetLang,
    'isLeftSpeaker': isLeftSpeaker,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory ConversationMessage.fromMap(Map m) {
    final ts = m['timestamp'];
    return ConversationMessage(
      id: (m['id'] as String?) ?? '',
      original: (m['original'] as String?) ?? '',
      translated: (m['translated'] as String?) ?? '',
      sourceLang: (m['sourceLang'] as String?) ?? 'auto',
      targetLang: (m['targetLang'] as String?) ?? 'en',
      isLeftSpeaker: (m['isLeftSpeaker'] as bool?) ?? true,
      timestamp: ts is int
          ? DateTime.fromMillisecondsSinceEpoch(ts)
          : DateTime.now(),
    );
  }
}
