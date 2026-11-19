import 'package:flutter/material.dart';
import '../models/hymn.dart';

class VerseDisplay extends StatelessWidget {
  final Verse verse;
  final double fontSize;
  /// Optional text colour. Null uses the theme's text colour.
  final Color? lyricColor;

  const VerseDisplay({
    super.key,
    required this.verse,
    required this.fontSize,
    this.lyricColor,
  });

  bool get _isChorus =>
      verse.label.toLowerCase().contains('chorus') ||
      verse.label.toLowerCase().contains('refrain');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChorus = _isChorus;
    final textColor = lyricColor ?? theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: isChorus
          ? BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.07),
              border: Border(
                left: BorderSide(color: theme.colorScheme.primary, width: 3),
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            )
          : null,
      padding: isChorus
          ? const EdgeInsets.fromLTRB(14, 10, 14, 10)
          : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            verse.label,
            style: TextStyle(
              fontSize: fontSize - 3,
              fontWeight: FontWeight.w700,
              color: isChorus
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            verse.lines,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.75,
              fontWeight: FontWeight.w500,
              color: textColor,
              fontStyle: isChorus ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}