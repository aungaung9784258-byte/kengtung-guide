import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits true when the device has some kind of network connection.
///
/// Note this reports *reachability of a network*, not that the internet
/// actually works — which is the right signal for "should I try to fetch a
/// tile or a route".
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  bool has(List<ConnectivityResult> r) =>
      r.any((e) => e != ConnectivityResult.none);

  yield has(await Connectivity().checkConnectivity());
  yield* Connectivity().onConnectivityChanged.map(has);
});

/// Convenience synchronous read, defaults to online while unknown.
final onlineProvider = Provider<bool>(
    (ref) => ref.watch(isOnlineProvider).value ?? true);
