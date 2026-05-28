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

class Hymn {
  final dynamic number; // int or String (e.g. "12a")
  final String? key;    // musical key e.g. "G", "Ab", "Eb"
  final String title;
  final String firstLine;
  final List<Verse> verses;

  const Hymn({
    required this.number,
    this.key,
    required this.title,
    required this.firstLine,
    required this.verses,
  });

  factory Hymn.fromJson(Map<String, dynamic> json) => Hymn(
        number: json['number'],
        key: json['key'] as String?,
        title: json['title'] as String,
        firstLine: json['first_line'] as String,
        verses: (json['verses'] as List)
            .map((v) => Verse.fromJson(v as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        if (key != null) 'key': key,
        'title': title,
        'first_line': firstLine,
        'verses': verses.map((v) => v.toJson()).toList(),
      };
}