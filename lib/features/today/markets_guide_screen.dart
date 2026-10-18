import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/motion_widgets.dart';

/// The long-read companion to the "Today" tab: every market of the
/// five-day cycle, one after another, with the detail that does not fit
/// on a card — which ethnic groups come, what they bring, which hours
/// are worth getting up for, and how sure we actually are.
///
/// It reads `assets/data/markets.json` directly rather than going through
/// MarketCycle, because that parser keeps only the handful of fields the
/// Today screen needs and would silently drop the rest.
class MarketsGuideScreen extends ConsumerWidget {
  const MarketsGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final my = lang == 'my';
    final data = ref.watch(_marketsGuideProvider);

    return Scaffold(
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              my ? 'ဒေတာ ဖတ်၍ မရပါ။\n$e' : 'Could not read the data.\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (j) => _Body(json: j, my: my),
      ),
    );
  }
}

final _marketsGuideProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/markets.json');
  return jsonDecode(raw) as Map<String, dynamic>;
});

class _Body extends StatelessWidget {
  const _Body({required this.json, required this.my});
  final Map<String, dynamic> json;
  final bool my;

  @override
  Widget build(BuildContext context) {
    final slots = (json['slots'] as List?) ?? const [];
    final permanent = (json['permanent'] as List?) ?? const [];
    final orderConfirmed = json['slotOrderConfirmed'] == true;
    final tips = (json['visitorTips'] as Map?)?[my ? 'my' : 'en'] as List?;

    var index = 0;

    return CustomScrollView(
      slivers: [
        _GuideHeader(my: my),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
          sliver: SliverList.list(
            children: [
              if (!orderConfirmed)
                RevealIn(
                  index: index++,
                  child: _NoticeCard(
                    icon: Icons.schedule_rounded,
                    colour: AppColors.gold,
                    title: my ? 'ဈေးရက် အစီအစဉ် မသေချာသေးပါ' : 'The order of the days is not confirmed',
                    body: my
                        ? 'ဈေးငါးခု၏ အမည်များ မှန်ကန်သော်လည်း မည်သည့်ဈေးသည် မည်သည့်ရက်တွင် ကျရောက်သည်ကို '
                            'မြေပြင်၌ အတည်မပြုရသေးပါ။ ထွက်ခွာမီ ဒေသခံကို မေးပါ။'
                        : 'The five names are right, but which market falls on which day of the cycle has not '
                            'been checked on the ground yet. Ask locally before you set out.',
                  ),
                ),
              const SizedBox(height: 18),
              _Heading(my ? 'ငါးရက်ဈေး အလှည့်ကျ' : 'The five-day cycle'),
              const SizedBox(height: 4),
              Text(
                my
                    ? 'ဈေးတစ်ခုစီ ငါးရက်လျှင် တစ်ကြိမ် ပြန်လည်ကျရောက်သည်။'
                    : 'Each of these comes round once every five days.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              for (final s in slots)
                RevealIn(
                  index: index++,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _MarketCard(m: s as Map<String, dynamic>, my: my),
                  ),
                ),
              const SizedBox(height: 14),
              _Heading(my ? 'အမြဲဖွင့်သော ဈေးများ' : 'Markets outside the cycle'),
              const SizedBox(height: 14),
              for (final p in permanent)
                RevealIn(
                  index: index++,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _MarketCard(
                        m: p as Map<String, dynamic>, my: my, inCycle: false),
                  ),
                ),
              if (tips != null && tips.isNotEmpty) ...[
                const SizedBox(height: 14),
                _Heading(my ? 'ခရီးသွားများအတွက်' : 'For visitors'),
                const SizedBox(height: 12),
                for (final tip in tips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(Icons.lightbulb_outline_rounded,
                              size: 17, color: AppColors.gold),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$tip',
                            style: TextStyle(
                              fontSize: my ? 14.5 : 15,
                              height: my ? 1.9 : 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 10),
              Center(
                child: Text(
                  my
                      ? 'ဤစာမျက်နှာသည် ဒေသခံ အသိပညာနှင့် သတင်းရင်းမြစ်များမှ စုစည်းထားခြင်း ဖြစ်သည်။'
                      : 'Compiled from local knowledge and published sources.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 11.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideHeader extends StatelessWidget {
  const _GuideHeader({required this.my});
  final bool my;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 150,
      backgroundColor: AppColors.jadeDeep,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14),
        title: Text(
          my ? 'ငါးရက်ဈေး လမ်းညွှန်' : 'Five-day markets',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            height: my ? 1.6 : 1.1,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.jadeGradient),
            ),
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 26,
              bottom: -46,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.13),
                ),
              ),
            ),
            Positioned(
              right: 22,
              top: 56,
              child: Icon(
                Icons.storefront_rounded,
                size: 56,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      );
}

/// One market, told in full.
class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.m, required this.my, this.inCycle = true});

  final Map<String, dynamic> m;
  final bool my;
  final bool inCycle;

  String _s(String key) {
    final v = m[key];
    if (v is Map) return (v[my ? 'my' : 'en'] ?? v['en'] ?? '').toString();
    return v?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = _s('name');
    final desc = _s('description');
    final ward = _s('ward');
    final hours = m['openHours'] as String?;
    final peak = m['peakHours'] as String?;
    final lat = (m['lat'] as num?)?.toDouble();
    final lng = (m['lng'] as num?)?.toDouble();
    final coordState = m['coordConfidence'] as String?;
    final groups = (m['ethnicGroups'] as List?)?.cast<dynamic>();
    final goods = (m['goods'] as List?)?.cast<dynamic>();
    final dist = (m['distanceFromTownKm'] as num?)?.toDouble();
    final annual = m['annual'] == true;
    final slot = m['slot'] as int?;
    final confirmed = m['slotConfirmed'] == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (annual ? AppColors.gold : AppColors.jade)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  annual
                      ? Icons.celebration_rounded
                      : inCycle
                          ? Icons.storefront_rounded
                          : Icons.store_mall_directory_rounded,
                  size: 20,
                  color: annual ? AppColors.gold : AppColors.jade,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: my ? 16 : 16.5,
                        fontWeight: FontWeight.w800,
                        height: my ? 1.55 : 1.2,
                      ),
                    ),
                    if (ward.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        ward,
                        style: TextStyle(
                          fontSize: my ? 13 : 13.5,
                          height: my ? 1.7 : 1.3,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (inCycle && slot != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: confirmed
                        ? AppColors.jade.withValues(alpha: 0.13)
                        : cs.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    my ? 'ရက် ${slot + 1}' : 'Day ${slot + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: confirmed
                          ? AppColors.jade
                          : cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hours != null)
                _Fact(icon: Icons.schedule_rounded, text: hours),
              if (peak != null)
                _Fact(
                  icon: Icons.local_fire_department_rounded,
                  text: '${my ? 'အစည်ကားဆုံး' : 'Busiest'} $peak',
                  colour: AppColors.coral,
                ),
              if (dist != null)
                _Fact(
                  icon: Icons.straighten_rounded,
                  text: my
                      ? 'မြို့မှ ${dist.toStringAsFixed(0)} ကီလိုမီတာ'
                      : '${dist.toStringAsFixed(0)} km from town',
                ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 13),
            Text(
              desc,
              style: TextStyle(
                fontSize: my ? 14.5 : 15,
                height: my ? 1.95 : 1.5,
              ),
            ),
          ],
          if (groups != null && groups.isNotEmpty) ...[
            const SizedBox(height: 14),
            _MiniLabel(my ? 'တွေ့ရလေ့ရှိသော တိုင်းရင်းသားများ' : 'Who you will meet'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final g in groups)
                  _Chip(text: '$g', colour: AppColors.jade),
              ],
            ),
          ],
          if (goods != null && goods.isNotEmpty) ...[
            const SizedBox(height: 14),
            _MiniLabel(my ? 'ရောင်းချသည့် ပစ္စည်းများ' : 'What is sold'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final g in goods)
                  _Chip(text: '$g', colour: AppColors.gold),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _CoordLine(lat: lat, lng: lng, state: coordState, my: my),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text, this.colour});
  final IconData icon;
  final String text;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    final c = colour ?? Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.colour});
  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colour.withValues(alpha: 0.28)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colour,
          ),
        ),
      );
}

/// Honest about what we know. A pin that is only a guess says so.
class _CoordLine extends StatelessWidget {
  const _CoordLine({
    required this.lat,
    required this.lng,
    required this.state,
    required this.my,
  });

  final double? lat;
  final double? lng;
  final String? state;
  final bool my;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final has = lat != null && lng != null;
    final exact = state == 'verified';

    final colour = !has
        ? cs.onSurface.withValues(alpha: 0.45)
        : exact
            ? AppColors.jade
            : AppColors.gold;

    final label = !has
        ? (my
            ? 'တည်နေရာ ကိုဩဒိနိတ် မရသေးပါ — မြေပုံပေါ် မပြနိုင်သေးပါ'
            : 'No coordinates yet — this one cannot be shown on the map')
        : exact
            ? '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}'
            : (my
                ? '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)} · ခန့်မှန်းခြေ'
                : '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)} · approximate');

    return Row(
      children: [
        Icon(has ? Icons.place_rounded : Icons.location_off_rounded,
            size: 15, color: colour),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: my ? 1.6 : 1.3,
              fontWeight: FontWeight.w600,
              color: colour,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.colour,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color colour;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colour.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: colour),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(fontSize: 13, height: 1.75),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Button that lives in the Today header and opens this page.
class MarketsGuideButton extends StatelessWidget {
  const MarketsGuideButton({super.key, required this.tooltip});
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PressableScale(
        onTap: () => context.push('/markets-guide'),
        child: Tooltip(
          message: tooltip,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.menu_book_rounded,
                    size: 20, color: Colors.white),
                Positioned(
                  right: 7,
                  top: 7,
                  child: Icon(Icons.lightbulb_rounded,
                      size: 11, color: AppColors.gold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
