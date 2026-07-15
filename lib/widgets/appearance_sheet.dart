import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../app.dart';
import '../providers/providers.dart';

/// Shared appearance bottom sheet — used by HomeScreen and HymnScreen.
class AppearanceSheet extends ConsumerStatefulWidget {
  const AppearanceSheet({super.key});

  @override
  ConsumerState<AppearanceSheet> createState() => _AppearanceSheetState();
}

class _AppearanceSheetState extends ConsumerState<AppearanceSheet> {
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
                  width: 40,
                  height: 4,
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
                                width: 32,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: t.$4.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 24,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: t.$4.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 16,
                                height: 16,
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
                                          width: 8,
                                          height: 8,
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
                  Icon(Icons.brightness_low, size: 18, color: dimColor),
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
                  Icon(Icons.brightness_high, size: 18, color: accent),
                ],
              ),
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