import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../core/services/offline_map_service.dart';

/// Serves map tiles from the on-device cache first, falling back to the
/// network. This is what makes the map work offline — and it also means any
/// area the user browses while online is silently saved for later.
///
/// On web we fall back to the normal network provider, because the browser
/// manages its own HTTP cache.
class CachedTileProvider extends TileProvider {
  CachedTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    if (kIsWeb) return NetworkImage(url);
    return CachedNetworkImageProvider(
      url,
      cacheManager: OfflineMapService.tileCache,
      headers: const {'User-Agent': OfflineMapService.userAgent},
    );
  }
}
