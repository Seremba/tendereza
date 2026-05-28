import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/providers.dart';
import 'screens/home_screen.dart';

/// Tendereza theme enum — 5 themes
enum TenderezaTheme { light, sepia, dark, black, gold }

/// Official ALPS color palette + theme-specific colors
class AlpsColors {
  // ── Primary: SDA Navy ──
  static const navy          = Color(0xFF042C53);
  static const navySurface   = Color(0xFF0C447C);
  static const navyLight     = Color(0xFF185FA5);

  // ── Accent: Teal ──
  static const teal          = Color(0xFF1D9E75);
  static const tealDark      = Color(0xFF0F6E56);
  static const tealLight     = Color(0xFF5DCAA5);

  // ── Dark mode text ──
  static const textPrimary   = Color(0xFFB5D4F4);
  static const textDim       = Color(0xFF85B7EB);
  static const textFaint     = Color(0xFF3A5070);

  // ── Light mode ──
  static const lightBg       = Color(0xFFF7F3F0);
  static const lightSurface  = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFF0EBE7);
  static const lightText     = Color(0xFF1A1A1A);
  static const lightTextDim  = Color(0xFF6B6B6B);
  static const lightBorder   = Color(0xFFE8E0DA);
  static const lightTeal     = Color(0xFFD6F0E7);
  static const lightNavBar   = Color(0xFFE8F5F0);

  // ── Sepia ──
  static const sepiaBg       = Color(0xFFF5ECD7);
  static const sepiaSurface  = Color(0xFFEDE0C4);
  static const sepiaText     = Color(0xFF2C1810);
  static const sepiaTextDim  = Color(0xFF6B4E38);
  static const sepiaBorder   = Color(0xFFDDD0B8);
  static const sepiaTeal     = Color(0xFFB8D8CF);

  // ── Black (AMOLED) ──
  static const blackBg       = Color(0xFF000000);
  static const blackSurface  = Color(0xFF121212);
  static const blackSurface2 = Color(0xFF1E1E1E);
  static const blackText     = Color(0xFFF0F0F0);
  static const blackTextDim  = Color(0xFF9E9E9E);
  static const blackBorder   = Color(0xFF2A2A2A);

  // ── Gold ──
  static const goldBg        = Color(0xFF1C1208);
  static const goldSurface   = Color(0xFF2A1E0F);
  static const goldSurface2  = Color(0xFF3A2A14);
  static const goldAccent    = Color(0xFFC8922A);
  static const goldAccentLight = Color(0xFFE8B84B);
  static const goldAccentDark  = Color(0xFF8B6318);
  static const goldText      = Color(0xFFF5ECD7);
  static const goldTextDim   = Color(0xFFD4B896);
  static const goldBorder    = Color(0xFF8B6B48);
  static const goldTeal      = Color(0xFF3A2A14);

  // ── Neutrals ──
  static const grayDarker    = Color(0xFF222222);
  static const grayDark      = Color(0xFF4A4A4A);
  static const gray          = Color(0xFF717171);
  static const grayLight     = Color(0xFFF5F5F5);

  // ── Aliases ──
  static const darkSurface   = navySurface;
  static const darkBg        = navy;
  static const cave          = teal;
  static const caveDarkMode  = tealLight;
  static const velvet        = teal;
}

class SdaHymnalApp extends ConsumerWidget {
  const SdaHymnalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(appThemeProvider);
    final fontFamily = ref.watch(fontFamilyProvider);

    // Map TenderezaTheme to Flutter ThemeMode for system behavior
    final themeMode = switch (appTheme) {
      TenderezaTheme.light => ThemeMode.light,
      TenderezaTheme.sepia => ThemeMode.light,
      TenderezaTheme.dark  => ThemeMode.dark,
      TenderezaTheme.black => ThemeMode.dark,
      TenderezaTheme.gold  => ThemeMode.dark,
    };

    return MaterialApp(
      title: 'SDA Hymnal',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildTheme(appTheme, fontFamily, false),
      darkTheme: _buildTheme(appTheme, fontFamily, true),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme(
      TenderezaTheme appTheme, String fontFamily, bool isDarkMode) {
    // Pick colors based on theme
    final Color bg;
    final Color surface;
    final Color surface2;
    final Color text;
    final Color textDim;
    final Color border;
    final Color accent;
    final Color accentLight;
    final Color accentDark;
    final Brightness brightness;

    switch (appTheme) {
      case TenderezaTheme.light:
        bg         = AlpsColors.lightBg;
        surface    = AlpsColors.lightSurface;
        surface2   = AlpsColors.lightSurface2;
        text       = AlpsColors.lightText;
        textDim    = AlpsColors.lightTextDim;
        border     = AlpsColors.lightBorder;
        accent     = AlpsColors.teal;
        accentLight= AlpsColors.tealLight;
        accentDark = AlpsColors.tealDark;
        brightness = Brightness.light;
      case TenderezaTheme.sepia:
        bg         = AlpsColors.sepiaBg;
        surface    = AlpsColors.sepiaSurface;
        surface2   = AlpsColors.sepiaSurface;
        text       = AlpsColors.sepiaText;
        textDim    = AlpsColors.sepiaTextDim;
        border     = AlpsColors.sepiaBorder;
        accent     = AlpsColors.teal;
        accentLight= AlpsColors.tealLight;
        accentDark = AlpsColors.tealDark;
        brightness = Brightness.light;
      case TenderezaTheme.dark:
        bg         = AlpsColors.navy;
        surface    = AlpsColors.navySurface;
        surface2   = AlpsColors.navyLight;
        text       = AlpsColors.textPrimary;
        textDim    = AlpsColors.textDim;
        border     = const Color(0xFF4A6080);
        accent     = AlpsColors.teal;
        accentLight= AlpsColors.tealLight;
        accentDark = AlpsColors.tealDark;
        brightness = Brightness.dark;
      case TenderezaTheme.black:
        bg         = AlpsColors.blackBg;
        surface    = AlpsColors.blackSurface;
        surface2   = AlpsColors.blackSurface2;
        text       = AlpsColors.blackText;
        textDim    = AlpsColors.blackTextDim;
        border     = const Color(0xFF505050);
        accent     = AlpsColors.teal;
        accentLight= AlpsColors.tealLight;
        accentDark = AlpsColors.tealDark;
        brightness = Brightness.dark;
      case TenderezaTheme.gold:
        bg         = AlpsColors.goldBg;
        surface    = AlpsColors.goldSurface;
        surface2   = AlpsColors.goldSurface2;
        text       = AlpsColors.goldText;
        textDim    = AlpsColors.goldTextDim;
        border     = AlpsColors.goldBorder;
        accent     = AlpsColors.goldAccent;
        accentLight= AlpsColors.goldAccentLight;
        accentDark = AlpsColors.goldAccentDark;
        brightness = Brightness.dark;
    }

    // Resolve font
    final baseTextTheme = _fontTextTheme(fontFamily);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: brightness == Brightness.dark ? bg : Colors.white,
      secondary: accentDark,
      onSecondary: Colors.white,
      tertiary: accentLight,
      onTertiary: bg,
      error: const Color(0xFFE24B4A),
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surface2,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      textTheme: baseTextTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: appTheme == TenderezaTheme.light ||
                appTheme == TenderezaTheme.sepia
            ? AlpsColors.navy
            : surface,
        foregroundColor: Colors.white,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: baseTextTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(30)),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(30)),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(30)),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: TextStyle(color: textDim),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),

      dividerTheme: DividerThemeData(
        color: border,
        thickness: 0.8,
        space: 0,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return baseTextTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? accent : textDim,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? accent : textDim);
        }),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: brightness == Brightness.dark ? bg : Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: brightness == Brightness.dark ? bg : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        selectedColor: accent,
        labelStyle: baseTextTheme.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        shape: const StadiumBorder(),
      ),
    );
  }

  TextTheme _fontTextTheme(String fontFamily) {
    switch (fontFamily) {
      case 'Poppins':
        return GoogleFonts.poppinsTextTheme();
      case 'Lato':
        return GoogleFonts.latoTextTheme();
      case 'Nunito':
        return GoogleFonts.nunitoTextTheme();
      case 'Gentium Plus':
        return GoogleFonts.gentiumPlusTextTheme();
      default:
        return GoogleFonts.latoTextTheme();
    }
  }
}