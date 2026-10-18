import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/place.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/category_chips.dart';
import '../../shared/widgets/motion_widgets.dart';
import '../../shared/widgets/place_card.dart';
import '../about/widgets/about_entry_card.dart';
import '../../shared/widgets/update_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();

  /// Scroll offset for the parallax header.
  ///
  /// This is a ValueNotifier, NOT setState: only the header rebuilds while
  /// you scroll. Calling setState here would rebuild the whole list, every
  /// card and every image 60 times a second - that is what made scrolling
  /// feel heavy.
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);

  /// Cached "popular" ordering so we do not re-sort on every rebuild.
  List<Place>? _popularCache;
  List<Place>? _popularSource;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final o = _scroll.offset;
    // Ignore sub-pixel noise; the header cannot show it anyway.
    if ((o - _offset.value).abs() > 0.5) _offset.value = o;
  }

  List<Place> _popularOf(List<Place> all) {
    if (identical(_popularSource, all) && _popularCache != null) {
      return _popularCache!;
    }
    final sorted = [...all]
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    _popularSource = all;
    _popularCache = sorted;
    return sorted;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final lang = ref.watch(langProvider);
    final asyncPlaces = ref.watch(placesProvider);
    final filtered = ref.watch(filteredPlacesProvider);
    final query = ref.watch(searchQueryProvider);
    final searching = ref.watch(isSearchingProvider);

    return Scaffold(
      body: asyncPlaces.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final popular = _popularOf(all);

          return CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Checks for a new release and pops the update card.
              // Renders nothing and takes no space.
              const SliverToBoxAdapter(child: UpdateGate()),

              // ---------- Parallax hero header ----------
              // ---------- Parallax hero header ----------

              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                stretch: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                flexibleSpace: ValueListenableBuilder<double>(
                  valueListenable: _offset,
                  builder: (_, off, __) =>
                      _HeroHeader(offset: off, lang: lang),
                ),
              ),

              // ---------- Search ----------
              SliverToBoxAdapter(
                child: RevealIn(
                  index: 0,
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: _SearchBar(
                      controller: _searchCtrl,
                      hint: t.search,
                      onChanged: (v) => ref
                          .read(searchQueryProvider.notifier)
                          .state = v,
                      onClear: () {
                        _searchCtrl.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ),
              ),

              // ---------- About Kyaing Tong ----------              // ADD ↓
              // Single entry point to /about-kengtung. Hidden while
              // searching, same as Popular and Categories below.
              if (!searching)
                const SliverToBoxAdapter(
                  child: RevealIn(
                    index: 1,
                    child: AboutEntryCard(
                      // Page gutter is 20 everywhere else on Home.
                      margin: EdgeInsets.fromLTRB(20, 16, 20, 0),
                    ),
                  ),
                ),                                                  // ADD ↑

              // ---------- Suggestion header (search mode) ----------
              if (searching)
                SliverToBoxAdapter(
                  child: _ResultHeader(count: filtered.length, query: query),
                ),

              // ---------- Popular rail (browse mode only) ----------
              if (!searching)
                SliverToBoxAdapter(
                  child: RevealIn(
                    index: 2,
                    child: _SectionHeader(title: t.popularPlaces),
                  ),
                ),
              if (!searching)
                SliverToBoxAdapter(
                child: RevealIn(
                  index: 3,
                  child: SizedBox(
                    height: 230,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      itemCount: popular.length.clamp(0, 8),
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => PopularPlaceCard(
                        place: popular[i],
                        onTap: () =>
                            context.push('/place/${popular[i].id}'),
                      ),
                    ),
                  ),
                ),
              ),

              // ---------- Categories ----------
              if (!searching)
                SliverToBoxAdapter(
                  child: RevealIn(
                    index: 4,
                    child: _SectionHeader(title: t.categories),
                  ),
                ),
              if (!searching)
                const SliverToBoxAdapter(
                  child: RevealIn(index: 5, child: CategoryChips()),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 18)),

              // ---------- Nothing found ----------
              if (searching && filtered.isEmpty)
                SliverToBoxAdapter(
                  child: _NoResults(query: query),
                ),

              // ---------- Results list ----------
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => RevealIn(
                    // Re-trigger the stagger whenever the query changes so the
                    // suggestions animate in instead of popping.
                    key: ValueKey('$query-${filtered[i].id}'),
                    index: i.clamp(0, 6),
                    child: PlaceListCard(
                      place: filtered[i],
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        context.push('/place/${filtered[i].id}');
                      },
                      onViewMap: () =>
                          context.go('/map?focus=${filtered[i].id}'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Collapsing header: background image drifts slower than the scroll
/// (classic parallax), text rises and fades as it collapses.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.offset, required this.lang});

  final double offset;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    // Myanmar script stacks diacritics above and below the baseline, so it
    // needs noticeably more line height than Latin or the glyphs collide.
    final isMy = lang == 'my';
    // 0 -> fully expanded, 1 -> fully collapsed
    final progress = (offset / 200).clamp(0.0, 1.0);

    return FlexibleSpaceBar(
      collapseMode: CollapseMode.parallax,
      // blurBackground runs a live gaussian blur over a full-screen image
      // on every frame - it is the single most expensive thing a header can
      // do on a mid-range phone. zoomBackground alone looks almost the same.
      stretchModes: const [StretchMode.zoomBackground],
      titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
      title: Opacity(
        opacity: progress,
        child: Text(
          t.t('cityName'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      background: Stack(
        fit: StackFit.expand,
        children: [
          // Background photo — drifts at 35% of scroll speed (parallax).
          Transform.translate(
            offset: Offset(0, offset * AppMotion.parallaxFactor),
            child: Transform.scale(
              scale: 1 + progress * 0.08,
              child: Image.asset(
                'assets/images/hero_kengtung.jpg',
                fit: BoxFit.cover,
                // Decode at roughly display size instead of full resolution.
                cacheWidth: 1080,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF145C4A),
                        Color(0xFF0FA47F),
                        Color(0xFF7FC9A6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.heroScrim),
            ),
          ),
          // Headline — slides up and fades out as the header collapses
          Positioned(
            left: 20,
            right: 20,
            bottom: 28 + progress * 20,
            child: Opacity(
              opacity: (1 - progress * 1.6).clamp(0.0, 1.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.exploreIn,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: isMy ? 1.7 : 1.2,
                    ),
                  ),
                  SizedBox(height: isMy ? 6 : 2),
                  Text(
                    t.t('cityName'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMy ? 30 : 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: isMy ? 0 : -1,
                      height: isMy ? 1.6 : 1.05,
                    ),
                  ),
                  SizedBox(height: isMy ? 10 : 6),
                  Text(
                    t.tagline,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: isMy ? 1.7 : 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.hint,
    required this.onChanged,
    required this.controller,
    required this.onClear,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (_, value, __) => TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          // Autocorrect fights Burmese input and "helpfully" rewrites place
          // names mid-search.
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search_rounded, size: 21),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 19),
                    onPressed: onClear,
                    tooltip: 'Clear',
                  ),
          ),
        ),
      ),
    );
  }
}

/// "12 results for 'lake'" strip shown above the suggestions.
class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.count, required this.query});
  final int count;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: const BoxDecoration(
              gradient: AppColors.jadeGradient,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count ${context.l10n.t('results')}  ·  "${query.trim()}"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty state with a hint about what else can be typed.
class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
      child: Column(
        children: [
          Icon(Icons.travel_explore_rounded,
              size: 56, color: cs.onSurface.withValues(alpha: 0.22)),
          const SizedBox(height: 16),
          Text(
            context.l10n.t('noResults'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.t('noResultsHint'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.6,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: const BoxDecoration(
              gradient: AppColors.jadeGradient,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          const SizedBox(width: 10),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
