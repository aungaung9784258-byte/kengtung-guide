import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/models/place.dart';

/// Renders a place photo from an asset path or a URL, and falls back to a
/// tasteful category-coloured gradient + icon when no photo exists yet.
class PlaceImage extends StatelessWidget {
  const PlaceImage({
    super.key,
    required this.place,
    this.index = 0,
    this.fit = BoxFit.cover,
    this.decodeWidth = 600,
  });

  final Place place;
  final int index;
  final BoxFit fit;

  /// Decode the bitmap at roughly this width instead of its full resolution.
  ///
  /// A 1408px photo shown inside a 170px card still costs ~4 MB of RAM and a
  /// full-size decode unless we cap it here. Pass a larger value on the
  /// detail screen where the photo really is full width.
  final int decodeWidth;

  @override
  Widget build(BuildContext context) {
    if (place.images.length > index) {
      final src = place.images[index];
      if (src.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: src,
          fit: fit,
          memCacheWidth: decodeWidth,
          fadeInDuration: const Duration(milliseconds: 300),
          placeholder: (_, __) => _fallback(context),
          errorWidget: (_, __, ___) => _fallback(context),
        );
      }
      return Image.asset(
        src,
        fit: fit,
        cacheWidth: decodeWidth,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    final c = place.category.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(c.withValues(alpha: 0.85), Colors.black12),
            Color.alphaBlend(c.withValues(alpha: 0.45), Colors.black38),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          place.category.icon,
          size: 44,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}