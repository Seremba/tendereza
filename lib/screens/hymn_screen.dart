import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../app.dart';
import '../models/hymn.dart';
import '../providers/providers.dart';
import '../widgets/language_toggle.dart';
import '../widgets/verse_display.dart';

class HymnScreen extends ConsumerStatefulWidget {
  final dynamic hymnNumber;
  const HymnScreen({super.key, required this.hymnNumber});

  @override
  ConsumerState<HymnScreen> createState() => _HymnScreenState();
}

class _HymnScreenState extends ConsumerState<HymnScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isPageControllerReady = false;
  final Map<int, int> _activeVerseByPage = {};
  final Map<int, ScrollController> _scrollControllers = {};
  final Map<int, List<GlobalKey>> _verseKeysByPage = {};

  @override
  void dispose() {
    _pageController.dispose();
    for (final sc in _scrollControllers.values) {
      sc.dispose();
    }
    super.dispose();
  }

  int _compareNumbers(dynamic a, dynamic b) {
    if (a is int && b is int) return a.compareTo(b);
    if (a is int) return -1;
    if (b is int) return 1;
    return a.toString().compareTo(b.toString());
  }

  ScrollController _scrollControllerFor(int index) =>
      _scrollControllers.putIfAbsent(index, () => ScrollController());

  List<GlobalKey> _verseKeysFor(int index, int verseCount) {
    final existing = _verseKeysByPage[index];
    if (existing != null && existing.length == verseCount) return existing;
    final keys = List.generate(verseCount, (_) => GlobalKey());
    _verseKeysByPage[index] = keys;
    return keys;
  }

  Future<void> _scrollToVerse(int pageIndex, int verseIndex) async {
    final current = _activeVerseByPage[pageIndex] ?? 0;
    final keys = _verseKeysByPage[pageIndex];
    final verseCount = keys?.length ?? 0;
    final isLast = verseIndex == verseCount - 1;
    final targetIndex = (verseIndex == current && isLast) ? 0 : verseIndex;

    setState(() => _activeVerseByPage[pageIndex] = targetIndex);

    final targetKeys = _verseKeysByPage[pageIndex];
    final scrollCtrl = _scrollControllers[pageIndex];
    if (targetKeys == null || targetIndex >= targetKeys.length) return;
    if (scrollCtrl == null) return;

    // Step 1: jump to top so all items are laid out
    scrollCtrl.jumpTo(0);
    if (targetIndex == 0) return;

    // Step 2: wait one frame for layout
    await WidgetsBinding.instance.endOfFrame;

    final ctx = targetKeys[targetIndex].currentContext;
    if (ctx == null || !ctx.mounted) return;

    final renderObj = ctx.findRenderObject() as RenderBox?;
    if (renderObj == null) return;

    final scrollBox = scrollCtrl.position.context.storageContext
        .findRenderObject() as RenderBox?;
    if (scrollBox == null) return;

    final itemOffset =
        renderObj.localToGlobal(Offset.zero, ancestor: scrollBox).dy;
    final target =
        (itemOffset - 20).clamp(0.0, scrollCtrl.position.maxScrollExtent);

    await scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index, List<Hymn> hymns) {
    setState(() => _currentIndex = index);
    _activeVerseByPage.remove(index);
    _verseKeysByPage.remove(index);
    ref.read(recentlyViewedProvider.notifier).record(hymns[index].number);
  }

  void _share(Hymn hymn, String lang) {
    final sb = StringBuffer();
    sb.writeln('${hymn.number}. ${hymn.title}');
    sb.writeln();
    for (final v in hymn.verses) {
      sb.writeln('— ${v.label} —');
      sb.writeln(v.lines);
      sb.writeln();
    }
    sb.writeln('Shared from Tendereza — SDA Hymnal');
    Share.share(sb.toString(), subject: '${hymn.number}. ${hymn.title}');
  }

  void _showHistory(BuildContext context, Hymn hymn) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HistorySheet(hymn: hymn),
    );
  }

  void _showAudioComingSoon(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AudioComingSoonSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final favourites = ref.watch(favouritesProvider);
    final appTheme = ref.watch(appThemeProvider);
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;
    final hymnsAsync = lang == 'en'
        ? ref.watch(englishHymnsProvider)
        : ref.watch(lugandaHymnsProvider);

    final bg = Theme.of(context).scaffoldBackgroundColor;
    final titleColor = cs.onSurface;
    final dimColor = cs.onSurface.withValues(alpha: 0.5);
    final surfaceColor = cs.surface;
    final badgeBg = cs.onSurface.withValues(alpha: 0.1);
    final badgeFg = cs.onSurface.withValues(alpha: 0.6);

    return hymnsAsync.when(
      loading: () => Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: accent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: bg,
        body: Center(
            child: Text('Error: $e', style: TextStyle(color: dimColor))),
      ),
      data: (hymns) {
        final sorted = [...hymns]
          ..sort((a, b) => _compareNumbers(a.number, b.number));

        final startIndex = sorted.indexWhere(
            (h) => h.number.toString() == widget.hymnNumber.toString());
        final safeStart = startIndex < 0 ? 0 : startIndex;

        if (!_isPageControllerReady) {
          _pageController = PageController(initialPage: safeStart);
          _currentIndex = safeStart;
          _isPageControllerReady = true;
        }

        final currentHymn = sorted[_currentIndex];
        final isFav = favourites.contains(currentHymn.number.toString());
        final activeVerse = _activeVerseByPage[_currentIndex] ?? 0;
        final isFirst = _currentIndex == 0;
        final isLast = _currentIndex == sorted.length - 1;
        final hasHistory = currentHymn.history != null;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      _IconBtn(
                        icon: Icons.arrow_back,
                        color: dimColor,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      _IconBtn(
                        icon: Icons.text_fields,
                        color: dimColor,
                        onTap: () =>
                            _showReadingSettings(context, ref, appTheme),
                      ),
                      const SizedBox(width: 8),
                      // ── Scroll / History icon ──
                      _IconBtn(
                        icon: Icons.history_edu_outlined,
                        color: hasHistory ? accent : dimColor,
                        onTap: () {
                          if (hasHistory) {
                            _showHistory(context, currentHymn);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _IconBtn(
                        icon: isFav
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isFav ? accent : dimColor,
                        onTap: () => ref
                            .read(favouritesProvider.notifier)
                            .toggle(currentHymn.number),
                      ),
                      const SizedBox(width: 8),
                      _IconBtn(
                        icon: Icons.share_outlined,
                        color: dimColor,
                        onTap: () => _share(currentHymn, lang),
                      ),
                      const SizedBox(width: 8),
                      const LanguageToggle(),
                    ],
                  ),
                ),

                // ── Hymn header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      Text(
                        '${currentHymn.number}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentHymn.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          height: 1.3,
                        ),
                      ),
                      if (currentHymn.key != null) ...[
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style:
                                TextStyle(fontSize: 13, color: dimColor),
                            children: [
                              const TextSpan(text: 'Doh is '),
                              TextSpan(
                                text: currentHymn.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Verse chip bar ──
                _VerseNavBar(
                  verses: currentHymn.verses,
                  activeIndex: activeVerse,
                  accent: accent,
                  badgeBg: badgeBg,
                  badgeFg: badgeFg,
                  onTap: (i) => _scrollToVerse(_currentIndex, i),
                ),

                // ── PageView ──
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => _onPageChanged(i, sorted),
                    itemCount: sorted.length,
                    itemBuilder: (_, pageIndex) {
                      final hymn = sorted[pageIndex];
                      final verseKeys =
                          _verseKeysFor(pageIndex, hymn.verses.length);
                      final scrollCtrl = _scrollControllerFor(pageIndex);
                      return ListView.builder(
                        controller: scrollCtrl,
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 40),
                        itemCount: hymn.verses.length,
                        itemBuilder: (_, i) => VerseDisplay(
                          key: verseKeys[i],
                          verse: hymn.verses[i],
                          fontSize: fontSize,
                        ),
                      );
                    },
                  ),
                ),

                // ── Prev / Next bar + Audio play button ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      // Audio play button
                      GestureDetector(
                        onTap: () => _showAudioComingSoon(context),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: dimColor,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Nav pill
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              _NavArrow(
                                icon: Icons.chevron_left,
                                enabled: !isFirst,
                                accent: accent,
                                dimColor: dimColor,
                                onTap: () => _pageController.previousPage(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  lang == 'lg'
                                      ? 'Oluyimba ${currentHymn.number}'
                                      : 'Hymn ${currentHymn.number}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                  ),
                                ),
                              ),
                              _NavArrow(
                                icon: Icons.chevron_right,
                                enabled: !isLast,
                                accent: accent,
                                dimColor: dimColor,
                                onTap: () => _pageController.nextPage(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReadingSettings(
      BuildContext context, WidgetRef ref, TenderezaTheme appTheme) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReadingSettingsSheet(appTheme: appTheme),
    );
  }
}

// ── Icon button ──
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 22, color: color),
    );
  }
}

// ── Prev/Next arrow ──
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color accent;
  final Color dimColor;
  final VoidCallback onTap;

  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.accent,
    required this.dimColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? accent : dimColor.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(icon, size: 26, color: color),
      ),
    );
  }
}

// ── Verse navigation chip bar ──
class _VerseNavBar extends StatelessWidget {
  final List<Verse> verses;
  final int activeIndex;
  final Color accent;
  final Color badgeBg;
  final Color badgeFg;
  final void Function(int) onTap;

  const _VerseNavBar({
    required this.verses,
    required this.activeIndex,
    required this.accent,
    required this.badgeBg,
    required this.badgeFg,
    required this.onTap,
  });

  String _shortLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('chorus') || l.contains('refrain')) return 'C';
    final match = RegExp(r'\d+').firstMatch(label);
    if (match != null) return match.group(0)!;
    return label.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: verses.length,
        itemBuilder: (_, i) {
          final isActive = i == activeIndex;
          final shortLabel = _shortLabel(verses[i].label);
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? accent : badgeBg,
              ),
              child: Center(
                child: Text(
                  shortLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : badgeFg,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── History Sheet ──
class _HistorySheet extends StatelessWidget {
  final Hymn hymn;
  const _HistorySheet({required this.hymn});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final h = hymn.history!;
    final titleColor = cs.onSurface;
    final dimColor = cs.onSurface.withValues(alpha: 0.75);
    final accent = cs.primary;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Song History',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: titleColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Hymn ${hymn.number} · ${hymn.title}',
              style: TextStyle(
                  fontSize: 12,
                  color: accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 16),

            // Meta pills
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (h.year != null)
                  _MetaPill(label: '📅 ${h.year}', accent: accent),
                if (h.author != null)
                  _MetaPill(label: '✍️ ${h.author}', accent: accent),
                if (h.composer != null)
                  _MetaPill(label: '🎵 ${h.composer}', accent: accent),
                if (h.tune != null)
                  _MetaPill(label: '🎼 ${h.tune}', accent: accent),
              ],
            ),

            if (h.story != null) ...[
              const SizedBox(height: 20),
              Text(
                h.story!,
                style: TextStyle(
                  fontSize: 14,
                  color: dimColor,
                  height: 1.75,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color accent;
  const _MetaPill({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12,
            color: accent,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Audio Coming Soon Sheet ──
class _AudioComingSoonSheet extends StatelessWidget {
  const _AudioComingSoonSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(
              Icons.headphones_outlined,
              color: cs.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Audio Coming Soon',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'We are working on bringing hymn audio to Tendereza. Stay tuned!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.65),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ── Reading Settings Sheet ──
class _ReadingSettingsSheet extends ConsumerWidget {
  final TenderezaTheme appTheme;
  const _ReadingSettingsSheet({required this.appTheme});

  static const _fonts = ['Lato', 'Poppins', 'Nunito', 'Gentium Plus'];

  static const _themes = [
    (TenderezaTheme.light, 'Light',  Color(0xFFFFFFFF), Color(0xFF1A1A1A), Color(0xFF1D9E75)),
    (TenderezaTheme.sepia, 'Sepia',  Color(0xFFF5ECD7), Color(0xFF2C1810), Color(0xFF1D9E75)),
    (TenderezaTheme.dark,  'Dark',   Color(0xFF042C53), Color(0xFFB5D4F4), Color(0xFF1D9E75)),
    (TenderezaTheme.black, 'Black',  Color(0xFF000000), Color(0xFFF0F0F0), Color(0xFF1D9E75)),
    (TenderezaTheme.gold,  'Gold',   Color(0xFF1C1208), Color(0xFFF5ECD7), Color(0xFFC8922A)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final fontSizeNotifier = ref.read(fontSizeProvider.notifier);
    final fontFamily = ref.watch(fontFamilyProvider);
    final currentTheme = ref.watch(appThemeProvider);
    final cs = Theme.of(context).colorScheme;
    final textColor = cs.onSurface;
    final dimColor = cs.onSurface.withValues(alpha: 0.5);
    final accent = cs.primary;
    final surfaceColor = cs.surface;
    final borderColor = cs.outline;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Text Size ──
            Text('Text Size',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: fontSizeNotifier.decrease,
                  child: Text('A−',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: fontSize > FontSizeNotifier.min
                              ? accent
                              : dimColor)),
                ),
                Expanded(
                  child: Slider(
                    value: fontSize,
                    min: FontSizeNotifier.min,
                    max: FontSizeNotifier.max,
                    divisions: ((FontSizeNotifier.max - FontSizeNotifier.min) /
                            FontSizeNotifier.step)
                        .toInt(),
                    activeColor: accent,
                    inactiveColor: accent.withValues(alpha: 0.2),
                    onChanged: (v) {
                      final snapped = (v / FontSizeNotifier.step).round() *
                          FontSizeNotifier.step.toDouble();
                      fontSizeNotifier.setSize(snapped);
                    },
                  ),
                ),
                GestureDetector(
                  onTap: fontSizeNotifier.increase,
                  child: Text('A+',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: fontSize < FontSizeNotifier.max
                              ? accent
                              : dimColor)),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Divider(color: borderColor),
            const SizedBox(height: 20),

            // ── Typeface ──
            Text('Typeface',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _fonts.map((font) {
                final isSelected = fontFamily == font;
                return GestureDetector(
                  onTap: () =>
                      ref.read(fontFamilyProvider.notifier).setFamily(font),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withValues(alpha: 0.12)
                          : surfaceColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? accent : borderColor,
                        width: isSelected ? 1.5 : 0.8,
                      ),
                    ),
                    child: Text(
                      font,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isSelected ? accent : textColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            Divider(color: borderColor),
            const SizedBox(height: 20),

            // ── Theme ──
            Text('Theme',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _themes.map((t) {
                final isSelected = currentTheme == t.$1;
                return GestureDetector(
                  onTap: () =>
                      ref.read(appThemeProvider.notifier).setTheme(t.$1),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 68,
                        decoration: BoxDecoration(
                          color: t.$3,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? t.$5 : borderColor,
                            width: isSelected ? 2.5 : 0.8,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: t.$5.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32, height: 3,
                              decoration: BoxDecoration(
                                color: t.$4.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 24, height: 3,
                              decoration: BoxDecoration(
                                color: t.$4.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 16, height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isSelected
                                        ? t.$5
                                        : t.$4.withValues(alpha: 0.4),
                                    width: 1.5),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 8, height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: t.$5,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.$2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isSelected ? accent : dimColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}