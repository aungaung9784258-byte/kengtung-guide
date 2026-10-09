import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/place.dart';

/// Phase 1: places are bundled as a local asset so the app works fully offline.
/// Phase 2: swap `_load()` for a remote fetch + local cache.
class PlaceRepository {
  List<Place>? _cache;

  Future<List<Place>> getAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/places.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Place.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }

  Future<Place?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
