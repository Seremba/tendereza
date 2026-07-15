import 'package:flutter/material.dart';
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
import '../widgets/appearance_sheet.dart';

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
      builder: (_) => const AppearanceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(appThemeProvider);

    final themeIcon = switch (appTheme) {
      TenderezaTheme.light => Icons.light_mode_outlined,
      TenderezaTheme.sepia => Icons.auto_awesome_outlined,
      TenderezaTheme.dark => Icons.dark_mode_outlined,
      TenderezaTheme.black => Icons.bedtime_outlined,
      TenderezaTheme.gold => Icons.stars_outlined,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tendereza'),
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
