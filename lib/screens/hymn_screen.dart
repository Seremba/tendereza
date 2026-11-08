import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import '../app.dart';
import '../models/hymn.dart';
import '../providers/providers.dart';
import '../services/audio_service.dart';
import '../utils/hymn_utils.dart';
import '../widgets/appearance_sheet.dart';
import '../widgets/language_toggle.dart';
import '../widgets/verse_display.dart';

class HymnScreen extends ConsumerStatefulWidget {
  final dynamic hymnNumber;
  const HymnScreen({super.key, required this.hymnNumber});

  @override
  ConsumerState<HymnScreen> createState() => _HymnScreenState();
}

class _HymnScreenState extends ConsumerState<HymnScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isPageControllerReady = false;
  final Map<int, int> _activeVerseByPage = {};
  final Map<int, ScrollController> _scrollControllers = {};
  final Map<int, List<GlobalKey>> _verseKeysByPage = {};

  bool _showFontButtons = true;
  Timer? _fontButtonTimer;
  bool _isProgrammaticScroll = false; // silences _onScroll during chip-tap scrolls

  // ── Auto-scroll engine ──
  // Scrolling runs on a ticker so it stays smooth at any speed. Only the
  // Pause, ✕, end-of-hymn and swipe-to-next paths stop it. Taps and holds
  // don't; a drag by hand pauses it only while the finger is down.
  Ticker? _autoTicker;
  bool _autoRunning = false;   // control bar is showing
  bool _autoPlaying = false;   // actively moving
  bool _userDragging = false;  // finger is on the lyrics
  Duration _lastTick = Duration.zero;
  // Speed lives in autoScrollSpeedProvider so it is remembered.
  double get _autoSpeed => ref.read(autoScrollSpeedProvider);
  static const double _basePixelsPerSecond = 20.0; // at 1.0×, tuned on device

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
    _autoTicker?.dispose();
    _pageController.dispose();
    for (final sc in _scrollControllers.values) {
      sc.dispose();
    }
    super.dispose();
  }

  /// Auto-scroll sings the hymn as a full song: the chorus follows every verse,
  /// including the last one. Display only, the stored hymn is never changed.
  List<Verse> _autoSongFlow(List<Verse> verses) {
    bool isChorus(Verse v) {
      final l = v.label.toLowerCase();
      return l.contains('chorus') || l.contains('refrain');
    }

    final chorus = verses.where(isChorus).firstOrNull;
    if (chorus == null) return verses; // no chorus, nothing to repeat

    final out = <Verse>[];
    for (final v in verses) {
      if (identical(v, chorus)) continue; // placed after each verse instead
      out.add(v);
      if (!isChorus(v)) out.add(chorus);  // chorus after every verse
    }
    return out;
  }

  // ── Auto-scroll engine ──────────────────────────────────────────────────

  ScrollController? get _currentScrollController =>
      _scrollControllers[_currentIndex];

  void _ensureTicker() {
    _autoTicker ??= createTicker(_onAutoTick);
  }

  /// Tapping Auto: starts at the remembered speed straight away.
  void _startAuto() {
    final ctrl = _currentScrollController;
    if (ctrl == null || !ctrl.hasClients) return;
    _ensureTicker();
    setState(() {
      _autoRunning = true;
      _autoPlaying = true;
    });
    _lastTick = Duration.zero;
    if (!_autoTicker!.isActive) _autoTicker!.start();
  }

  /// Pause / resume. Leaves the control bar showing either way.
  void _toggleAutoPlaying() {
    if (!_autoRunning) return;
    setState(() => _autoPlaying = !_autoPlaying);
    _lastTick = Duration.zero;
    if (_autoPlaying && !(_autoTicker?.isActive ?? false)) {
      _autoTicker!.start();
    }
  }

  /// ✕ — stops everything and brings the verse chips back.
  void _stopAuto() {
    _autoTicker?.stop();
    setState(() {
      _autoRunning = false;
      _autoPlaying = false;
    });
  }

  void _onAutoTick(Duration elapsed) {
    final ctrl = _currentScrollController;
    if (ctrl == null || !ctrl.hasClients) {
      _stopAuto();
      return;
    }

    // Pausing while the finger is on the lyrics, or while Pause is set
    if (!_autoPlaying || _userDragging) {
      _lastTick = elapsed; // don't count paused time as a jump
      return;
    }

    final dt = _lastTick == Duration.zero
        ? 0.0
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    final step = _basePixelsPerSecond * _autoSpeed * dt;
    final pos = ctrl.position;
    final next = (pos.pixels + step).clamp(0.0, pos.maxScrollExtent);
    ctrl.jumpTo(next);

    // Reached the end of this hymn: stop cleanly
    if (next >= pos.maxScrollExtent) _stopAuto();
  }

  /// Dragging the lyrics pauses only while the finger is down.
  bool _onLyricsScroll(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _userDragging = true;
    } else if (n is ScrollEndNotification) {
      _userDragging = false;
      _lastTick = Duration.zero; // resume from wherever the drag left off
    }
    return false;
  }

  void _setAutoSpeed(double v) {
    ref.read(autoScrollSpeedProvider.notifier).setSpeed(v);
    setState(() {}); // refresh the displayed number
  }

  /// Speed sheet, opened from the speed number.
  void _showSpeedSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SpeedSheet(
        initial: _autoSpeed,
        onChanged: _setAutoSpeed,
        onStart: () {
          Navigator.pop(context);
          if (!_autoRunning) _startAuto();
        },
      ),
    );
  }

  /// Swiping to another hymn always stops auto-scroll.
  void _stopAutoForNewHymn() {
    if (_autoRunning) _stopAuto();
  }

  ScrollController _scrollControllerFor(int index) {
    if (_scrollControllers.containsKey(index)) return _scrollControllers[index]!;
    final controller = ScrollController();
    // Update active verse chip as user scrolls manually
    controller.addListener(() => _onScroll(index));
    _scrollControllers[index] = controller;
    return controller;
  }

  /// Detects which verse is currently in view as the user scrolls
  /// and updates the active chip accordingly.
  void _onScroll(int pageIndex) {
    // Stay silent while a chip tap is driving a programmatic scroll
    if (_isProgrammaticScroll) return;
    // Guard against setState after dispose
    if (!mounted) return;

    final keys = _verseKeysByPage[pageIndex];
    if (keys == null || keys.isEmpty) return;

    // Threshold: roughly the height of the fixed header above the PageView
    // (status bar + top bar + hymn header + chip bar ≈ 220px)
    const threshold = 220.0;

    int detected = 0;
    for (int i = 0; i < keys.length; i++) {
      final ctx = keys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final topY = box.localToGlobal(Offset.zero).dy;
      // Keep updating detected as long as the verse top
      // has passed the threshold — the last one that qualifies
      // is the verse currently in view
      if (topY <= threshold) detected = i;
    }

    if (_activeVerseByPage[pageIndex] != detected) {
      setState(() => _activeVerseByPage[pageIndex] = detected);
    }
  }

  List<GlobalKey> _verseKeysFor(int index, int verseCount) {
    final existing = _verseKeysByPage[index];
    if (existing != null && existing.length == verseCount) return existing;
    final keys = List.generate(verseCount, (_) => GlobalKey());
    _verseKeysByPage[index] = keys;
    return keys;
  }

  Future<void> _scrollToVerse(int pageIndex, int verseIndex) async {
    if (!mounted) return;
    setState(() => _activeVerseByPage[pageIndex] = verseIndex);

    final scrollCtrl = _scrollControllers[pageIndex];
    if (scrollCtrl == null) return;

    _isProgrammaticScroll = true;

    if (verseIndex == 0) {
      await scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _isProgrammaticScroll = false;
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) { _isProgrammaticScroll = false; return; }

    final targetKeys = _verseKeysByPage[pageIndex];
    if (targetKeys == null || verseIndex >= targetKeys.length) {
      _isProgrammaticScroll = false;
      return;
    }
    final ctx = targetKeys[verseIndex].currentContext;
    if (ctx == null || !ctx.mounted) {
      _isProgrammaticScroll = false;
      return;
    }

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );

    _isProgrammaticScroll = false;
  }

  void _onPageChanged(int index, List<Hymn> hymns) {
    _stopAutoForNewHymn();
    setState(() => _currentIndex = index);
    _activeVerseByPage.remove(index);
    _verseKeysByPage.remove(index);
    ref.read(recentlyViewedProvider.notifier).record(hymns[index].number);
    ref.read(hymnAudioProvider.notifier).stop();
    _maybeRequestReview();
  }

  /// Triggers the in-app review prompt once the user has opened 5 hymns.
  /// Google controls whether the popup actually appears — it will never
  /// show more than once every few weeks and is suppressed for users
  /// who have already reviewed the app.
  Future<void> _maybeRequestReview() async {
    if (!mounted) return;
    final recentCount = ref.read(recentlyViewedProvider).length;
    if (recentCount == 5) {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      }
    }
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
    sb.writeln('Download: https://play.google.com/store/apps/details?id=com.sericklabs.tendereza');
    Share.share(sb.toString(), subject: '${hymn.number}. ${hymn.title}');
  }

  void _showAppearanceSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AppearanceSheet(),
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
    final appTheme = ref.watch(appThemeProvider);
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;

    final themeIcon = switch (appTheme) {
      TenderezaTheme.light => Icons.light_mode_outlined,
      TenderezaTheme.sepia => Icons.auto_awesome_outlined,
      TenderezaTheme.black => Icons.bedtime_outlined,
      TenderezaTheme.gold  => Icons.stars_outlined,
    };
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
          ..sort((a, b) => compareHymnNumbers(a.number, b.number));

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
                            // ── Appearance ──
                            _IconBtn(
                              icon: themeIcon,
                              color: dimColor,
                              onTap: () => _showAppearanceSheet(context),
                            ),
                            const SizedBox(width: 16),
                            // ── Favourite ──
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
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                        child: Column(
                          children: [
                            // Number
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
                            // Luganda / primary title
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
                            // English title — only shown on Luganda side
                            if (lang == 'lg' &&
                                currentHymn.englishTitle != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                currentHymn.englishTitle!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: dimColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            // Meta line: Doh · Source · Composer
                            if (currentHymn.hasMetadata) ...[
                              const SizedBox(height: 6),
                              _MetaLine(
                                hymn: currentHymn,
                                accent: accent,
                                dimColor: dimColor,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── Verse chips OR auto-scroll bar (never both) ──
                      // Same fixed height in both modes so the lyrics never jump.
                      SizedBox(
                        height: 44,
                        child: _autoRunning
                            ? _AutoScrollBar(
                                speed: _autoSpeed,
                                playing: _autoPlaying,
                                accent: accent,
                                dimColor: dimColor,
                                onStop: _stopAuto,
                                onTogglePlay: _toggleAutoPlaying,
                                onSpeedDown: () => _setAutoSpeed(_autoSpeed - 0.1),
                                onSpeedUp: () => _setAutoSpeed(_autoSpeed + 0.1),
                                onSpeedTap: () => _showSpeedSheet(context),
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _VerseNavBar(
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
                                  ),
                                  _AutoButton(
                                    accent: accent,
                                    speed: _autoSpeed,
                                    onTap: _startAuto,
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                      ),

                      // ── PageView ──
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (i) => _onPageChanged(i, sorted),
                          itemCount: sorted.length,
                          itemBuilder: (_, pageIndex) {
                            final hymn = sorted[pageIndex];
                            // Song flow only on the hymn being auto-scrolled
                            final lyrics = (_autoRunning && pageIndex == _currentIndex)
                                ? _autoSongFlow(hymn.verses)
                                : hymn.verses;
                            final verseKeys =
                                _verseKeysFor(pageIndex, lyrics.length);
                            final scrollCtrl =
                                _scrollControllerFor(pageIndex);
                            return NotificationListener<ScrollNotification>(
                              onNotification: _onLyricsScroll,
                              child: SingleChildScrollView(
                              controller: scrollCtrl,
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 20, 40),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(
                                  lyrics.length,
                                  (i) => VerseDisplay(
                                    key: verseKeys[i],
                                    verse: lyrics[i],
                                    fontSize: fontSize,
                                  ),
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
                    color: isActive
                        ? Theme.of(context).colorScheme.onPrimary
                        : badgeFg,
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

// ── Speed sheet: slider 0.5× to 3.0×, reset, start ──
class _SpeedSheet extends ConsumerStatefulWidget {
  final double initial;
  final ValueChanged<double> onChanged;
  final VoidCallback onStart;

  const _SpeedSheet({
    required this.initial,
    required this.onChanged,
    required this.onStart,
  });

  @override
  ConsumerState<_SpeedSheet> createState() => _SpeedSheetState();
}

class _SpeedSheetState extends ConsumerState<_SpeedSheet> {
  late double _value = widget.initial;

  static const double _min = 0.5;
  static const double _max = 3.0;
  static const double _defaultSpeed = 1.0;

  void _set(double v) {
    final snapped = (v.clamp(_min, _max) * 10).round() / 10;
    setState(() => _value = snapped);
    widget.onChanged(snapped);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;
    final dim = cs.onSurface.withValues(alpha: 0.6);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Auto-scroll speed',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  '${_value.toStringAsFixed(1)}×',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accent,
                inactiveTrackColor: accent.withValues(alpha: 0.2),
                thumbColor: accent,
                overlayColor: accent.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: _value,
                min: _min,
                max: _max,
                divisions: 25, // 0.1 steps across 0.5 – 3.0
                onChanged: _set,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Slower 0.5×', style: TextStyle(fontSize: 12, color: dim)),
                Text('3.0× Faster', style: TextStyle(fontSize: 12, color: dim)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _set(_defaultSpeed),
                  child: Text(
                    'Reset to ${_defaultSpeed.toStringAsFixed(1)}×',
                    style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                  ),
                ),
                FilledButton.icon(
                  onPressed: widget.onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start auto-scroll'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Auto-scroll button, shown in the chip row when idle ──
class _AutoButton extends StatelessWidget {
  final Color accent;
  final double speed;
  final VoidCallback onTap;

  const _AutoButton({
    required this.accent,
    required this.speed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 16, color: accent),
            const SizedBox(width: 4),
            Text(
              'Auto ${speed.toStringAsFixed(1)}×',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Control bar, shown in place of the chips while scrolling ──
class _AutoScrollBar extends StatelessWidget {
  final double speed;
  final bool playing;
  final Color accent;
  final Color dimColor;
  final VoidCallback onStop;
  final VoidCallback onTogglePlay;
  final VoidCallback onSpeedDown;
  final VoidCallback onSpeedUp;
  final VoidCallback onSpeedTap;

  const _AutoScrollBar({
    required this.speed,
    required this.playing,
    required this.accent,
    required this.dimColor,
    required this.onStop,
    required this.onTogglePlay,
    required this.onSpeedDown,
    required this.onSpeedUp,
    required this.onSpeedTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // ✕ stop and return to the verse chips
            IconButton(
              tooltip: 'Stop auto-scroll',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close_rounded, size: 20, color: dimColor),
              onPressed: onStop,
            ),
            const Spacer(),
            // − speed +
            IconButton(
              tooltip: 'Slower',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.remove, size: 20, color: accent),
              onPressed: onSpeedDown,
            ),
            GestureDetector(
              onTap: onSpeedTap,
              child: Padding(
                // Clear space either side so the number never touches − or +
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${speed.toStringAsFixed(1)}×',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Faster',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.add, size: 20, color: accent),
              onPressed: onSpeedUp,
            ),
            const Spacer(),
            // Pause / play
            GestureDetector(
              onTap: onTogglePlay,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 20,
                  color: cs.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meta line: Doh is X · CH 73 · Composer ──
class _MetaLine extends StatelessWidget {
  final Hymn hymn;
  final Color accent;
  final Color dimColor;

  const _MetaLine({
    required this.hymn,
    required this.accent,
    required this.dimColor,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <InlineSpan>[];
    final sep = TextSpan(
      text: '  ·  ',
      style: TextStyle(color: dimColor.withValues(alpha: 0.3)),
    );

    if (hymn.key != null) {
      parts.add(TextSpan(
        children: [
          TextSpan(
            text: 'Doh is ',
            style: TextStyle(color: dimColor.withValues(alpha: 0.55)),
          ),
          TextSpan(
            text: hymn.key,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ));
    }

    if (hymn.bookSource != null) {
      if (parts.isNotEmpty) parts.add(sep);
      parts.add(TextSpan(text: hymn.bookSource!));
    }

    if (hymn.composer != null) {
      if (parts.isNotEmpty) parts.add(sep);
      parts.add(TextSpan(text: hymn.composer!));
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 11,
          color: dimColor.withValues(alpha: 0.55),
        ),
        children: parts,
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
                  ? cs.onPrimary
                  : cs.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
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