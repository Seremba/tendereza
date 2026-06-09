import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

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

// ── Donate Sheet ──
class _DonateSheet extends StatelessWidget {
  final ColorScheme cs;
  const _DonateSheet({required this.cs});

  @override
  Widget build(BuildContext context) {
    final textColor = cs.onSurface;
    final dimColor = cs.onSurface.withValues(alpha: 0.6);

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(Icons.volunteer_activism_outlined,
              size: 48, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'Support Tendereza',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us keep this app free and growing.\nYour support means a lot!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: dimColor, height: 1.6),
          ),
          const SizedBox(height: 24),
          // TODO: add MTN MoMo number
          // TODO: add Airtel Money number
          // TODO: add Flutterwave donate link
          Text(
            'Donation options coming soon.',
            style: TextStyle(fontSize: 13, color: dimColor),
          ),
        ],
      ),
    );
  }
}

// ── Privacy Policy Sheet ──
class _PrivacyPolicySheet extends StatelessWidget {
  final ColorScheme cs;
  const _PrivacyPolicySheet({required this.cs});

  @override
  Widget build(BuildContext context) {
    final textColor = cs.onSurface;
    final dimColor = cs.onSurface.withValues(alpha: 0.6);

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tendereza does not collect, store, or share any personal data. '
            'All hymn data is stored locally on your device. '
            'No account or internet connection is required to use the app.',
            style: TextStyle(fontSize: 14, color: dimColor, height: 1.7),
          ),
          const SizedBox(height: 12),
          Text(
            'For questions, contact us at sericklabs@gmail.com',
            style: TextStyle(fontSize: 13, color: cs.primary),
          ),
        ],
      ),
    );
  }
}