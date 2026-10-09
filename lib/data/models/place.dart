import 'package:latlong2/latlong.dart';
import 'place_category.dart';

/// A bilingual string: { "en": "...", "my": "..." }
class L10nText {
  final String en;
  final String my;
  const L10nText({required this.en, required this.my});

  factory L10nText.fromJson(dynamic json) {
    if (json == null) return const L10nText(en: '', my: '');
    if (json is String) return L10nText(en: json, my: json);
    return L10nText(
      en: json['en'] as String? ?? '',
      my: json['my'] as String? ?? json['en'] as String? ?? '',
    );
  }

  /// Falls back to English when the Myanmar text is missing.
  String call(String langCode) =>
      langCode == 'my' && my.trim().isNotEmpty ? my : en;
}

class Place {
  final String id;
  final L10nText name;
  final PlaceCategory category;
  final L10nText description;
  final L10nText address;
  final double lat;
  final double lng;
  final String? phone;
  final String? openHours;
  final List<String> images;
  final double? rating;
  final List<String> tags;

  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.lat,
    required this.lng,
    this.phone,
    this.openHours,
    this.images = const [],
    this.rating,
    this.tags = const [],
  });

  LatLng get latLng => LatLng(lat, lng);

  bool get isEmergency => category == PlaceCategory.emergency;

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: j['id'] as String,
        name: L10nText.fromJson(j['name']),
        category: PlaceCategory.fromId(j['category'] as String? ?? 'place'),
        description: L10nText.fromJson(j['description']),
        address: L10nText.fromJson(j['address']),
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        phone: j['phone'] as String?,
        openHours: j['openHours'] as String?,
        images: (j['images'] as List?)?.cast<String>() ?? const [],
        rating: (j['rating'] as num?)?.toDouble(),
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
      );
}
