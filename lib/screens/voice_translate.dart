import 'dart:async';

import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_translate/widgets/pulsing_mic.dart';
import 'package:easy_translate/widgets/language_chip.dart';
import 'package:easy_translate/widgets/language_picker.dart';
import 'package:easy_translate/providers/voice_provider.dart';
import 'package:easy_translate/Google_Ads/Native_Ads/NativeAdManager.dart';

class VoiceTranslateScreen extends StatefulWidget {
  const VoiceTranslateScreen({super.key});
  @override
  State<VoiceTranslateScreen> createState() => _VoiceTranslateScreenState();
}

class _VoiceTranslateScreenState extends State<VoiceTranslateScreen> {
  VoiceProvider? _provider;

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
    unawaited(_provider?.reset());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VoiceProvider>();
    return Scaffold(
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
      bottomNavigationBar: const NativeAdManager(),
    );
  }
}
