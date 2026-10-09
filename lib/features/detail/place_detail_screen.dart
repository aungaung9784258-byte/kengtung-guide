import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/place.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/motion_widgets.dart';
import '../../shared/widgets/photo_gallery.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  const PlaceDetailScreen({super.key, required this.placeId});
  final String placeId;

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  final _scroll = ScrollController();
  double _offset = 0;

  // Taller hero: the old 380 left the title squeezed right against the
  // photo once the rounded sheet slid up over it.
  static const _heroHeight = 420.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (mounted) setState(() => _offset = _scroll.offset);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final lang = ref.watch(langProvider);
    final places = ref.watch(placesProvider).value ?? const <Place>[];
    final place = places.where((p) => p.id == widget.placeId).firstOrNull;

    if (place == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isFav = ref.watch(favouritesProvider).contains(place.id);
    final progress = (_offset / _heroHeight).clamp(0.0, 1.0);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // ---------- Parallax photo hero ----------
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _heroHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Swipeable gallery; drifts at 35% of scroll speed
                      // and zooms slightly on overscroll.
                      Transform.translate(
                        offset: Offset(0, _offset * AppMotion.parallaxFactor),
                        child: Transform.scale(
                          scale: 1 + (_offset < 0 ? -_offset / 400 : 0),
                          child: PlaceGallery(
                            place: place,
                            heroTag: 'place-img-${place.id}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------- Rounded content sheet that slides over the photo ----------
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -34),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(34)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Grab handle: visually separates the sheet from the
                        // photo so the title no longer looks glued to it.
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        RevealIn(
                          index: 0,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  place.name(lang),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        // Myanmar stacks diacritics above and
                                        // below, so it needs a taller line box.
                                        height: lang == 'my' ? 1.65 : 1.22,
                                        letterSpacing:
                                            lang == 'my' ? 0 : -0.4,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (place.rating != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 16, color: AppColors.gold),
                                      const SizedBox(width: 4),
                                      Text(
                                        place.rating!.toStringAsFixed(1),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        RevealIn(
                          index: 1,
                          child: Row(
                            children: [
                              const Icon(Icons.place_rounded,
                                  size: 15, color: AppColors.jade),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(place.address(lang),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        RevealIn(
                          index: 2,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Pill(
                                icon: place.category.icon,
                                label: t.t(place.category.labelKey),
                                color: place.category.color,
                              ),
                              if (place.openHours != null)
                                _Pill(
                                  icon: Icons.schedule_rounded,
                                  label: place.openHours!,
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ...place.tags.map((tag) => _Pill(
                                    icon: Icons.sell_rounded,
                                    label: tag,
                                    color: cs.onSurface.withValues(alpha: 0.4),
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        RevealIn(
                          index: 3,
                          child: Text(t.description,
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                        ),
                        const SizedBox(height: 8),
                        RevealIn(
                          index: 4,
                          child: Text(place.description(lang),
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        if (place.phone != null &&
                            place.phone!.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          RevealIn(
                            index: 5,
                            child: _CallRow(phone: place.phone!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ---------- Top bar that fades in a solid background on scroll ----------
          _FloatingTopBar(
            progress: progress,
            title: place.name(lang),
            isFav: isFav,
            onBack: () => context.pop(),
            onFav: () =>
                ref.read(favouritesProvider.notifier).toggle(place.id),
          ),

          // ---------- Sticky action bar ----------
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: RevealIn(
              delay: AppMotion.base,
              offset: const Offset(0, 0.5),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.go('/map?focus=${place.id}'),
                      icon: const Icon(Icons.near_me_rounded, size: 18),
                      label: Text(t.viewInMap),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: const Color(0xFF3A2600)),
                      onPressed: () =>
                          context.go('/map?focus=${place.id}&route=1'),
                      icon: const Icon(Icons.route_rounded, size: 18),
                      label: Text(t.findPath),
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

class _FloatingTopBar extends StatelessWidget {
  const _FloatingTopBar({
    required this.progress,
    required this.title,
    required this.isFav,
    required this.onBack,
    required this.onFav,
  });

  final double progress;
  final String title;
  final bool isFav;
  final VoidCallback onBack;
  final VoidCallback onFav;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return AnimatedContainer(
      duration: AppMotion.micro,
      height: MediaQuery.of(context).padding.top + 62,
      color: bg.withValues(alpha: progress),
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16),
      child: Row(
        children: [
          _CircleIcon(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedOpacity(
              opacity: progress > 0.6 ? 1 : 0,
              duration: AppMotion.fast,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          FavouriteButton(isFavourite: isFav, onTap: onFav),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.85,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({required this.phone});
  final String phone;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => launchUrl(Uri.parse('tel:$phone')),
      icon: const Icon(Icons.phone_rounded, size: 18, color: AppColors.danger),
      label: Text('${context.l10n.call}  $phone'),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
