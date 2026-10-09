import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum TravelMode { walk, bike, drive }

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  /// True when this is an offline straight-line estimate rather than a real
  /// road route.
  final bool approximate;

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.approximate = false,
  });

  String get distanceLabel => distanceMeters < 1000
      ? '${distanceMeters.round()} m'
      : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

  String get durationLabel {
    final m = (durationSeconds / 60).round();
    if (m < 60) return '$m min';
    return '${m ~/ 60} h ${m % 60} min';
  }
}

/// Free routing via the public OSRM demo server — no API key, no billing.
///
/// NOTE: the demo server is rate-limited and not guaranteed for production.
/// For launch, either self-host OSRM (free, a small VPS is enough for one
/// township) or switch `_host` to another free OSRM mirror.
class RoutingService {
  static const _host = 'https://router.project-osrm.org';

  static String _profile(TravelMode m) => switch (m) {
        TravelMode.walk => 'foot',
        TravelMode.bike => 'bike',
        TravelMode.drive => 'driving',
      };

  /// Supports multiple waypoints: [start, stop1, stop2, ..., end].
  static Future<RouteResult?> route(
    List<LatLng> waypoints, {
    TravelMode mode = TravelMode.drive,
  }) async {
    if (waypoints.length < 2) return null;

    final coords =
        waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
    final uri = Uri.parse(
        '$_host/route/v1/${_profile(mode)}/$coords?overview=full&geometries=geojson');

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final r = routes.first as Map<String, dynamic>;
      final coordsList =
          (r['geometry']['coordinates'] as List).cast<List>();

      return RouteResult(
        points: coordsList
            .map((c) => LatLng(
                  (c[1] as num).toDouble(),
                  (c[0] as num).toDouble(),
                ))
            .toList(),
        distanceMeters: (r['distance'] as num).toDouble(),
        durationSeconds: (r['duration'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Offline fallback: a direct line between two points with straight-line
  /// distance and a rough time estimate. GPS needs no internet, so the user
  /// still sees where they are and which direction to head.
  static RouteResult straightLine(
    LatLng from,
    LatLng to, {
    TravelMode mode = TravelMode.drive,
  }) {
    final meters = const Distance().as(LengthUnit.Meter, from, to);

    // Average speeds in m/s, deliberately conservative for hill roads.
    final speed = switch (mode) {
      TravelMode.walk => 1.25,
      TravelMode.bike => 3.6,
      TravelMode.drive => 8.0,
    };

    return RouteResult(
      points: [from, to],
      distanceMeters: meters,
      durationSeconds: meters / speed,
      approximate: true,
    );
  }
}
