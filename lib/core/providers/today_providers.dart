import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/village.dart';
import '../../data/repositories/guide_repository.dart';
import '../services/market_cycle.dart';

/// Providers for the Today tab and the Villages screens.
///
/// Kept in their own file so `app_providers.dart` never has to be touched.

final guideRepositoryProvider = Provider((ref) => GuideRepository());

/// ---------- Villages ----------

final villagesProvider = FutureProvider<List<Village>>(
    (ref) => ref.watch(guideRepositoryProvider).villages());

final villagePeoplesProvider = FutureProvider<List<String>>(
    (ref) => ref.watch(guideRepositoryProvider).peoples());

/// Selected ethnic-group filter chip on the Villages list (null == All).
final villageFilterProvider = StateProvider<String?>((ref) => null);

/// Villages after the ethnic-group filter, easiest first.
final filteredVillagesProvider = Provider<List<Village>>((ref) {
  final all = ref.watch(villagesProvider).value ?? const <Village>[];
  final filter = ref.watch(villageFilterProvider);

  final list = filter == null
      ? [...all]
      : all.where((v) => v.peoples.contains(filter)).toList();

  list.sort((a, b) {
    final d = a.difficulty.index.compareTo(b.difficulty.index);
    if (d != 0) return d;
    return a.totalMinutes.compareTo(b.totalMinutes);
  });
  return list;
});

final villageByIdProvider =
    Provider.family<Village?, String>((ref, id) {
  for (final v in ref.watch(villagesProvider).value ?? const <Village>[]) {
    if (v.id == id) return v;
  }
  return null;
});

/// ---------- Festivals ----------

final festivalsProvider = FutureProvider<List<Festival>>(
    (ref) => ref.watch(guideRepositoryProvider).festivals());

/// Festivals happening today (usually none, sometimes one).
final festivalsTodayProvider = Provider<List<Festival>>((ref) {
  final all = ref.watch(festivalsProvider).value ?? const <Festival>[];
  final now = DateTime.now();
  return all.where((f) => f.isOn(now)).toList();
});

/// The next few festivals still ahead of us, soonest first.
final upcomingFestivalsProvider =
    Provider.family<List<Festival>, int>((ref, count) {
  final all = ref.watch(festivalsProvider).value ?? const <Festival>[];
  final now = DateTime.now();
  final ahead = all.where((f) {
    final last = f.lastDay ?? f.anchorDate;
    if (last == null) return false;
    return !DateTime(last.year, last.month, last.day)
        .isBefore(DateTime(now.year, now.month, now.day));
  }).toList();
  return ahead.take(count).toList();
});

/// ---------- Market cycle ----------

final marketCycleProvider = FutureProvider<MarketCycle>(
    (ref) => ref.watch(guideRepositoryProvider).markets());

/// Today's market in the five-day rotation, or null while loading.
final todayMarketProvider = Provider<MarketSlot?>(
    (ref) => ref.watch(marketCycleProvider).value?.today);

/// The next five days of the rotation, starting today.
final upcomingMarketsProvider = Provider<List<MarketDay>>(
    (ref) => ref.watch(marketCycleProvider).value?.upcoming(count: 5) ?? const []);
