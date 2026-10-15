import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/motion_widgets.dart';

/// ---------------------------------------------------------------------------
/// AboutEntryCard
///
/// The single entry point to the About page from Home. A slim strip card —
/// thumbnail, title, one line of what is inside, chevron.
///
/// Deliberately NOT a floating button over the hero: a button covers the photo
/// and tells the reader nothing about what is behind it.
///
/// Drop it into the Home list right under the search bar.
/// ---------------------------------------------------------------------------
class AboutEntryCard extends ConsumerWidget {
  const AboutEntryCard({
    super.key,
    this.thumbnail = 'assets/images/lake.jpg',
    this.margin = const EdgeInsets.fromLTRB(16, 16, 16, 2),
  });

  final String thumbnail;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final my = ref.watch(langProvider) == 'my';
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final title = my ? 'ကျိုင်းတုံအကြောင်း' : 'About Kyaing Tong';
    final subtitle = my
        ? 'နှစ် ၇၀၀၊ လူမျိုး ၁၃ မျိုး၊ ဈေး ၅ ခု'
        : '700 years, 13 peoples, 5 markets';

    return Padding(
      padding: margin,
      child: PressableScale(
        onTap: () => context.push('/about-kengtung'),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: dark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.28 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(
                  thumbnail,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 52,
                    height: 52,
                    color: AppColors.jadeSoft,
                    child: const Icon(Icons.menu_book_outlined,
                        size: 22, color: AppColors.jadeDeep),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: my ? 13 : 13.5,
                        fontWeight: FontWeight.w800,
                        height: my ? 1.6 : 1.25,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: my ? 10.5 : 11,
                        height: my ? 1.7 : 1.35,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.chevron_right_rounded,
                    color: AppColors.jade, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
