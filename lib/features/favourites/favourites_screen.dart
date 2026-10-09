import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../data/models/place.dart';
import '../../data/models/place_category.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/motion_widgets.dart';
import '../../shared/widgets/place_card.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final favIds = ref.watch(favouritesProvider);
    final all = ref.watch(placesProvider).value ?? const <Place>[];
    final saved = all.where((p) => favIds.contains(p.id)).toList();

    // Group by category
    final grouped = <PlaceCategory, List<Place>>{};
    for (final p in saved) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    return Scaffold(
      body: saved.isEmpty
          ? _Empty(message: t.noFavourites)
          : CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverAppBar.large(
                  title: Text(t.favourites),
                  pinned: true,
                  backgroundColor:
                      Theme.of(context).scaffoldBackgroundColor,
                ),
                for (final entry in grouped.entries) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: Row(
                        children: [
                          Icon(entry.key.icon,
                              size: 17, color: entry.key.color),
                          const SizedBox(width: 8),
                          Text(t.t(entry.key.labelKey),
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: entry.key.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${entry.value.length}',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: entry.key.color)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: entry.value.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => RevealIn(
                        index: i.clamp(0, 5),
                        child: PlaceListCard(
                          place: entry.value[i],
                          onTap: () =>
                              context.push('/place/${entry.value[i].id}'),
                          onViewMap: () =>
                              context.go('/map?focus=${entry.value[i].id}'),
                        ),
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RevealIn(
        scaleFrom: 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
