import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/weather_service.dart';

/// Frosted pill showing Kengtung's live temperature and sky condition.
///
/// Data: Open-Meteo (free, no API key). Falls back to the last cached
/// reading when offline, shown dimmed with a cloud-off icon.
class WeatherBadge extends ConsumerWidget {
  const WeatherBadge({
    super.key,
    this.onLight = true,
    this.compact = false,
  });

  /// True when sitting on a dark photo (white text). False on a light card.
  final bool onLight;

  /// Temperature only, no condition text.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weatherProvider);
    final lang = ref.watch(langProvider);

    final fg = onLight ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: async.when(
        loading: () => _Shell(
          onLight: onLight,
          key: const ValueKey('load'),
          child: SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(fg.withValues(alpha: 0.7)),
            ),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (w) {
          if (w == null) return const SizedBox.shrink();

          final label = lang == 'my' ? w.labelMy : w.labelEn;

          return _Shell(
            onLight: onLight,
            key: ValueKey('${w.code}-${w.tempC}'),
            dim: w.stale,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(w.icon, size: 18, color: fg),
                const SizedBox(width: 7),
                Text(
                  '${w.tempC.round()}\u00B0C',
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 14,
                    color: fg.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.92),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
                if (w.stale) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.cloud_off_rounded,
                      size: 13, color: fg.withValues(alpha: 0.65)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({
    super.key,
    required this.child,
    required this.onLight,
    this.dim = false,
  });

  final Widget child;
  final bool onLight;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final base = onLight
        ? Colors.white.withValues(alpha: 0.18)
        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.9);
    final border = onLight
        ? Colors.white.withValues(alpha: 0.28)
        : Theme.of(context).dividerColor;

    return Opacity(
      opacity: dim ? 0.65 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: border),
          boxShadow: onLight
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}