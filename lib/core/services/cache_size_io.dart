import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Mobile / desktop: sum the size of every cached tile file on disk.
Future<int> measureTileCacheBytes(String cacheKey) async {
  try {
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/$cacheKey');
    if (!await dir.exists()) return 0;

    var total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  } catch (_) {
    return 0;
  }
}
