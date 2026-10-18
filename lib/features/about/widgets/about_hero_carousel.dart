import 'dart:async';

import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// AboutHeroCarousel
///
/// Replaces the single still photo at the top of the About page with an
/// automatically advancing set of photos.
///
///   * advances every [interval] (3 s by default)
///   * the user can swipe by hand; the timer restarts after they let go
///   * dots at the bottom-right show how many photos there are
///   * tapping the photo opens a full-screen viewer that can be pinch-zoomed
///
/// Self-contained on purpose: it does not depend on FrostedPhoto, PlaceGallery
/// or any Hero tag, so it cannot collide with anything already on the page.
/// ---------------------------------------------------------------------------
class AboutHeroCarousel extends StatefulWidget {
  const AboutHeroCarousel({
    super.key,
    required this.images,
    required this.kicker,
    required this.title,
    required this.subtitle,
    this.height = 420,
    this.interval = const Duration(seconds: 3),
  });

  final List<String> images;
  final String kicker;
  final String title;
  final String subtitle;
  final double height;
  final Duration interval;

  @override
  State<AboutHeroCarousel> createState() => _AboutHeroCarouselState();
}

class _AboutHeroCarouselState extends State<AboutHeroCarousel> {
  late final PageController _page = PageController();
  Timer? _timer;
  int _index = 0;

  List<String> get _imgs =>
      widget.images.isEmpty ? const ['assets/images/hero_kengtung.jpg'] : widget.images;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  /// (Re)start the auto-advance timer. Called on init, after a manual swipe
  /// and after the full-screen viewer closes.
  void _arm() {
    _timer?.cancel();
    if (_imgs.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || !_page.hasClients) return;
      final next = (_index + 1) % _imgs.length;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 620),
        curve: const Cubic(.16, 1, .3, 1),
      );
    });
  }

  void _openViewer() {
    _timer?.cancel();
    Navigator.of(context)
        .push(
          PageRouteBuilder<void>(
            opaque: false,
            barrierColor: Colors.black,
            transitionDuration: const Duration(milliseconds: 240),
            pageBuilder: (_, __, ___) =>
                _HeroLightbox(images: _imgs, initial: _index),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
          ),
        )
        .then((_) => _arm());
  }

  @override
  Widget build(BuildContext context) {
    final imgs = _imgs;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ---- the photos ----
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification && n.dragDetails != null) {
                _timer?.cancel();
              } else if (n is ScrollEndNotification) {
                _arm();
              }
              return false;
            },
            child: PageView.builder(
              controller: _page,
              itemCount: imgs.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => GestureDetector(
                onTap: _openViewer,
                child: Image.asset(
                  imgs[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFF1A2A25),
                    child: Center(
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Colors.white24, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ---- dark gradient so the title stays readable ----
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: widget.height * 0.52,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00060C0A),
                      Color(0x4D060C0A),
                      Color(0x9E060C0A),
                      Color(0xCC060C0A),
                    ],
                    stops: [0.0, 0.42, 0.78, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ---- kicker / title / subtitle ----
          Positioned(
            left: 22,
            right: 22,
            bottom: 34,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.kicker.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xE6FFFFFF),
                      fontSize: 11,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                            color: Color(0x8C000000),
                            blurRadius: 6,
                            offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      color: Color(0xDEFFFFFF),
                      fontSize: 13.5,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---- "tap to enlarge" hint ----
          Positioned(
            right: 16,
            top: 54,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x59000000),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.zoom_out_map_rounded,
                    color: Colors.white70, size: 16),
              ),
            ),
          ),

          // ---- dots ----
          if (imgs.length > 1)
            Positioned(
              right: 20,
              bottom: 14,
              child: IgnorePointer(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(imgs.length, (i) {
                    final on = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.only(left: 5),
                      width: on ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: on ? Colors.white : const Color(0x80FFFFFF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-screen, pinch-zoomable viewer. Swipe sideways to change photo,
/// double-tap or pinch to zoom, tap the X (or the background) to close.
class _HeroLightbox extends StatefulWidget {
  const _HeroLightbox({required this.images, required this.initial});

  final List<String> images;
  final int initial;

  @override
  State<_HeroLightbox> createState() => _HeroLightboxState();
}

class _HeroLightboxState extends State<_HeroLightbox> {
  late final PageController _page =
      PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _page,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _ZoomablePhoto(image: widget.images[i]),
          ),

          // close button
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x59000000),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // counter
          if (widget.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 18,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x59000000),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({required this.image});

  final String image;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto>
    with SingleTickerProviderStateMixin {
  final TransformationController _ctrl = TransformationController();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  Animation<Matrix4>? _tween;
  TapDownDetails? _doubleTapAt;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      if (_tween != null) _ctrl.value = _tween!.value;
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final zoomedIn = _ctrl.value.getMaxScaleOnAxis() > 1.2;
    final Matrix4 end;
    if (zoomedIn) {
      end = Matrix4.identity();
    } else {
      final p = _doubleTapAt?.localPosition ?? Offset.zero;
      const scale = 2.6;
      end = Matrix4.identity()
        ..translate(-p.dx * (scale - 1), -p.dy * (scale - 1))
        ..scale(scale);
    }
    _tween = Matrix4Tween(begin: _ctrl.value, end: end)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _doubleTapAt = d,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _ctrl,
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: Image.asset(
            widget.image,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white24,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
