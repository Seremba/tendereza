import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => ref.read(languageProvider.notifier).toggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangLabel(label: 'LG', active: lang == 'lg'),
            const SizedBox(width: 4),
            Container(
              width: 1,
              height: 14,
              color: cs.onPrimary.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 4),
            _LangLabel(label: 'EN', active: lang == 'en'),
          ],
        ),
      ),
    );
  }
}

class _LangLabel extends StatelessWidget {
  final String label;
  final bool active;
  const _LangLabel({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: active ? FontWeight.bold : FontWeight.normal,
        // Text on the accent pill: white on teal, dark on gold
        color: active ? onPrimary : onPrimary.withValues(alpha: 0.6),
      ),
    );
  }
}