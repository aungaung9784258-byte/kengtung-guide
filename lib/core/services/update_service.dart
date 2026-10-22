import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the manifest lives. Raw GitHub is free, needs no API key and is
/// served through a CDN. It caches for a few minutes, which is fine for us.
const String kVersionManifestUrl =
    'https://raw.githubusercontent.com/aungaung9784258-byte/kengtung-guide/main/version.json';

/// Describes a release that is newer than the installed build.
@immutable
class UpdateInfo {
  const UpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.downloadUrl,
    required this.sizeMb,
    required this.mandatory,
    required this.notesEn,
    required this.notesMy,
  });

  final String versionName;
  final int versionCode;
  final String downloadUrl;
  final double sizeMb;

  /// When true the banner cannot be dismissed.
  final bool mandatory;

  final List<String> notesEn;
  final List<String> notesMy;

  List<String> notes(bool myanmar) => myanmar ? notesMy : notesEn;

  static UpdateInfo? fromJson(Map<String, dynamic> json) {
    final code = (json['versionCode'] as num?)?.toInt();
    final url = json['downloadUrl'] as String?;
    if (code == null || url == null || url.isEmpty) return null;

    List<String> notes(String key) {
      final raw = json['notes'];
      if (raw is Map && raw[key] is List) {
        return (raw[key] as List).map((e) => e.toString()).toList();
      }
      return const [];
    }

    return UpdateInfo(
      versionName: json['versionName'] as String? ?? '',
      versionCode: code,
      downloadUrl: url,
      sizeMb: (json['sizeMb'] as num?)?.toDouble() ?? 0,
      mandatory: json['mandatory'] == true,
      notesEn: notes('en'),
      notesMy: notes('my'),
    );
  }
}

/// Checks a tiny JSON manifest on GitHub and reports whether a newer build
/// exists. Fails silently: no network, bad JSON or a server hiccup simply
/// means "no update", never an error in the user's face.
class UpdateService {
  UpdateService._();

  static const _kLastCheckKey = 'update_last_check_ms';
  static const _kSkippedCodeKey = 'update_skipped_code';
  static const _kSnoozeUntilKey = 'update_snooze_until_ms';

  /// Do not hit the network more often than this.
  static const Duration minInterval = Duration(hours: 6);

  /// Returns the newer release, or null when up to date / unreachable.
  ///
  /// [force] ignores both the 6 hour throttle and a previously skipped
  /// version — use it for a "Check for updates" button in Settings.
   static Future<UpdateInfo?> check({bool force = false}) async {
    try {
      
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      if (!force) {
        final last = prefs.getInt(_kLastCheckKey) ?? 0;
        if (now - last < minInterval.inMilliseconds) {
          
          return null;
        }
      }

      final res = await http
          .get(Uri.parse(kVersionManifestUrl))
          .timeout(const Duration(seconds: 8));
      
      if (res.statusCode != 200) return null;

      await prefs.setInt(_kLastCheckKey, now);

      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        
        return null;
      }

      final info = UpdateInfo.fromJson(decoded);
      if (info == null) {
        
        return null;
      }

      final installed = await currentBuildNumber();
      
      if (info.versionCode <= installed) return null;

      if (!force && !info.mandatory) {
        final skipped = prefs.getInt(_kSkippedCodeKey) ?? 0;
        if (skipped >= info.versionCode) {
          
          return null;
        }
        final snoozeUntil = prefs.getInt(_kSnoozeUntilKey) ?? 0;
        if (now < snoozeUntil) {
          
          return null;
        }
      }

      
      return info;
    } catch (e) {
      
      return null;
    }
  }

  /// The `+N` part of `version:` in pubspec.yaml.
  static Future<int> currentBuildNumber() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  }

  /// The `1.0.0` part of `version:` in pubspec.yaml.
  static Future<String> currentVersionName() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Remember that the user does not want to be nagged about this build.
  static Future<void> skip(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSkippedCodeKey, versionCode);
  }

  /// Stay quiet for 24 hours, then offer the same build again.
  static Future<void> snoozeForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now()
        .add(const Duration(hours: 24))
        .millisecondsSinceEpoch;
    await prefs.setInt(_kSnoozeUntilKey, until);
  }

  /// Clears the throttle so the next [check] hits the network.
  static Future<void> resetThrottle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastCheckKey);
  }
}
