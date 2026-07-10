import 'dart:async';

import 'package:easy_translate/Google_Ads/Native_Ads/NativeAdManager.dart';
import 'package:easy_translate/Google_Ads/ShowAds.dart';
import 'package:easy_translate/providers/voice_provider.dart';
import 'package:easy_translate/widgets/language_chip.dart';
import 'package:easy_translate/widgets/language_picker.dart';
import 'package:easy_translate/widgets/pulsing_mic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../utils/constants.dart';
import '../utils/extensions.dart';

class VoiceTranslateScreen extends StatefulWidget {
  const VoiceTranslateScreen({super.key});
  @override
  State<VoiceTranslateScreen> createState() => _VoiceTranslateScreenState();
}

class _VoiceTranslateScreenState extends State<VoiceTranslateScreen> {
  VoiceProvider? _provider;

  bool _backHandling = false;
  Timer? _backFallback;

  @override
  void initState() {
    super.initState();
    final p = context.read<VoiceProvider>();
    p.resetSync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) p.reset();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<VoiceProvider>();
  }

  @override
  void dispose() {
    _backFallback?.cancel();
    unawaited(_provider?.reset());
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (_backHandling) return;
    _backHandling = true;

    final navigator = Navigator.of(context);

    void doPop() {
      _backFallback?.cancel();
      _backFallback = null;
      if (!mounted) return;
      if (navigator.canPop()) navigator.pop();
      _backHandling = false;
    }

    _backFallback = Timer(const Duration(milliseconds: 2500), doPop);
    ShowInterstitialAds().showBackInterstitialAds(onBeforeShow: doPop);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VoiceProvider>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text(S.voiceTranslate)),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: LanguageChip(
                      language: Languages.byCode(p.source),
                      onTap: () async {
                        final l = await pickLanguage(
                          context,
                          selected: p.source,
                        );
                        if (l != null) p.setSource(l.code);
                      },
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded),
                  Expanded(
                    child: LanguageChip(
                      language: Languages.byCode(p.target),
                      onTap: () async {
                        final l = await pickLanguage(
                          context,
                          selected: p.target,
                        );
                        if (l != null) p.setTarget(l.code);
                      },
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (p.partial.isNotEmpty)
                Text(
                  p.partial,
                  textAlign: TextAlign.center,
                  style: context.text.titleLarge,
                ).animate().fadeIn(),
              const SizedBox(height: 24),
              if (p.result != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      p.result!.translatedText,
                      textAlign: TextAlign.center,
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.06),
              const Spacer(),
              PulsingMic(
                active: p.isListening,
                busy: p.isTranslating,
                onTap: () => p.isListening ? p.stop() : p.start(),
              ),
              const SizedBox(height: 12),
              Text(
                p.isTranslating
                    ? 'Translating…'
                    : p.isListening
                    ? S.listening
                    : S.tapToSpeak,
                style: context.text.titleMedium,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
        bottomNavigationBar: SafeArea(child: const NativeAdManager()),
      ),
    );
  }
}
