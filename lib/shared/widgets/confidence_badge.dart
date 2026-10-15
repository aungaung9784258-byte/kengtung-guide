import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/services/market_cycle.dart' show DataConfidence;
import '../../l10n/app_localizations.dart';

/// A small coloured pill telling the user how much to trust a fact.
///
/// Being honest about a gap is the whole point: a traveller who knows a time
/// is unconfirmed will ask at the hotel. One who is shown a confident wrong
/// time will miss the market.
class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({
    super.key,
    required this.confidence,
    this.compact = false,
  });

  final DataConfidence confidence;
  final bool compact;

  static Color colorOf(DataConfidence c) => switch (c) {
        DataConfidence.verified => AppColors.jade,
        DataConfidence.estimated => AppColors.gold,
        DataConfidence.unverified => AppColors.coral,
      };

  static IconData iconOf(DataConfidence c) => switch (c) {
        DataConfidence.verified => Icons.verified_rounded,
        DataConfidence.estimated => Icons.schedule_rounded,
        DataConfidence.unverified => Icons.help_outline_rounded,
      };

  static String labelKeyOf(DataConfidence c) => switch (c) {
        DataConfidence.verified => 'confVerified',
        DataConfidence.estimated => 'confEstimated',
        DataConfidence.unverified => 'confUnverified',
      };

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final c = colorOf(confidence);

    if (compact) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconOf(confidence), size: 12, color: c),
          const SizedBox(width: 5),
          Text(
            t.t(labelKeyOf(confidence)),
            style: TextStyle(
              fontSize: 11,
              height: t.isMyanmar ? 1.6 : 1.2,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

/// The legend shown once at the bottom of the Today tab, explaining the
/// three badge colours.
class ConfidenceLegend extends StatelessWidget {
  const ConfidenceLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cs = Theme.of(context).colorScheme;

    Widget row(DataConfidence c, String key) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: ConfidenceBadge(confidence: c, compact: true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.t(key),
                  style: TextStyle(
                    fontSize: 12,
                    height: t.isMyanmar ? 1.7 : 1.35,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.t('howSureLegend'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: t.isMyanmar ? 1.7 : 1.2,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          row(DataConfidence.verified, 'confVerifiedHint'),
          row(DataConfidence.estimated, 'confEstimatedHint'),
          row(DataConfidence.unverified, 'confUnverifiedHint'),
        ],
      ),
    );
  }
}
