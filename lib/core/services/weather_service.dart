import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Live weather for Kengtung.
///
/// Provider: **Open-Meteo** (https://open-meteo.com)
///   - completely free for non-commercial use
///   - NO API key, NO account, NO credit card
///   - ~10,000 calls/day soft limit, we use about 50
///
/// Offline-first: the last successful reading is cached in SharedPreferences
/// and shown (greyed, with a cloud-off icon) when there is no internet.
class Weather {
  const Weather({
    required this.tempC,
    required this.feelsC,
    required this.humidity,
    required this.code,
    required this.isDay,
    required this.windKmh,
    required this.fetchedAt,
    this.stale = false,
  });

  final double tempC;
  final double feelsC;
  final int humidity;
  final int code; // WMO weather interpretation code
  final bool isDay;
  final double windKmh;
  final DateTime fetchedAt;

  /// True when this came from the cache because the network failed.
  final bool stale;

  Weather copyWith({bool? stale}) => Weather(
        tempC: tempC,
        feelsC: feelsC,
        humidity: humidity,
        code: code,
        isDay: isDay,
        windKmh: windKmh,
        fetchedAt: fetchedAt,
        stale: stale ?? this.stale,
      );

  Map<String, dynamic> toJson() => {
        't': tempC,
        'f': feelsC,
        'h': humidity,
        'c': code,
        'd': isDay,
        'w': windKmh,
        'at': fetchedAt.toIso8601String(),
      };

  factory Weather.fromJson(Map<String, dynamic> j) => Weather(
        tempC: (j['t'] as num).toDouble(),
        feelsC: (j['f'] as num).toDouble(),
        humidity: (j['h'] as num).toInt(),
        code: (j['c'] as num).toInt(),
        isDay: j['d'] == true,
        windKmh: (j['w'] as num).toDouble(),
        fetchedAt: DateTime.parse(j['at'] as String),
      );

  // -------------------------------------------------------------------
  //  WMO code -> icon + label
  //  https://open-meteo.com/en/docs
  // -------------------------------------------------------------------
  IconData get icon {
    if (code == 0) return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    if (code <= 2) return isDay ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded;
    if (code == 3) return Icons.cloud_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 57) return Icons.grain_rounded;
    if (code >= 61 && code <= 67) return Icons.umbrella_rounded;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 80 && code <= 82) return Icons.water_drop_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.cloud_queue_rounded;
  }

  /// English label.
  String get labelEn {
    if (code == 0) return 'Clear';
    if (code == 1) return 'Mostly clear';
    if (code == 2) return 'Partly cloudy';
    if (code == 3) return 'Overcast';
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 51 && code <= 57) return 'Drizzle';
    if (code >= 61 && code <= 65) return 'Rain';
    if (code == 66 || code == 67) return 'Freezing rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code == 85 || code == 86) return 'Snow showers';
    if (code == 95) return 'Thunderstorm';
    if (code >= 96) return 'Thunderstorm, hail';
    return 'Cloudy';
  }

  /// Myanmar label.
  String get labelMy {
    if (code == 0) return 'ကြည်လင်';
    if (code == 1) return 'အတော်အသင့် ကြည်လင်';
    if (code == 2) return 'တိမ်အနည်းငယ်';
    if (code == 3) return 'တိမ်ထူ';
    if (code == 45 || code == 48) return 'မြူဆိုင်း';
    if (code >= 51 && code <= 57) return 'မိုးဖွဲ';
    if (code >= 61 && code <= 65) return 'မိုးရွာ';
    if (code == 66 || code == 67) return 'မိုးခဲရွာ';
    if (code >= 71 && code <= 77) return 'နှင်းကျ';
    if (code >= 80 && code <= 82) return 'မိုးသည်းထန်';
    if (code == 85 || code == 86) return 'နှင်းသည်းထန်';
    if (code == 95) return 'မိုးကြိုးပစ်';
    if (code >= 96) return 'မိုးကြိုးနှင့် မိုးသီး';
    return 'တိမ်ဖုံး';
  }
}

class WeatherService {
  WeatherService._();

  /// Kengtung town centre.
  static const double lat = 21.2913;
  static const double lng = 99.6002;

  static const _cacheKey = 'weather_cache_v1';

  static Uri get _url => Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lng'
        '&current=temperature_2m,apparent_temperature,relative_humidity_2m,'
        'weather_code,is_day,wind_speed_10m'
        '&timezone=Asia%2FYangon',
      );

  /// Fetches live weather; on any failure returns the cached reading
  /// flagged as [Weather.stale], or null if nothing was ever cached.
  static Future<Weather?> fetch() async {
    try {
            final res = await http.get(_url).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return await _cached();

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final c = body['current'] as Map<String, dynamic>;

      final w = Weather(
        tempC: (c['temperature_2m'] as num).toDouble(),
        feelsC: (c['apparent_temperature'] as num).toDouble(),
        humidity: (c['relative_humidity_2m'] as num).toInt(),
        code: (c['weather_code'] as num).toInt(),
        isDay: (c['is_day'] as num) == 1,
        windKmh: (c['wind_speed_10m'] as num).toDouble(),
        fetchedAt: DateTime.now(),
      );

      final p = await SharedPreferences.getInstance();
      await p.setString(_cacheKey, jsonEncode(w.toJson()));
      return w;
    } catch (_) {
      return _cached();
    }
  }

  static Future<Weather?> _cached() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_cacheKey);
      if (raw == null) return null;
      return Weather.fromJson(jsonDecode(raw) as Map<String, dynamic>)
          .copyWith(stale: true);
    } catch (_) {
      return null;
    }
  }
}

/// Refetches every 15 minutes while the app is open.
final weatherProvider = StreamProvider<Weather?>((ref) async* {
  yield await WeatherService.fetch();
  yield* Stream.periodic(const Duration(minutes: 15))
      .asyncMap((_) => WeatherService.fetch());
});