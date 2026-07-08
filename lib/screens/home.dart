import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'camera_translate.dart';
import 'conversation.dart';
import 'favorites.dart';
import 'gallery_translate.dart';
import 'history.dart';
import 'settings.dart';
import 'text_translate.dart';
import 'voice_translate.dart';
import '../Google_Ads/Native_Ads/BottomNavSafeNativeAd.dart';
import '../Google_Ads/ShowAds.dart';
import '../providers/deps.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: [
          TickerMode(enabled: _tab == 0, child: const _Body()),
          const HistoryScreen(),
          const FavoritesScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: _tab,
        onSelected: (i) {
          setState(() => _tab = i);
          activeTabIndex.value = -1;
          activeTabIndex.value = i;
        },
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _items = <_NavItem>[
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: 'History',
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded,
    ),
    _NavItem(
      label: 'Favorites',
      icon: Icons.star_outline,
      activeIcon: Icons.star_rounded,
    ),
    _NavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final isDark = scheme.brightness == Brightness.dark;

    final glassColor = isDark
        ? const Color(0xFF111A33).withValues(alpha: 0.62)
        : Colors.white.withValues(alpha: 0.65);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.6);
    final glowColor = const Color(
      0xFF3B82F6,
    ).withValues(alpha: isDark ? 0.28 : 0.18);

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: glassColor,
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(width: 1.2, color: borderColor),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        _FloatingNavButton(
                          item: _items[i],
                          selected: i == selectedIndex,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onSelected(i);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _FloatingNavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _FloatingNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final inactiveFg = scheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(26),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.42),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: selected ? 0.18 : 0.10),
          highlightColor: Colors.white.withValues(
            alpha: selected ? 0.06 : 0.03,
          ),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 18 : 14,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    key: ValueKey('${item.label}_$selected'),
                    color: selected ? Colors.white : inactiveFg,
                    size: 22,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            item.label,
                            style: context.text.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  static const double _adHeight = 60;
  static const double _pillHeight = 58;
  static const double _adNavGap = 5;
  static const double _gridAdGap = 36;

  @override
  Widget build(BuildContext context) {
    final systemBottom = MediaQuery.viewPaddingOf(context).bottom;
    final safeArea = systemBottom > 12 ? systemBottom : 12.0;
    final bottomReserve =
        _pillHeight + safeArea + _adNavGap + _adHeight + _gridAdGap;

    return Stack(
      children: [
        CustomScrollView(
          physics: ClampingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _Header()),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Quick actions',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: context.colors.primary,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
            ),

            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomReserve),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildListDelegate([
                  _ActionTile(
                    icon: Icons.mic_rounded,
                    label: S.voiceTranslate,
                    subtitle: 'Speak any phrase',
                    gradient: const [Color(0xFFEC4899), Color(0xFFF59E0B)],
                    screen: const VoiceTranslateScreen(),
                    index: 0,
                  ),
                  _ActionTile(
                    icon: Icons.forum_rounded,
                    label: S.conversation,
                    subtitle: 'Talk face to face',
                    gradient: const [Color(0xFF6366F1), Color(0xFFA855F7)],
                    screen: const ConversationScreen(),
                    index: 1,
                  ),
                  _ActionTile(
                    icon: Icons.camera_alt_rounded,
                    label: S.cameraTranslate,
                    subtitle: 'Snap & translate',
                    gradient: const [Color(0xFF10B981), Color(0xFF06B6D4)],
                    screen: const CameraTranslateScreen(),
                    index: 2,
                  ),
                  _ActionTile(
                    icon: Icons.photo_library_rounded,
                    label: S.galleryTranslate,
                    subtitle: 'From your photos',
                    gradient: const [Color(0xFFF43F5E), Color(0xFF8B5CF6)],
                    screen: const GalleryTranslateScreen(),
                    index: 3,
                  ),
                ]),
              ),
            ),
          ],
        ),

        const Align(
          alignment: Alignment.bottomCenter,
          child: BottomNavSafeNativeAd(tabIndex: 0, gap: _adNavGap),
        ),
      ],
    );
  }
}

class _Header extends StatefulWidget {
  const _Header();
  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 290 + topInset,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => CustomPaint(painter: _MeshPainter(_c.value)),
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) => Stack(
                  children: [
                    _Orb(
                      offset: Offset(
                        40 + math.sin(_c.value * 2 * math.pi) * 30,
                        100 + topInset + math.cos(_c.value * 2 * math.pi) * 20,
                      ),
                      size: 140,
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    _Orb(
                      offset: Offset(
                        260 + math.cos(_c.value * 2 * math.pi) * 24,
                        60 +
                            topInset +
                            math.sin(_c.value * 2 * math.pi + 1) * 18,
                      ),
                      size: 90,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    _Orb(
                      offset: Offset(
                        200 + math.sin(_c.value * 2 * math.pi + 2) * 40,
                        180 +
                            topInset +
                            math.cos(_c.value * 2 * math.pi + 2) * 30,
                      ),
                      size: 120,
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                      children: [
                        Text(
                          'Hello',
                          style: context.text.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),

                        const Text('👋', style: TextStyle(fontSize: 18))
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .rotate(
                              begin: -0.05,
                              end: 0.1,
                              duration: 700.ms,
                              curve: Curves.easeInOut,
                            ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.1, end: 0),
                const SizedBox(height: 6),
                Text(
                      'Translate\nbeautifully.',
                      style: context.text.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: -0.5,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 500.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 8),
                Text(
                  '100+ languages · voice · camera · OCR',
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                const Spacer(),
                const _HeroCta()
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final Offset offset;
  final double size;
  final Color color;
  const _Orb({required this.offset, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double t;
  _MeshPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const colorsA = [Color(0xFF6366F1), Color(0xFFEC4899)];
    const colorsB = [Color(0xFF06B6D4), Color(0xFFA855F7)];
    final c1 = Color.lerp(
      colorsA[0],
      colorsB[0],
      (math.sin(t * 2 * math.pi) + 1) / 2,
    )!;
    final c2 = Color.lerp(
      colorsA[1],
      colorsB[1],
      (math.cos(t * 2 * math.pi) + 1) / 2,
    )!;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(math.sin(t * 2 * math.pi), -1),
        end: Alignment(-math.sin(t * 2 * math.pi), 1),
        colors: [c1, c2],
      ).createShader(rect);

    final rrect = RRect.fromRectAndCorners(
      rect,
      bottomLeft: const Radius.circular(36),
      bottomRight: const Radius.circular(36),
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) => oldDelegate.t != t;
}

class _HeroCta extends StatelessWidget {
  const _HeroCta();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => ShowInterstitialAds().showClickInterstitialAds(
          onBeforeShow: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TextTranslateScreen()),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF6366F1,
                          ).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 2600.ms,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.textTranslate,
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1C1B1F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Type, paste or speak',
                      style: context.text.bodySmall?.copyWith(
                        color: const Color(0xFF6B6E7B),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_rounded, color: Color(0xFF1C1B1F))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveX(
                    begin: 0,
                    end: 6,
                    duration: 900.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final Widget screen;
  final int index;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.screen,
    required this.index,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final delay = (700 + widget.index * 120).ms;
    return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () => ShowInterstitialAds().showClickInterstitialAds(
            onBeforeShow: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => widget.screen)),
          ),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: Icon(
                      widget.icon,
                      size: 110,
                      color: Colors.white.withValues(alpha: 0.13),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              style: context.text.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle,
                              style: context.text.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: delay, duration: 450.ms)
        .slideY(
          begin: 0.25,
          end: 0,
          delay: delay,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
