import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:latlong2/latlong.dart';

// dart:io is unavailable on web, so disk measurement lives behind a
// conditional import.
import 'cache_size_stub.dart'
    if (dart.library.io) 'cache_size_io.dart';

/// A rectangular area of the map that the user can download for offline use.
class OfflineRegion {
  final String id;
  final String nameEn;
  final String nameMy;
  final double south, north, west, east;
  final int minZoom, maxZoom;

  const OfflineRegion({
    required this.id,
    required this.nameEn,
    required this.nameMy,
    required this.south,
    required this.north,
    required this.west,
    required this.east,
    required this.minZoom,
    required this.maxZoom,
  });

  /// Kengtung town centre — small, fast, covers everything a visitor walks to.
  static const town = OfflineRegion(
    id: 'town',
    nameEn: 'Kengtung town',
    nameMy: 'ကျိုင်းတုံမြို့',
    south: 21.25,
    north: 21.33,
    west: 99.56,
    east: 99.65,
    minZoom: 11,
    maxZoom: 17, // ~1,460 tiles, ~26 MB
  );

  /// Town + Loi Mwe + the main roads out of the valley.
  static const wide = OfflineRegion(
    id: 'wide',
    nameEn: 'Kengtung + surroundings',
    nameMy: 'ကျိုင်းတုံနှင့် ပတ်ဝန်းကျင်',
    south: 21.00,
    north: 21.36,
    west: 99.50,
    east: 99.72,
    minZoom: 11,
    maxZoom: 16, // ~3,950 tiles, ~70 MB
  );

  static const all = [town, wide];

  String name(String lang) => lang == 'my' ? nameMy : nameEn;

  LatLngBounds get bounds =>
      LatLngBounds(south: south, north: north, west: west, east: east);
}

class LatLngBounds {
  final double south, north, west, east;
  const LatLngBounds({
    required this.south,
    required this.north,
    required this.west,
    required this.east,
  });
  LatLng get center => LatLng((south + north) / 2, (west + east) / 2);
}

/// Progress of a region download.
class DownloadProgress {
  final int done;
  final int total;
  final bool finished;
  final String? error;

  const DownloadProgress({
    required this.done,
    required this.total,
    this.finished = false,
    this.error,
  });

  double get fraction => total == 0 ? 0 : done / total;
  int get percent => (fraction * 100).round();
}

/// Downloads and stores OpenStreetMap tiles on the device so the map keeps
/// working with no connection.
///
/// IMPORTANT — tile source policy:
/// The public OSM tile servers forbid bulk downloading. The region sizes here
/// are deliberately small and the downloader is rate-limited to stay polite,
/// which is fine for development and a handful of users. **Before you publish
/// to the stores**, point [tileUrlTemplate] at your own tile source:
///   * a self-hosted Protomaps `.pmtiles` file (one small file, free), or
///   * a self-hosted OSM tile server, or
///   * OpenFreeMap / another provider that permits caching.
/// Everything else in this class stays the same.
class OfflineMapService {
  OfflineMapService._();

  static const tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const userAgent = 'KengtungGuide/0.1 (community travel app)';

  /// Dedicated cache store so clearing offline maps doesn't wipe place photos.
  static final CacheManager tileCache = CacheManager(
    Config(
      cacheKey,
      stalePeriod: const Duration(days: 365), // map geometry changes slowly
      maxNrOfCacheObjects: 20000,
    ),
  );

  // ---------- tile maths (Web Mercator / slippy map) ----------

  static int lonToX(double lon, int z) =>
      ((lon + 180.0) / 360.0 * (1 << z)).floor();

  static int latToY(double lat, int z) {
    final r = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) /
            2.0 *
            (1 << z))
        .floor();
  }

  /// Every tile URL inside a region, across its zoom range.
  static List<String> tileUrls(OfflineRegion r) {
    final urls = <String>[];
    for (var z = r.minZoom; z <= r.maxZoom; z++) {
      final x1 = lonToX(r.west, z);
      final x2 = lonToX(r.east, z);
      final y1 = latToY(r.north, z); // north = smaller y
      final y2 = latToY(r.south, z);
      for (var x = math.min(x1, x2); x <= math.max(x1, x2); x++) {
        for (var y = math.min(y1, y2); y <= math.max(y1, y2); y++) {
          urls.add(tileUrlTemplate
              .replaceFirst('{z}', '$z')
              .replaceFirst('{x}', '$x')
              .replaceFirst('{y}', '$y'));
        }
      }
    }
    return urls;
  }

  static int tileCount(OfflineRegion r) => tileUrls(r).length;

  /// Rough size estimate — an OSM PNG tile averages ~18 KB.
  static String estimatedSize(OfflineRegion r) {
    final mb = tileCount(r) * 18 / 1024;
    return '${mb.toStringAsFixed(0)} MB';
  }

  // ---------- download ----------

  static bool _cancelled = false;
  static void cancel() => _cancelled = true;

  /// Downloads every tile in [region], emitting progress as it goes.
  ///
  /// Concurrency is capped at 4 with a small delay between batches so we
  /// never hammer the tile server.
  static Stream<DownloadProgress> download(OfflineRegion region) async* {
    _cancelled = false;
    final urls = tileUrls(region);
    final total = urls.length;
    var done = 0;

    yield DownloadProgress(done: 0, total: total);

    const batchSize = 4;
    for (var i = 0; i < urls.length; i += batchSize) {
      if (_cancelled) {
        yield DownloadProgress(done: done, total: total, finished: true);
        return;
      }

      final batch = urls.skip(i).take(batchSize);
      await Future.wait(batch.map((url) async {
        try {
          await tileCache.downloadFile(
            url,
            authHeaders: const {'User-Agent': userAgent},
          );
        } catch (_) {
          // A missing tile must not abort the whole region.
        }
        done++;
      }));

      yield DownloadProgress(done: done, total: total);
      await Future.delayed(const Duration(milliseconds: 120)); // be polite
    }

    yield DownloadProgress(done: done, total: total, finished: true);
  }

  // ---------- inspect / clear ----------

  static const cacheKey = 'kengtung_map_tiles';

  /// Bytes currently used by cached tiles (0 on web).
  static Future<int> cacheSizeBytes() => measureTileCacheBytes(cacheKey);

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    if (mb < 1) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  static Future<void> clear() => tileCache.emptyCache();
}
