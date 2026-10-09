import 'package:flutter/material.dart';
import '../../app/theme/app_motion.dart';

/// Fades + slides a widget in once, with an optional stagger delay.
/// Use `index` inside lists to get a cascading reveal.
class RevealIn extends StatefulWidget {
  const RevealIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = const Offset(0, 0.08),
    this.duration = AppMotion.base,
    this.delay = Duration.zero,
    this.scaleFrom = 1.0,
  });

  final Widget child;
  final int index;
  final Offset offset;
  final Duration duration;
  final Duration delay;
  final double scaleFrom;

  @override
  State<RevealIn> createState() => _RevealInState();
}

class _RevealInState extends State<RevealIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    final wait = widget.delay + AppMotion.stagger * widget.index;
    Future.delayed(wait, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved =
        CurvedAnimation(parent: _c, curve: AppMotion.easeOutExpoCurve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position:
            Tween(begin: widget.offset, end: Offset.zero).animate(curved),
        child: widget.scaleFrom == 1.0
            ? widget.child
            : ScaleTransition(
                scale: Tween(begin: widget.scaleFrom, end: 1.0)
                    .animate(curved),
                child: widget.child,
              ),
      ),
    );
  }
}

/// Scales down slightly while pressed — makes every card feel physical.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.965,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: AppMotion.micro,
        curve: AppMotion.gentle,
        child: widget.child,
      ),
    );
  }
}

/// A heart that pops when toggled.
class FavouriteButton extends StatelessWidget {
  const FavouriteButton({
    super.key,
    required this.isFavourite,
    required this.onTap,
    this.size = 20,
    this.background,
  });

  final bool isFavourite;
  final VoidCallback onTap;
  final double size;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.82,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(size * 0.42),
        decoration: BoxDecoration(
          color: background ??
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          switchInCurve: AppMotion.springy,
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: Icon(
            isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(isFavourite),
            size: size,
            color: isFavourite
                ? const Color(0xFFFF6B5A)
                : Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}

/// Frosted translucent panel used over photos and the map.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
