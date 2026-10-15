import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/services/market_cycle.dart';
import '../models/village.dart';

/// Loads the bundled "living guide" data: villages, festivals and the
/// five-day market cycle.
///
/// Separate from PlaceRepository on purpose — nothing here touches places.json
/// and nothing here can break the existing Home / Map screens.
class GuideRepository {
  List<Village>? _villages;
  List<Festival>? _festivals;
  MarketCycle? _markets;

  Future<List<Village>> villages() async {
    if (_villages != null) return _villages!;
    final raw = await rootBundle.loadString('assets/data/villages.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return _villages = list.map(Village.fromJson).toList();
  }

  Future<List<Village>> _villagesOrEmpty() async {
    try {
      return await villages();
    } catch (_) {
      return const [];
    }
  }

  Future<Village?> villageById(String id) async {
    for (final v in await _villagesOrEmpty()) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Every ethnic group mentioned by at least one village, de-duplicated and
  /// sorted — used to build the filter chips without hard-coding a list.
  Future<List<String>> peoples() async {
    final set = <String>{};
    for (final v in await _villagesOrEmpty()) {
      set.addAll(v.peoples);
    }
    final out = set.toList()..sort();
    return out;
  }

  Future<List<Festival>> festivals() async {
    if (_festivals != null) return _festivals!;
    final raw = await rootBundle.loadString('assets/data/festivals.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final out = list.map(Festival.fromJson).toList()
      ..sort((a, b) {
        final x = a.anchorDate, y = b.anchorDate;
        if (x == null && y == null) return 0;
        if (x == null) return 1;
        if (y == null) return -1;
        return x.compareTo(y);
      });
    return _festivals = out;
  }

  Future<MarketCycle> markets() async {
    if (_markets != null) return _markets!;
    final raw = await rootBundle.loadString('assets/data/markets.json');
    return _markets =
        MarketCycle.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
