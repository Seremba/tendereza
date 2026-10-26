class Verse {
  final String label;
  final String lines;
  const Verse({required this.label, required this.lines});
  factory Verse.fromJson(Map<String, dynamic> json) => Verse(
        label: json['label'] as String,
        lines: json['lines'] as String,
      );
  Map<String, dynamic> toJson() => {'label': label, 'lines': lines};
}

class HymnHistory {
  final int? year;
  final String? author;
  final String? composer;
  final String? tune;
  final String? story;

  const HymnHistory({
    this.year,
    this.author,
    this.composer,
    this.tune,
    this.story,
  });

  factory HymnHistory.fromJson(Map<String, dynamic> json) => HymnHistory(
        year: json['year'] as int?,
        author: json['author'] as String?,
        composer: json['composer'] as String?,
        tune: json['tune'] as String?,
        story: json['story'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (year != null) 'year': year,
        if (author != null) 'author': author,
        if (composer != null) 'composer': composer,
        if (tune != null) 'tune': tune,
        if (story != null) 'story': story,
      };
}

class Hymn {
  final dynamic number;
  final String? key;
  final String title;

  /// English title — shown below the Luganda title on the LG side.
  /// Populated in hymns_lg.json only; null on the English side.
  final String? englishTitle;

  /// Composer / arranger name e.g. "John B. Dykes"
  final String? composer;

  /// Book source reference e.g. "CH 73"
  final String? bookSource;

  final String firstLine;
  final List<Verse> verses;
  final HymnHistory? history;

  const Hymn({
    required this.number,
    this.key,
    required this.title,
    this.englishTitle,
    this.composer,
    this.bookSource,
    required this.firstLine,
    required this.verses,
    this.history,
  });

  /// Returns true for children's songs whose number starts with "C"
  bool get isChildrenSong =>
      number is String && number.toString().startsWith('C');

  /// True when at least one piece of metadata is available to display
  bool get hasMetadata =>
      key != null || composer != null || bookSource != null;

  factory Hymn.fromJson(Map<String, dynamic> json) => Hymn(
        number:       json['number'],
        key:          json['key']           as String?,
        title:        json['title']         as String,
        englishTitle: json['english_title'] as String?,
        composer:     json['composer']      as String?,
        bookSource:   json['book_source']   as String?,
        firstLine:    json['first_line']    as String,
        verses: (json['verses'] as List)
            .map((v) => Verse.fromJson(v as Map<String, dynamic>))
            .toList(),
        history: json['history'] != null
            ? HymnHistory.fromJson(json['history'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        if (key != null)          'key':           key,
        'title':                  title,
        if (englishTitle != null) 'english_title': englishTitle,
        if (composer != null)     'composer':      composer,
        if (bookSource != null)   'book_source':   bookSource,
        'first_line':             firstLine,
        'verses': verses.map((v) => v.toJson()).toList(),
        if (history != null) 'history': history!.toJson(),
      };
}