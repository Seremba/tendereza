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
  bool _isChildrenMode = false;

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
    // Children's songs go up to C28 — 2 digits max; hymns up to 250 — 3 digits max
    final maxLen = _isChildrenMode ? 2 : 3;
    if (_input.length >= maxLen) return;
    HapticFeedback.lightImpact();
    setState(() => _input += digit);
  }

  void _backspace() {
    if (_input.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _setMode(bool children) {
    HapticFeedback.lightImpact();
    setState(() {
      _isChildrenMode = children;
      _input = '';
    });
  }

  int _compareNumbers(dynamic a, dynamic b) {
    if (a is int && b is int) return a.compareTo(b);
    if (a is int) return -1;
    if (b is int) return 1;
    final re = RegExp(r'^([A-Za-z]*)(\d+)$');
    final aM = re.firstMatch(a.toString());
    final bM = re.firstMatch(b.toString());
    if (aM != null && bM != null) {
      final pc = aM.group(1)!.compareTo(bM.group(1)!);
      if (pc != 0) return pc;
      return int.parse(aM.group(2)!).compareTo(int.parse(bM.group(2)!));
    }
    return a.toString().compareTo(b.toString());
  }

  List<Hymn> _filtered(List<Hymn> hymns) {
    if (_input.isEmpty) return [];
    // In children's mode prefix with 'C' so "19" matches "C19"
    final query = _isChildrenMode ? 'C$_input' : _input;
    return hymns
        .where((h) => h.number.toString().startsWith(query))
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
    final recentNums = ref.watch(recentlyViewedProvider);

    // Amber for children's mode, teal for hymns mode
    final modeAccent =
        _isChildrenMode ? Colors.amber.shade700 : cs.primary;

    return Column(
      children: [
        // ── Results list (only visible when typing) ──
        if (_input.isNotEmpty)
          Expanded(
            child: hymnsAsync.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: modeAccent)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (hymns) {
                final results = _filtered(hymns);
                final display =
                    _isChildrenMode ? 'C$_input' : '#$_input';
                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      lang == 'lg'
                          ? 'Tewali luyimba lwa $display'
                          : 'No hymn found for $display',
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
                    isFavourite:
                        favourites.contains(results[i].number.toString()),
                    onTap: () => _openHymn(results[i].number),
                    onFavouriteTap: () => ref
                        .read(favouritesProvider.notifier)
                        .toggle(results[i].number),
                  ),
                );
              },
            ),
          ),

        // ── Suggestions (recently viewed or defaults) ──
        if (_input.isEmpty)
          Expanded(
            child: hymnsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (hymns) {
                final hymnMap = {
                  for (final h in hymns) h.number.toString(): h
                };

                // Filter recents by current mode
                final filteredRecents = _isChildrenMode
                    ? recentNums
                        .where((n) => n.startsWith('C'))
                        .toList()
                    : recentNums
                        .where((n) => !n.startsWith('C'))
                        .toList();

                // Default suggestions per mode
                final defaultNums = _isChildrenMode
                    ? ['C1', 'C2', 'C3', 'C4', 'C5']
                    : ['1', '51', '130', '224', '239'];

                final suggestedNums = filteredRecents.isNotEmpty
                    ? filteredRecents.take(5).toList()
                    : defaultNums;

                final suggested = suggestedNums
                    .map((n) => hymnMap[n.toString()])
                    .whereType<Hymn>()
                    .toList();

                if (suggested.isEmpty) return const SizedBox.shrink();

                final label = filteredRecents.isNotEmpty
                    ? (lang == 'lg'
                        ? 'BYALABIDDWA OLUVANNYUMA'
                        : 'RECENTLY VIEWED')
                    : _isChildrenMode
                        ? (lang == 'lg'
                            ? "ENNYIMBA Z'ABAANA"
                            : "CHILDREN'S SONGS")
                        : (lang == 'lg'
                            ? 'ENYIMBA EMANYIFU'
                            : 'POPULAR HYMNS');

                return ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    ...suggested.map(
                      (h) => HymnCard(
                        hymn: h,
                        isFavourite:
                            favourites.contains(h.number.toString()),
                        onTap: () => _openHymn(h.number),
                        onFavouriteTap: () => ref
                            .read(favouritesProvider.notifier)
                            .toggle(h.number),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // ── Numpad pinned at bottom ──
        Container(
          color: bg,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Mode toggle pill ──
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    _ModeTab(
                      label: lang == 'lg'
                          ? 'Enyimba 1–250'
                          : 'Hymns 1–250',
                      active: !_isChildrenMode,
                      activeColor: cs.primary,
                      onTap: () => _setMode(false),
                    ),
                    _ModeTab(
                      label: lang == 'lg' ? "Ab'aana" : "Children's",
                      active: _isChildrenMode,
                      activeColor: Colors.amber.shade700,
                      onTap: () => _setMode(true),
                    ),
                  ],
                ),
              ),

              // ── Number display ──
              SizedBox(
                height: 64,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: _input.isEmpty
                        ? Text(
                            lang == 'lg'
                                ? 'Ennamba yo luyimba...'
                                : 'Type a number...',
                            key: const ValueKey('hint'),
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  cs.onSurface.withValues(alpha: 0.25),
                              letterSpacing: 0.5,
                            ),
                          )
                        : Text(
                            // Show "C19" in children's mode, "19" in hymns mode
                            _isChildrenMode ? 'C$_input' : _input,
                            key: ValueKey(_input),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 10,
                              color: modeAccent,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Number keys ──
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

              // ── Bottom row: backspace, 0, SING ──
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5),
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5),
                      child: _NumKey(
                          label: '0', cs: cs, onTap: () => _press('0')),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5),
                      child: _YimbaKey(
                        input: _input,
                        lang: lang,
                        cs: cs,
                        isChildrenMode: _isChildrenMode,
                        modeAccent: modeAccent,
                        hymnsAsync: hymnsAsync,
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
      ],
    );
  }
}

// ── Mode toggle tab ──
class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? Colors.white
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
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
  final bool isChildrenMode;
  final Color modeAccent;
  final AsyncValue<List<Hymn>> hymnsAsync;
  final void Function(dynamic) onOpen;
  final List<Hymn> Function(List<Hymn>) filtered;

  const _YimbaKey({
    required this.input,
    required this.lang,
    required this.cs,
    required this.isChildrenMode,
    required this.modeAccent,
    required this.hymnsAsync,
    required this.onOpen,
    required this.filtered,
  });

  @override
  Widget build(BuildContext context) {
    final results = hymnsAsync.whenData(filtered).value ?? [];
    // In children's mode, exact match is e.g. "C1" when user typed "1"
    final queryNum =
        isChildrenMode ? 'C$input' : input;
    final exactMatch =
        results.where((h) => h.number.toString() == queryNum).firstOrNull;
    final canOpen =
        input.isNotEmpty && (exactMatch != null || results.length == 1);
    final target =
        exactMatch ?? (results.length == 1 ? results.first : null);

    return Material(
      color: canOpen
          ? modeAccent
          : modeAccent.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: canOpen && target != null
            ? () => onOpen(target.number)
            : null,
        child: SizedBox(
          height: 58,
          child: Center(
            child: Text(
              lang == 'lg' ? 'YIMBA' : 'SING',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color:
                    Colors.white.withValues(alpha: canOpen ? 1.0 : 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}