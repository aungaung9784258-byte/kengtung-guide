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
import '../../core/services/routing_service.dart';
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
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
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
                    width: 26,
                    height: 26,
                    child: const _MeDot(),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassPanel(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    radius: 18,
                    child: TextField(
                      onChanged: (v) => ref
                          .read(searchQueryProvider.notifier)
                          .state = v,
                      decoration: InputDecoration(
                        hintText: context.l10n.search,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        filled: false,
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const CategoryChips(),
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

          // Route summary chip
          if (_route != null)
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
    this.distanceKm,
    this.loading = false,
  });

  final Place place;
  final VoidCallback onFindPath;
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
