import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app.dart';
import '../providers/providers.dart';

class LanguageToggle extends ConsumerWidget {
  /// True when shown on the app bar. On a light (teal) bar the pill turns
  /// white with teal text, so it doesn't disappear into the header.
  final bool onBar;

  const LanguageToggle({super.key, this.onBar = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final lightBar = onBar && theme.brightness == Brightness.light;
    final pillBg = lightBar ? Colors.white : cs.primary;
    final textOn = lightBar ? AlpsColors.teal : cs.onPrimary;

    return GestureDetector(
      onTap: () => ref.read(languageProvider.notifier).toggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangLabel(label: 'LG', active: lang == 'lg', color: textOn),
            const SizedBox(width: 4),
            Container(
              width: 1,
              height: 14,
              color: textOn.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 4),
            _LangLabel(label: 'EN', active: lang == 'en', color: textOn),
          ],
        ),
      ),
    );
  }
}

class _LangLabel extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;

  const _LangLabel({
    required this.label,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: active ? FontWeight.bold : FontWeight.normal,
        color: active ? color : color.withValues(alpha: 0.6),
      ),
    );
  }
}