/// ---------------------------------------------------------------------------
/// Myanmar text utilities.
///
/// Three separate problems get solved here. They are often confused with each
/// other, so it is worth being precise:
///
///   1. ENCODING  — Zawgyi vs Unicode. Two fonts that use the SAME codepoints
///      for DIFFERENT letters. "မြန်မာ" in Zawgyi bytes is gibberish to a
///      Unicode renderer. Fixed by [zawgyiToUnicode].
///
///   2. ORDER     — Unicode stores ဈေး as ဈ+ေ+း, but most keyboards emit the
///      left-rendering vowel FIRST because that is where the user sees it.
///      Both look identical on screen; the bytes differ. Fixed by
///      [reorder]. This is the one that broke the search box.
///
///   3. RENDERING — an old or Zawgyi-only system font draws stacked
///      diacritics on top of each other. Fixed by BUNDLING Padauk
///      (see pubspec.yaml + AppTheme.myanmarFallback), not by any code here.
/// ---------------------------------------------------------------------------
library;

class MyanmarText {
  MyanmarText._();

  // ===========================================================================
  // 1. Zawgyi detection
  // ===========================================================================

  /// Codepoints that Zawgyi reassigned for glyph shaping and that effectively
  /// never occur in ordinary Burmese Unicode text.
  ///
  /// NOTE on what is deliberately NOT in this set:
  ///
  ///   * No "shape" heuristic. The obvious one — a vowel sign followed by a
  ///     consonant — is perfectly legal Unicode: "နောင်တုံကန်" contains
  ///     U+103A followed by U+1000. Testing that rule against places.json
  ///     flagged 60 of 60 valid strings as Zawgyi. Converting them would have
  ///     destroyed every Myanmar name in the app.
  ///
  ///   * U+1090-U+1099 are Shan digits in Unicode. This is a guide to a town
  ///     in Shan State, so they are excluded even though Zawgyi reuses two of
  ///     them.
  ///
  /// Detection is therefore evidence-only: no evidence means leave it alone.
  static final _zawgyiOnly = RegExp(
    r'[\u1033\u1034\u1035\u105A\u1060-\u1069\u106C\u106D'
    r'\u1070-\u108F\u1094-\u1097]',
  );

  /// True when [s] contains a codepoint that only Zawgyi uses.
  ///
  /// Conservative on purpose: converting valid Unicode "just in case" would
  /// corrupt it, which is far worse than leaving rare Zawgyi untouched.
  static bool isZawgyi(String s) {
    if (s.isEmpty || !hasMyanmar(s)) return false;
    return _zawgyiOnly.hasMatch(s);
  }

  static final _myanmarBlock = RegExp(r'[\u1000-\u109F]');
  static bool hasMyanmar(String s) => _myanmarBlock.hasMatch(s);

  // ===========================================================================
  // 2. Zawgyi -> Unicode
  // ===========================================================================

  /// Ordered rewrite rules. Order matters: each one assumes the previous
  /// ones have already run. Derived from the public Rabbit / SIL mapping.
  static final List<(RegExp, String)> _z2u = [
    // --- codepoints Zawgyi reassigned -------------------------------------
    (RegExp(r'\u106A'), '\u1009'), // ဪ-form ja
    (RegExp(r'\u106B'), '\u100A'),
    (RegExp(r'\u1064'), '\u1004\u103A\u1039'), // kinzi
    (RegExp(r'\u108B'), '\u1004\u103A\u1039\u102D'),
    (RegExp(r'\u108C'), '\u1004\u103A\u1039\u102E'),
    (RegExp(r'\u108D'), '\u1004\u103A\u1039\u1036'),
    (RegExp(r'\u108E'), '\u102D\u1036'),
    (RegExp(r'\u108F'), '\u1014'),
    (RegExp(r'\u1090'), '\u101B'),
    (RegExp(r'\u1091'), '\u100F\u1039\u1091'),
    (RegExp(r'\u1019\u102C(?=\u1039)'), '\u1019\u102C'),
    (RegExp(r'\u1025(?=\u1039)'), '\u1009'),
    (RegExp(r'\u1025\u102E'), '\u1026'),
    (RegExp(r'\u1037\u1032'), '\u1032\u1037'),

    // --- medials ----------------------------------------------------------
    (RegExp(r'[\u103D\u1087]'), '\u103E'), // ha-htoe
    (RegExp(r'\u103C'), '\u103D'), // wa-swe
    (RegExp(r'[\u103B\u107E-\u1084]'), '\u103C'), // ya-yit (all widths)
    (RegExp(r'[\u103A\u107D]'), '\u103B'), // ya-pin
    (RegExp(r'\u103F'), '\u1065'),

    // --- consonants Zawgyi duplicated for shaping -------------------------
    (RegExp(r'[\u1060]'), '\u1039\u1000'),
    (RegExp(r'[\u1061]'), '\u1039\u1001'),
    (RegExp(r'[\u1062]'), '\u1039\u1002'),
    (RegExp(r'[\u1063]'), '\u1039\u1003'),
    (RegExp(r'[\u1065]'), '\u1039\u1005'),
    (RegExp(r'[\u1066\u1067]'), '\u1039\u1006'),
    (RegExp(r'[\u1068\u1069]'), '\u1039\u1007'),
    (RegExp(r'[\u106C\u106D]'), '\u1039\u100A'),
    (RegExp(r'[\u106E\u106F]'), '\u100D\u1039\u100D'),
    (RegExp(r'[\u1070]'), '\u1039\u100B'),
    (RegExp(r'[\u1071\u1072]'), '\u1039\u100C'),
    (RegExp(r'[\u1073\u1074]'), '\u1039\u100D'),
    (RegExp(r'[\u1075]'), '\u1039\u100E'),
    (RegExp(r'[\u1076]'), '\u1039\u100F'),
    (RegExp(r'[\u1077\u1078]'), '\u1039\u1010'),
    (RegExp(r'[\u1079\u107A]'), '\u1039\u1011'),
    (RegExp(r'[\u107B]'), '\u1039\u1012'),
    (RegExp(r'[\u107C]'), '\u1039\u1013'),
    (RegExp(r'[\u1085]'), '\u1039\u1018'),
    (RegExp(r'[\u1086]'), '\u103F'),
    (RegExp(r'[\u1088]'), '\u103E\u102F'),
    (RegExp(r'[\u1089]'), '\u103E\u1030'),
    (RegExp(r'[\u108A]'), '\u103D\u103E'),

    // --- vowels / tone marks ---------------------------------------------
    (RegExp(r'[\u1033]'), '\u102F'),
    (RegExp(r'[\u1034]'), '\u1030'),
    (RegExp(r'[\u1035]'), '\u102F'),
    (RegExp(r'[\u1095]'), '\u103E\u1037'),
    (RegExp(r'[\u1094\u1096]'), '\u1037'),
    (RegExp(r'[\u1092]'), '\u100B\u1039\u100C'),
    (RegExp(r'[\u1097]'), '\u100B\u1039\u100B'),
  ];

  /// Best-effort Zawgyi -> Unicode conversion.
  ///
  /// Returns [s] unchanged when it does not look like Zawgyi, so it is safe
  /// to call on anything.
  static String zawgyiToUnicode(String s) {
    if (!isZawgyi(s)) return s;
    var out = s;
    for (final (re, to) in _z2u) {
      out = out.replaceAll(re, to);
    }
    return reorder(out);
  }

  // ===========================================================================
  // 3. Storage-order repair (the search-box fix)
  // ===========================================================================

  static const _base = r'\u1000-\u102A\u103F\u104E';

  /// U+1031 ( ေ ) and U+103C ( ြ ) render to the LEFT of their base, so
  /// keyboards emit them first. Unicode stores them after.
  static final _prefix = RegExp('([\u1031\u103C]+)([$_base])');

  /// Canonical order for the signs that follow a base consonant, so that
  /// e.g. ု + ိ and ိ + ု compare equal.
  static final _dotBelowBeforeVowel =
      RegExp('([\u1037])([\u102F\u1030\u102D\u102E\u1032])');

  /// Moves left-rendering signs behind their base and fixes the two orderings
  /// users most often get wrong. Idempotent and safe on already-correct text.
  static String reorder(String s) {
    if (!s.contains('\u1031') &&
        !s.contains('\u103C') &&
        !s.contains('\u1037')) {
      return s;
    }
    var out = s;
    for (var i = 0; i < 4; i++) {
      final next = out
          .replaceAllMapped(_prefix, (m) => '${m[2]}${m[1]}')
          .replaceAllMapped(_dotBelowBeforeVowel, (m) => '${m[2]}${m[1]}');
      if (next == out) break;
      out = next;
    }
    return out;
  }

  /// One call that makes any Myanmar input comparable: strip zero-width
  /// joiners, convert Zawgyi if present, then repair the order.
  static String canonical(String s) {
    final clean = s.replaceAll('\u200b', '').replaceAll('\u200c', '');
    return reorder(zawgyiToUnicode(clean));
  }

  /// Consonant skeleton — every vowel sign, medial, tone mark and virama
  /// removed. Used as a relaxed last-resort match in search.
  static String skeleton(String s) =>
      s.replaceAll(RegExp(r'[\u102B-\u103E\u1039\u103A]'), '');
}
