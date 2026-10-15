import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/today_providers.dart';
import '../../data/models/village.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/confidence_badge.dart';
import '../../shared/widgets/motion_widgets.dart';

/// Browse the hill-tribe villages around Kengtung, filtered by ethnic group.
class VillagesScreen extends ConsumerWidget {
  const VillagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final lang = ref.watch(langProvider);
    final cs = Theme.of(context).colorScheme;

    final villages = ref.watch(filteredVillagesProvider);
    final peoples = ref.watch(villagePeoplesProvider).value ?? const <String>[];
    final filter = ref.watch(villageFilterProvider);
    final loading = ref.watch(villagesProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('villagesTitle')),
        centerTitle: false,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: Text(
                      t.t('villagesIntro'),
                      style: TextStyle(
                        fontSize: 13,
                        height: t.isMyanmar ? 1.8 : 1.45,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: peoples.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (c, i) {
                        final label = i == 0 ? t.all : peoples[i - 1];
                        final value = i == 0 ? null : peoples[i - 1];
                        final sel = filter == value;
                        return _Chip(
                          label: label,
                          selected: sel,
                          onTap: () => ref
                              .read(villageFilterProvider.notifier)
                              .state = value,
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  sliver: SliverList.separated(
                    itemCount: villages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (c, i) => RevealIn(
                      index: i < 6 ? i : 0,
                      child: VillageCard(village: villages[i], lang: lang),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.gentle,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.jadeGradient : null,
          color: selected ? null : cs.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : cs.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: t.isMyanmar ? 1.6 : 1.2,
            color: selected ? Colors.white : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

/// A village card: photo hero when we have one, jade gradient when we don't.
class VillageCard extends StatelessWidget {
  const VillageCard({super.key, required this.village, required this.lang});
  final Village village;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cs = Theme.of(context).colorScheme;

    return PressableScale(
      onTap: () => context.push('/village/${village.id}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 148,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (village.hasPhoto)
                    Hero(
                      tag: 'village-${village.id}',
                      child: VillagePhoto(path: village.images.first),
                    )
                  else
                    const DecoratedBox(
                      decoration:
                          BoxDecoration(gradient: AppColors.jadeGradient),
                    ),
                  if (!village.hasPhoto)
                    Center(
                      child: Icon(
                        Icons.cottage_rounded,
                        size: 54,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.heroScrim),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final p in village.peoplesFor(lang))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  p,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          village.name(lang),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            height: t.isMyanmar ? 1.7 : 1.15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: ConfidenceBadge(confidence: village.confidence),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    village.summary(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: t.isMyanmar ? 1.8 : 1.4,
                      color: cs.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Fact(
                        icon: Icons.directions_car_rounded,
                        text: village.driveMinutes != null
                            ? '${village.driveMinutes} ${t.t('minShort')}'
                            : '?',
                      ),
                      const SizedBox(width: 14),
                      _Fact(
                        icon: Icons.directions_walk_rounded,
                        text: (village.trekMinutes ?? 0) > 0
                            ? '${village.trekMinutes} ${t.t('minShort')}'
                            : (village.trekMinutes == 0 ? '—' : '?'),
                      ),
                      const SizedBox(width: 14),
                      _Fact(
                        icon: Icons.terrain_rounded,
                        text: t.t(village.difficulty.labelKey),
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

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: cs.onSurface.withValues(alpha: 0.45)),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Shows a village photo from the asset bundle, or from the phone's storage
/// once the team starts adding their own pictures.
///
/// Mirrors how PlaceImage already works, so swapping a sample JPEG for a real
/// one needs no code change at all — just overwrite the file.
class VillagePhoto extends StatelessWidget {
  const VillagePhoto({super.key, required this.path, this.fit = BoxFit.cover});
  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.jadeGradient),
        );

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (c, e, s) => fallback(),
      );
    }
    if (!kIsWeb) {
      return Image.file(
        File(path),
        fit: fit,
        errorBuilder: (c, e, s) => fallback(),
      );
    }
    return fallback();
  }
}
