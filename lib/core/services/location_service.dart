import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static const kengtungCenter = LatLng(21.2913, 99.6002);

  /// Returns the device position, or null if permission is denied / unavailable.
  static Future<LatLng?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

  final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Live position stream for "follow me" mode.
  static Stream<LatLng> stream() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).map((p) => LatLng(p.latitude, p.longitude));

  static double distanceKm(LatLng a, LatLng b) =>
      const Distance().as(LengthUnit.Kilometer, a, b);
}
