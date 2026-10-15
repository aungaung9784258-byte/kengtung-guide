import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/about_content.dart';
import '../../data/models/place.dart' show L10nText;
import '../../shared/widgets/motion_widgets.dart';
import 'widgets/frosted_photo.dart';

/// ---------------------------------------------------------------------------
/// About Kyaing Tong
///
/// A read-only magazine page. Every word and every photo path comes from
/// assets/data/about_kengtung.json — change the JSON, hot reload, done.
///
/// This file adds its own provider so lib/core/providers/app_providers.dart
/// does not need to be touched.
/// ---------------------------------------------------------------------------

final aboutContentProvider = FutureProvider<AboutContent>((ref) async {
  final raw = await rootBundle.loadString('assets/data/about_kengtung.json');
  return AboutContent.fromJson(json.decode(raw) as Map<String, dynamic>);
});

class AboutKengtungScreen extends ConsumerWidget {
  const AboutKengtungScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(aboutContentProvider);
    final lang = ref.watch(langProvider);

    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: lang == 'my'
              ? 'အကြောင်းအရာ ဖတ်၍ မရပါ။'
              : 'Could not load this page.',
        ),
        data: (content) => _AboutBody(content: content, lang: lang),
      ),
    );
  }
}

class _AboutBody extends StatelessWidget {
  const _AboutBody({required this.content, required this.lang});

  final AboutContent content;
  final String lang;

  bool get _my => lang == 'my';
  String _t(L10nText v) => _my ? v.my : v.en;

  @override
  Widget build(BuildContext context) {
    final cover = content.cover;

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: FrostedCover(
                image: cover.image,
                parallax: cover.parallax,
                kicker: _t(cover.kicker),
                title: _t(cover.title),
                subtitle: _t(cover.subtitle),
                height: MediaQuery.sizeOf(context).height * 0.52,
              ),
            ),
            SliverList.builder(
              itemCount: content.sections.length,
              itemBuilder: (context, i) => RevealIn(
                index: 0,
                child: _Section(
                  section: content.sections[i],
                  lang: lang,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SourcesBlock(sources: content.sources, lang: lang),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),

        // Back arrow — the only control on the page.
        Positioned(
          left: 10,
          top: MediaQuery.paddingOf(context).top + 6,
          child: _GlassBack(onTap: () => context.pop()),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section dispatcher
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.section, required this.lang});

  final AboutSection section;
  final String lang;

  bool get _my => lang == 'my';
  String _t(L10nText v) => _my ? v.my : v.en;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bodyStyle = TextStyle(
      fontSize: _my ? 13.5 : 14,
      height: _my ? 1.95 : 1.68,
      color: cs.onSurface.withValues(alpha: 0.88),
    );

    // Everything is padded by hand instead of wrapping the whole column in a
    // Padding, so the big figures can run edge to edge without needing an
    // OverflowBox (which breaks layout inside a sliver).
    Widget pad(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: child,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        pad(_SectionHeading(number: section.number, title: _t(section.title))),
        const SizedBox(height: 12),

        for (final p in section.body) ...[
          pad(Text(_t(p), style: bodyStyle)),
          const SizedBox(height: 12),
        ],

        if (section.type == 'stats')
          pad(_Stats(section: section, lang: lang)),
        if (section.type == 'timeline')
          pad(_Timeline(entries: section.timeline, lang: lang)),
        if (section.names.isNotEmpty) pad(_NameGrid(names: section.names)),
        if (section.type == 'pills') pad(_Pills(pills: section.pills)),
        if (section.type == 'landmarks')
          pad(_Landmarks(landmarks: section.landmarks, lang: lang)),
        if (section.type == 'rows') pad(_Rows(rows: section.rows, lang: lang)),

        if (section.note != null) ...[
          const SizedBox(height: 10),
          pad(_Note(text: _t(section.note!))),
        ],

        if (section.cta != null) ...[
          const SizedBox(height: 14),
          pad(_Cta(label: _t(section.cta!.label), route: section.cta!.route)),
        ],

        if (section.pair.length == 2) ...[
          const SizedBox(height: 16),
          pad(Row(
            children: [
              for (var i = 0; i < 2; i++) ...[
                if (i == 1) const SizedBox(width: 10),
                Expanded(
                  child: FrostedPhoto(
                    image: section.pair[i].image,
                    height: 210,
                    parallax: section.pair[i].parallax,
                    caption: _t(section.pair[i].caption),
                    bandHeight: 96,
                    borderRadius: BorderRadius.circular(18),
                    captionStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          )),
        ],

        if (section.disclaimer != null) ...[
          const SizedBox(height: 8),
          pad(Text(
            _t(section.disclaimer!),
            style: TextStyle(
              fontSize: 10.5,
              height: 1.6,
              fontStyle: FontStyle.italic,
              color: cs.onSurfaceVariant,
            ),
          )),
        ],

        // Full-bleed figure: no horizontal padding at all.
        if (section.figure != null) ...[
          const SizedBox(height: 22),
          FrostedPhoto(
            image: section.figure!.image,
            height: 330,
            parallax: section.figure!.parallax,
            caption: _t(section.figure!.caption),
            disclaimer: section.figure!.disclaimer == null
                ? null
                : _t(section.figure!.disclaimer!),
            bandHeight: 150,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: AppColors.jade,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.section, required this.lang});

  final AboutSection section;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final my = lang == 'my';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.9,
      children: [
        for (final s in section.stats)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    text: s.value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                    children: [
                      if (s.unit.isNotEmpty)
                        TextSpan(
                          text: s.unit,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  my ? s.label.my : s.label.en,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: my ? 10 : 10.5,
                    height: my ? 1.6 : 1.3,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.entries, required this.lang});

  final List<AboutTimelineEntry> entries;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final my = lang == 'my';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // dot + rail
                Column(
                  children: [
                    const SizedBox(height: 5),
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entries[i].confidence == AboutConfidence.verified
                            ? AppColors.jade
                            : AppColors.gold,
                      ),
                    ),
                    if (i != entries.length - 1)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          color: cs.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[i].year,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          my ? entries[i].text.my : entries[i].text.en,
                          style: TextStyle(
                            fontSize: my ? 12.5 : 13,
                            height: my ? 1.9 : 1.55,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 2),
        Row(
          children: [
            _LegendDot(color: AppColors.jade, label: my ? 'အတည်ပြု' : 'verified'),
            const SizedBox(width: 14),
            _LegendDot(color: AppColors.gold, label: my ? 'ခန့်မှန်း' : 'estimated'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
}

class _NameGrid extends StatelessWidget {
  const _NameGrid({required this.names});
  final List<AboutNameForm> names;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < names.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                border: i == names.length - 1
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      names[i].script,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.7,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      names[i].text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
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

class _Pills extends StatelessWidget {
  const _Pills({required this.pills});
  final List<String> pills;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final p in pills)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.jadeSoft.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark ? 0.12 : 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? cs.onSurface
                    : AppColors.jadeDeep,
              ),
            ),
          ),
      ],
    );
  }
}

class _Landmarks extends StatelessWidget {
  const _Landmarks({required this.landmarks, required this.lang});

  final List<AboutLandmark> landmarks;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final my = lang == 'my';

    return Column(
      children: [
        for (final l in landmarks)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  my ? l.name.my : l.name.en,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  my ? l.text.my : l.text.en,
                  style: TextStyle(
                    fontSize: my ? 12.5 : 13,
                    height: my ? 1.9 : 1.55,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.rows, required this.lang});

  final List<AboutRow> rows;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final my = lang == 'my';

    return Column(
      children: [
        for (final r in rows)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        my ? r.title.my : r.title.en,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.6,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        my ? r.text.my : r.text.en,
                        style: TextStyle(
                          fontSize: my ? 12 : 12.5,
                          height: my ? 1.9 : 1.55,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          height: 1.7,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}

class _Cta extends StatelessWidget {
  const _Cta({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          gradient: AppColors.jadeGradient,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SourcesBlock extends StatelessWidget {
  const _SourcesBlock({required this.sources, required this.lang});

  final AboutSources sources;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final my = lang == 'my';

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              my ? sources.title.my : sources.title.en,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            for (final s in sources.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '· $s',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.65,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Text(
              '✎  ${my ? sources.correction.my : sources.correction.en}',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.6,
                fontWeight: FontWeight.w700,
                color: AppColors.jade,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              my ? sources.correctionBody.my : sources.correctionBody.en,
              style: TextStyle(
                fontSize: 11.5,
                height: my ? 1.9 : 1.6,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassBack extends StatelessWidget {
  const _GlassBack({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressableScale(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 20),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
}
