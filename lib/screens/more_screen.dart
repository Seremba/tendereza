import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../app.dart';
import '../providers/providers.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final titleColor = cs.onSurface;
    final dimColor = cs.onSurface.withValues(alpha: 0.75);
    final surfaceColor = cs.surface;
    final borderColor = cs.outline;
    final accent = cs.primary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Text(
                    'More',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showDonateSheet(context, cs),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volunteer_activism,
                              color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Donate',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  // ── App info header ──
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.music_note,
                              color: Colors.white, size: 44),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tendereza',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('v1.0.0',
                            style: TextStyle(fontSize: 13, color: dimColor)),
                        const SizedBox(height: 6),
                        Text(
                          'Sing, listen and grow in faith.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: dimColor,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // ── Settings ──
                  _SectionLabel(label: 'Settings', dimColor: dimColor),
                  _SettingsCard(
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    children: [
                      _SettingsRow(
                        icon: Icons.brightness_6_outlined,
                        title: 'Theme',
                        subtitle: _themeLabel(ref),
                        titleColor: titleColor,
                        dimColor: dimColor,
                        borderColor: borderColor,
                        onTap: () => _showThemeSheet(context, ref, cs),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Support ──
                  _SectionLabel(label: 'Support', dimColor: dimColor),
                  _SettingsCard(
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    children: [
                      _SettingsRow(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        titleColor: titleColor,
                        dimColor: dimColor,
                        borderColor: borderColor,
                        onTap: () => _showPrivacyPolicy(context, cs),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Community ──
                  _SectionLabel(label: 'Community', dimColor: dimColor),
                  _SettingsCard(
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    children: [
                      _SettingsRow(
                        icon: Icons.share_outlined,
                        title: 'Share the App',
                        titleColor: titleColor,
                        dimColor: dimColor,
                        borderColor: borderColor,
                        onTap: () => Share.share(
                          'Try Tendereza — the SDA Hymnal app in Luganda & English! https://play.google.com/store/apps/details?id=com.sericklabs.tendereza',
                          subject: 'Tendereza — SDA Hymnal',
                        ),
                      ),
                      Divider(height: 1, indent: 50, color: borderColor),
                      _SettingsRow(
                        icon: Icons.star_outline,
                        title: 'Rate the App',
                        titleColor: titleColor,
                        dimColor: dimColor,
                        borderColor: borderColor,
                        onTap: () {
                          // TODO: open Play Store rating when live
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Footer ──
                  Center(
                    child: Column(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: dimColor,
                              height: 1.6,
                            ),
                            children: const [
                              TextSpan(text: 'Tendereza was made with '),
                              TextSpan(text: '❤️'),
                              TextSpan(text: ' by\nPatrick Seremba.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'If you enjoy using this app,\nplease share it with someone.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: dimColor.withValues(alpha: 0.8),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(WidgetRef ref) {
    final mode = ref.watch(appThemeProvider);
    return switch (mode) {
      TenderezaTheme.light => 'Light',
      TenderezaTheme.sepia => 'Sepia',
      TenderezaTheme.dark  => 'Dark',
      TenderezaTheme.black => 'Black',
      TenderezaTheme.gold  => 'Gold',
    };
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ThemeSheet(cs: cs),
    );
  }

  void _showDonateSheet(BuildContext context, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DonateSheet(cs: cs),
    );
  }

  void _showPrivacyPolicy(BuildContext context, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PrivacyPolicySheet(cs: cs),
    );
  }
}

// ── Section label ──
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color dimColor;
  const _SectionLabel({required this.label, required this.dimColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: dimColor,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ── Settings card ──
class _SettingsCard extends StatelessWidget {
  final Color surfaceColor;
  final Color borderColor;
  final List<Widget> children;

  const _SettingsCard({
    required this.surfaceColor,
    required this.borderColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(children: children),
    );
  }
}

// ── Settings row — all colors explicit, no cs.outline ──
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color titleColor;
  final Color dimColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.titleColor,
    required this.dimColor,
    required this.borderColor,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: dimColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(fontSize: 12, color: dimColor)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: dimColor),
          ],
        ),
      ),
    );
  }
}

// ── Theme sheet ──
class _ThemeSheet extends ConsumerWidget {
  final ColorScheme cs;
  const _ThemeSheet({required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appThemeProvider);
    final notifier = ref.read(appThemeProvider.notifier);

    final options = [
      (TenderezaTheme.light, 'Light'),
      (TenderezaTheme.sepia, 'Sepia'),
      (TenderezaTheme.dark,  'Dark'),
      (TenderezaTheme.black, 'Black'),
      (TenderezaTheme.gold,  'Gold'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('Theme',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final isSelected = current == opt.$1;
            return GestureDetector(
              onTap: () {
                notifier.setTheme(opt.$1);
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        opt.$2,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cs.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Donate sheet ──
class _DonateSheet extends StatelessWidget {
  final ColorScheme cs;
  const _DonateSheet({required this.cs});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollController) => ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('❤️', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              Text('Support Tendereza',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
              const SizedBox(height: 10),
              Text(
                'Tendereza is free and built with love. '
                'If it has been a blessing to you, '
                'consider supporting its development.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.75),
                    height: 1.6),
              ),
              const SizedBox(height: 24),
              _DonateOption(
                label: 'MTN Mobile Money',
                icon: Icons.phone_android,
                color: const Color(0xFFFFCC00),
                onTap: () {
                  // TODO: add MTN MoMo number
                },
              ),
              const SizedBox(height: 12),
              _DonateOption(
                label: 'Airtel Money',
                icon: Icons.phone_android,
                color: const Color(0xFFE40000),
                onTap: () {
                  // TODO: add Airtel Money number
                },
              ),
              const SizedBox(height: 12),
              _DonateOption(
                label: 'Flutterwave',
                icon: Icons.credit_card_outlined,
                color: cs.primary,
                onTap: () {
                  // TODO: add Flutterwave donate link
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonateOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DonateOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

// ── Privacy Policy sheet ──
class _PrivacyPolicySheet extends StatelessWidget {
  final ColorScheme cs;
  const _PrivacyPolicySheet({required this.cs});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Privacy Policy',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _PolicySection(
                    title: 'Introduction',
                    body: 'Tendereza is committed to protecting your privacy. This policy explains how we handle your information.',
                    cs: cs,
                  ),
                  _PolicySection(
                    title: 'Data We Collect',
                    body: 'Tendereza does not collect any personal data. Your favourites and settings are stored locally on your device only.',
                    cs: cs,
                  ),
                  _PolicySection(
                    title: 'Device Permissions',
                    body: 'The app only requires storage access to save your preferences. No other permissions are required.',
                    cs: cs,
                  ),
                  _PolicySection(
                    title: 'Internet Usage',
                    body: 'Tendereza works fully offline. We do not transmit any data over the network.',
                    cs: cs,
                  ),
                  _PolicySection(
                    title: 'Contact',
                    body: 'If you have any questions about this policy, contact us at: pserembae.patrick@gmail.com',
                    cs: cs,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  final ColorScheme cs;

  const _PolicySection({
    required this.title,
    required this.body,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.75),
                  height: 1.6)),
        ],
      ),
    );
  }
}