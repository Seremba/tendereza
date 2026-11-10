import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app.dart';
import '../data/hymn_repository.dart';
import '../models/hymn.dart';

// ─────────────────────────────────────────────
// SharedPreferences instance (async)
// ─────────────────────────────────────────────
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main() after await');
});

// ─────────────────────────────────────────────
// THEME (5 themes)
// ─────────────────────────────────────────────
class AppThemeNotifier extends Notifier<TenderezaTheme> {
  static const _key = 'app_theme';

  @override
  TenderezaTheme build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_key);
    return switch (stored) {
      'light'  => TenderezaTheme.light,
      'sepia'  => TenderezaTheme.sepia,
      'black'  => TenderezaTheme.black,
      'gold'   => TenderezaTheme.gold,
      _        => TenderezaTheme.light, // default for fresh installs
    };
  }

  void setTheme(TenderezaTheme theme) {
    state = theme;
    ref.read(sharedPreferencesProvider).setString(_key, theme.name);
  }

  // Legacy toggle for AppBar dark mode button
  void toggle() {
    final next = switch (state) {
      TenderezaTheme.light  => TenderezaTheme.black,
      TenderezaTheme.sepia  => TenderezaTheme.black,
      TenderezaTheme.black  => TenderezaTheme.light,
      TenderezaTheme.gold   => TenderezaTheme.light,
    };
    setTheme(next);
  }
}

final appThemeProvider =
    NotifierProvider<AppThemeNotifier, TenderezaTheme>(AppThemeNotifier.new);

// Keep themeProvider as an alias so existing code doesn't break
final themeProvider = appThemeProvider;

// ─────────────────────────────────────────────
// FONT FAMILY
// ─────────────────────────────────────────────
class FontFamilyNotifier extends Notifier<String> {
  static const _key = 'font_family';

  /// Typefaces bundled with the app. Anything else (e.g. the retired
  /// Lato / Nunito) falls back to the default.
  static const validFamilies = [
    'Poppins',
    'Gentium Plus',
    'Lora',
    'EB Garamond',
  ];
  static const defaultFamily = 'Gentium Plus';

  @override
  String build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_key);
    return validFamilies.contains(stored) ? stored! : defaultFamily;
  }

  void setFamily(String family) {
    state = family;
    ref.read(sharedPreferencesProvider).setString(_key, family);
  }
}

final fontFamilyProvider =
    NotifierProvider<FontFamilyNotifier, String>(FontFamilyNotifier.new);

// ─────────────────────────────────────────────
// LANGUAGE  (en | lg)
// ─────────────────────────────────────────────
class LanguageNotifier extends Notifier<String> {
  static const _key = 'language';

  @override
  String build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString(_key) ?? 'lg';
  }

  void toggle() {
    final next = state == 'en' ? 'lg' : 'en';
    state = next;
    ref.read(sharedPreferencesProvider).setString(_key, next);
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);

// ─────────────────────────────────────────────
// FONT SIZE
// ─────────────────────────────────────────────
class FontSizeNotifier extends Notifier<double> {
  static const _key = 'font_size';
  static const double min = 14;
  static const double max = 48;
  static const double step = 2;

  @override
  double build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getDouble(_key) ?? 18.0;
  }

  void increase() => _set((state + step).clamp(min, max));
  void decrease() => _set((state - step).clamp(min, max));
  void setSize(double v) => _set(v.clamp(min, max));

  void _set(double v) {
    state = v;
    ref.read(sharedPreferencesProvider).setDouble(_key, v);
  }
}

// ─────────────────────────────────────────────
// AUTO-SCROLL SPEED  (0.5× – 3.0×, remembered)
// ─────────────────────────────────────────────
class AutoScrollSpeedNotifier extends Notifier<double> {
  static const _key = 'autoscroll_speed';
  static const double min = 0.5;
  static const double max = 3.0;
  static const double defaultSpeed = 0.6;

  @override
  double build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getDouble(_key) ?? defaultSpeed;
  }

  /// Snaps to 0.1 steps and keeps the value inside the range.
  void setSpeed(double v) {
    final snapped = (v.clamp(min, max) * 10).round() / 10;
    state = snapped;
    ref.read(sharedPreferencesProvider).setDouble(_key, snapped);
  }

  void reset() => setSpeed(defaultSpeed);
}

final autoScrollSpeedProvider =
    NotifierProvider<AutoScrollSpeedNotifier, double>(
        AutoScrollSpeedNotifier.new);

final fontSizeProvider =
    NotifierProvider<FontSizeNotifier, double>(FontSizeNotifier.new);

// ─────────────────────────────────────────────
// BRIGHTNESS  (session-only, not persisted)
// ─────────────────────────────────────────────
class BrightnessNotifier extends Notifier<double> {
  @override
  double build() => -1.0; // -1 = use system default

  void setValue(double value) => state = value.clamp(0.1, 1.0);
  void reset() => state = -1.0;
}

final brightnessProvider =
    NotifierProvider<BrightnessNotifier, double>(BrightnessNotifier.new);

// ─────────────────────────────────────────────
// FAVOURITES
// ─────────────────────────────────────────────
class FavouritesNotifier extends Notifier<Set<String>> {
  static const _key = 'favourites';

  @override
  Set<String> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getStringList(_key) ?? [];
    return raw.toSet();
  }

  void toggle(dynamic hymnNumber) {
    final key = hymnNumber.toString();
    final updated = Set<String>.from(state);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    state = updated;
    ref
        .read(sharedPreferencesProvider)
        .setStringList(_key, updated.toList());
  }

  bool isFavourite(dynamic hymnNumber) =>
      state.contains(hymnNumber.toString());
}

final favouritesProvider =
    NotifierProvider<FavouritesNotifier, Set<String>>(FavouritesNotifier.new);

// ─────────────────────────────────────────────
// HYMN DATA (async, cached)
// ─────────────────────────────────────────────
final englishHymnsProvider = FutureProvider<List<Hymn>>((ref) {
  return HymnRepository.loadEnglish();
});

final lugandaHymnsProvider = FutureProvider<List<Hymn>>((ref) {
  return HymnRepository.loadLuganda();
});

final activeHymnsProvider = FutureProvider<List<Hymn>>((ref) async {
  final lang = ref.watch(languageProvider);
  return lang == 'en'
      ? await ref.watch(englishHymnsProvider.future)
      : await ref.watch(lugandaHymnsProvider.future);
});

// ─────────────────────────────────────────────
// SEARCH QUERY
// ─────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredHymnsProvider = FutureProvider<List<Hymn>>((ref) async {
  final hymns = await ref.watch(activeHymnsProvider.future);
  final query = ref.watch(searchQueryProvider);
  return HymnRepository.search(hymns, query);
});

// ─────────────────────────────────────────────
// RECENTLY VIEWED
// ─────────────────────────────────────────────
class RecentlyViewedNotifier extends Notifier<List<String>> {
  static const _key = 'recently_viewed';
  static const int _max = 10;

  @override
  List<String> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getStringList(_key) ?? [];
  }

  void record(dynamic hymnNumber) {
    final key = hymnNumber.toString();
    final updated = [key, ...state.where((n) => n != key)];
    state = updated.take(_max).toList();
    ref.read(sharedPreferencesProvider).setStringList(_key, state);
  }

  void clear() {
    state = [];
    ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final recentlyViewedProvider =
    NotifierProvider<RecentlyViewedNotifier, List<String>>(
        RecentlyViewedNotifier.new);