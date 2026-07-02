import 'package:flutter/material.dart';
import 'package:easy_translate/providers/deps.dart';
import 'NativeAdManager.dart';

class BottomNavSafeNativeAd extends StatefulWidget {
  final int? tabIndex;
  final double gap;

  const BottomNavSafeNativeAd({super.key, this.tabIndex, this.gap = 3});

  @override
  State<BottomNavSafeNativeAd> createState() => _BottomNavSafeNativeAdState();
}

class _BottomNavSafeNativeAdState extends State<BottomNavSafeNativeAd> {
  int _adKey = 0;
  bool _hasBeenVisited = false;

  @override
  void initState() {
    super.initState();
    if (widget.tabIndex == null || activeTabIndex.value == widget.tabIndex) {
      _hasBeenVisited = true;
    }
    if (widget.tabIndex != null) {
      activeTabIndex.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    if (widget.tabIndex != null) {
      activeTabIndex.removeListener(_onTabChanged);
    }
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    if (activeTabIndex.value == widget.tabIndex) {
      setState(() {
        _hasBeenVisited = true;
        _adKey++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final rawBottom = view.viewPadding.bottom / view.devicePixelRatio;
    final safeArea = rawBottom > 12 ? rawBottom : 12.0;
    const pillHeight = 58.0;
    final floatingNavHeight = pillHeight + safeArea;
    return Padding(
      padding: EdgeInsets.only(bottom: floatingNavHeight + widget.gap),
      child: _hasBeenVisited
          ? NativeAdManager(
              key: ValueKey('native-ad-${widget.tabIndex}-$_adKey'),
            )
          : const SizedBox.shrink(),
    );
  }
}
