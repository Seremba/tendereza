/// Shared utility for comparing hymn numbers across the app.
/// Handles both integer hymn numbers (1–250) and
/// string children's song numbers ("C1"–"C28").
///
/// Sort order: integers first (ascending), then strings (natural sort).
/// Examples:
///   1 < 2 < 250 < C1 < C2 < C10 < C28
int compareHymnNumbers(dynamic a, dynamic b) {
  if (a is int && b is int) return a.compareTo(b);
  if (a is int) return -1; // regular hymns always sort before children's
  if (b is int) return 1;
  // Both strings — natural sort so C2 < C10 (not C10 < C2 lexicographically)
  final re = RegExp(r'^([A-Za-z]*)(\d+)$');
  final aM = re.firstMatch(a.toString());
  final bM = re.firstMatch(b.toString());
  if (aM != null && bM != null) {
    final prefixCmp = aM.group(1)!.compareTo(bM.group(1)!);
    if (prefixCmp != 0) return prefixCmp;
    return int.parse(aM.group(2)!).compareTo(int.parse(bM.group(2)!));
  }
  return a.toString().compareTo(b.toString());
}