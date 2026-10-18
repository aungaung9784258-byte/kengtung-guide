import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/motion_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────
//  THE ONLY LINE YOU NEED TO EDIT
//  Your Telegram username, without the leading "@".
//  Example: 'kyaingtong_dev'  →  https://t.me/kyaingtong_dev
const String kTelegramUsername = 'SoraBeatz_67';
// ─────────────────────────────────────────────────────────────────────────

/// "Contact the developer" card for the Settings tab.
///
/// Tapping it opens the Telegram app directly when it is installed, falls
/// back to the browser when it is not, and — if even that fails, which
/// happens on stripped-down ROMs — copies the handle to the clipboard so
/// the tap is never a dead end.
class ContactCard extends ConsumerWidget {
  const ContactCard({super.key});

  static const _telegramBlue = Color(0xFF229ED9);

  Future<void> _openTelegram(BuildContext context, bool my) async {
    final messenger = ScaffoldMessenger.of(context);

    // tg:// reaches the installed app even when the link handler is off.
    final app = Uri.parse('tg://resolve?domain=$kTelegramUsername');
    final web = Uri.parse('https://t.me/$kTelegramUsername');

    for (final uri in [app, web]) {
      try {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return;
      } catch (_) {
        // Try the next one.
      }
    }

    await Clipboard.setData(
        const ClipboardData(text: '@$kTelegramUsername'));
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          my
              ? 'Telegram ကို ဖွင့်၍ မရပါ။ @$kTelegramUsername ကို ကူးယူပြီးပါပြီ။'
              : 'Could not open Telegram. @$kTelegramUsername was copied instead.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final my = ref.watch(langProvider) == 'my';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
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
                child: const Icon(Icons.support_agent_rounded,
                    size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                my ? 'ဆက်သွယ်ရန်' : 'Contact us',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            my
                ? 'အမှားတွေ့ပါက၊ နေရာအသစ် ထည့်ချင်ပါက၊ သို့မဟုတ် ဈေးရက် အချက်အလက် ပြင်ချင်ပါက '
                    'တိုက်ရိုက် စာပို့နိုင်ပါတယ်။'
                : 'Found a mistake, know a place we missed, or can confirm a market day? '
                    'Message us directly.',
            style: TextStyle(
              fontSize: my ? 13.5 : 14,
              height: my ? 1.9 : 1.45,
              color: cs.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 16),
          PressableScale(
            onTap: () => _openTelegram(context, my),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _telegramBlue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _telegramBlue.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    my ? 'Telegram မှ ဆက်သွယ်ရန်' : 'Message us on Telegram',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: PressableScale(
              onTap: () async {
                await Clipboard.setData(
                    const ClipboardData(text: '@$kTelegramUsername'));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(my ? 'ကူးယူပြီးပါပြီ' : 'Copied'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '@$kTelegramUsername',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
