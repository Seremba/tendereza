import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hymn.dart';
import '../providers/providers.dart';
import '../widgets/hymn_card.dart';
import 'hymn_screen.dart';

// ── Browse tab enum ──
enum _BrowseTab { all, hymns, children }

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  _BrowseTab _activeTab = _BrowseTab.all;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openHymn(dynamic hymnNumber) {
    ref.read(recentlyViewedProvider.notifier).record(hymnNumber);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HymnScreen(hymnNumber: hymnNumber)),
    );
  }

  List<Hymn> _applyTabFilter(List<Hymn> hymns) {
    switch (_activeTab) {
      case _BrowseTab.hymns:
        return hymns.where((h) => !h.isChildrenSong).toList();
      case _BrowseTab.children:
        return hymns.where((h) => h.isChildrenSong).toList();
      case _BrowseTab.all:
        return hymns;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final favourites = ref.watch(favouritesProvider);
    final filteredAsync = ref.watch(filteredHymnsProvider);
    final recentNums = ref.watch(recentlyViewedProvider);
    final query = ref.watch(searchQueryProvider);
    final lang = ref.watch(languageProvider);
    final isSearching = query.isNotEmpty;

    final borderColor = cs.outline;
    final dimColor = cs.onSurface.withValues(alpha: 0.7);
    final textColor = cs.onSurface;
    final accent = cs.primary;

    return Column(
      children: [
        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _searchFocusNode.hasFocus
                  ? accent.withValues(alpha: 0.08)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _searchFocusNode.hasFocus ? accent : borderColor,
                width: _searchFocusNode.hasFocus ? 1.5 : 0.8,
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: lang == 'lg'
                    ? 'Noonya oluyimba...'
                    : 'Search hymns…',
                hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.45), fontSize: 13),
                prefixIcon: Icon(
                  Icons.search,
                  color: _searchFocusNode.hasFocus
                      ? accent
                      : cs.onSurface.withValues(alpha: 0.45),
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: dimColor, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),

        // ── Tab bar ──
        _BrowseTabBar(
          active: _activeTab,
          lang: lang,
          accent: accent,
          dimColor: dimColor,
          borderColor: borderColor,
          onSelect: (tab) => setState(() => _activeTab = tab),
        ),

        // ── Hymn list ──
        Expanded(
          child: filteredAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: accent),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e', style: TextStyle(color: dimColor)),
            ),
            data: (allHymns) {
              final hymns = _applyTabFilter(allHymns);

              if (hymns.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 56, color: borderColor),
                      const SizedBox(height: 12),
                      Text(
                        lang == 'lg'
                            ? 'Tewali luyimba lyalabiddwa.'
                            : 'No hymns found.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: dimColor),
                      ),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  // ── Result count ──
                  if (isSearching && hymns.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: accent.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${hymns.length} ${lang == 'lg' ? 'emiyimba' : hymns.length == 1 ? 'hymn found' : 'hymns found'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Recently viewed ──
                  if (!isSearching &&
                      recentNums.isNotEmpty &&
                      _activeTab != _BrowseTab.children)
                    SliverToBoxAdapter(
                      child: _RecentlyViewedSection(
                        recentNums: recentNums,
                        hymns: allHymns,
                        lang: lang,
                        cs: cs,
                        onTap: _openHymn,
                        onClear: () =>
                            ref.read(recentlyViewedProvider.notifier).clear(),
                      ),
                    ),

                  if (!isSearching &&
                      recentNums.isNotEmpty &&
                      _activeTab != _BrowseTab.children)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                        child: Text(
                          _sectionLabel(lang, _activeTab),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: dimColor,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),

                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => HymnCard(
                        hymn: hymns[i],
                        isFavourite:
                            favourites.contains(hymns[i].number.toString()),
                        onTap: () => _openHymn(hymns[i].number),
                        onFavouriteTap: () => ref
                            .read(favouritesProvider.notifier)
                            .toggle(hymns[i].number),
                      ),
                      childCount: hymns.length,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _sectionLabel(String lang, _BrowseTab tab) {
    if (lang == 'lg') {
      return tab == _BrowseTab.children
          ? 'ENNYIMBA Z\'ABAANA'
          : 'EMIYIMBA GYONNA';
    }
    return tab == _BrowseTab.children ? 'CHILDREN\'S SONGS' : 'ALL HYMNS';
  }
}

// ── Tab bar widget ──
class _BrowseTabBar extends StatelessWidget {
  final _BrowseTab active;
  final String lang;
  final Color accent;
  final Color dimColor;
  final Color borderColor;
  final void Function(_BrowseTab) onSelect;

  const _BrowseTabBar({
    required this.active,
    required this.lang,
    required this.accent,
    required this.dimColor,
    required this.borderColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (tab: _BrowseTab.all, label: lang == 'lg' ? 'Byonna' : 'All'),
      (tab: _BrowseTab.hymns, label: lang == 'lg' ? 'Emiyimba (1–250)' : 'Hymns (1–250)'),
      (tab: _BrowseTab.children, label: lang == 'lg' ? 'Ab\'aana' : 'Children\'s'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor.withValues(alpha: 0.4), width: 0.8),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: tabs.map((t) {
            final isActive = active == t.tab;
            return GestureDetector(
              onTap: () => onSelect(t.tab),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                margin: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  t.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? accent
                        : dimColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Recently Viewed strip ──
class _RecentlyViewedSection extends StatelessWidget {
  final List<String> recentNums;
  final List<Hymn> hymns;
  final String lang;
  final ColorScheme cs;
  final void Function(dynamic) onTap;
  final VoidCallback onClear;

  const _RecentlyViewedSection({
    required this.recentNums,
    required this.hymns,
    required this.lang,
    required this.cs,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hymnMap = {for (final h in hymns) h.number.toString(): h};
    final recents =
        recentNums.map((n) => hymnMap[n]).whereType<Hymn>().toList();
    if (recents.isEmpty) return const SizedBox.shrink();

    final dimColor = cs.onSurface.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
          child: Row(
            children: [
              Text(
                lang == 'lg' ? 'BYALABIDDWA' : 'RECENTLY VIEWED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: dimColor,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    lang == 'lg' ? 'Sazamu' : 'Clear',
                    style: TextStyle(fontSize: 11, color: cs.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recents.length,
            itemBuilder: (_, i) => _RecentCard(
              hymn: recents[i],
              cs: cs,
              onTap: () => onTap(recents[i].number),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, indent: 16, endIndent: 16, color: cs.outline),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  final Hymn hymn;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _RecentCard({
    required this.hymn,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 118,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${hymn.number}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              hymn.title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                height: 1.35,
                color: cs.onSurface,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}