import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:easy_translate/widgets/language_picker.dart';
import 'package:easy_translate/providers/conversation_provider.dart';
import 'package:easy_translate/providers/ocr_provider.dart';
import 'package:easy_translate/providers/settings_provider.dart';
import 'package:easy_translate/providers/translation_provider.dart';
import 'package:easy_translate/providers/voice_provider.dart';
import 'package:easy_translate/Google_Ads/Native_Ads/BottomNavSafeNativeAd.dart';

final Future<PackageInfo> _packageInfoFuture = PackageInfo.fromPlatform();
const Color _kDestructiveRed = Color(0xFFE53935);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SettingsProvider>();
    final s = p.settings;

    return Scaffold(
      bottomNavigationBar: const BottomNavSafeNativeAd(tabIndex: 3),
      appBar: AppBar(
        toolbarHeight: 45,
        title: const Text(
          S.settings,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            _SectionCard(
              title: 'Appearance',
              icon: Icons.palette_rounded,
              children: [
                _ThemePicker(selected: s.themeMode, onChanged: p.setTheme),
              ],
            ),

            _SectionCard(
              title: 'Defaults',
              icon: Icons.tune_rounded,
              children: [
                _NavRow(
                  icon: Icons.language_rounded,
                  title: 'Default source',
                  trailingText: Languages.byCode(s.defaultSource).name,
                  flag: Languages.byCode(s.defaultSource).flag,
                  onTap: () async {
                    final l = await pickLanguage(
                      context,
                      includeAuto: true,
                      selected: s.defaultSource,
                    );
                    if (l != null) p.setSource(l.code);
                  },
                ),
                const _Divider(),
                _NavRow(
                  icon: Icons.translate_rounded,
                  title: 'Default target',
                  trailingText: Languages.byCode(s.defaultTarget).name,
                  flag: Languages.byCode(s.defaultTarget).flag,
                  onTap: () async {
                    final l = await pickLanguage(
                      context,
                      selected: s.defaultTarget,
                    );
                    if (l != null) p.setTarget(l.code);
                  },
                ),
              ],
            ),

            _SectionCard(
              title: 'Speech',
              icon: Icons.record_voice_over_rounded,
              children: [
                _SwitchRow(
                  icon: Icons.campaign_rounded,
                  title: 'Auto-speak translations',
                  subtitle: 'Play the result out loud automatically',
                  value: s.autoSpeak,
                  onChanged: p.setAutoSpeak,
                ),
                const _Divider(),
                _SliderRow(
                  icon: Icons.speed_rounded,
                  title: 'Speech rate',
                  value: s.speechRate,
                  onChanged: p.setRate,
                ),
              ],
            ),

            _SectionCard(
              title: 'Privacy',
              icon: Icons.shield_moon_rounded,
              children: [
                _SwitchRow(
                  icon: Icons.history_rounded,
                  title: 'Save translation history',
                  subtitle: 'Keep a searchable log on this device',
                  value: s.saveHistory,
                  onChanged: p.setSaveHistory,
                ),
              ],
            ),

            _SectionCard(
              title: 'About',
              icon: Icons.info_rounded,
              children: [_VersionRow()],
            ),

            const SizedBox(height: 24),
            _ResetSettingsButton(
              onConfirmedReset: () {
                p.resetToDefaults();
                context.read<TranslationProvider>().applyDefaults();
                context.read<OcrProvider>().applyDefaults();
                context.read<VoiceProvider>().applyDefaults();
                context.read<ConversationProvider>().applyDefaults();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ResetSettingsButton extends StatelessWidget {
  final VoidCallback onConfirmedReset;
  const _ResetSettingsButton({required this.onConfirmedReset});

  Future<void> _confirm(BuildContext context) async {
    final scheme = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: scheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _kDestructiveRed.withValues(alpha: 0.18),
                      _kDestructiveRed.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kDestructiveRed.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: _kDestructiveRed,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reset all settings?',
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Theme, default languages, speech preferences, history '
                'toggle, and conversation layout will be restored to '
                'their defaults.',
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const Text('Reset'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kDestructiveRed,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      onConfirmedReset();
      if (context.mounted) {
        context.snack('Settings restored to defaults');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: OutlinedButton.icon(
        onPressed: () => _confirm(context),
        icon: const Icon(Icons.restart_alt_rounded, color: _kDestructiveRed),
        label: const Text(
          'Reset settings',
          style: TextStyle(
            color: _kDestructiveRed,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: _kDestructiveRed.withValues(alpha: 0.15),
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: _kDestructiveRed.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        final info = snapshot.data;
        final text = info == null ? '—' : info.version;
        return _NavRow(
          icon: Icons.tag_rounded,
          title: 'Version',
          trailingText: text,
          onTap: null,
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: context.colors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: context.text.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.colors.primary,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: context.colors.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: context.colors.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _ThemeOption(
              label: 'System',
              themeMode: ThemeMode.system,
              isSelected: selected == ThemeMode.system,
              onTap: () => onChanged(ThemeMode.system),
              preview: _SystemPreview(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ThemeOption(
              label: 'Light',
              themeMode: ThemeMode.light,
              isSelected: selected == ThemeMode.light,
              onTap: () => onChanged(ThemeMode.light),
              preview: _SidePreview(dark: false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ThemeOption(
              label: 'Dark',
              themeMode: ThemeMode.dark,
              isSelected: selected == ThemeMode.dark,
              onTap: () => onChanged(ThemeMode.dark),
              preview: _SidePreview(dark: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final ThemeMode themeMode;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget preview;
  const _ThemeOption({
    required this.label,
    required this.themeMode,
    required this.isSelected,
    required this.onTap,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),

            border: Border.all(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? context.colors.primary.withValues(alpha: 0.08)
                : null,
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 9 / 16,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: preview,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: context.text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? context.colors.primary : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidePreview extends StatelessWidget {
  final bool dark;
  const _SidePreview({required this.dark});

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF1C1B1F) : const Color(0xFFFAF8FF);
    final fg = dark ? Colors.white : const Color(0xFF1C1B1F);
    final accent = context.colors.primary;
    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 14,
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
          ),
          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 6),

          for (var i = 0; i < 2; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _SystemPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _DiagonalClipper(),
      child: Stack(
        children: [
          const Positioned.fill(child: _SidePreview(dark: false)),

          Positioned.fill(
            child: ClipPath(
              clipper: _TopHalfClipper(),
              child: const _SidePreview(dark: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()..addRect(Offset.zero & size);
  @override
  bool shouldReclip(covariant CustomClipper oldClipper) => false;
}

class _TopHalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) => false;
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final String? flag;
  final VoidCallback? onTap;
  const _NavRow({
    required this.icon,
    required this.title,
    this.trailingText,
    this.flag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: _RowIcon(icon: icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flag != null) ...[
            Text(flag!, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
          ],
          if (trailingText != null)
            Text(
              trailingText!,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      secondary: _RowIcon(icon: icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  const _SliderRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _RowIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title)),
                    Text(
                      '${value.toStringAsFixed(2)}×',
                      style: context.text.labelLarge?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                Slider.adaptive(
                  min: 0.2,
                  max: 1.0,
                  divisions: 8,
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  final IconData icon;
  const _RowIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: context.colors.primary),
    );
  }
}
