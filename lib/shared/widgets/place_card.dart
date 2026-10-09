import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/place.dart';
import '../../l10n/app_localizations.dart';
import 'motion_widgets.dart';
import 'parallax.dart';
import 'place_image.dart';

/// Tall card used in the horizontal "Popular Places" rail.
/// The photo parallaxes horizontally as the rail scrolls.
class PopularPlaceCard extends ConsumerWidget {
  const PopularPlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.width = 190,
  });

  final Place place;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final favs = ref.watch(favouritesProvider);
    final isFav = favs.contains(place.id);

    return PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'place-img-${place.id}',
                child: ParallaxItem(
                  axis: Axis.horizontal,
                  borderRadius: BorderRadius.circular(AppTheme.rLg),
                  background: PlaceImage(place: place),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration:
                              BoxDecoration(gradient: AppColors.heroScrim),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: FavouriteButton(
                          isFavourite: isFav,
                          onTap: () => ref
                              .read(favouritesProvider.notifier)
                              .toggle(place.id),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: _CategoryBadge(place: place),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              place.name(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.place_rounded,
                    size: 13, color: AppColors.jade),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    place.address(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
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

/// Wide horizontal card used in vertical lists (category results, favourites).
/// The photo parallaxes vertically as the list scrolls.
class PlaceListCard extends ConsumerWidget {
  const PlaceListCard({
    super.key,
    required this.place,
    required this.onTap,
    this.onViewMap,
    this.distanceKm,
  });

  final Place place;
  final VoidCallback onTap;
  final VoidCallback? onViewMap;
  final double? distanceKm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final t = context.l10n;
    final isFav = ref.watch(favouritesProvider).contains(place.id);
    final cs = Theme.of(context).colorScheme;

    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppTheme.rLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 
                  Theme.of(context).brightness == Brightness.light
                      ? 0.06
                      : 0.30),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: Hero(
                tag: 'place-img-${place.id}',
                child: ParallaxItem(
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                  background: PlaceImage(place: place),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (place.rating != null) ...[
                        const Icon(Icons.star_rounded,
                            size: 16, color: AppColors.gold),
                        const SizedBox(width: 2),
                        Text(place.rating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded,
                          size: 13, color: AppColors.jade),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          distanceKm == null
                              ? place.address(lang)
                              : '${place.address(lang)}  ·  ${distanceKm!.toStringAsFixed(1)} ${t.t('distanceKm')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MiniButton(
                        icon: Icons.near_me_rounded,
                        label: t.viewInMap,
                        onTap: onViewMap ?? onTap,
                      ),
                      const Spacer(),
                      FavouriteButton(
                        isFavourite: isFav,
                        size: 18,
                        background: cs.onSurface.withValues(alpha: 0.05),
                        onTap: () => ref
                            .read(favouritesProvider.notifier)
                            .toggle(place.id),
                      ),
                    ],
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

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: const BoxDecoration(
          gradient: AppColors.jadeGradient,
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: place.category.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(place.category.icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            context.l10n.t(place.category.labelKey),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
