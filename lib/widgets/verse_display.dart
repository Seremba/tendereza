import 'package:flutter/material.dart';
import '../models/hymn.dart';

class VerseDisplay extends StatelessWidget {
  final Verse verse;
  final double fontSize;

  const VerseDisplay({
    super.key, // key forwarded to root widget — required for Scrollable.ensureVisible
    required this.verse,
    required this.fontSize,
  });

  bool get _isChorus =>
      verse.label.toLowerCase().contains('chorus') ||
      verse.label.toLowerCase().contains('refrain');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChorus = _isChorus;

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
          // FIX 1: label also selectable
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
          // FIX 1: lyrics selectable
          SelectableText(
            verse.lines,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.75,
              color: theme.colorScheme.onSurface,
              fontStyle: isChorus ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}