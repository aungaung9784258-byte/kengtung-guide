import '../../data/models/place.dart';
import 'myanmar_text.dart';

/// ---------------------------------------------------------------------------
/// Keyword search + ranking.
///
/// Goals:
///   * one letter is enough to get useful suggestions
///   * searches EVERY field: name (both languages), tags, category, address,
///     description, even the id
///   * multiple words behave like AND ("shan noodle", "lake cafe")
///   * results come back RANKED, so the best match is first instead of
///     whatever order places.json happens to be in
/// ---------------------------------------------------------------------------
class SearchService {
  SearchService._();

  // --- Myanmar script normalisation ----------------------------------------
  //
  // All of the hard work lives in MyanmarText. Briefly:
  //   * Zawgyi text gets converted to Unicode
  //   * left-rendering vowels (ေ ြ) typed before their consonant get moved
  //     back where Unicode stores them
  // Without this, "ဈေး" typed on a phone never matches "ဈေး" in places.json
  // even though the two are pixel-identical on screen.

  /// Consonant skeleton, used for the relaxed fallback pass.
  static String skeleton(String s) => MyanmarText.skeleton(s);

  /// Lowercase, repair Myanmar encoding + ordering, collapse whitespace.
  static String normalize(String s) => MyanmarText.canonical(s.toLowerCase())
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static List<String> terms(String query) => normalize(query)
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList(growable: false);

  /// How well a single haystack matches a single term.
  /// 0 = no match. Higher = better.
  static int _fieldScore(String haystack, String term, int weight) {
    if (haystack.isEmpty) return 0;
    final h = normalize(haystack);

    if (h == term) return weight * 4; // exact field
    if (h.startsWith(term)) return weight * 3; // "nau" -> "Naung Tung Lake"

    // Start of any word: "tung" -> "Naung Tung Lake"
    for (final w in h.split(' ')) {
      if (w.startsWith(term)) return weight * 2;
    }

    if (h.contains(term)) return weight; // anywhere
    return 0;
  }

  /// Total score for one place against one term, across all its fields.
  static int _termScore(Place p, String term, String lang, String categoryLabel) {
    var best = 0;

    void take(int v) {
      if (v > best) best = v;
    }

    // Name in the language on screen matters most.
    take(_fieldScore(p.name(lang), term, 100));
    take(_fieldScore(p.name.en, term, 80));
    take(_fieldScore(p.name.my, term, 80));

    for (final tag in p.tags) {
      take(_fieldScore(tag, term, 60));
    }

    take(_fieldScore(categoryLabel, term, 45));
    take(_fieldScore(p.category.id, term, 40));
    take(_fieldScore(p.address(lang), term, 25));
    take(_fieldScore(p.address.en, term, 20));
    take(_fieldScore(p.description(lang), term, 10));
    take(_fieldScore(p.description.en, term, 8));
    take(_fieldScore(p.id.replaceAll('-', ' '), term, 30));

    return best;
  }

  /// Rank [all] against [query]. Empty query returns an empty list — the
  /// caller decides what to show when nothing has been typed.
  ///
  /// [categoryLabelOf] lets the caller pass the localized category name
  /// ("Pagodas" / "ဘုရားများ") so typing a category also works.
  static List<Place> rank(
    List<Place> all,
    String query, {
    required String lang,
    required String Function(Place) categoryLabelOf,
    int limit = 50,
  }) {
    final ts = terms(query);
    if (ts.isEmpty) return const [];

    final scored = <(Place, int)>[];

    for (final p in all) {
      final label = categoryLabelOf(p);
      var total = 0;
      var matchedAll = true;

      for (final term in ts) {
        final s = _termScore(p, term, lang, label);
        if (s == 0) {
          matchedAll = false;
          break;
        }
        total += s;
      }

      if (!matchedAll) continue;

      // Nudge well-rated places up when scores tie.
      total = total * 10 + ((p.rating ?? 0) * 2).round();
      scored.add((p, total));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));

    if (scored.isNotEmpty) {
      return scored.take(limit).map((e) => e.$1).toList();
    }

    // Nothing matched exactly. Retry on the consonant skeleton so a missing
    // or extra tone mark does not produce an empty screen.
    return _relaxed(all, ts, lang, categoryLabelOf, limit);
  }

  static List<Place> _relaxed(
    List<Place> all,
    List<String> ts,
    String lang,
    String Function(Place) categoryLabelOf,
    int limit,
  ) {
    final skeletons = ts.map(skeleton).where((e) => e.isNotEmpty).toList();
    if (skeletons.isEmpty) return const [];

    final out = <Place>[];
    for (final p in all) {
      final hay = skeleton(normalize([
        p.name(lang),
        p.name.en,
        p.name.my,
        categoryLabelOf(p),
        p.tags.join(' '),
        p.address(lang),
      ].join(' ')));

      if (skeletons.every(hay.contains)) out.add(p);
      if (out.length >= limit) break;
    }
    return out;
  }

  /// Index of the first term inside [text], for highlighting the matched
  /// part in the suggestion list. Returns (start, end) or null.
  static (int, int)? highlightRange(String text, String query) {
    final ts = terms(query);
    if (ts.isEmpty) return null;
    final h = normalize(text);

    for (final term in ts) {
      final i = h.indexOf(term);
      // The normalized string can be shorter than the original; only use the
      // range when the lengths still line up, otherwise skip highlighting
      // rather than slice the wrong characters.
      if (i >= 0 && h.length == text.length) return (i, i + term.length);
    }
    return null;
  }
}
