import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app.dart';
import '../providers/providers.dart';
import '../widgets/hymn_card.dart';
import '../widgets/language_toggle.dart';
import 'browse_screen.dart';
import 'hymn_screen.dart';
import 'more_screen.dart';
import 'numpad_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Reset brightness to system default when app goes to background
      ScreenBrightness().resetScreenBrightness();
      ref.read(brightnessProvider.notifier).reset();
    }
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
      builder: (_) => const _AppearanceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(appThemeProvider);

    final themeIcon = switch (appTheme) {
      TenderezaTheme.light => Icons.light_mode_outlined,
      TenderezaTheme.sepia => Icons.auto_awesome_outlined,
      TenderezaTheme.dark  => Icons.dark_mode_outlined,
      TenderezaTheme.black => Icons.bedtime_outlined,
      TenderezaTheme.gold  => Icons.stars_outlined,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('SDA Hymnal'),
        actions: [
          IconButton(
            tooltip: 'Appearance',
            icon: Icon(themeIcon, color: Colors.white70),
            onPressed: () => _showAppearanceSheet(context),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8, left: 4),
            child: Center(child: LanguageToggle()),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          NumpadScreen(),
          FavouritesScreen(),
          BrowseScreen(),
          MoreScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dialpad_outlined),
            selectedIcon: Icon(Icons.dialpad),
            label: 'Numpad',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favourites',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// ── Appearance Sheet ──
class _AppearanceSheet extends ConsumerStatefulWidget {
  const _AppearanceSheet();

  @override
  ConsumerState<_AppearanceSheet> createState() => _AppearanceSheetState();
}

class _AppearanceSheetState extends ConsumerState<_AppearanceSheet> {
  static const _fonts = ['Lato', 'Poppins', 'Nunito', 'Gentium Plus'];

  static const _themes = [
    (TenderezaTheme.light, 'Light', Color(0xFFFFFFFF), Color(0xFF1A1A1A), Color(0xFF1D9E75)),
    (TenderezaTheme.sepia, 'Sepia', Color(0xFFF5ECD7), Color(0xFF2C1810), Color(0xFF1D9E75)),
    (TenderezaTheme.dark,  'Dark',  Color(0xFF042C53), Color(0xFFB5D4F4), Color(0xFF1D9E75)),
    (TenderezaTheme.black, 'Black', Color(0xFF000000), Color(0xFFF0F0F0), Color(0xFF1D9E75)),
    (TenderezaTheme.gold,  'Gold',  Color(0xFF1C1208), Color(0xFFF5ECD7), Color(0xFFC8922A)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;
    final textColor = cs.onSurface;
    final dimColor = cs.onSurface.withValues(alpha: 0.5);
    final borderColor = cs.outline;
    final surfaceColor = cs.surface;

    final currentTheme = ref.watch(appThemeProvider);
    final fontFamily = ref.watch(fontFamilyProvider);
    final brightness = ref.watch(brightnessProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        color: cs.surface,
        child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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

            // ── Theme ──
            _SectionLabel(label: 'Theme', textColor: textColor),
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
                                  width: 1.5,
                                ),
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

            const SizedBox(height: 24),
            Divider(color: borderColor),
            const SizedBox(height: 20),

            // ── Typeface ──
            _SectionLabel(label: 'Typeface', textColor: textColor),
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
                        fontFamily: font,
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

            // ── Brightness ──
            _SectionLabel(label: 'Brightness', textColor: textColor),
            const SizedBox(height: 4),
            Text(
              'Resets when you leave the app',
              style: TextStyle(fontSize: 11, color: dimColor),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.brightness_low,
                    size: 18, color: dimColor),
                Expanded(
                  child: Slider(
                    value: brightness < 0
                        ? MediaQuery.of(context).platformBrightness ==
                                Brightness.dark
                            ? 0.3
                            : 0.7
                        : brightness,
                    min: 0.1,
                    max: 1.0,
                    activeColor: accent,
                    inactiveColor: accent.withValues(alpha: 0.2),
                    onChanged: (v) {
                      ref.read(brightnessProvider.notifier).setValue(v);
                      ScreenBrightness().setScreenBrightness(v);
                    },
                  ),
                ),
                Icon(Icons.brightness_high,
                    size: 18, color: accent),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color textColor;
  const _SectionLabel({required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: textColor.withValues(alpha: 0.85),
      ),
    );
  }
}

// ── Favourites Screen ──
class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  void _openHymn(BuildContext context, WidgetRef ref, dynamic hymnNumber) {
    ref.read(recentlyViewedProvider.notifier).record(hymnNumber);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HymnScreen(hymnNumber: hymnNumber)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final favourites = ref.watch(favouritesProvider);
    final lang = ref.watch(languageProvider);
    final hymnsAsync = lang == 'en'
        ? ref.watch(englishHymnsProvider)
        : ref.watch(lugandaHymnsProvider);

    return hymnsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: cs.primary),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: cs.outline)),
      ),
      data: (hymns) {
        final favHymns = hymns
            .where((h) => favourites.contains(h.number.toString()))
            .toList()
          ..sort((a, b) {
            if (a.number is int && b.number is int) {
              return (a.number as int).compareTo(b.number as int);
            }
            return a.number.toString().compareTo(b.number.toString());
          });

        if (favHymns.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border, size: 64, color: cs.outline),
                const SizedBox(height: 16),
                Text(
                  lang == 'lg'
                      ? 'Tewali byokwagala.\nKuba ♡ ku luyimba.'
                      : 'No favourites yet.\nTap ♡ on any hymn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                lang == 'lg'
                    ? '${favHymns.length} EMIYIMBA GYOKWAGALA'
                    : '${favHymns.length} FAVOURITE${favHymns.length == 1 ? '' : 'S'}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.7),
                  letterSpacing: 1.4,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: favHymns.length,
                itemBuilder: (_, i) {
                  final hymn = favHymns[i];
                  return HymnCard(
                    hymn: hymn,
                    isFavourite: true,
                    onTap: () => _openHymn(context, ref, hymn.number),
                    onFavouriteTap: () => ref
                        .read(favouritesProvider.notifier)
                        .toggle(hymn.number),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}