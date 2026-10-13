import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/basemap.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/navigation_service.dart';
import '../../core/services/routing_service.dart';
import '../../core/services/search_service.dart';
import '../../data/models/place.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/cached_tile_provider.dart';
import '../../shared/widgets/category_chips.dart';
import '../../shared/widgets/motion_widgets.dart';
import '../../shared/widgets/place_image.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.focusId, this.autoRoute = false});
  final String? focusId;
  final bool autoRoute;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final _map = MapController();
  Place? _selected;
  LatLng? _me;
  RouteResult? _route;
  TravelMode _mode = TravelMode.drive;
  bool _loadingRoute = false;
  bool _routeIsApprox = false; // true when offline: straight line only
  BasemapStyle _basemap = BasemapStyle.street;

  // --- live navigation -----------------------------------------------------
  NavSession? _nav;
  Place? _navTarget;
  double _mapRotation = 0; // degrees, mirrors the camera
  bool _cameraBusy = false; // our own camera moves must not kill follow mode

  bool get _navigating => _nav != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _me = await LocationService.current();
      if (mounted) setState(() {});
      _applyFocus();
    });
  }

  @override
  void dispose() {
    _nav?.removeListener(_onNavTick);
    _nav?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapScreen old) {
    super.didUpdateWidget(old);
    if (old.focusId != widget.focusId) _applyFocus();
  }

  void _applyFocus() {
    final id = widget.focusId;
    if (id == null) return;
    final places = ref.read(placesProvider).value ?? const <Place>[];
    final p = places.where((e) => e.id == id).toList();
    if (p.isEmpty) return;
    _select(p.first, animate: true);
    if (widget.autoRoute) _findPath(p.first);
  }

  /// Smoothly fly the camera instead of jumping.
  void _flyTo(LatLng dest, double zoom) {
    final camera = _map.camera;
    final latT = Tween(begin: camera.center.latitude, end: dest.latitude);
    final lngT = Tween(begin: camera.center.longitude, end: dest.longitude);
    final zoomT = Tween(begin: camera.zoom, end: zoom);

    final c = AnimationController(vsync: this, duration: AppMotion.slow);
    final anim = CurvedAnimation(parent: c, curve: AppMotion.emphasized);
    c.addListener(() => _map.move(
          LatLng(latT.evaluate(anim), lngT.evaluate(anim)),
          zoomT.evaluate(anim),
        ));
    c.addStatusListener((s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        c.dispose();
      }
    });
    c.forward();
  }

  void _select(Place p, {bool animate = true}) {
    setState(() => _selected = p);
    if (animate) _flyTo(p.latLng, 16);
  }

  Future<void> _findPath(Place p) async {
    setState(() => _loadingRoute = true);

    // GPS works without internet, so we can always locate the user.
    final me = _me ?? await LocationService.current();
    _me = me;
    if (me == null) {
      if (mounted) {
        setState(() => _loadingRoute = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('locationDenied'))),
        );
      }
      return;
    }

    // Turn-by-turn routing needs a server. Offline, fall back to a direct
    // line + straight-line distance so the user still knows which way to go.
    final online = ref.read(onlineProvider);
    RouteResult? r;
    var approx = false;

    if (online) {
      r = await RoutingService.route([me, p.latLng], mode: _mode);
    }
    if (r == null) {
      r = RoutingService.straightLine(me, p.latLng, mode: _mode);
      approx = true;
    }

    if (!mounted) return;
    setState(() {
      _route = r;
      _routeIsApprox = approx;
      _loadingRoute = false;
    });

    if (approx) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('routeApprox'))),
      );
    }
    _map.fitCamera(CameraFit.coordinates(
      coordinates: r.points,
      padding: const EdgeInsets.fromLTRB(60, 180, 60, 280),
    ));
  }

  // ==========================================================================
  // Live navigation
  // ==========================================================================

  /// Begin following the user along [_route] towards [p].
  void _startNavigation(Place p) {
    if (_route == null) return;
    _stopNavigation(notify: false);

    final s = NavSession(
      destination: p.latLng,
      mode: _mode,
      initialRoute: _route!,
      isOnline: () => ref.read(onlineProvider),
    );
    s.addListener(_onNavTick);
    s.start(initialPosition: _me);

    setState(() {
      _nav = s;
      _navTarget = p;
      _selected = null; // the nav panel replaces the place sheet
    });

    // Snap straight into course-up chase view.
    _cameraBusy = true;
    _map.moveAndRotate(_me ?? p.latLng, 17.5, -s.bearing);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _cameraBusy = false);
  }

  void _stopNavigation({bool notify = true}) {
    final s = _nav;
    if (s == null) return;
    s.removeListener(_onNavTick);
    s.dispose();
    _nav = null;
    _navTarget = null;
    if (notify) {
      setState(() {});
      _resetNorth();
    }
  }

  /// Called on every GPS fix. Moves the camera, then repaints.
  void _onNavTick() {
    final s = _nav;
    if (s == null || !mounted) return;

    if (s.arrived) {
      final name = _navTarget?.name(ref.read(langProvider)) ?? '';
      _stopNavigation();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.jade,
          content: Text('${context.l10n.t('arrived')} $name'),
        ),
      );
      return;
    }

    final me = s.me;
    if (me != null && s.followCamera) {
      _cameraBusy = true;
      if (s.courseUp) {
        _map.moveAndRotate(me, _map.camera.zoom, -s.bearing);
      } else {
        _map.move(me, _map.camera.zoom);
      }
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _cameraBusy = false);
    }

    setState(() {
      _me = me ?? _me;
      _route = s.route;
      _routeIsApprox = s.route.approximate;
    });
  }

  /// Any manual pan/zoom/rotate drops out of follow mode, exactly like
  /// Google Maps. The re-centre button brings it back.
  void _onCameraChanged(MapCamera camera, bool hasGesture) {
    if (_mapRotation != camera.rotation) {
      // Repaint the compass needle without a full rebuild storm.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _mapRotation = camera.rotation);
      });
    }
    if (hasGesture && !_cameraBusy && _nav != null && _nav!.followCamera) {
      setState(() => _nav!.followCamera = false);
    }
  }

  void _recenter() {
    final s = _nav;
    if (s == null) {
      if (_me != null) _flyTo(_me!, 16);
      return;
    }
    setState(() => s.followCamera = true);
    _cameraBusy = true;
    final me = s.me ?? _me;
    if (me != null) {
      s.courseUp
          ? _map.moveAndRotate(me, 17.5, -s.bearing)
          : _map.move(me, 17.5);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _cameraBusy = false);
  }

  void _resetNorth() {
    _cameraBusy = true;
    _map.rotate(0);
    setState(() => _mapRotation = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cameraBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(filteredPlacesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final online = ref.watch(onlineProvider);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: LocationService.kengtungCenter,
              initialZoom: 14,
              minZoom: 9,
              maxZoom: 19,
              onTap: (_, __) => setState(() => _selected = null),
              onPositionChanged: _onCameraChanged,
              interactionOptions: const InteractionOptions(
                // Rotation is now ON: two-finger twist to turn the map.
                flags: InteractiveFlag.all,
                // Twist must be deliberate so it doesn't fight pinch-zoom.
                rotationThreshold: 12,
                pinchZoomThreshold: 0.4,
                pinchMoveThreshold: 36,
              ),
            ),
            children: [
              // FREE basemap: OpenStreetMap raster tiles. No key, no billing.
              // Attribution is required by the OSM tile usage policy.
              // Base imagery. Street / Satellite / Hybrid - all free, no key.
              TileLayer(
                key: ValueKey(_basemap.id),
                urlTemplate: _basemap.urlTemplate,
                userAgentPackageName: 'com.kengtung.guide',
                maxNativeZoom: _basemap.maxNativeZoom,
                // Dark filter only suits the street map; never invert photos.
                tileBuilder:
                    (isDark && !_basemap.isSatellite) ? _darkTile : null,
                // Serves from the on-device cache first -> works offline,
                // and silently saves any area browsed while online.
                tileProvider: CachedTileProvider(),
              ),

              // Hybrid: transparent road + place-name labels over the photos.
              if (_basemap.overlayUrlTemplate != null)
                TileLayer(
                  key: const ValueKey('labels'),
                  urlTemplate: _basemap.overlayUrlTemplate!,
                  userAgentPackageName: 'com.kengtung.guide',
                  maxNativeZoom: 19,
                  tileProvider: CachedTileProvider(),
                ),

              if (_route != null)
                PolylineLayer(polylines: [
                  Polyline(
                    points: _route!.points,
                    strokeWidth: _routeIsApprox ? 4 : 6,
                    color: _routeIsApprox
                        ? AppColors.routeApprox
                        : AppColors.routeLine,
                    borderStrokeWidth: 2,
                    borderColor: AppColors.routeBorder,
                    pattern: _routeIsApprox
                        ? StrokePattern.dashed(segments: const [12, 10])
                        : const StrokePattern.solid(),
                  ),
                ]),

              // Destination flag while navigating.
              if (_navTarget != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _navTarget!.latLng,
                    width: 44,
                    height: 52,
                    child: _Pin(
                      place: _navTarget!,
                      selected: true,
                      onTap: () {},
                    ),
                  ),
                ]),

              MarkerLayer(markers: [
                if (_me != null)
                  Marker(
                    point: _nav?.me ?? _me!,
                    width: 44,
                    height: 44,
                    // Counter-rotate so we control the on-screen angle
                    // ourselves instead of inheriting the camera's.
                    rotate: true,
                    child: _navigating
                        ? _MeArrow(
                            // heading relative to the screen
                            angleDeg: _nav!.bearing + _mapRotation,
                            moving: _nav!.speedMps > 0.7,
                          )
                        : const _MeDot(),
                  ),
                ...places.map(
                  (p) => Marker(
                    point: p.latLng,
                    width: 46,
                    height: 54,
                    child: _Pin(
                      place: p,
                      selected: _selected?.id == p.id,
                      onTap: () => _select(p),
                    ),
                  ),
                ),
              ]),

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(_basemap.attribution, onTap: () {}),
                ],
              ),
            ],
          ),

          // Top: search + category filter rail
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _MapSearchField(onPick: _select),
                // The suggestion list needs the space, so the category rail
                // steps aside while the user is typing.
                if (!ref.watch(isSearchingProvider)) ...[
                  const SizedBox(height: 12),
                  const CategoryChips(),
                ],
                if (!online) ...[
                  const SizedBox(height: 12),
                  const _OfflineBanner(),
                ],
              ],
            ),
          ),

          // Right side controls
          Positioned(
            right: 18,
            bottom: _navigating ? 190 : (_selected == null ? 40 : 250),
            child: AnimatedSlide(
              offset: Offset.zero,
              duration: AppMotion.base,
              child: Column(
                children: [
                  if (_route != null && !_navigating)
                    _RoundBtn(
                      icon: Icons.close_rounded,
                      color: AppColors.danger,
                      onTap: () => setState(() => _route = null),
                    ),
                  if (_route != null && !_navigating)
                    const SizedBox(height: 10),

                  // Compass — appears as soon as the map is turned.
                  if (_mapRotation.abs() > 0.5) ...[
                    _CompassBtn(rotation: _mapRotation, onTap: _resetNorth),
                    const SizedBox(height: 10),
                  ],

                  // Course-up / north-up toggle, navigation only.
                  if (_navigating) ...[
                    _RoundBtn(
                      icon: _nav!.courseUp
                          ? Icons.navigation_rounded
                          : Icons.explore_rounded,
                      color: _nav!.courseUp ? AppColors.jade : null,
                      onTap: () {
                        setState(() => _nav!.courseUp = !_nav!.courseUp);
                        if (!_nav!.courseUp) {
                          _resetNorth();
                        } else {
                          _recenter();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  _BasemapButton(
                    style: _basemap,
                    onTap: () => setState(() => _basemap = _basemap.next),
                  ),
                  const SizedBox(height: 10),
                  _RoundBtn(
                    icon: _navigating && !_nav!.followCamera
                        ? Icons.gps_not_fixed_rounded
                        : Icons.my_location_rounded,
                    color: _navigating && !_nav!.followCamera
                        ? AppColors.gold
                        : null,
                    onTap: () async {
                      if (_navigating) {
                        _recenter();
                        return;
                      }
                      _me = await LocationService.current();
                      if (_me != null) _flyTo(_me!, 16);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),

          // Route summary chip (static preview only)
          if (_route != null && !_navigating)
            Positioned(
              top: MediaQuery.of(context).padding.top + 120,
              left: 20,
              child: RevealIn(
                scaleFrom: 0.9,
                child: GlassPanel(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          _routeIsApprox
                              ? Icons.straighten_rounded
                              : Icons.route_rounded,
                          size: 16,
                          color: _routeIsApprox
                              ? AppColors.gold
                              : AppColors.jade),
                      const SizedBox(width: 8),
                      Text(
                          _routeIsApprox
                              ? '${_route!.distanceLabel} · ${context.l10n.t('straightLine')}'
                              : '${_route!.distanceLabel} · ${_route!.durationLabel}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom sheet card for the selected place
          AnimatedPositioned(
            duration: AppMotion.base,
            curve: AppMotion.easeOutExpoCurve,
            left: 16,
            right: 16,
            bottom: _selected == null ? -260 : 24,
            child: _selected == null
                ? const SizedBox.shrink()
                : _PlaceSheet(
                    place: _selected!,
                    distanceKm: _me == null
                        ? null
                        : LocationService.distanceKm(
                            _me!, _selected!.latLng),
                    loading: _loadingRoute,
                    mode: _mode,
                    onModeChanged: (m) {
                      setState(() => _mode = m);
                      _findPath(_selected!);
                    },
                    onFindPath: () => _findPath(_selected!),
                    onStart: _route == null
                        ? null
                        : () => _startNavigation(_selected!),
                    onDetail: () =>
                        context.push('/place/${_selected!.id}'),
                  ),
          ),

          // Live navigation panel
          if (_navigating)
            Positioned(
              left: 14,
              right: 14,
              bottom: 22,
              child: _NavPanel(
                session: _nav!,
                target: _navTarget!,
                onStop: _stopNavigation,
              ),
            ),
        ],
      ),
    );
  }

  /// Cheap dark-mode basemap: invert + hue-rotate the OSM raster tiles.
  static Widget _darkTile(BuildContext c, Widget tile, TileImage image) =>
      ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -0.8, 0.0, 0.0, 0, 255,
          0.0, -0.8, 0.0, 0, 255,
          0.0, 0.0, -0.8, 0, 255,
          0, 0, 0, 1, 0,
        ]),
        child: tile,
      );
}

/// Cycles Street -> Satellite -> Hybrid, showing the current style's name.
class _BasemapButton extends StatelessWidget {
  const _BasemapButton({required this.style, required this.onTap});

  final BasemapStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PressableScale(
      scale: 0.9,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.fast,
              transitionBuilder: (c, a) =>
                  ScaleTransition(scale: a, child: c),
              child: Icon(style.icon,
                  key: ValueKey(style.id), size: 20, color: AppColors.jade),
            ),
            const SizedBox(height: 3),
            Text(
              context.l10n.t(style.labelKey),
              style: const TextStyle(
                  fontSize: 9.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown at the top of the map when there is no connection.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return RevealIn(
      scaleFrom: 0.94,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassPanel(
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 15, color: AppColors.gold),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  context.l10n.t('offlineBanner'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final Place place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.25 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.springy,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: place.category.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: place.category.color.withValues(alpha: 0.5),
                    blurRadius: selected ? 18 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(place.category.icon, size: 16, color: Colors.white),
            ),
            CustomPaint(
              size: const Size(10, 8),
              painter: _TailPainter(place.category.color),
            ),
          ],
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

class _MeDot extends StatefulWidget {
  const _MeDot();
  @override
  State<_MeDot> createState() => _MeDotState();
}

class _MeDotState extends State<_MeDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 26 * _c.value,
            height: 26 * _c.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.myLocationPulse
                  .withValues(alpha: (1 - _c.value) * 0.45),
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.myLocationDot,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.88,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Icon(icon,
            size: 20,
            color: color != null
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

class _PlaceSheet extends ConsumerWidget {
  const _PlaceSheet({
    required this.place,
    required this.onFindPath,
    required this.onStart,
    required this.onDetail,
    required this.mode,
    required this.onModeChanged,
    this.distanceKm,
    this.loading = false,
  });

  final Place place;
  final VoidCallback onFindPath;

  /// Null until a route exists — then it starts live navigation.
  final VoidCallback? onStart;
  final VoidCallback onDetail;
  final TravelMode mode;
  final ValueChanged<TravelMode> onModeChanged;
  final double? distanceKm;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final lang = ref.watch(langProvider);
    final isFav = ref.watch(favouritesProvider).contains(place.id);

    return GlassPanel(
      radius: 26,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                    width: 78, height: 78, child: PlaceImage(place: place)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(place.name(lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      distanceKm == null
                          ? place.address(lang)
                          : '${place.address(lang)} · ${distanceKm!.toStringAsFixed(1)} ${t.t('distanceKm')} ${t.nearYou}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    _ModeSwitch(mode: mode, onChanged: onModeChanged),
                  ],
                ),
              ),
              FavouriteButton(
                isFavourite: isFav,
                size: 18,
                onTap: () =>
                    ref.read(favouritesProvider.notifier).toggle(place.id),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: loading ? null : onFindPath,
                  icon: loading
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.route_rounded, size: 17),
                  label: Text(t.findPath),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetail,
                  icon: const Icon(Icons.info_outline_rounded, size: 17),
                  label: Text(t.viewDetail),
                ),
              ),
            ],
          ),
          // Appears once a route is on screen.
          AnimatedSize(
            duration: AppMotion.base,
            curve: AppMotion.easeOutExpoCurve,
            child: onStart == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onStart,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.jade,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.navigation_rounded, size: 18),
                        label: Text(t.t('startNavigation')),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});
  final TravelMode mode;
  final ValueChanged<TravelMode> onChanged;

  static const _icons = {
    TravelMode.walk: Icons.directions_walk_rounded,
    TravelMode.bike: Icons.pedal_bike_rounded,
    TravelMode.drive: Icons.directions_car_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: TravelMode.values.map((m) {
        final sel = m == mode;
        return GestureDetector(
          onTap: () => onChanged(m),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.jade
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icons[m],
                size: 15,
                color: sel
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface),
          ),
        );
      }).toList(),
    );
  }
}


/// Google-Maps-style heading arrow. Rotates to the user's course and gains a
/// soft halo while actually moving.
class _MeArrow extends StatelessWidget {
  const _MeArrow({required this.angleDeg, required this.moving});

  final double angleDeg;
  final bool moving;

  @override
  Widget build(BuildContext context) {
    // The bearing is already low-pass filtered inside NavSession, so a plain
    // transform here avoids the 359 -> 0 wrap-around spin an animated
    // rotation would produce.
    return Transform.rotate(
      angle: angleDeg * math.pi / 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: AppMotion.base,
            width: moving ? 44 : 34,
            height: moving ? 44 : 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.navArrowHalo.withValues(alpha: 0.18),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.navArrowDisc,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(20, 20),
            painter: _ArrowPainter(AppColors.navArrow),
          ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, 0)             // nose
      ..lineTo(w, h)                 // right tail
      ..lineTo(w / 2, h * 0.72)      // notch
      ..lineTo(0, h)                 // left tail
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

/// Needle that points to true north; tap to straighten the map.
class _CompassBtn extends StatelessWidget {
  const _CompassBtn({required this.rotation, required this.onTap});
  final double rotation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.9,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: rotation * math.pi / 180,
          child: const Icon(Icons.navigation_rounded,
              size: 20, color: AppColors.danger),
        ),
      ),
    );
  }
}

/// Bottom panel shown while navigating: ETA, remaining distance, live
/// progress bar, re-routing indicator and the Stop button.
class _NavPanel extends ConsumerWidget {
  const _NavPanel({
    required this.session,
    required this.target,
    required this.onStop,
  });

  final NavSession session;
  final Place target;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final lang = ref.watch(langProvider);
    final isMy = lang == 'my';

    return RevealIn(
      scaleFrom: 0.95,
      child: GlassPanel(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.jade.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.navigation_rounded,
                      size: 18, color: AppColors.jade),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        session.remainingTimeLabel,
                        style: TextStyle(
                          fontSize: isMy ? 20 : 22,
                          height: isMy ? 1.6 : 1.1,
                          fontWeight: FontWeight.w800,
                          color: AppColors.jade,
                        ),
                      ),
                      Text(
                        '${session.remainingDistanceLabel} · ${target.name(lang)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: isMy ? 1.7 : 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PressableScale(
                  scale: 0.88,
                  onTap: onStop,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      t.t('stopNavigation'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: session.completion),
                duration: AppMotion.base,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor:
                      AppColors.jade.withValues(alpha: 0.15),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.jade),
                ),
              ),
            ),
            AnimatedSize(
              duration: AppMotion.base,
              child: session.rerouting
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.gold),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            t.t('rerouting'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            if (!session.followCamera)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  t.t('tapRecenter'),
                  style: TextStyle(
                    fontSize: 11.5,
                    height: isMy ? 1.7 : 1.3,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


/// Map search box with a live suggestion list.
///
/// Typing updates [searchQueryProvider], which already drives the markers on
/// the map; the dropdown just surfaces the same ranked results so the user can
/// jump straight to one instead of hunting for its pin.
class _MapSearchField extends ConsumerStatefulWidget {
  const _MapSearchField({required this.onPick});

  final void Function(Place place) onPick;

  @override
  ConsumerState<_MapSearchField> createState() => _MapSearchFieldState();
}

class _MapSearchFieldState extends ConsumerState<_MapSearchField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  /// Hidden after a pick, so the list does not reopen over the chosen pin.
  bool _open = false;

  static const _maxSuggestions = 6;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus && _controller.text.isNotEmpty) {
        setState(() => _open = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    ref.read(searchQueryProvider.notifier).state = v;
    setState(() => _open = v.trim().isNotEmpty);
  }

  void _clear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() => _open = false);
    _focus.unfocus();
  }

  void _pick(Place p) {
    final lang = ref.read(langProvider);
    _controller.text = p.name(lang);
    // Keep the chosen place visible but stop filtering, so its neighbours
    // stay on the map for context.
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() => _open = false);
    _focus.unfocus();
    widget.onPick(p);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final lang = ref.watch(langProvider);
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final show = _open && query.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            radius: 18,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (_) {
                if (results.isNotEmpty) _pick(results.first);
              },
              decoration: InputDecoration(
                hintText: t.search,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                filled: false,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: _clear,
                        tooltip: MaterialLocalizations.of(context)
                            .cancelButtonLabel,
                      ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.fast,
            curve: AppMotion.easeOutExpoCurve,
            alignment: Alignment.topCenter,
            child: !show
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GlassPanel(
                      radius: 18,
                      padding: EdgeInsets.zero,
                      child: results.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 18),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_off_rounded,
                                      size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      t.t('noResults'),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const ClampingScrollPhysics(),
                              itemCount: results.length > _maxSuggestions
                                  ? _maxSuggestions
                                  : results.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                thickness: 1,
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.4),
                              ),
                              itemBuilder: (context, i) => _SuggestionTile(
                                place: results[i],
                                query: query,
                                lang: lang,
                                onTap: () => _pick(results[i]),
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

/// One row of the map suggestion list, with the matched span highlighted.
class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.place,
    required this.query,
    required this.lang,
    required this.onTap,
  });

  final Place place;
  final String query;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = place.category.color;
    final name = place.name(lang);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(place.category.icon, size: 17, color: c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Highlighted(text: name, query: query),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.t(place.category.labelKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.north_east_rounded, size: 15),
          ],
        ),
      ),
    );
  }
}

/// Bolds the part of [text] that matched [query].
class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final hit = base.copyWith(
      fontWeight: FontWeight.w900,
      color: AppColors.jade,
    );

    final r = SearchService.highlightRange(text, query);
    if (r == null) {
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: base);
    }
    final (start, end) = r;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: text.substring(0, start), style: base),
        TextSpan(text: text.substring(start, end), style: hit),
        TextSpan(text: text.substring(end), style: base),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
