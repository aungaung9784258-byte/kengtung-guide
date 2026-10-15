import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/today_providers.dart';
import '../../core/services/market_cycle.dart';
import '../../data/models/village.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/confidence_badge.dart';
import '../../shared/widgets/motion_widgets.dart';

/// "Today in Kengtung" — the one screen no general travel app can give you.
///
/// It answers three questions a visitor asks every single morning:
///   1. Which of the five rotating markets is on today?
///   2. Is there a festival on, or coming up?
///   3. Where could I go instead?
///
/// Everything is computed offline from bundled data. No network, ever.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final lang = ref.watch(langProvider);

    final market = ref.watch(todayMarketProvider);
    final week = ref.watch(upcomingMarketsProvider);
    final todayFests = ref.watch(festivalsTodayProvider);
    final soon = ref.watch(upcomingFestivalsProvider(4));
    final villages = ref.watch(villagesProvider).value ?? const <Village>[];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _TodayHeader(lang: lang),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            sliver: SliverList.list(
              children: [
                if (todayFests.isNotEmpty) ...[
                  for (var i = 0; i < todayFests.length; i++)
                    RevealIn(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FestivalTodayCard(
                            festival: todayFests[i], lang: lang),
                      ),
                    ),
                ],
                RevealIn(
                  index: todayFests.length,
                  child: _MarketTodayCard(market: market, lang: lang),
                ),
                const SizedBox(height: 18),
                RevealIn(
                  index: todayFests.length + 1,
                  child: _SectionTitle(t.t('nextFiveDays')),
                ),
                const SizedBox(height: 10),
                RevealIn(
                  index: todayFests.length + 2,
                  child: _WeekStrip(days: week, lang: lang),
                ),
                const SizedBox(height: 22),
                if (soon.isNotEmpty) ...[
                  RevealIn(
                    index: todayFests.length + 3,
                    child: _SectionTitle(t.t('comingUp')),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < soon.length; i++)
                    RevealIn(
                      index: todayFests.length + 4 + i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FestivalRow(festival: soon[i], lang: lang),
                      ),
                    ),
                  const SizedBox(height: 22),
                ],
                if (villages.isNotEmpty) ...[
                  RevealIn(
                    index: 10,
                    child: Row(
                      children: [
                        Expanded(child: _SectionTitle(t.t('villagesNearby'))),
                        TextButton(
                          onPressed: () => context.push('/villages'),
                          child: Text(t.t('seeAll')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  RevealIn(
                    index: 11,
                    child: SizedBox(
                      height: 132,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: villages.length > 6 ? 6 : villages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (c, i) =>
                            _VillageMiniCard(village: villages[i], lang: lang),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                const RevealIn(index: 12, child: ConfidenceLegend()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Jade gradient header with the date and a slow parallax drift.
class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final now = DateTime.now();
    final weekday = DateFormat.EEEE().format(now);
    final date = DateFormat.yMMMMd().format(now);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 168,
      backgroundColor: AppColors.jadeDeep,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 14),
        title: Text(
          t.t('todayTab'),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            height: t.isMyanmar ? 1.6 : 1.1,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.jadeGradient),
            ),
            Positioned(
              right: -40,
              top: -30,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -50,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.12),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 46),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      weekday,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        letterSpacing: t.isMyanmar ? 0 : 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: t.isMyanmar ? 1.7 : 1.2,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// The big card: which market is on today.
class _MarketTodayCard extends StatelessWidget {
  const _MarketTodayCard({required this.market, required this.lang});
  final MarketSlot? market;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cs = Theme.of(context).colorScheme;

    if (market == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final m = market!;
    final known = m.confidence.isKnown;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cMarket.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: AppColors.cMarket, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.t('marketToday'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: t.isMyanmar ? 1.6 : 1.2,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              ConfidenceBadge(confidence: m.confidence),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            known ? m.name(lang) : t.t('marketUnknownName'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: t.isMyanmar ? 1.7 : 1.15,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            known
                ? (m.description(lang) ?? '')
                : t.t('marketUnknownHint'),
            style: TextStyle(
              fontSize: 13,
              height: t.isMyanmar ? 1.8 : 1.45,
              color: cs.onSurface.withValues(alpha: 0.72),
            ),
          ),
          if (m.openHours != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 15, color: cs.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  m.openHours!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Horizontal strip of the next five days of the rotation.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days, required this.lang});
  final List<MarketDay> days;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cs = Theme.of(context).colorScheme;
    if (days.isEmpty) return const SizedBox(height: 92);

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (c, i) {
          final d = days[i];
          final isToday = i == 0;
          final known = d.market.confidence.isKnown;
          return Container(
            width: 104,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isToday ? AppColors.jadeGradient : null,
              color: isToday ? null : cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isToday
                    ? Colors.transparent
                    : cs.onSurface.withValues(alpha: 0.07),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? t.t('todayShort') : DateFormat.E().format(d.date),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isToday
                        ? Colors.white.withValues(alpha: 0.85)
                        : cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.MMMd().format(d.date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.white : cs.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  known ? d.market.name(lang) : '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: t.isMyanmar ? 1.6 : 1.25,
                    color: isToday
                        ? Colors.white.withValues(alpha: 0.9)
                        : cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Gold card for a festival happening right now.
class _FestivalTodayCard extends StatelessWidget {
  const _FestivalTodayCard({required this.festival, required this.lang});
  final Festival festival;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.t('happeningToday'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: t.isMyanmar ? 1.6 : 1.2,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  festival.name(lang),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: t.isMyanmar ? 1.7 : 1.15,
                    color: Colors.white,
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

/// One row in the "coming up" list, with a day countdown.
class _FestivalRow extends StatelessWidget {
  const _FestivalRow({required this.festival, required this.lang});
  final Festival festival;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final days = festival.daysFrom(DateTime.now()) ?? 0;

    final countdown = days <= 0
        ? t.t('todayShort')
        : days == 1
            ? t.t('tomorrow')
            : '$days ${t.t('daysShort')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.jade.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  countdown,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.jadeDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  festival.name(lang),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: t.isMyanmar ? 1.7 : 1.2,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  festival.hasExactDate
                      ? DateFormat.yMMMd().format(festival.date!)
                      : t.t('dateNotAnnounced'),
                  style: TextStyle(
                    fontSize: 12,
                    height: t.isMyanmar ? 1.6 : 1.2,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          ConfidenceBadge(confidence: festival.confidence, compact: true),
        ],
      ),
    );
  }
}

/// Small village card used in the horizontal teaser row.
class _VillageMiniCard extends StatelessWidget {
  const _VillageMiniCard({required this.village, required this.lang});
  final Village village;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cs = Theme.of(context).colorScheme;

    return PressableScale(
      onTap: () => context.push('/village/${village.id}'),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.jadeSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                village.peoplesFor(lang).isEmpty
                    ? '—'
                    : village.peoplesFor(lang).first,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.jadeDeep,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              village.name(lang),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: t.isMyanmar ? 1.7 : 1.2,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.directions_walk_rounded,
                    size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  village.totalMinutes > 0
                      ? '${village.totalMinutes} ${t.t('minShort')}'
                      : '?',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
