import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_motion.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/place_category.dart';
import '../../l10n/app_localizations.dart';

/// Animated, colour-aware category filter rail.
class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key, this.padding});

  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(categoryFilterProvider);
    final t = context.l10n;

    final items = <(PlaceCategory?, String)>[
      (null, t.all),
      ...PlaceCategory.values.map((c) => (c, t.t(c.labelKey))),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (cat, label) = items[i];
          final isSel = selected == cat;
          final color = cat?.color ?? Theme.of(context).colorScheme.primary;

          return _Chip(
            label: label,
            icon: cat?.icon,
            color: color,
            selected: isSel,
            index: i,
            onTap: () =>
                ref.read(categoryFilterProvider.notifier).state = cat,
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.index,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final bool selected;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOutExpoCurve,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : cs.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? color : cs.onSurface.withValues(alpha: 0.12),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 15,
                  color: selected ? Colors.white : color),
              const SizedBox(width: 6),
            ],
            AnimatedDefaultTextStyle(
              duration: AppMotion.fast,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : cs.onSurface,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
