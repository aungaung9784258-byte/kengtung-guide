/// Web: the browser manages its own HTTP cache, so there is no directory
/// for us to measure.
Future<int> measureTileCacheBytes(String cacheKey) async => 0;
