import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/offline_map_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/motion_widgets.dart';

/// Settings panel: download the Kengtung map for offline use.
class OfflineMapsCard extends ConsumerStatefulWidget {
  const OfflineMapsCard({super.key});

  @override
  ConsumerState<OfflineMapsCard> createState() => _OfflineMapsCardState();
}

class _OfflineMapsCardState extends ConsumerState<OfflineMapsCard> {
  StreamSubscription<DownloadProgress>? _sub;
  DownloadProgress? _progress;
  String? _activeRegionId;
  int _cacheBytes = 0;

  @override
  void initState() {
    super.initState();
    _refreshSize();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _refreshSize() async {
    final b = await OfflineMapService.cacheSizeBytes();
    if (mounted) setState(() => _cacheBytes = b);
  }

  void _start(OfflineRegion region) {
    setState(() {
      _activeRegionId = region.id;
      _progress = DownloadProgress(
          done: 0, total: OfflineMapService.tileCount(region));
    });

    _sub = OfflineMapService.download(region).listen((p) {
      if (!mounted) return;
      setState(() => _progress = p);
      if (p.finished) {
        _activeRegionId = null;
        _refreshSize();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('downloadDone'))),
        );
      }
    });
  }

  void _cancel() {
    OfflineMapService.cancel();
    _sub?.cancel();
    setState(() {
      _activeRegionId = null;
      _progress = null;
    });
  }

  Future<void> _clear() async {
    await OfflineMapService.clear();
    await _refreshSize();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('offlineCleared'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final lang = ref.watch(langProvider);
    final online = ref.watch(onlineProvider);
    final cs = Theme.of(context).colorScheme;
    final busy = _activeRegionId != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.jadeGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_download_rounded,
                    size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(t.t('offlineMaps'),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              _StatusDot(online: online),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.t('offlineMapsHint'),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 18),

          if (kIsWeb)
            // The browser manages its own tile cache; manual download would
            // just duplicate it.
            Text(t.t('offlineWeb'),
                style: Theme.of(context).textTheme.bodySmall)
          else
          for (final region in OfflineRegion.all) ...[
            _RegionRow(
              title: region.name(lang),
              subtitle:
                  '${OfflineMapService.tileCount(region)} tiles · ~${OfflineMapService.estimatedSize(region)}',
              downloading: _activeRegionId == region.id,
              progress:
                  _activeRegionId == region.id ? _progress : null,
              enabled: !busy && online,
              onDownload: () => _start(region),
              onCancel: _cancel,
            ),
            const SizedBox(height: 12),
          ],

          if (!kIsWeb) ...[
          const SizedBox(height: 4),
          Divider(color: cs.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.sd_storage_rounded,
                  size: 15, color: cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${t.t('storageUsed')}: ${OfflineMapService.formatBytes(_cacheBytes)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (_cacheBytes > 0)
                TextButton(
                  onPressed: busy ? null : _clear,
                  child: Text(t.t('clearOffline'),
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          ],
        ],
      ),
    );
  }
}

class _RegionRow extends StatelessWidget {
  const _RegionRow({
    required this.title,
    required this.subtitle,
    required this.downloading,
    required this.enabled,
    required this.onDownload,
    required this.onCancel,
    this.progress,
  });

  final String title;
  final String subtitle;
  final bool downloading;
  final bool enabled;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final DownloadProgress? progress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.easeOutExpoCurve,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: downloading
              ? AppColors.jade.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              if (downloading)
                PressableScale(
                  scale: 0.88,
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stop_rounded,
                        size: 16, color: Colors.white),
                  ),
                )
              else
                PressableScale(
                  scale: 0.9,
                  onTap: enabled ? onDownload : () {},
                  child: Opacity(
                    opacity: enabled ? 1 : 0.4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: const BoxDecoration(
                        gradient: AppColors.jadeGradient,
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded,
                              size: 15, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(context.l10n.t('download'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (downloading && progress != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress!.fraction),
                duration: AppMotion.fast,
                curve: AppMotion.gentle,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 7,
                  backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.jade),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${progress!.done} / ${progress!.total}',
                    style: Theme.of(context).textTheme.labelSmall),
                Text('${progress!.percent}%',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.jade)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    final c = online ? AppColors.jade : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.t(online ? 'online' : 'offline'),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: c),
          ),
        ],
      ),
    );
  }
}
