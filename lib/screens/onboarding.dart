import 'package:easy_translate/Google_Ads/Native_Ads/ExpandedNativeAdManager.dart';

import 'home.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_translate/widgets/primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final List<Widget> pages = [Onboarding1(), Onboarding2(), Onboarding3()];
  @override
  Widget build(BuildContext context) {
    Future<void> finish() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(K.prefOnboardingDone, true);
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: scaffoldBg,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(onPressed: finish, child: const Text(S.skip)),
              ),

              Expanded(
                child: PageView.builder(
                  itemCount: 3,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => pages[index],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.colors.primaryContainer,
                                    ),
                                    child: Icon(
                                      Icons.translate_rounded,
                                      size: 86,
                                      color: context.colors.primary,
                                    ),
                                  )
                                  .animate(key: ValueKey(0))
                                  .scale(
                                    begin: const Offset(0.8, 0.8),
                                    curve: Curves.easeOutBack,
                                  )
                                  .fadeIn(),
                              const SizedBox(height: 20),
                              Text(
                                S.onboarding[0].$1,
                                textAlign: TextAlign.center,
                                style: context.text.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                S.onboarding[0].$2,
                                textAlign: TextAlign.center,
                                style: context.text.bodyLarge?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(S.onboarding.length, (
                                  i,
                                ) {
                                  final active = i == 0;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 16,
                                    ),
                                    height: 8,
                                    width: active ? 28 : 8,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? context.colors.primary
                                          : context.colors.outlineVariant,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const ExpandedNativeAdManager(),
            const SizedBox(height: 76),
          ],
        ),

        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: PrimaryButton(
            label: S.next,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const Onboarding2()));
            },
          ),
        ),
      ],
    );
  }
}

class Onboarding2 extends StatelessWidget {
  const Onboarding2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                        width: 180,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              context.colors.primaryContainer,
                                        ),
                                        child: Icon(
                                          Icons.forum_rounded,
                                          size: 86,
                                          color: context.colors.primary,
                                        ),
                                      )
                                      .animate(key: ValueKey(1))
                                      .scale(
                                        begin: const Offset(0.8, 0.8),
                                        curve: Curves.easeOutBack,
                                      )
                                      .fadeIn(),
                                  const SizedBox(height: 20),
                                  Text(
                                    S.onboarding[1].$1,
                                    textAlign: TextAlign.center,
                                    style: context.text.headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    S.onboarding[1].$2,
                                    textAlign: TextAlign.center,
                                    style: context.text.bodyLarge?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      S.onboarding.length,
                                      (i) {
                                        final active = i == 1;
                                        return AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 16,
                                          ),
                                          height: 8,
                                          width: active ? 28 : 8,
                                          decoration: BoxDecoration(
                                            color: active
                                                ? context.colors.primary
                                                : context.colors.outlineVariant,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const ExpandedNativeAdManager(),
                const SizedBox(height: 76),
              ],
            ),

            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: PrimaryButton(
                label: S.next,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const Onboarding3()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Onboarding3 extends StatelessWidget {
  const Onboarding3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                        width: 180,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              context.colors.primaryContainer,
                                        ),
                                        child: Icon(
                                          Icons.cloud_off_rounded,
                                          size: 86,
                                          color: context.colors.primary,
                                        ),
                                      )
                                      .animate(key: ValueKey(2))
                                      .scale(
                                        begin: const Offset(0.8, 0.8),
                                        curve: Curves.easeOutBack,
                                      )
                                      .fadeIn(),
                                  const SizedBox(height: 20),
                                  Text(
                                    S.onboarding[2].$1,
                                    textAlign: TextAlign.center,
                                    style: context.text.headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    S.onboarding[2].$2,
                                    textAlign: TextAlign.center,
                                    style: context.text.bodyLarge?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      S.onboarding.length,
                                      (i) {
                                        final active = i == 2;
                                        return AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 16,
                                          ),
                                          height: 8,
                                          width: active ? 28 : 8,
                                          decoration: BoxDecoration(
                                            color: active
                                                ? context.colors.primary
                                                : context.colors.outlineVariant,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const ExpandedNativeAdManager(),
                const SizedBox(height: 76),
              ],
            ),

            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: PrimaryButton(
                label: S.getStarted,
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(K.prefOnboardingDone, true);
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
