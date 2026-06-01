import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hymn.dart';
import '../providers/providers.dart';
import '../widgets/hymn_card.dart';
import 'hymn_screen.dart';

class NumpadScreen extends ConsumerStatefulWidget {
  const NumpadScreen({super.key});

  @override
  ConsumerState<NumpadScreen> createState() => _NumpadScreenState();
}

class _NumpadScreenState extends ConsumerState<NumpadScreen> {
  String _input = '';

  void _openHymn(dynamic number) {
    ref.read(recentlyViewedProvider.notifier).record(number);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HymnScreen(hymnNumber: number)),
    ).then((_) {
      setState(() => _input = '');
    });
  }

  void _press(String digit) {
    if (_input.length >= 3) return;
    HapticFeedback.lightImpact();
    setState(() => _input += digit);
  }

  void _backspace() {
    if (_input.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  int _compareNumbers(dynamic a, dynamic b) {
    if (a is int && b is int) return a.compareTo(b);
    if (a is int) return -1;
    if (b is int) return 1;
    return a.toString().compareTo(b.toString());
  }

  List<Hymn> _filtered(List<Hymn> hymns) {
    if (_input.isEmpty) return [];
    return hymns
        .where((h) => h.number.toString().startsWith(_input))
        .toList()
      ..sort((a, b) => _compareNumbers(a.number, b.number));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final lang = ref.watch(languageProvider);
    final hymnsAsync = lang == 'en'
        ? ref.watch(englishHymnsProvider)
        : ref.watch(lugandaHymnsProvider);
    final favourites = ref.watch(favouritesProvider);

    return Column(
      children: [
        // ── Results list (only visible when typing) ──
        if (_input.isNotEmpty)
          Expanded(
            child: hymnsAsync.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: cs.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (hymns) {
                final results = _filtered(hymns);
                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      lang == 'lg'
                          ? 'Tewali luyimba lwa #$_input'
                          : 'No hymn found for #$_input',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  itemCount: results.length,
                  itemBuilder: (_, i) => HymnCard(
                    hymn: results[i],
                    isFavourite: favourites.contains(results[i].number),
                    onTap: () => _openHymn(results[i].number),
                    onFavouriteTap: () => ref
                        .read(favouritesProvider.notifier)
                        .toggle(results[i].number),
                  ),
                );
              },
            ),
          ),

        // ── Numpad (centered when no input) ──
        Expanded(
          flex: 1,
          child: Center(
            child: Container(
          color: bg,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Number display above keys ──
              SizedBox(
                height: 64,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: _input.isEmpty
                        ? Text(
                            lang == 'lg'
                                ? 'Tandika ennamba...'
                                : 'Type a number...',
                            key: const ValueKey('hint'),
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface.withValues(alpha: 0.25),
                              letterSpacing: 0.5,
                            ),
                          )
                        : Text(
                            _input,
                            key: ValueKey(_input),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 10,
                              color: cs.primary,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final row in [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: row
                        .map((d) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5),
                                child: _NumKey(
                                  label: d,
                                  cs: cs,
                                  onTap: () => _press(d),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: _NumKey(
                        icon: Icons.backspace_outlined,
                        cs: cs,
                        onTap: _backspace,
                        enabled: _input.isNotEmpty,
                        subtle: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child:
                          _NumKey(label: '0', cs: cs, onTap: () => _press('0')),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: _YimbaKey(
                        input: _input,
                        lang: lang,
                        cs: cs,
                        hymnsAsync: lang == 'en'
                            ? ref.watch(englishHymnsProvider)
                            : ref.watch(lugandaHymnsProvider),
                        onOpen: _openHymn,
                        filtered: (hymns) => _filtered(hymns),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Individual numpad key ──
class _NumKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool subtle;
  final bool enabled;
  final ColorScheme cs;

  const _NumKey({
    this.label,
    this.icon,
    required this.onTap,
    required this.cs,
    this.subtle = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = cs.surface;
    final fg = cs.onSurface;

    return Material(
      color: enabled ? bg : bg.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      elevation: enabled ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: 58,
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: subtle
                          ? fg.withValues(alpha: 0.45)
                          : fg,
                    ),
                  )
                : Icon(
                    icon,
                    size: 22,
                    color: enabled
                        ? fg.withValues(alpha: 0.7)
                        : fg.withValues(alpha: 0.25),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── YIMBA / SING key ──
class _YimbaKey extends StatelessWidget {
  final String input;
  final String lang;
  final ColorScheme cs;
  final AsyncValue<List<Hymn>> hymnsAsync;
  final void Function(dynamic) onOpen;
  final List<Hymn> Function(List<Hymn>) filtered;

  const _YimbaKey({
    required this.input,
    required this.lang,
    required this.cs,
    required this.hymnsAsync,
    required this.onOpen,
    required this.filtered,
  });

  @override
  Widget build(BuildContext context) {
    final results = hymnsAsync.whenData(filtered).value ?? [];
    final exactMatch =
        results.where((h) => h.number.toString() == input).firstOrNull;
    final canOpen =
        input.isNotEmpty && (exactMatch != null || results.length == 1);
    final target = exactMatch ?? (results.length == 1 ? results.first : null);

    return Material(
      color: canOpen
          ? cs.primary
          : cs.primary.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap:
            canOpen && target != null ? () => onOpen(target.number) : null,
        child: SizedBox(
          height: 58,
          child: Center(
            child: Text(
              lang == 'lg' ? 'YIMBA' : 'SING',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: canOpen ? 1.0 : 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}