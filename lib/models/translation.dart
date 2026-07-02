enum TranslationOrigin { text, voice, conversation, camera, gallery }

class Translation {
  final String id;
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final DateTime createdAt;
  final bool isFavorite;
  final TranslationOrigin origin;

  Translation({
    required this.id,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.createdAt,
    this.isFavorite = false,
    this.origin = TranslationOrigin.text,
  });

  Translation copyWith({String? translatedText, bool? isFavorite}) =>
      Translation(
        id: id,
        sourceText: sourceText,
        translatedText: translatedText ?? this.translatedText,
        sourceLang: sourceLang,
        targetLang: targetLang,
        createdAt: createdAt,
        isFavorite: isFavorite ?? this.isFavorite,
        origin: origin,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'sourceText': sourceText,
    'translatedText': translatedText,
    'sourceLang': sourceLang,
    'targetLang': targetLang,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'isFavorite': isFavorite,
    'origin': origin.index,
  };

  factory Translation.fromMap(Map m) {
    final created = m['createdAt'];
    final createdAt = created is int
        ? DateTime.fromMillisecondsSinceEpoch(created)
        : DateTime.now();
    final originRaw = m['origin'];
    final originIdx = originRaw is int ? originRaw : 0;
    return Translation(
      id: (m['id'] as String?) ?? '',
      sourceText: (m['sourceText'] as String?) ?? '',
      translatedText: (m['translatedText'] as String?) ?? '',
      sourceLang: (m['sourceLang'] as String?) ?? 'auto',
      targetLang: (m['targetLang'] as String?) ?? 'en',
      createdAt: createdAt,
      isFavorite: (m['isFavorite'] as bool?) ?? false,
      origin: TranslationOrigin
          .values[originIdx.clamp(0, TranslationOrigin.values.length - 1)],
    );
  }
}
