/// Five-day rotating market cycle of Kengtung Township.
///
/// Markets in the Shan hills do not open every day in one place: each village
/// takes a turn, and the turn comes round every fifth day. Knowing *which*
/// market is on today is the single most useful thing a visitor can be told,
/// and no general map app will ever tell them.
///
/// The whole thing is arithmetic from one verified anchor date, so it works
/// offline forever and needs no API, no notification server and no updates.
///
/// This file is standalone: it imports nothing but `dart:core` and touches no
/// existing code.
library;

/// How sure we are about a piece of data. Shown to the user as a badge —
/// hiding a gap is worse than admitting it.
enum DataConfidence {
  /// Official source or government calendar.
  verified,

  /// Guidebook or tour operator. Probably right, worth checking locally.
  estimated,

  /// Placeholder waiting for the field survey.
  unverified;

  static DataConfidence parse(String? s) => switch (s) {
        'verified' => DataConfidence.verified,
        'estimated' => DataConfidence.estimated,
        _ => DataConfidence.unverified,
      };

  bool get isKnown => this != DataConfidence.unverified;
}

/// One slot of the rotating cycle.
class MarketSlot {
  const MarketSlot({
    required this.slot,
    required this.nameEn,
    required this.nameMy,
    required this.confidence,
    this.id,
    this.lat,
    this.lng,
    this.openHours,
    this.source,
    this.descriptionEn,
    this.descriptionMy,
  });

  final int slot;
  final String? id;
  final String nameEn;
  final String nameMy;
  final double? lat;
  final double? lng;
  final String? openHours;
  final DataConfidence confidence;
  final String? source;
  final String? descriptionEn;
  final String? descriptionMy;

  /// True once the survey has given this slot a real place.
  bool get hasLocation => lat != null && lng != null;

  String name(String lang) => lang == 'my' ? nameMy : nameEn;

  String? description(String lang) =>
      lang == 'my' ? (descriptionMy ?? descriptionEn) : descriptionEn;

  factory MarketSlot.fromJson(Map<String, dynamic> j) {
    final name = (j['name'] as Map?)?.cast<String, dynamic>() ?? const {};
    final desc = (j['description'] as Map?)?.cast<String, dynamic>();
    return MarketSlot(
      slot: (j['slot'] as num).toInt(),
      id: j['id'] as String?,
      nameEn: (name['en'] as String?) ?? 'Market',
      nameMy: (name['my'] as String?) ?? (name['en'] as String?) ?? 'ဈေး',
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
      openHours: j['openHours'] as String?,
      confidence: DataConfidence.parse(j['confidence'] as String?),
      source: j['source'] as String?,
      descriptionEn: desc?['en'] as String?,
      descriptionMy: desc?['my'] as String?,
    );
  }
}

/// A market happening on a particular day.
class MarketDay {
  const MarketDay({required this.date, required this.market});
  final DateTime date;
  final MarketSlot market;
}

/// The cycle itself, built from `assets/data/markets.json`.
class MarketCycle {
  const MarketCycle({
    required this.cycleLength,
    required this.anchor,
    required this.anchorSlot,
    required this.slots,
    this.permanent = const [],
  });

  final int cycleLength;

  /// A date on which [anchorSlot] was held. Everything else follows from this.
  final DateTime anchor;
  final int anchorSlot;
  final List<MarketSlot> slots;

  /// Markets that do not rotate (the central market, the buffalo market).
  final List<MarketSlot> permanent;

  factory MarketCycle.fromJson(Map<String, dynamic> j) {
    final raw = (j['slots'] as List?) ?? const [];
    final perm = (j['permanent'] as List?) ?? const [];
    return MarketCycle(
      cycleLength: (j['cycleLength'] as num?)?.toInt() ?? 5,
      anchor: _dayOf(DateTime.parse(j['anchorDate'] as String)),
      anchorSlot: (j['anchorSlot'] as num?)?.toInt() ?? 0,
      slots: [
        for (final s in raw) MarketSlot.fromJson((s as Map).cast<String, dynamic>())
      ]..sort((a, b) => a.slot.compareTo(b.slot)),
      permanent: [
        for (var i = 0; i < perm.length; i++)
          MarketSlot.fromJson({
            'slot': -1 - i,
            ...(perm[i] as Map).cast<String, dynamic>(),
          })
      ],
    );
  }

  /// Midnight local time — the cycle is a whole-day thing, so the clock part
  /// of a DateTime must never leak into the arithmetic.
  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Which slot of the cycle [date] falls on.
  int slotOn(DateTime date) {
    final days = _dayOf(date).difference(anchor).inDays;
    return ((days + anchorSlot) % cycleLength + cycleLength) % cycleLength;
  }

  /// The market held on [date]. Never null — an unsurveyed slot still returns
  /// its placeholder so the UI can show "we don't know this one yet".
  MarketSlot marketOn(DateTime date) {
    final i = slotOn(date);
    return slots.firstWhere((s) => s.slot == i, orElse: () => slots.first);
  }

  /// Today's market.
  MarketSlot get today => marketOn(DateTime.now());

  /// The next [count] days, starting with [from] (default today).
  List<MarketDay> upcoming({int count = 5, DateTime? from}) {
    final start = _dayOf(from ?? DateTime.now());
    return [
      for (var i = 0; i < count; i++)
        MarketDay(
          date: start.add(Duration(days: i)),
          market: marketOn(start.add(Duration(days: i))),
        ),
    ];
  }

  /// The next date on which [slot] comes round, counting [from] itself.
  DateTime nextDateForSlot(int slot, {DateTime? from}) {
    final start = _dayOf(from ?? DateTime.now());
    for (var i = 0; i < cycleLength; i++) {
      final d = start.add(Duration(days: i));
      if (slotOn(d) == slot) return d;
    }
    return start; // unreachable while cycleLength > 0
  }

  /// Whole days until [slot] next comes round. 0 means today.
  int daysUntilSlot(int slot, {DateTime? from}) =>
      nextDateForSlot(slot, from: from)
          .difference(_dayOf(from ?? DateTime.now()))
          .inDays;
}
