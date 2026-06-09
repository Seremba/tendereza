import 'package:flutter/material.dart';
import '../models/hymn.dart';

class HymnCard extends StatelessWidget {
  final Hymn hymn;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onFavouriteTap;

  const HymnCard({
    super.key,
    required this.hymn,
    required this.isFavourite,
    required this.onTap,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isChildren = hymn.isChildrenSong;

    final cardBg     = cs.surface;
    final borderColor = cs.outline.withValues(alpha: 0.4);
    final titleColor  = cs.onSurface;
    final dimColor    = cs.onSurface.withValues(alpha: 0.75);

    // Teal badge for regular hymns, amber for children's songs
    final badgeBg = isChildren
        ? Colors.amber.withValues(alpha: 0.18)
        : cs.primary.withValues(alpha: 0.2);
    final badgeFg = isChildren
        ? Colors.amber.shade700
        : cs.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Circular number badge ──
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${hymn.number}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: badgeFg,
                  fontSize: hymn.number.toString().length > 2 ? 11 : 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // ── Title + first line ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hymn.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hymn.firstLine,
                    style: TextStyle(color: dimColor, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // ── Favourite icon ──
            GestureDetector(
              onTap: onFavouriteTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  isFavourite ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: isFavourite ? cs.primary : cs.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}