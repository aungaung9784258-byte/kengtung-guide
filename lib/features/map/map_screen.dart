import 'dart:async';
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

  // ---- live navigation ----
  NavSession? _nav;          // non-null while navigating
  Place? _navTarget;
  bool _courseUp = true;

  /// Follow mode: while true the camera stays locked on the user. Panning
  /// the map by hand breaks the lock so people can look ahead, and it
  /// re-arms itself after a short pause (or instantly via the button).
  bool _follow = true;
  Timer? _refollowTimer;     // rotate the map to the direction of travel

  // ---- search suggestions ----
  final _searchCtrl = TextEditingController();
  String _query = '';

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
    _refollowTimer?.cancel();
    _stopNavigation(silent: true);
    _searchCtrl.dispose();
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

    // ALWAYS ask the router first.
    //
    // This used to be guarded by `if (online)`. The connectivity plugin
    // reports "offline" far too eagerly - a captive Wi-Fi, a slow mobile
    // handover or simply a device it does not understand - and when it did,
    // the app never even attempted a real route and silently showed the
    // straight-line estimate instead. RoutingService already handles failure
    // (it tries several mirrors and returns null), so the guard only ever
    // removed working routes.
    RouteResult? r = await RoutingService.route([me, p.latLng], mode: _mode);
    var approx = false;

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

  // ---------------------------------------------------------------------
  // Live navigation
  // ---------------------------------------------------------------------

  void _startNavigation(Place target) {
    final r = _route;
    final me = _me;
    if (r == null || me == null) return;

    _stopNavigation(silent: true);

    final nav = NavSession(
      destination: target.latLng,
      mode: _mode,
      initialRoute: r,
      isOnline: () => ref.read(onlineProvider),
    );

    nav.addListener(_onNavTick);
    nav.start(initialPosition: me);

    setState(() {
      _nav = nav;
      _navTarget = target;
      _selected = null;   // the bottom card gives way to the nav banner
      _follow = true;
    });
    _refollowTimer?.cancel();

    _map.moveAndRotate(me, 17.5, _courseUp ? -nav.bearing : 0);
  }

  void _stopNavigation({bool silent = false}) {
    final nav = _nav;
    if (nav == null) return;
    _refollowTimer?.cancel();
    nav.removeListener(_onNavTick);
    nav.dispose();
    _nav = null;
    _navTarget = null;
    if (!silent && mounted) {
      setState(() {});
      _map.rotate(0);
    }
  }

  /// Called whenever the user moves the camera themselves during
  /// navigation: drop the lock and arm the countdown that restores it.
  void _breakFollow() {
    _refollowTimer?.cancel();
    _refollowTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _nav != null) _recenter();
    });
    if (_follow) setState(() => _follow = false);
  }

  /// Snap the camera back onto the user and resume following.
  void _recenter() {
    _refollowTimer?.cancel();
    final nav = _nav;
    final me = nav?.me ?? _me;
    if (me == null) return;
    setState(() => _follow = true);
    _map.moveAndRotate(
      me,
      _map.camera.zoom < 16 ? 17.5 : _map.camera.zoom,
      (nav != null && _courseUp) ? -nav.bearing : _map.camera.rotation,
    );
  }

  void _onNavTick() {
    final nav = _nav;
    if (nav == null || !mounted) return;

    setState(() => _route = nav.route);

    final me = nav.me;
    if (me != null) {
      _me = me;
      // Only drive the camera while the lock is on, otherwise the map
      // would snap back under the user's finger every GPS fix.
      if (_follow) {
        _map.moveAndRotate(
          me,
          _map.camera.zoom < 16 ? 17.5 : _map.camera.zoom,
          _courseUp ? -nav.bearing : _map.camera.rotation,
        );
      }
    }

    if (nav.arrived) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('arrived'))),
      );
      _stopNavigation();
    }
  }

  /// Suggestions for the search box. Computed on the spot so no extra
  /// provider is needed and nothing outside this file has to change.
  List<Place> _suggestions() {
    if (_query.trim().isEmpty) return const [];
    final all = ref.read(placesProvider).value ?? const <Place>[];
    final t = context.l10n;
    return SearchService.rank(
      all,
      _query,
      lang: ref.read(langProvider),
      categoryLabelOf: (p) => t.t(p.category.labelKey),
      limit: 6,
    );
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
              maxZoom: 18,
              onTap: (_, __) => setState(() => _selected = null),
              // Two-finger twist now rotates the map (was disabled before).
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
                rotationThreshold: 12,
                pinchZoomThreshold: 0.4,
              ),
              // If the user twists the map by hand while navigating we drop
              // out of course-up so the map does not fight the gesture.
              onMapEvent: (e) {
                if (_nav == null) return;
                final byHand = e.source != MapEventSource.mapController &&
                    e.source != MapEventSource.custom;
                if (!byHand) return;

                // A twist by hand also leaves course-up, so the map stops
                // fighting the gesture.
                if (e is MapEventRotate && _courseUp) {
                  setState(() => _courseUp = false);
                }
                // MapEventWithMove covers drag, fling, pinch and
                // double-tap zoom in one check.
                if (e is MapEventWithMove ||
                    e is MapEventMove ||
                    e is MapEventRotate) {
                  _breakFollow();
                }
              },
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
                        ? AppColors.gold
                        : AppColors.jade,
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                    pattern: _routeIsApprox
                        ? StrokePattern.dashed(segments: const [12, 10])
                        : const StrokePattern.solid(),
                  ),
                ]),

              MarkerLayer(markers: [
                if (_me != null)
                  Marker(
                    point: _me!,
                    width: _nav == null ? 26 : 46,
                    height: _nav == null ? 26 : 46,
                    child: _nav == null
                        ? const _MeDot()
                        : _MeArrow(
                            // Angle relative to the map, so the arrow keeps
                            // pointing the right way whether the map is
                            // rotated course-up or locked north-up.
                            headingDeg:
                                _nav!.bearing - _map.camera.rotation,
                          ),
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

          // Top: search + category filter rail  (hidden while navigating)
          if (_nav == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassPanel(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      radius: 18,
                      child: TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        onChanged: (v) {
                          ref.read(searchQueryProvider.notifier).state = v;
                          setState(() => _query = v);
                        },
                        decoration: InputDecoration(
                          hintText: context.l10n.search,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          filled: false,
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    ref
                                        .read(searchQueryProvider.notifier)
                                        .state = '';
                                    setState(() => _query = '');
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),

                  // ---- live suggestions ----
                  if (_query.trim().isNotEmpty)
                    Builder(builder: (context) {
                      final hits = _suggestions();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: GlassPanel(
                          radius: 18,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: hits.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Text(
                                    context.l10n.t('noResults'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final p in hits)
                                      _SuggestionTile(
                                        place: p,
                                        onTap: () {
                                          FocusScope.of(context).unfocus();
                                          _searchCtrl.clear();
                                          ref
                                              .read(searchQueryProvider
                                                  .notifier)
                                              .state = '';
                                          setState(() => _query = '');
                                          _select(p);
                                        },
                                      ),
                                  ],
                                ),
                        ),
                      );
                    }),

                  if (_query.trim().isEmpty) ...[
                    const SizedBox(height: 12),
                    const CategoryChips(),
                  ],
                  if (!online && _query.trim().isEmpty) ...[
                    const SizedBox(height: 12),
                    const _OfflineBanner(),
                  ],
                ],
              ),
            ),

          // Top banner while navigating
          if (_nav != null) _NavBanner(
            nav: _nav!,
            target: _navTarget,
            mode: _mode,
            courseUp: _courseUp,
            onToggleNorth: () {
              setState(() => _courseUp = !_courseUp);
              _map.rotate(_courseUp ? -_nav!.bearing : 0);
            },
            onStop: _stopNavigation,
          ),

          // Right side controls
          if (_nav == null)
            Positioned(
              right: 18,
            bottom: _selected == null ? 40 : 250,
            child: AnimatedSlide(
              offset: Offset.zero,
              duration: AppMotion.base,
              child: Column(
                children: [
                  if (_route != null)
                    _RoundBtn(
                      icon: Icons.close_rounded,
                      color: AppColors.danger,
                      onTap: () => setState(() => _route = null),
                    ),
                  if (_route != null) const SizedBox(height: 10),
                  _CompassButton(map: _map),
                  _BasemapButton(
                    style: _basemap,
                    onTap: () => setState(() => _basemap = _basemap.next),
                  ),
                  const SizedBox(height: 10),
                  _RoundBtn(
                    icon: Icons.my_location_rounded,
                    onTap: () async {
                      _me = await LocationService.current();
                      if (_me != null) _flyTo(_me!, 16);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),

          // While navigating the control column is hidden, but the basemap
          // (satellite) switch stays — people want the aerial view most
          // exactly when they are driving.
          if (_nav != null)
            Positioned(
              right: 18,
              bottom: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BasemapButton(
                    style: _basemap,
                    onTap: () => setState(() => _basemap = _basemap.next),
                  ),
                ],
              ),
            ),

          // Re-centre pill: only while the camera lock is off.
          if (_nav != null && !_follow)
            Positioned(
              left: 0,
              right: 0,
              bottom: 44,
              child: Center(
                child: RevealIn(
                  scaleFrom: 0.85,
                  child: PressableScale(
                    onTap: _recenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.jade,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.jade.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.my_location_rounded,
                              size: 17, color: Colors.white),
                          const SizedBox(width: 7),
                          Text(
                            ref.watch(langProvider) == 'my'
                                ? 'ပြန်ချိန်ရန်'
                                : 'Re-centre',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Route summary chip (the nav banner replaces it while navigating)
          if (_route != null && _nav == null)
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
                              : '${_route!.distanceLabel} · '
                                  '${_Eta.range(_mode, _route!.distanceMeters, ref.watch(langProvider))}',
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
                    routeMeters:
                        _routeIsApprox ? null : _route?.distanceMeters,
                    hasRoute: _route != null && !_routeIsApprox,
                    onStart: () => _startNavigation(_selected!),
                    onDetail: () =>
                        context.push('/place/${_selected!.id}'),
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
              color: AppColors.jade.withValues(alpha: (1 - _c.value) * 0.45),
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.jade,
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
    required this.onDetail,
    required this.mode,
    required this.onModeChanged,
    required this.hasRoute,
    required this.onStart,
    this.distanceKm,
    this.routeMeters,
    this.loading = false,
  });

  final Place place;
  final VoidCallback onFindPath;
  final VoidCallback onDetail;
  final TravelMode mode;
  final ValueChanged<TravelMode> onModeChanged;

  /// A real road route is on screen, so navigation can be started.
  final bool hasRoute;
  final VoidCallback onStart;

  final double? distanceKm;
  /// Road distance of the current route, when one has been found.
  final double? routeMeters;
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
          if (routeMeters != null) ...[
            const SizedBox(height: 12),
            _EtaRow(meters: routeMeters!, active: mode, lang: lang),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              // Before a route exists: "Find path".
              // Once a real road route is drawn: "Start" takes its place and
              // a small refresh button re-runs the search.
              Expanded(
                child: hasRoute
                    ? FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.jade),
                        onPressed: onStart,
                        icon: const Icon(Icons.navigation_rounded, size: 17),
                        label: Text(t.t('startNavigation')),
                      )
                    : FilledButton.icon(
                        // Gold, matching the "Find path" button on the
                        // detail screen so the two read as the same action.
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: const Color(0xFF3A2600),
                        ),
                        onPressed: loading ? null : onFindPath,
                        icon: loading
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF3A2600)))
                            : const Icon(Icons.route_rounded, size: 17),
                        label: Text(t.findPath),
                      ),
              ),
              const SizedBox(width: 10),
              if (hasRoute) ...[
                OutlinedButton(
                  onPressed: loading ? null : onFindPath,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14)),
                  child: const Icon(Icons.refresh_rounded, size: 17),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetail,
                  icon: const Icon(Icons.info_outline_rounded, size: 17),
                  label: Text(t.viewDetail),
                ),
              ),
            ],
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
    TravelMode.bike: Icons.two_wheeler_rounded,
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

/// ---------------------------------------------------------------------------
/// The user's own position while navigating: a heading arrow instead of a dot.
/// ---------------------------------------------------------------------------
class _MeArrow extends StatelessWidget {
  const _MeArrow({required this.headingDeg});

  final double headingDeg;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: headingDeg * math.pi / 180,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.jade.withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.jadeGradient,
          ),
          child: Center(
            child: Icon(Icons.navigation_rounded,
                size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Banner shown at the top while navigation is running.
/// ---------------------------------------------------------------------------
class _NavBanner extends ConsumerWidget {
  const _NavBanner({
    required this.nav,
    required this.target,
    required this.mode,
    required this.courseUp,
    required this.onToggleNorth,
    required this.onStop,
  });

  final NavSession nav;
  final Place? target;
  final TravelMode mode;
  final bool courseUp;
  final VoidCallback onToggleNorth;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final lang = ref.watch(langProvider);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: GlassPanel(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.navigation_rounded,
                    size: 20, color: AppColors.jade),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${nav.remainingDistanceLabel}  ·  '
                        '${_Eta.range(mode, nav.remainingMeters, lang)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      if (target != null)
                        Text(
                          target!.name(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: courseUp ? t.t('northUp') : t.t('courseUp'),
                  onPressed: onToggleNorth,
                  icon: Icon(
                    courseUp
                        ? Icons.explore_rounded
                        : Icons.navigation_outlined,
                    size: 20,
                  ),
                ),
                IconButton(
                  tooltip: t.t('stopNavigation'),
                  onPressed: onStop,
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: AppColors.danger),
                ),
              ],
            ),
            if (nav.rerouting) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text(t.t('rerouting'),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: nav.completion.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.jade),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// One row in the search suggestion list.
/// ---------------------------------------------------------------------------
class _SuggestionTile extends ConsumerWidget {
  const _SuggestionTile({required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final t = context.l10n;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: place.category.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(place.category.icon,
                  size: 17, color: place.category.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  Text(
                    '${t.t(place.category.labelKey)}  ·  ${place.address(lang)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
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

/// Compass that appears only when the map is rotated away from north.
/// Tapping it springs the map back to north-up.
class _CompassButton extends StatefulWidget {
  const _CompassButton({required this.map});
  final MapController map;

  @override
  State<_CompassButton> createState() => _CompassButtonState();
}

class _CompassButtonState extends State<_CompassButton> {
  StreamSubscription<MapEvent>? _sub;
  double _rot = 0;

  @override
  void initState() {
    super.initState();
    _sub = widget.map.mapEventStream.listen((_) {
      final r = widget.map.camera.rotation;
      if ((r - _rot).abs() > 0.1) setState(() => _rot = r);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _rot.abs() % 360 > 0.5 && _rot.abs() % 360 < 359.5;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppMotion.fast,
        child: AnimatedScale(
          scale: visible ? 1 : 0.7,
          duration: AppMotion.fast,
          curve: AppMotion.springy,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PressableScale(
              onTap: () {
                widget.map.rotate(0);
                setState(() => _rot = 0);
              },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: _rot * math.pi / 180,
                  child: CustomPaint(painter: _CompassPainter()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.3;
    final north = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx - r * 0.42, c.dy + r * 0.28)
      ..lineTo(c.dx, c.dy + r * 0.08)
      ..close();
    final south = Path()
      ..moveTo(c.dx, c.dy + r)
      ..lineTo(c.dx + r * 0.42, c.dy - r * 0.28)
      ..lineTo(c.dx, c.dy - r * 0.08)
      ..close();
    canvas.drawPath(north, Paint()..color = AppColors.coral);
    canvas.drawPath(
      south,
      Paint()..color = const Color(0xFF9AA5A1),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) => false;
}

/// Travel-time estimates calibrated for Kengtung, not for a motorway.
///
/// OSRM returns the duration a car would need at the speed limit, which is
/// far too optimistic here: narrow town lanes, motorbikes everywhere,
/// unsealed stretches once you leave the grid, and hills on every approach
/// road. These numbers come from real average speeds rather than limits,
/// and a range is shown instead of one figure because an honest estimate
/// is more useful than a precise-looking wrong one.
class _Eta {
  /// Average speed in km/h, which rises with distance because short trips
  /// are all junctions and long ones are mostly open road.
  static double _kmh(TravelMode m, double km) => switch (m) {
        TravelMode.walk => km < 2 ? 4.2 : 4.6,
        // Motorbike: the usual way to get around town.
        TravelMode.bike => km < 3
            ? 24
            : km < 10
                ? 33
                : 42,
        TravelMode.drive => km < 3
            ? 22
            : km < 10
                ? 30
                : 46,
      };

  /// Fixed overhead: unlocking and parking a vehicle, waiting at the gate.
  static double _overheadMin(TravelMode m) => switch (m) {
        TravelMode.walk => 0,
        TravelMode.bike => 1.5,
        TravelMode.drive => 3,
      };

  static double minutes(TravelMode m, double meters) {
    final km = meters / 1000;
    return km / _kmh(m, km) * 60 + _overheadMin(m);
  }

  /// "12–15 min" / "၁၂–၁၅ မိနစ်" — a plausible band, never a false promise.
  static String range(TravelMode m, double meters, String lang) {
    final mid = minutes(m, meters);
    var lo = (mid * 0.85).round();
    var hi = (mid * 1.25).round();
    if (lo < 1) lo = 1;
    if (hi <= lo) hi = lo + 1;
    final unit = lang == 'my' ? 'မိနစ်' : 'min';
    if (hi >= 60) {
      final h = (mid / 60);
      final hLabel = h.toStringAsFixed(h < 10 ? 1 : 0);
      return lang == 'my' ? '$hLabel နာရီခန့်' : '~$hLabel hr';
    }
    return '$lo–$hi $unit';
  }
}

/// Side-by-side travel times so the choice of vehicle is an informed one.
class _EtaRow extends StatelessWidget {
  const _EtaRow({
    required this.meters,
    required this.active,
    required this.lang,
  });

  final double meters;
  final TravelMode active;
  final String lang;

  static const _icons = {
    TravelMode.drive: Icons.directions_car_rounded,
    TravelMode.bike: Icons.two_wheeler_rounded,
    TravelMode.walk: Icons.directions_walk_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: _icons.entries.map((e) {
        final sel = e.key == active;
        return Expanded(
          child: AnimatedContainer(
            duration: AppMotion.fast,
            margin: const EdgeInsets.only(right: 8),
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.jade.withValues(alpha: 0.13)
                  : onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel
                    ? AppColors.jade.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                Icon(e.value,
                    size: 16,
                    color: sel
                        ? AppColors.jade
                        : onSurface.withValues(alpha: 0.65)),
                const SizedBox(height: 3),
                FittedBox(
                  child: Text(
                    _Eta.range(e.key, meters, lang),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                      color: sel
                          ? AppColors.jade
                          : onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
