import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/place.dart';
import '../../data/models/place_category.dart';
import '../../data/repositories/place_repository.dart';
import '../../l10n/app_localizations.dart';
import '../services/search_service.dart';

/// ---------- Settings (language + theme) ----------

class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;
  const AppSettings({required this.locale, required this.themeMode});

  AppSettings copyWith({Locale? locale, ThemeMode? themeMode}) => AppSettings(
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
      );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier()
      : super(const AppSettings(
          locale: Locale('en'), // English is the default
          themeMode: ThemeMode.system,
        )) {
    _restore();
  }

  static const _kLang = 'lang';
  static const _kTheme = 'theme';

  Future<void> _restore() async {
    final p = await SharedPreferences.getInstance();
    final lang = p.getString(_kLang) ?? 'en';
    final theme = p.getString(_kTheme) ?? 'system';
    state = AppSettings(
      locale: Locale(lang),
      themeMode: switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
    );
  }

  Future<void> setLocale(Locale l) async {
    state = state.copyWith(locale: l);
    (await SharedPreferences.getInstance()).setString(_kLang, l.languageCode);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    state = state.copyWith(themeMode: m);
    (await SharedPreferences.getInstance()).setString(_kTheme, m.name);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
        (ref) => SettingsNotifier());

/// Convenience: current language code ('en' | 'my')
final langProvider =
    Provider<String>((ref) => ref.watch(settingsProvider).locale.languageCode);

/// ---------- Places ----------

final placeRepositoryProvider = Provider((ref) => PlaceRepository());

final placesProvider = FutureProvider<List<Place>>(
    (ref) => ref.watch(placeRepositoryProvider).getAll());

/// Currently selected category filter on Home / Map (null == All)
final categoryFilterProvider = StateProvider<PlaceCategory?>((ref) => null);

/// Free-text search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// True as soon as the user has typed anything at all.
final isSearchingProvider = Provider<bool>(
    (ref) => ref.watch(searchQueryProvider).trim().isNotEmpty);

/// Localized category name, used so typing "pagoda" / "ဘုရား" finds places.
String _categoryLabel(Place p, String lang) {
  final l = AppLocalizations(Locale(lang));
  return l.t(p.category.labelKey);
}

/// Ranked keyword results. Empty list when nothing has been typed.
///
/// Unlike the old `contains()` filter this searches name (both languages),
/// tags, category, address, description and id, requires every typed word to
/// match, and returns the BEST match first.
final searchResultsProvider = Provider<List<Place>>((ref) {
  final all = ref.watch(placesProvider).value ?? const <Place>[];
  final q = ref.watch(searchQueryProvider);
  final lang = ref.watch(langProvider);
  final cat = ref.watch(categoryFilterProvider);

  final pool =
      cat == null ? all : all.where((p) => p.category == cat).toList();

  return SearchService.rank(
    pool,
    q,
    lang: lang,
    categoryLabelOf: (p) => _categoryLabel(p, lang),
  );
});

/// Places after category + search filtering.
///
/// When a query is present this is simply the ranked search result, so the
/// list on Home and the pins on the Map stay in sync with the suggestions.
final filteredPlacesProvider = Provider<List<Place>>((ref) {
  final all = ref.watch(placesProvider).value ?? const <Place>[];
  final cat = ref.watch(categoryFilterProvider);

  if (ref.watch(isSearchingProvider)) return ref.watch(searchResultsProvider);

  if (cat == null) return all;
  return all.where((p) => p.category == cat).toList();
});

/// ---------- Favourites ----------

class FavouritesNotifier extends StateNotifier<Set<String>> {
  FavouritesNotifier() : super({}) {
    _restore();
  }
  static const _key = 'favourites';

  Future<void> _restore() async {
    final p = await SharedPreferences.getInstance();
    state = (p.getStringList(_key) ?? []).toSet();
  }

  Future<void> toggle(String id) async {
    final next = {...state};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = next;
    (await SharedPreferences.getInstance())
        .setStringList(_key, next.toList());
  }

  bool isFavourite(String id) => state.contains(id);
}

final favouritesProvider =
    StateNotifierProvider<FavouritesNotifier, Set<String>>(
        (ref) => FavouritesNotifier());
