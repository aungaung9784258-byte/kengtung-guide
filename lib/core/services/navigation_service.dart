import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'routing_service.dart';

/// ---------------------------------------------------------------------------
/// Geometry helpers (equirectangular approximation — accurate well under 1 %
/// at town scale, and ~100x cheaper than haversine in a per-frame loop).
/// ---------------------------------------------------------------------------
class NavGeo {
  static const double _metersPerDegLat = 111320.0;

  static double _mPerDegLng(double lat) =>
      _metersPerDegLat * math.cos(lat * math.pi / 180);

  /// Flat-earth metre offsets of [p] relative to [origin].
  static (double, double) _xy(LatLng p, LatLng origin) => (
        (p.longitude - origin.longitude) * _mPerDegLng(origin.latitude),
        (p.latitude - origin.latitude) * _metersPerDegLat,
      );

  static double distance(LatLng a, LatLng b) {
    final (dx, dy) = _xy(b, a);
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Initial bearing from [a] to [b] in degrees, 0 = north, clockwise.
  static double bearing(LatLng a, LatLng b) {
    final (dx, dy) = _xy(b, a);
    final deg = math.atan2(dx, dy) * 180 / math.pi;
    return (deg + 360) % 360;
  }

  /// Perpendicular distance in metres from [p] to the segment a–b, plus the
  /// fraction (0..1) along the segment where the foot of the perpendicular is.
  static (double, double) distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final (ax, ay) = (0.0, 0.0);
    final (bx, by) = _xy(b, a);
    final (px, py) = _xy(p, a);

    final dx = bx - ax;
    final dy = by - ay;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) return (math.sqrt(px * px + py * py), 0);

    var t = ((px - ax) * dx + (py - ay) * dy) / len2;
    t = t.clamp(0.0, 1.0);

    final cx = ax + t * dx;
    final cy = ay + t * dy;
    final ex = px - cx;
    final ey = py - cy;
    return (math.sqrt(ex * ex + ey * ey), t);
  }

  /// Interpolate between two points by fraction [t].
  static LatLng lerp(LatLng a, LatLng b, double t) => LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

  /// Shortest signed difference between two bearings, in (-180, 180].
  static double angleDelta(double from, double to) {
    var d = (to - from) % 360;
    if (d > 180) d -= 360;
    if (d <= -180) d += 360;
    return d;
  }

  /// Rotate [current] towards [target] by at most [maxStep] degrees.
  /// Keeps the compass from snapping when GPS heading is noisy.
  static double smoothAngle(double current, double target, double factor) =>
      current + angleDelta(current, target) * factor;
}

/// Where the user is relative to the route right now.
class RouteProgress {
  const RouteProgress({
    required this.snapped,
    required this.segmentIndex,
    required this.offRouteMeters,
    required this.remainingMeters,
    required this.courseBearing,
  });

  /// The user's position projected onto the route line.
  final LatLng snapped;
  final int segmentIndex;

  /// Perpendicular distance from the route line.
  final double offRouteMeters;
  final double remainingMeters;

  /// Direction the route is heading at this point (degrees, 0 = north).
  final double courseBearing;
}

/// ---------------------------------------------------------------------------
/// Live turn-by-turn-ish navigation session.
///
/// Google-Maps-like behaviour, built only from free pieces:
///   * follows the GPS stream and keeps the blue arrow on the user
///   * snaps the user onto the route line and counts down the remaining
///     distance / time
///   * detects when the user leaves the route and automatically fetches a new
///     one (throttled, so a bad GPS fix can't spam the router)
///   * reports arrival
///
/// It is a plain [ChangeNotifier] so the map screen can listen without
/// rebuilding anything else.
/// ---------------------------------------------------------------------------
class NavSession extends ChangeNotifier {
  NavSession({
    required this.destination,
    required this.mode,
    required RouteResult initialRoute,
    required this.isOnline,
    this.offRouteThresholdMeters = 45,
    this.arriveThresholdMeters = 35,
  }) : _route = initialRoute;

  final LatLng destination;
  TravelMode mode;

  /// Called by the owner so the session knows whether the router is reachable.
  final bool Function() isOnline;

  final double offRouteThresholdMeters;
  final double arriveThresholdMeters;

  RouteResult _route;
  RouteResult get route => _route;

  StreamSubscription<Position>? _sub;

  LatLng? _me;
  LatLng? get me => _me;

  /// Smoothed heading used to rotate the arrow and the camera.
  double _bearing = 0;
  double get bearing => _bearing;

  double _speedMps = 0;
  double get speedMps => _speedMps;

  RouteProgress? _progress;
  RouteProgress? get progress => _progress;

  bool _rerouting = false;
  bool get rerouting => _rerouting;

  bool _arrived = false;
  bool get arrived => _arrived;

  int _rerouteCount = 0;
  int get rerouteCount => _rerouteCount;

  /// Consecutive fixes that were off the line. Requiring a few in a row stops
  /// one noisy GPS reading from triggering a pointless reroute.
  int _offRouteStrikes = 0;
  DateTime _lastReroute = DateTime.fromMillisecondsSinceEpoch(0);

  /// Set false as soon as the user pans the map themselves.
  bool followCamera = true;

  /// Course-up (rotate the map with the user) vs north-up.
  bool courseUp = true;

  double get remainingMeters =>
      _progress?.remainingMeters ?? _route.distanceMeters;

  /// Remaining time, recomputed from the remaining distance so the ETA
  /// actually counts down as you drive.
  double get remainingSeconds {
    final total = _route.distanceMeters;
    if (total <= 0) return 0;
    return _route.durationSeconds * (remainingMeters / total);
  }

  String get remainingDistanceLabel => remainingMeters < 1000
      ? '${remainingMeters.round()} m'
      : '${(remainingMeters / 1000).toStringAsFixed(1)} km';

  String get remainingTimeLabel {
    final m = (remainingSeconds / 60).round();
    if (m < 1) return '<1 min';
    if (m < 60) return '$m min';
    return '${m ~/ 60} h ${m % 60} min';
  }

  /// Fraction of the route already travelled, 0..1 — drives the progress bar.
  double get completion {
    final total = _route.distanceMeters;
    if (total <= 0) return 0;
    return (1 - remainingMeters / total).clamp(0.0, 1.0);
  }

  // -------------------------------------------------------------------------

  void start({LatLng? initialPosition}) {
    if (initialPosition != null) _ingest(initialPosition, null, null);

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        // 4 m keeps the arrow lively while walking without burning battery.
        distanceFilter: 4,
      ),
    ).listen(
      (p) => _ingest(
        LatLng(p.latitude, p.longitude),
        p.heading,
        p.speed,
      ),
      onError: (_) {},
    );
  }

  Future<void> setMode(TravelMode m) async {
    if (m == mode) return;
    mode = m;
    await _reroute(force: true);
  }

  void _ingest(LatLng pos, double? gpsHeading, double? speed) {
    _me = pos;
    _speedMps = (speed ?? 0).abs();

    final prog = _computeProgress(pos);
    _progress = prog;

    // --- heading -----------------------------------------------------------
    // Below walking pace the GPS compass is noise, so follow the route's own
    // direction instead. Above it, trust the device.
    double target;
    if (_speedMps > 0.7 && gpsHeading != null && gpsHeading >= 0) {
      target = gpsHeading;
    } else if (prog != null) {
      target = prog.courseBearing;
    } else {
      target = _bearing;
    }
    // Low-pass filter: 35 % of the way to the new angle each fix.
    _bearing = (NavGeo.smoothAngle(_bearing, target, 0.35) + 360) % 360;

    // --- arrival -----------------------------------------------------------
    if (!_arrived &&
        NavGeo.distance(pos, destination) <= arriveThresholdMeters) {
      _arrived = true;
      notifyListeners();
      return;
    }

    // --- off-route detection ----------------------------------------------
    if (prog != null && prog.offRouteMeters > offRouteThresholdMeters) {
      _offRouteStrikes++;
      if (_offRouteStrikes >= 2) _reroute();
    } else {
      _offRouteStrikes = 0;
    }

    notifyListeners();
  }

  RouteProgress? _computeProgress(LatLng pos) {
    final pts = _route.points;
    if (pts.length < 2) return null;

    var bestDist = double.infinity;
    var bestIdx = 0;
    var bestT = 0.0;

    for (var i = 0; i < pts.length - 1; i++) {
      final (d, t) = NavGeo.distanceToSegment(pos, pts[i], pts[i + 1]);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
        bestT = t;
      }
    }

    final snapped = NavGeo.lerp(pts[bestIdx], pts[bestIdx + 1], bestT);

    // Remaining = rest of the current segment + every segment after it.
    var remaining = NavGeo.distance(snapped, pts[bestIdx + 1]);
    for (var i = bestIdx + 1; i < pts.length - 1; i++) {
      remaining += NavGeo.distance(pts[i], pts[i + 1]);
    }

    return RouteProgress(
      snapped: snapped,
      segmentIndex: bestIdx,
      offRouteMeters: bestDist,
      remainingMeters: remaining,
      courseBearing: NavGeo.bearing(pts[bestIdx], pts[bestIdx + 1]),
    );
  }

  Future<void> _reroute({bool force = false}) async {
    if (_rerouting) return;

    // Never hammer the free OSRM demo server.
    final since = DateTime.now().difference(_lastReroute);
    if (!force && since < const Duration(seconds: 8)) return;

    final from = _me;
    if (from == null) return;

    _rerouting = true;
    _lastReroute = DateTime.now();
    notifyListeners();

    RouteResult? fresh;
    if (isOnline()) {
      fresh = await RoutingService.route([from, destination], mode: mode);
    }
    fresh ??= RoutingService.straightLine(from, destination, mode: mode);

    _route = fresh;
    _offRouteStrikes = 0;
    _rerouteCount++;
    _rerouting = false;
    _progress = _computeProgress(from);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
