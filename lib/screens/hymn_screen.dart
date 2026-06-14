import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../models/hymn.dart';
import '../providers/providers.dart';
import '../services/audio_service.dart';
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

  bool _showFontButtons = true;
  Timer? _fontButtonTimer;

  void _showFontButtonsTemporarily() {
    setState(() => _showFontButtons = true);
    _fontButtonTimer?.cancel();
    _fontButtonTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showFontButtons = false);
    });
  }

  @override
  void dispose() {
    _fontButtonTimer?.cancel();
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
    setState(() => _activeVerseByPage[pageIndex] = verseIndex);

    final scrollCtrl = _scrollControllers[pageIndex];
    if (scrollCtrl == null) return;

    if (verseIndex == 0) {
      await scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    await WidgetsBinding.instance.endOfFrame;

    final targetKeys = _verseKeysByPage[pageIndex];
    if (targetKeys == null || verseIndex >= targetKeys.length) return;
    final ctx = targetKeys[verseIndex].currentContext;
    if (ctx == null || !ctx.mounted) return;

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  void _onPageChanged(int index, List<Hymn> hymns) {
    setState(() => _currentIndex = index);
    _activeVerseByPage.remove(index);
    _verseKeysByPage.remove(index);
    ref.read(recentlyViewedProvider.notifier).record(hymns[index].number);
    ref.read(hymnAudioProvider.notifier).stop();
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

  void _showNoAudio(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _NoAudioSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final favourites = ref.watch(favouritesProvider);
    final audioState = ref.watch(hymnAudioProvider);
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

        // ── Audio state for current hymn ──
        final hasAudio = HymnAudioNotifier.hasAudio(currentHymn.number);
        final isThisHymn = audioState.currentHymn?.toString() ==
            currentHymn.number.toString();
        final isThisPlaying = isThisHymn && audioState.isPlaying;
        final isThisLoading = isThisHymn && audioState.isLoading;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _showFontButtons) _showFontButtonsTemporarily();
        });

        return Scaffold(
          backgroundColor: bg,
          body: GestureDetector(
            onTap: _showFontButtonsTemporarily,
            behavior: HitTestBehavior.translucent,
            child: Stack(
              children: [
                SafeArea(
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
                              onTap: () {
                                ref.read(hymnAudioProvider.notifier).stop();
                                Navigator.of(context).pop();
                              },
                            ),
                            const Spacer(),
                            _IconBtn(
                              icon: Icons.history_edu_outlined,
                              color: hasHistory ? accent : dimColor,
                              onTap: () {
                                if (hasHistory) {
                                  _showHistory(context, currentHymn);
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                            _IconBtn(
                              icon: isFav
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFav ? accent : dimColor,
                              onTap: () => ref
                                  .read(favouritesProvider.notifier)
                                  .toggle(currentHymn.number),
                            ),
                            const SizedBox(width: 16),
                            _IconBtn(
                              icon: Icons.share_outlined,
                              color: dimColor,
                              onTap: () => _share(currentHymn, lang),
                            ),
                            const SizedBox(width: 16),
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
                                  style: TextStyle(
                                      fontSize: 13, color: dimColor),
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
                        onTap: (i) {
                          final current =
                              _activeVerseByPage[_currentIndex] ?? 0;
                          final verseCount = currentHymn.verses.length;
                          final target =
                              (i == current) ? (current + 1) % verseCount : i;
                          _scrollToVerse(_currentIndex, target);
                        },
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
                            final scrollCtrl =
                                _scrollControllerFor(pageIndex);
                            return SingleChildScrollView(
                              controller: scrollCtrl,
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 20, 40),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(
                                  hymn.verses.length,
                                  (i) => VerseDisplay(
                                    key: verseKeys[i],
                                    verse: hymn.verses[i],
                                    fontSize: fontSize,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Bottom bar ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Row(
                          children: [
                            // ── Play / Pause button ──
                            GestureDetector(
                              onTap: hasAudio
                                  ? () => ref
                                      .read(hymnAudioProvider.notifier)
                                      .toggle(currentHymn.number)
                                  : () => _showNoAudio(context),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: isThisPlaying
                                      ? accent.withValues(alpha: 0.15)
                                      : surfaceColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: hasAudio
                                        ? accent.withValues(alpha: 0.5)
                                        : accent.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: isThisLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: accent,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          isThisPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: hasAudio
                                              ? (isThisHymn
                                                  ? accent
                                                  : dimColor)
                                              : dimColor.withValues(alpha: 0.4),
                                          size: 24,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // ── Prev / Next pill ──
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
                                      onTap: () =>
                                          _pageController.previousPage(
                                        duration: const Duration(
                                            milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        lang == 'lg'
                                            ? 'Oluyimba ${currentHymn.number}'
                                            : currentHymn.isChildrenSong
                                                ? 'Song ${currentHymn.number}'
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
                                        duration: const Duration(
                                            milliseconds: 300),
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

                      // ── Progress bar (visible only while audio is active) ──
                      if (isThisHymn &&
                          (isThisPlaying || audioState.isPaused) &&
                          audioState.total > Duration.zero)
                        _AudioProgressBar(
                          position: audioState.position,
                          total: audioState.total,
                          accent: accent,
                          dimColor: dimColor,
                        ),
                    ],
                  ),
                ),

                // ── Floating A+ / A- ──
                Positioned(
                  right: 12,
                  bottom: 100,
                  child: AnimatedOpacity(
                    opacity: _showFontButtons ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Column(
                      children: [
                        _FontSizeButton(
                          label: 'A+',
                          onTap: () {
                            ref.read(fontSizeProvider.notifier).increase();
                            _showFontButtonsTemporarily();
                          },
                          enabled: ref.watch(fontSizeProvider) <
                              FontSizeNotifier.max,
                          cs: cs,
                        ),
                        const SizedBox(height: 8),
                        _FontSizeButton(
                          label: 'A−',
                          onTap: () {
                            ref.read(fontSizeProvider.notifier).decrease();
                            _showFontButtonsTemporarily();
                          },
                          enabled: ref.watch(fontSizeProvider) >
                              FontSizeNotifier.min,
                          cs: cs,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Audio progress bar ──
class _AudioProgressBar extends StatelessWidget {
  final Duration position;
  final Duration total;
  final Color accent;
  final Color dimColor;

  const _AudioProgressBar({
    required this.position,
    required this.total,
    required this.accent,
    required this.dimColor,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = total.inMilliseconds > 0
        ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text(_fmt(position),
              style: TextStyle(fontSize: 10, color: dimColor)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  color: accent,
                  backgroundColor: accent.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          Text(_fmt(total),
              style: TextStyle(fontSize: 10, color: dimColor)),
        ],
      ),
    );
  }
}

// ── Icon button ──
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap, child: Icon(icon, size: 22, color: color));
}

// ── Prev/Next arrow ──
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color accent;
  final Color dimColor;
  final VoidCallback onTap;
  const _NavArrow(
      {required this.icon,
      required this.enabled,
      required this.accent,
      required this.dimColor,
      required this.onTap});

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

// ── Floating font size button ──
class _FontSizeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final ColorScheme cs;

  const _FontSizeButton(
      {required this.label,
      required this.onTap,
      required this.enabled,
      required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                enabled ? cs.primary : cs.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: enabled
                  ? Colors.white
                  : cs.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ),
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Song History',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor)),
            const SizedBox(height: 4),
            Text('Hymn ${hymn.number} · ${hymn.title}',
                style: TextStyle(
                    fontSize: 12,
                    color: accent,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 16),
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
              Text(h.story!,
                  style: TextStyle(
                      fontSize: 14, color: dimColor, height: 1.75)),
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
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: accent,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── No Audio Sheet ──
class _NoAudioSheet extends StatelessWidget {
  const _NoAudioSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(Icons.headphones_outlined,
                color: cs.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text('No Audio Yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(
            "Instrumental audio for this hymn hasn't been added yet. Check back in a future update!",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.65),
                height: 1.6),
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