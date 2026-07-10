import 'dart:async';

import '../utils/constants.dart';
import '../utils/extensions.dart';

import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_translate/providers/translation_provider.dart';
import 'package:easy_translate/widgets/language_swap_bar.dart';
import 'package:easy_translate/widgets/translation_card.dart';
import 'package:easy_translate/Google_Ads/Native_Ads/NativeAdManager.dart';
import 'package:easy_translate/Google_Ads/ShowAds.dart';

class TextTranslateScreen extends StatefulWidget {
  const TextTranslateScreen({super.key});
  @override
  State<TextTranslateScreen> createState() => _TextTranslateScreenState();
}

class _TextTranslateScreenState extends State<TextTranslateScreen> {
  final _controller = TextEditingController();
  TranslationProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<TranslationProvider>();
    if (!identical(next, _provider)) {
      _provider?.removeListener(_syncFromProvider);
      _provider = next;
      _provider!.addListener(_syncFromProvider);
      _syncFromProvider();
    }
  }

  void _syncFromProvider() {
    if (!mounted) return;
    final p = _provider;
    if (p == null) return;
    if (_controller.text != p.input) {
      _controller.value = TextEditingValue(
        text: p.input,
        selection: TextSelection.collapsed(offset: p.input.length),
      );
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_syncFromProvider);
    _backFallback?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  bool _backHandling = false;
  Timer? _backFallback;

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
    final p = context.watch<TranslationProvider>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text(S.textTranslate)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),  
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LanguageSwapBar(
                  source: p.source,
                  target: p.target,
                  onSource: p.setSource,
                  onTarget: p.setTarget,
                  onSwap: p.swap,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _controller,
                          onChanged: p.setInput,
                          maxLines: 6,
                          minLines: 3,
                          autocorrect: false,
                          enableSuggestions: false,
                          smartDashesType: SmartDashesType.disabled,
                          smartQuotesType: SmartQuotesType.disabled,
                          decoration: const InputDecoration(
                            hintText: 'Enter text to translate…',
                            border: InputBorder.none,
                            filled: false,
                          ),
                          style: context.text.titleMedium,
                        ),

                        if (p.detectedCode != null && p.source.isAuto)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Text(
                              'Detected: ${p.detectedCode}',
                              style: context.text.labelSmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            if (p.input.isNotEmpty)
                              IconButton(
                                tooltip: 'Listen',
                                visualDensity: VisualDensity.compact,
                                onPressed: p.speakInput,
                                icon: const Icon(Icons.volume_up_rounded),
                              ),
                            IconButton(
                              tooltip: p.isListening ? 'Stop' : 'Speak',
                              visualDensity: VisualDensity.compact,
                              onPressed: p.isListening
                                  ? p.stopListening
                                  : p.startListening,
                              icon: Icon(
                                p.isListening
                                    ? Icons.stop_circle_rounded
                                    : Icons.mic_rounded,
                                color: p.isListening
                                    ? context.colors.error
                                    : context.colors.primary,
                              ),
                            ),
                            if (p.input.isNotEmpty)
                              IconButton(
                                tooltip: 'Clear',
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  _controller.clear();
                                  p.clear();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: p.isLoading
                                  ? null
                                  : () {
                                      _dismissKeyboard();
                                      p.translate();
                                    },

                              icon: p.isLoading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Lottie.asset(
                                        'assets/lottie/loading_dots.json',
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : const Icon(Icons.translate_rounded),
                              label: const Text('Translate'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (p.error != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      p.error!,
                      style: TextStyle(color: context.colors.error),
                    ),
                  ),

                if (p.isLoading && p.result == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 80,
                          child: Lottie.asset(
                            'assets/lottie/loading_dots.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Translating…',
                          style: context.text.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (p.result != null)
                  TranslationCard(
                    t: p.result!,
                    onSpeak: p.speakResult,
                    onCopy: () async {
                      final msg = await p.copy();
                      if (context.mounted) context.snack(msg);
                    },
                    onShare: p.share,
                    onFavorite: p.toggleFavorite,
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(child: const NativeAdManager()),
      ),
    );
  }
}
