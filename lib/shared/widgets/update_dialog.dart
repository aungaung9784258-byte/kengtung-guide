import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kDebugMode; 
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/update_service.dart';

const Color _kJade = Color(0xFF0FA47F);
const Color _kInk = Color(0xFF0B1412);

bool _isMyanmar(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'my';

/// Invisible widget that checks for a new release and, if there is one,
/// pops the update card over a blurred background.
///
/// Drop a single `const UpdateGate()` anywhere inside the Home screen's
/// widget tree — it renders nothing and takes no space.
class UpdateGate extends StatefulWidget {
  const UpdateGate({
    super.key,
    this.delay = const Duration(milliseconds: 900),
  });

  /// Wait a moment after Home appears so the entrance animations finish
  /// before the card interrupts.
  final Duration delay;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  /// Only ever interrupt once per app launch.
  static bool _shownThisSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (_shownThisSession) return;

  final info = await UpdateService.check(force: kDebugMode);
    if (info == null || !mounted) return;

    await Future<void>.delayed(widget.delay);
    if (!mounted) return;

    _shownThisSession = true;
    await showUpdateDialog(context, info);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Shows the update card over a blurred, dimmed background.
Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  final my = _isMyanmar(context);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: !info.mandatory,
    barrierLabel: my ? 'ပိတ်ရန်' : 'Dismiss',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, __, ___) {
      final eased = CurvedAnimation(
        parent: anim,
        curve: const Cubic(.16, 1, .3, 1),
        reverseCurve: Curves.easeInCubic,
      );

      return Stack(
        children: [
          // Frosted, dimmed backdrop.
          FadeTransition(
            opacity: anim,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Container(color: Colors.black.withValues(alpha: .34)),
            ),
          ),
          FadeTransition(
            opacity: eased,
            child: ScaleTransition(
              scale: Tween<double>(begin: .90, end: 1).animate(eased),
              child: Center(
                child: _UpdateCard(info: info, myanmar: my),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _UpdateCard extends StatefulWidget {
  const _UpdateCard({required this.info, required this.myanmar});

  final UpdateInfo info;
  final bool myanmar;

  @override
  State<_UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends State<_UpdateCard> {
  /// Ticked by the user: stay quiet for the next 24 hours.
  bool _quietToday = false;

  UpdateInfo get info => widget.info;
  bool get myanmar => widget.myanmar;

  /// Honour the checkbox whenever the card goes away without downloading.
  Future<void> _applyQuiet() async {
    if (_quietToday) await UpdateService.snoozeForToday();
  }

  Future<void> _download(BuildContext context) async {
    Navigator.of(context).maybePop();
    final uri = Uri.parse(info.downloadUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Nothing sensible to do if there is no browser.
    }
  }

  /// "Later" — never mention this build again.
  Future<void> _later(BuildContext context) async {
    await UpdateService.skip(info.versionCode);
    await _applyQuiet();
    if (context.mounted) Navigator.of(context).maybePop();
  }

  /// The ✕ — just close. It comes back on the next launch, unless the
  /// checkbox was ticked.
  Future<void> _close(BuildContext context) async {
    await _applyQuiet();
    if (context.mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF16221E) : Colors.white;
    final onSurface = dark ? Colors.white : _kInk;
    final hair = onSurface.withValues(alpha: dark ? .14 : .10);

    final notes = info.notes(myanmar).take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: surface,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          elevation: 18,
          shadowColor: Colors.black.withValues(alpha: .4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _kJade.withValues(alpha: dark ? .20 : .12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.system_update_alt_rounded,
                        color: _kJade,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      myanmar ? 'ဗားရှင်းအသစ် ရပါပြီ' : 'Update available',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      myanmar
                          ? 'ဗားရှင်း ${info.versionName}'
                              '${info.sizeMb > 0 ? ' · ~${info.sizeMb.toStringAsFixed(0)} MB' : ''}'
                              ' ရရှိနိုင်ပါပြီ။'
                          : 'Version ${info.versionName}'
                              '${info.sizeMb > 0 ? ' · ~${info.sizeMb.toStringAsFixed(0)} MB' : ''}'
                              ' is ready to install.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.6,
                        color: onSurface.withValues(alpha: .66),
                      ),
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      for (final line in notes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 7, right: 9),
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: _kJade,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  line,
                                  style: TextStyle(
                                    fontSize: 12.8,
                                    height: 1.5,
                                    color: onSurface.withValues(alpha: .8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
                  ),
                  // ✕ — close without making any decision. The card comes
                  // back on the next launch.
                  if (!info.mandatory)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _close(context),
                          child: Padding(
                            padding: const EdgeInsets.all(9),
                            child: Icon(
                              Icons.close_rounded,
                              size: 19,
                              color: onSurface.withValues(alpha: .45),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (!info.mandatory) ...[
                Divider(height: 1, thickness: 1, color: hair),
                _QuietCheckbox(
                  value: _quietToday,
                  label: myanmar
                      ? 'ဒီနေ့အတွက် ထပ်မပြပါနှင့်'
                      : "Don't show again today",
                  onSurface: onSurface,
                  onChanged: (v) => setState(() => _quietToday = v),
                ),
              ],
              Divider(height: 1, thickness: 1, color: hair),
              IntrinsicHeight(
                child: Row(
                  children: [
                    if (!info.mandatory) ...[
                      Expanded(
                        child: _CardButton(
                          label: myanmar ? 'နောက်မှ' : 'Later',
                          color: onSurface.withValues(alpha: .55),
                          bold: false,
                          onTap: () => _later(context),
                        ),
                      ),
                      VerticalDivider(width: 1, thickness: 1, color: hair),
                    ],
                    Expanded(
                      child: _CardButton(
                        label: myanmar ? 'ယခု ရယူမည်' : 'Update now',
                        color: _kJade,
                        bold: true,
                        onTap: () => _download(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round jade checkbox + label, used for "don't show again today".
class _QuietCheckbox extends StatelessWidget {
  const _QuietCheckbox({
    required this.value,
    required this.label,
    required this.onSurface,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final Color onSurface;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? _kJade : Colors.transparent,
                border: Border.all(
                  color: value ? _kJade : onSurface.withValues(alpha: .30),
                  width: 1.6,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.2,
                  fontWeight: FontWeight.w500,
                  color: onSurface.withValues(alpha: value ? .78 : .55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.color,
    required this.bold,
    required this.onTap,
    
  });

  final String label;
  final Color color;
  final bool bold;
  final VoidCallback onTap;
  

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}
