import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/motion_widgets.dart';

/// One credited person. [initials] is derived automatically but can be
/// overridden when the automatic pick reads badly.
class _Person {
  const _Person(this.name, this.colors, {this.initials, this.role});
  final String name;
  final List<Color> colors;
  final String? initials;
  final String? role;

  String get tag {
    if (initials != null) return initials!;
    final parts = name
        .replaceAll('Dr.', '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

// Palette drawn from the category colours so the credits feel part of the app.
const _jade = [AppColors.jade, AppColors.jadeDeep];
const _gold = [AppColors.gold, AppColors.goldDeep];
const _sky = [Color(0xFF55B0FF), Color(0xFF2E8BF2)];
const _rose = [Color(0xFFFF8A7A), Color(0xFFE2457A)];
const _indigo = [Color(0xFF8B7BF0), Color(0xFF6C5CE7)];
const _chilli = [Color(0xFFFF9A4D), Color(0xFFF2762E)];
const _teal = [Color(0xFF2ACFCB), Color(0xFF00A3A1)];
const _navy = [Color(0xFF3C76C4), Color(0xFF1F4E8C)];
const _amber = [Color(0xFFFFC94D), Color(0xFFE08A00)];
const _forest = [Color(0xFF34C79E), AppColors.jadeDeep];
const _coral = [Color(0xFFFF8E82), AppColors.coral];

const _supervisor = _Person('Dr. Yin Win Chit', _gold, initials: 'YC');
const _lead = _Person('Thet Zaw Aung', _jade, initials: 'TZ');

const _designers = [
  _Person('Thet Zaw Aung', _jade, initials: 'TZ'),
  _Person('Hein Myo Myat', _sky, initials: 'HM'),
];

const _dataTeam = [
  _Person('Hein Myo Myat', _sky, initials: 'HM'),
  _Person('Zayar Myint', _rose, initials: 'ZM'),
  _Person('Htet Wai Yan Moe', _indigo, initials: 'HW'),
  _Person('Kyaw Wanna', _chilli, initials: 'KW'),
  _Person('Antt Min Aung', _teal, initials: 'AM'),
  _Person('San Min Htwe', _navy, initials: 'SM'),
  _Person('Win Ei Phyu', _amber, initials: 'WE'),
  _Person('Shoon Lae Htoo', _forest, initials: 'SL'),
  _Person('Yoon Myat Thiri', _coral, initials: 'YM'),
];

/// Settings → About → the people behind the app.
class CreditsCard extends StatelessWidget {
  const CreditsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final my = t.isMyanmar;

    return SettingsCard(
      title: t.t('credits'),
      icon: Icons.groups_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(t.t('crSupervisor'), isMy: my, first: true),
          _Featured(person: _supervisor, role: t.t('crSupervisorRole')),

          _SectionLabel(t.t('crLead'), isMy: my),
          _Featured(person: _lead, role: t.t('crLeadRole')),

          _SectionLabel(t.t('crDesign'), isMy: my),
          Row(
            children: [
              for (var i = 0; i < _designers.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _PairCell(person: _designers[i])),
              ],
            ],
          ),

          _SectionLabel(t.t('crData'), isMy: my),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _dataTeam.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 104,
            ),
            itemBuilder: (_, i) => _GridCell(person: _dataTeam[i]),
          ),

          _SectionLabel(t.t('crQa'), isMy: my),
          _WholeTeamBanner(label: t.t('crWholeTeam')),

          const SizedBox(height: 20),
          _Footer(isMy: my),
        ],
      ),
    );
  }
}

/// Credits to the free data providers the app depends on. Also satisfies the
/// OpenStreetMap / Esri attribution requirements.
class ThanksCard extends StatelessWidget {
  const ThanksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final lines = [
      t.t('thxOsm'),
      t.t('thxEsri'),
      t.t('thxMeteo'),
      t.t('thxOsrm'),
      t.t('thxPadauk'),
    ];
    return SettingsCard(
      title: t.t('thanksTo'),
      icon: Icons.star_rounded,
      iconColors: _gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7, right: 11, left: 3),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: AppColors.gold, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(l,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/* =======================================================================
   Pieces
   ======================================================================= */

/// Public twin of the private `_Card` in settings_screen.dart so other
/// settings panels can match it exactly.
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.iconColors,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final List<Color>? iconColors;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: iconColors == null
                      ? AppColors.jadeGradient
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: iconColors!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// A gradient tile holding the person's initials. No image asset, so adding
/// people never grows the APK.
class _Avatar extends StatelessWidget {
  const _Avatar(this.person, {this.size = 46});
  final _Person person;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: person.colors,
        ),
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: [
          BoxShadow(
            color: person.colors.last.withValues(alpha: 0.32),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        person.tag,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
          letterSpacing: 0.5,
          height: 1.0,
        ),
      ),
    );
  }
}

/// "─── PROJECT SUPERVISOR ──────────" rule.
/// Myanmar never gets uppercase or letter-spacing — both mangle the script.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.isMy, this.first = false});
  final String text;
  final bool isMy;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 20, bottom: 11),
      child: Row(
        children: [
          Flexible(
            child: Text(
              isMy ? text : text.toUpperCase(),
              style: TextStyle(
                fontSize: isMy ? 11.5 : 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: isMy ? 0 : 1.4,
                height: isMy ? 1.7 : 1.3,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
                height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
          ),
        ],
      ),
    );
  }
}

/// Supervisor / lead — big avatar, accent bar down the left edge.
class _Featured extends StatelessWidget {
  const _Featured({required this.person, required this.role});
  final _Person person;
  final String role;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: person.colors.first, width: 4),
        ),
      ),
      child: Row(
        children: [
          _Avatar(person, size: 60),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2)),
                const SizedBox(height: 3),
                Text(role,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Side-by-side chip used for the two designers.
class _PairCell extends StatelessWidget {
  const _PairCell({required this.person});
  final _Person person;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Avatar(person, size: 34),
          const SizedBox(width: 9),
          Expanded(
            child: Text(person.name,
                style: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

/// 2-column grid cell for the data team.
class _GridCell extends StatelessWidget {
  const _GridCell({required this.person});
  final _Person person;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PressableScale(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 13, 8, 10),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(person),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                person.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WholeTeamBanner extends StatelessWidget {
  const _WholeTeamBanner({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.jade.withValues(alpha: 0.14)
            : AppColors.jadeSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 17, color: AppColors.jade),
          const SizedBox(width: 9),
          Flexible(
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.6,
                  color: AppColors.jade,
                )),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.isMy});
  final bool isMy;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.55);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
        const SizedBox(height: 18),
        const Center(child: _UniLogo()),
        const SizedBox(height: 12),
        Text(
          isMy ? t.t('crProudly') : t.t('crProudly').toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMy ? 12 : 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: isMy ? 0 : 1.2,
            height: isMy ? 1.75 : 1.3,
            color: muted,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          t.t('crBatch'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            height: isMy ? 1.85 : 1.55,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          t.t('crUniversity'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: isMy ? 1.8 : 1.55,
            color: muted,
          ),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: t.t('crMadeWith')),
            const TextSpan(
                text: '  \u2665  ',
                style: TextStyle(color: AppColors.coral, fontSize: 12)),
            TextSpan(text: t.t('crMadeIn')),
          ]),
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 11.5, height: isMy ? 1.85 : 1.6, color: muted),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'v1.0.0  ·  2026',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// PUKT crest. A single 192 px PNG (~7 KB) with a circular alpha mask, so it
/// sits cleanly on both the light and the dark card surface.
class _UniLogo extends StatelessWidget {
  const _UniLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/pukt_logo.png',
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded,
            size: 30, color: AppColors.jadeDeep),
      ),
    );
  }
}
