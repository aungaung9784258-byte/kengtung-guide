import '../../core/services/market_cycle.dart' show DataConfidence;
import 'place.dart' show L10nText;

/// How hard it is to reach a village on foot.
enum TrekDifficulty {
  easy,
  moderate,
  hard;

  static TrekDifficulty parse(String? s) => switch (s) {
        'easy' => TrekDifficulty.easy,
        'hard' => TrekDifficulty.hard,
        _ => TrekDifficulty.moderate,
      };

  /// Key into AppLocalizations: 'trekEasy' | 'trekModerate' | 'trekHard'
  String get labelKey => switch (this) {
        TrekDifficulty.easy => 'trekEasy',
        TrekDifficulty.moderate => 'trekModerate',
        TrekDifficulty.hard => 'trekHard',
      };
}

/// Cultural guidance shown on the village detail screen.
class VillageEtiquette {
  const VillageEtiquette({this.doEn = const [], this.doMy = const [], this.dontEn = const [], this.dontMy = const []});

  final List<String> doEn;
  final List<String> doMy;
  final List<String> dontEn;
  final List<String> dontMy;

  bool get isEmpty => doEn.isEmpty && dontEn.isEmpty;

  List<String> dos(String lang) =>
      lang == 'my' && doMy.isNotEmpty ? doMy : doEn;

  List<String> donts(String lang) =>
      lang == 'my' && dontMy.isNotEmpty ? dontMy : dontEn;

  static List<String> _list(dynamic v) =>
      (v as List?)?.map((e) => e.toString()).toList() ?? const [];

  factory VillageEtiquette.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const VillageEtiquette();
    final d = (j['do'] as Map?)?.cast<String, dynamic>();
    final n = (j['dont'] as Map?)?.cast<String, dynamic>();
    return VillageEtiquette(
      doEn: _list(d?['en']),
      doMy: _list(d?['my']),
      dontEn: _list(n?['en']),
      dontMy: _list(n?['my']),
    );
  }
}

/// A hill-tribe village around Kengtung.
///
/// Deliberately NOT a [Place]: a Place guarantees `lat`/`lng`, and we do not
/// have coordinates for any village yet. Forcing fake coordinates in would
/// put wrong pins on the map, which is worse than no pin at all.
class Village {
  const Village({
    required this.id,
    required this.name,
    required this.peoples,
    required this.peoplesMy,
    required this.summary,
    required this.confidence,
    this.lat,
    this.lng,
    this.altitudeM,
    this.distanceKm,
    this.driveMinutes,
    this.trekMinutes,
    this.difficulty = TrekDifficulty.moderate,
    this.guideRequired = true,
    this.permitRequired = 'ask',
    this.bestSeason,
    this.images = const [],
    this.source,
    this.lastChecked,
    this.highlight,
    this.etiquette = const VillageEtiquette(),
  });

  final String id;
  final L10nText name;

  /// Ethnic groups living here, e.g. ['Akha', 'Lahu'].
  final List<String> peoples;
  final List<String> peoplesMy;

  final L10nText summary;

  /// Optional one-line "why go" note.
  final L10nText? highlight;

  final double? lat;
  final double? lng;
  final int? altitudeM;
  final double? distanceKm;
  final int? driveMinutes;
  final int? trekMinutes;

  final TrekDifficulty difficulty;
  final bool guideRequired;

  /// 'no' | 'yes' | 'ask'
  final String permitRequired;
  final String? bestSeason;
  final List<String> images;

  final DataConfidence confidence;
  final String? source;
  final String? lastChecked;
  final VillageEtiquette etiquette;

  /// False until someone stands in the village and records a GPS fix.
  /// The UI must not offer "Navigate" while this is false.
  bool get hasLocation => lat != null && lng != null;

  bool get hasPhoto => images.isNotEmpty;

  List<String> peoplesFor(String lang) =>
      lang == 'my' && peoplesMy.isNotEmpty ? peoplesMy : peoples;

  /// "45 min drive + 30 min walk" — built by the UI from these two.
  int get totalMinutes => (driveMinutes ?? 0) + (trekMinutes ?? 0);

  static List<String> _strs(dynamic v) =>
      (v as List?)?.map((e) => e.toString()).toList() ?? const [];

  factory Village.fromJson(Map<String, dynamic> j) {
    final hl = j['highlight'];
    return Village(
      id: j['id'] as String,
      name: L10nText.fromJson(j['name']),
      peoples: _strs(j['peoples']),
      peoplesMy: _strs(j['peoplesMy']),
      summary: L10nText.fromJson(j['summary']),
      highlight: hl == null ? null : L10nText.fromJson(hl),
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
      altitudeM: (j['altitude_m'] as num?)?.toInt(),
      distanceKm: (j['distance_km'] as num?)?.toDouble(),
      driveMinutes: (j['driveMinutes'] as num?)?.toInt(),
      trekMinutes: (j['trekMinutes'] as num?)?.toInt(),
      difficulty: TrekDifficulty.parse(j['difficulty'] as String?),
      guideRequired: j['guideRequired'] as bool? ?? true,
      permitRequired: j['permitRequired'] as String? ?? 'ask',
      bestSeason: j['bestSeason'] as String?,
      images: _strs(j['images']),
      confidence: DataConfidence.parse(j['confidence'] as String?),
      source: j['source'] as String?,
      lastChecked: j['lastChecked'] as String?,
      etiquette: VillageEtiquette.fromJson(
          (j['etiquette'] as Map?)?.cast<String, dynamic>()),
    );
  }
}

/// A festival or holiday with a known (or estimated) date.
class Festival {
  const Festival({
    required this.id,
    required this.name,
    required this.kind,
    required this.confidence,
    this.date,
    this.endDate,
    this.windowFrom,
    this.windowTo,
    this.source,
    this.highlight = false,
    this.description,
  });

  final String id;
  final L10nText name;

  /// 'buddhist' | 'ethnic' | 'public' | 'local'
  final String kind;

  /// Null when only a window is known (e.g. Sawbwa Market Day 2027).
  final DateTime? date;
  final DateTime? endDate;
  final DateTime? windowFrom;
  final DateTime? windowTo;

  final DataConfidence confidence;
  final String? source;
  final bool highlight;
  final L10nText? description;

  bool get hasExactDate => date != null;

  /// The day we sort and count down to: the exact date, or the start of the
  /// window when the exact date is not announced yet.
  DateTime? get anchorDate => date ?? windowFrom;

  /// Last day the event can still be happening.
  DateTime? get lastDay => endDate ?? windowTo ?? date;

  /// True if [day] falls inside this festival.
  bool isOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final s = date ?? windowFrom;
    if (s == null) return false;
    final e = lastDay ?? s;
    return !d.isBefore(DateTime(s.year, s.month, s.day)) &&
        !d.isAfter(DateTime(e.year, e.month, e.day));
  }

  /// Whole days from [from] until this starts. Negative once it has passed.
  int? daysFrom(DateTime from) {
    final a = anchorDate;
    if (a == null) return null;
    final f = DateTime(from.year, from.month, from.day);
    return DateTime(a.year, a.month, a.day).difference(f).inDays;
  }

  static DateTime? _d(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory Festival.fromJson(Map<String, dynamic> j) {
    final w = (j['window'] as Map?)?.cast<String, dynamic>();
    final desc = j['description'];
    return Festival(
      id: j['id'] as String,
      name: L10nText.fromJson(j['name']),
      kind: j['kind'] as String? ?? 'local',
      date: _d(j['date']),
      endDate: _d(j['endDate']),
      windowFrom: _d(w?['from']),
      windowTo: _d(w?['to']),
      confidence: DataConfidence.parse(j['confidence'] as String?),
      source: j['source'] as String?,
      highlight: j['highlight'] as bool? ?? false,
      description: desc == null ? null : L10nText.fromJson(desc),
    );
  }
}
