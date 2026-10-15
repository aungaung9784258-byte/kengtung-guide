import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/today_providers.dart';
import '../../data/models/village.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/confidence_badge.dart';
import '../../shared/widgets/motion_widgets.dart';
import 'villages_screen.dart' show VillagePhoto;

/// Everything a visitor needs before walking into someone's village:
/// how to get there, what they will see, and how to behave.
class VillageDetailScreen extends ConsumerWidget {
  const VillageDetailScreen({super.key, required this.villageId});
  final String villageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final lang = ref.watch(langProvider);
    final async = ref.watch(villagesProvider);
    final village = ref.watch(villageByIdProvider(villageId));

    if (async.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (village == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(t.t('villageNotFound'))),
      );
    }

    final v = village;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _Hero(village: v, lang: lang),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
            sliver: SliverList.list(
              children: [
                RevealIn(index: 0, child: _PeopleRow(village: v, lang: lang)),
                const SizedBox(height: 16),
                RevealIn(
                  index: 1,
                  child: Text(
                    v.summary(lang),
                    style: TextStyle(
                      fontSize: 14,
                      height: t.isMyanmar ? 1.9 : 1.55,
                      color: cs.onSurface.withValues(alpha: 0.82),
                    ),
                  ),
                ),
                if (v.highlight != null) ...[
                  const SizedBox(height: 14),
                  RevealIn(
                    index: 2,
                    child: _HighlightCard(text: v.highlight!(lang)),
                  ),
                ],
                const SizedBox(height: 20),
                RevealIn(index: 3, child: _QuickFacts(village: v)),
                const SizedBox(height: 20),
                RevealIn(index: 4, child: _BeforeYouGo(village: v)),
                if (v.images.length > 1) ...[
                  const SizedBox(height: 20),
                  RevealIn(index: 5, child: _Gallery(village: v)),
                ],
                if (!v.etiquette.isEmpty) ...[
                  const SizedBox(height: 20),
                  RevealIn(
                    index: 6,
                    child: _Etiquette(village: v, lang: lang),
                  ),
                ],
                const SizedBox(height: 20),
                RevealIn(index: 7, child: _SourceCard(village: v)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.village, required this.lang});
  final Village village;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 280,
      backgroundColor: AppColors.jadeDeep,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding:
            const EdgeInsetsDirectional.only(start: 56, end: 16, bottom: 14),
        title: Text(
          village.name(lang),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: t.isMyanmar ? 1.6 : 1.1,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (village.hasPhoto)
              Hero(
                tag: 'village-${village.id}',
                child: VillagePhoto(path: village.images.first),
              )
            else
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.jadeGradient),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.heroScrim),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeopleRow extends StatelessWidget {
  const _PeopleRow({required this.village, required this.lang});
  final Village village;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final p in village.peoplesFor(lang))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.jadeSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.jadeDeep,
              ),
            ),
          ),
        ConfidenceBadge(confidence: village.confidence),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star_rounded, size: 18, color: AppColors.goldDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: t.isMyanmar ? 1.8 : 1.45,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Drive time, walk time, difficulty, altitude — with '?' where we genuinely
/// do not know, rather than a confident guess.
class _QuickFacts extends StatelessWidget {
  const _QuickFacts({required this.village});
  final Village village;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final v = village;

    String mins(int? m) => m == null ? '?' : '$m ${t.t('minShort')}';

    final items = <List<Object>>[
      [Icons.directions_car_rounded, t.t('byCar'), mins(v.driveMinutes)],
      [
        Icons.directions_walk_rounded,
        t.t('onFoot'),
        v.trekMinutes == 0 ? '—' : mins(v.trekMinutes)
      ],
      [Icons.terrain_rounded, t.t('difficulty'), t.t(v.difficulty.labelKey)],
      [
        Icons.landscape_rounded,
        t.t('altitude'),
        v.altitudeM == null ? '?' : '${v.altitudeM} m'
      ],
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: [
        for (final it in items)
          _FactTile(
            icon: it[0] as IconData,
            label: it[1] as String,
            value: it[2] as String,
          ),
      ],
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unknown = value == '?';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.jade),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: unknown
                        ? AppColors.coral
                        : cs.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The red card. Guide, permit, season — and the honest warning that we have
/// no GPS fix for this village yet.
class _BeforeYouGo extends StatelessWidget {
  const _BeforeYouGo({required this.village});
  final Village village;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final v = village;

    final lines = <String>[
      if (v.guideRequired) t.t('needGuide'),
      switch (v.permitRequired) {
        'yes' => t.t('permitYes'),
        'no' => t.t('permitNo'),
        _ => t.t('permitAsk'),
      },
      if (v.bestSeason != null) '${t.t('bestSeason')}: ${v.bestSeason}',
      if (!v.hasLocation) t.t('noGpsYet'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_rounded,
                  size: 18, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(
                t.t('beforeYouGo'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: t.isMyanmar ? 1.7 : 1.2,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l,
                      style: TextStyle(
                        fontSize: 13,
                        height: t.isMyanmar ? 1.8 : 1.45,
                        color: cs.onSurface.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.village});
  final Village village;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: village.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (c, i) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 150,
            child: VillagePhoto(path: village.images[i]),
          ),
        ),
      ),
    );
  }
}

/// Do and don't, side by side. The single most useful thing we can print.
class _Etiquette extends StatelessWidget {
  const _Etiquette({required this.village, required this.lang});
  final Village village;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final dos = village.etiquette.dos(lang);
    final donts = village.etiquette.donts(lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.t('respectTitle'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: t.isMyanmar ? 1.7 : 1.2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _EtiquetteBox(
          title: t.t('pleaseDo'),
          items: dos,
          color: AppColors.jade,
          icon: Icons.check_rounded,
        ),
        const SizedBox(height: 10),
        _EtiquetteBox(
          title: t.t('pleaseDont'),
          items: donts,
          color: AppColors.danger,
          icon: Icons.close_rounded,
        ),
      ],
    );
  }
}

class _EtiquetteBox extends StatelessWidget {
  const _EtiquetteBox({
    required this.title,
    required this.items,
    required this.color,
    required this.icon,
  });
  final String title;
  final List<String> items;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cs = Theme.of(context).colorScheme;
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: t.isMyanmar ? 1.6 : 1.2,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      i,
                      style: TextStyle(
                        fontSize: 13,
                        height: t.isMyanmar ? 1.8 : 1.45,
                        color: cs.onSurface.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.village});
  final Village village;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined,
                  size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text(
                t.t('whereThisComesFrom'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: t.isMyanmar ? 1.6 : 1.2,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            village.source ?? t.t('sourceUnknown'),
            style: TextStyle(
              fontSize: 12,
              height: t.isMyanmar ? 1.7 : 1.4,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (village.lastChecked != null) ...[
            const SizedBox(height: 4),
            Text(
              '${t.t('lastChecked')}: ${village.lastChecked}',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
