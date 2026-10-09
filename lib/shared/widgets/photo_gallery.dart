import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../data/models/place.dart';
import 'motion_widgets.dart';
import 'place_image.dart';

/// ---------------------------------------------------------------------------
/// Hero gallery used at the top of the place-detail screen.
///
///  * big photo = swipeable PageView
///  * thumbnail strip underneath = tap to jump, the active one is highlighted
///  * tap the big photo (or the expand chip) = full-screen viewer with
///    two-finger pinch zoom
/// ---------------------------------------------------------------------------
class PlaceGallery extends StatefulWidget {
  const PlaceGallery({
    super.key,
    required this.place,
    this.heroTag,
  });

  final Place place;
  final String? heroTag;

  @override
  State<PlaceGallery> createState() => _PlaceGalleryState();
}

class _PlaceGalleryState extends State<PlaceGallery> {
  late final PageController _page = PageController();
  final _thumbs = ScrollController();
  int _index = 0;

  int get _count =>
      widget.place.images.isEmpty ? 1 : widget.place.images.length;

  @override
  void dispose() {
    _page.dispose();
    _thumbs.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    _page.animateToPage(
      i,
      duration: AppMotion.base,
      curve: AppMotion.easeOutExpoCurve,
    );
  }

  void _onPage(int i) {
    setState(() => _index = i);
    // Keep the active thumbnail in view.
    if (_thumbs.hasClients) {
      const itemExtent = 72.0 + 10.0; // width + separator
      final target = (i * itemExtent) - 90;
      _thumbs.animateTo(
        target.clamp(0.0, _thumbs.position.maxScrollExtent),
        duration: AppMotion.base,
        curve: Curves.easeOut,
      );
    }
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: AppMotion.base,
        pageBuilder: (_, a, __) => FadeTransition(
          opacity: a,
          child: FullscreenGallery(
            place: widget.place,
            initialIndex: _index,
          ),
        ),
      ),
    ).then((returned) {
      // Keep the hero in sync with wherever the user ended up.
      if (returned is int && returned != _index && mounted) {
        _page.jumpToPage(returned);
        _onPage(returned);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showThumbs = _count > 1;

    Widget pager = PageView.builder(
      controller: _page,
      onPageChanged: _onPage,
      physics: const BouncingScrollPhysics(),
      itemCount: _count,
      itemBuilder: (_, i) => GestureDetector(
        onTap: _openFullscreen,
        child: PlaceImage(
          place: widget.place,
          index: i,
          decodeWidth: 1080,
        ),
      ),
    );

    // Only the first photo participates in the shared-element transition,
    // otherwise Flutter sees duplicate tags mid-swipe.
    if (widget.heroTag != null && _index == 0) {
      pager = Hero(tag: widget.heroTag!, child: pager);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        pager,

        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.heroScrim),
            ),
          ),
        ),

        // counter + "tap to zoom" affordance
        Positioned(
          right: 20,
          bottom: showThumbs ? 134 : 74,
          child: GestureDetector(
            onTap: _openFullscreen,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.zoom_out_map_rounded,
                      size: 13, color: Colors.white),
                  if (_count > 1) ...[
                    const SizedBox(width: 7),
                    Text(
                      '${_index + 1}/$_count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // thumbnail strip
        if (showThumbs)
          Positioned(
            left: 20,
            right: 20,
            bottom: 66,
            child: SizedBox(
              height: 62,
              child: ListView.separated(
                controller: _thumbs,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _count,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final active = i == _index;
                  return RevealIn(
                    index: i,
                    scaleFrom: 0.8,
                    child: GestureDetector(
                      onTap: () => _goTo(i),
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        curve: AppMotion.springy,
                        width: active ? 82 : 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.28),
                            width: active ? 2.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: active ? 0.35 : 0.18),
                              blurRadius: active ? 14 : 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedOpacity(
                            duration: AppMotion.fast,
                            opacity: active ? 1 : 0.62,
                            child: PlaceImage(
                              place: widget.place,
                              index: i,
                              decodeWidth: 240,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Full-screen photo viewer: swipe between photos, pinch with two fingers to
/// zoom, double-tap to toggle 2.5x, drag down to dismiss.
/// ---------------------------------------------------------------------------
class FullscreenGallery extends StatefulWidget {
  const FullscreenGallery({
    super.key,
    required this.place,
    this.initialIndex = 0,
  });

  final Place place;
  final int initialIndex;

  @override
  State<FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<FullscreenGallery>
    with SingleTickerProviderStateMixin {
  late final PageController _page =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  /// One controller per page so each photo remembers its own zoom.
  final _zoom = <int, TransformationController>{};

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: AppMotion.base,
  );
  Animation<Matrix4>? _zoomAnim;

  bool get _isZoomed {
    final c = _zoom[_index];
    return c != null && c.value.getMaxScaleOnAxis() > 1.02;
  }

  TransformationController _ctrl(int i) =>
      _zoom.putIfAbsent(i, () => TransformationController());

  @override
  void dispose() {
    _anim.dispose();
    for (final c in _zoom.values) {
      c.dispose();
    }
    _page.dispose();
    super.dispose();
  }

  void _animateTo(Matrix4 target) {
    final c = _ctrl(_index);
    _zoomAnim = Matrix4Tween(begin: c.value, end: target)
        .animate(CurvedAnimation(parent: _anim, curve: AppMotion.emphasized));
    void listener() => c.value = _zoomAnim!.value;
    _anim
      ..removeListener(listener)
      ..addListener(listener)
      ..forward(from: 0);
  }

  void _handleDoubleTap(TapDownDetails d, int i) {
    final c = _ctrl(i);
    if (c.value.getMaxScaleOnAxis() > 1.02) {
      _animateTo(Matrix4.identity());
    } else {
      const scale = 2.5;
      final p = d.localPosition;
      // Built with setEntry instead of translate()/scale(): those two are
      // deprecated in current vector_math, and this is the same matrix.
      _animateTo(
        Matrix4.identity()
          ..setEntry(0, 0, scale)
          ..setEntry(1, 1, scale)
          ..setEntry(0, 3, -p.dx * (scale - 1))
          ..setEntry(1, 3, -p.dy * (scale - 1)),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final count =
        widget.place.images.isEmpty ? 1 : widget.place.images.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _page,
            itemCount: count,
            // While a photo is zoomed in, dragging should pan it, not flick
            // to the next photo.
            physics: _isZoomed
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final c = _ctrl(i);
              return GestureDetector(
                onDoubleTapDown: (d) => _handleDoubleTap(d, i),
                onDoubleTap: () {},
                child: InteractiveViewer(
                  transformationController: c,
                  minScale: 1,
                  maxScale: 5,
                  // Let the zoomed photo be dragged past its own edges a
                  // little; it feels much less rigid.
                  boundaryMargin: const EdgeInsets.all(40),
                  onInteractionEnd: (_) => setState(() {}),
                  child: Center(
                    child: PlaceImage(
                      place: widget.place,
                      index: i,
                      fit: BoxFit.contain,
                      decodeWidth: 1600,
                    ),
                  ),
                ),
              );
            },
          ),

          // close
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            child: _GlassIcon(
              icon: Icons.close_rounded,
              onTap: () => Navigator.of(context).pop(_index),
            ),
          ),

          // counter
          if (count > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 18,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_index + 1} / $count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

          // page dots
          if (count > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 26,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  count,
                  (i) => AnimatedContainer(
                    duration: AppMotion.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.85,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 21, color: Colors.white),
      ),
    );
  }
}
