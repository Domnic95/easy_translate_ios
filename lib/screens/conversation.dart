import '../utils/constants.dart';
import '../utils/extensions.dart';

import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:easy_translate/models/language.dart';
import 'package:easy_translate/models/conversation_message.dart';
import 'package:easy_translate/providers/conversation_provider.dart';
import 'package:easy_translate/providers/deps.dart';
import 'package:easy_translate/providers/settings_provider.dart';
import 'package:easy_translate/widgets/language_picker.dart';
import 'package:easy_translate/Google_Ads/BannerAds/BannerAdManager.dart';
import 'package:easy_translate/Google_Ads/RewardAds/RewardAdManager.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  ConversationProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final p = context.read<ConversationProvider>();
      await p.resetAll();
      if (!mounted) return;
      p.init();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<ConversationProvider>();
  }

  @override
  void dispose() {
    _provider?.resetAll();
    super.dispose();
  }

  Widget _layoutPicker(SettingsProvider sp, bool isChat) {
    return PopupMenuButton<ConversationMode>(
      tooltip: 'Conversation layout',
      position: PopupMenuPosition.under,
      icon: const Icon(Icons.view_agenda_outlined),
      onSelected: sp.setConversationMode,
      itemBuilder: (context) => [
        _modeMenuItem(
          context,
          value: ConversationMode.face,
          icon: Icons.group_outlined,
          label: 'Face-to-face',
          selected: !isChat,
        ),
        _modeMenuItem(
          context,
          value: ConversationMode.chat,
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chat',
          selected: isChat,
        ),
      ],
    );
  }

  PopupMenuItem<ConversationMode> _modeMenuItem(
    BuildContext context, {
    required ConversationMode value,
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return PopupMenuItem<ConversationMode>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(
            icon,
            color: selected ? scheme.primary : scheme.onSurface,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
            ),
          ),
          if (selected)
            Icon(Icons.check_rounded, color: scheme.primary, size: 18),
        ],
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    ConversationProvider p,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear conversation?'),
        content: const Text(
          'This will permanently delete the current conversation. '
          'Exported transcripts and history items are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.errorContainer,
              foregroundColor: context.colors.onErrorContainer,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) await p.clear();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ConversationProvider>();
    final sp = context.watch<SettingsProvider>();
    final mode = sp.settings.conversationMode;
    final isChat = mode == ConversationMode.chat;

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.conversation),
        bottom: p.isRetranslating ? const _RetranslatingBar() : null,
        actions: [
          if (!isChat) _layoutPicker(sp, isChat),
          IconButton(
            tooltip: 'Export',
            onPressed: p.messages.isEmpty
                ? null
                : () => RewardAdManager().loadAndShow(
                    callback: ({required bool rewardEarned}) {
                      SharePlus.instance.share(
                        ShareParams(text: p.exportText()),
                      );
                    },
                  ),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          if (isChat) ...[
            _layoutPicker(sp, isChat),
            IconButton(
              tooltip: 'Clear',
              onPressed: p.messages.isEmpty
                  ? null
                  : () => _confirmClear(context, p),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ],
      ),
      body: IndexedStack(
        index: isChat ? 0 : 1,
        children: [
          _ChatView(provider: p, isActive: isChat),
          _FaceView(provider: p),
        ],
      ),
      bottomNavigationBar: Offstage(
        offstage: isChat,
        child: BannerAdManager(initLoad: !isChat),
      ),
    );
  }
}

class _FaceView extends StatelessWidget {
  final ConversationProvider provider;
  const _FaceView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final p = provider;
    final hasAny =
        p.messages.isNotEmpty || p.isTranslating || p.activeSide != null;

    final aDisplay = _resolveDisplay(p, forLeftSide: true);
    final bDisplay = _resolveDisplay(p, forLeftSide: false);

    final surface = context.colors.surface;
    final panelGradient = [surface, surface];
    final panelGradientReversed = panelGradient;

    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 2,
            child: _SpeakerPanel(
              gradient: panelGradientReversed,
              label: 'Speaker B',
              language: Languages.byCode(p.rightLang),
              active: p.activeSide == false,
              disabled: p.activeSide == true || p.isTranslating,
              display: bDisplay,
              onTapMic: () {
                if (p.activeSide == false) {
                  p.stopListening();
                } else if (!p.isBusy) {
                  p.listenRight();
                }
              },
              onPickLanguage: () async {
                final l = await pickLanguage(context, selected: p.rightLang);
                if (l != null) p.setRight(l.code);
              },
            ),
          ),
        ),
        Container(height: 1, color: context.colors.outlineVariant),
        Expanded(
          child: _SpeakerPanel(
            gradient: panelGradient,
            label: 'Speaker A',
            language: Languages.byCode(p.leftLang),
            active: p.activeSide == true,
            disabled: p.activeSide == false || p.isTranslating,
            display: aDisplay,
            onTapMic: () {
              if (p.activeSide == true) {
                p.stopListening();
              } else if (!p.isBusy) {
                p.listenLeft();
              }
            },
            onPickLanguage: () async {
              final l = await pickLanguage(context, selected: p.leftLang);
              if (l != null) p.setLeft(l.code);
            },
          ),
        ),
        if (p.error != null)
          Container(
            width: double.infinity,
            color: context.colors.errorContainer,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              p.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.onErrorContainer),
            ),
          ),
        if (!hasAny)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Tap a mic to begin',
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  static _PanelDisplay _resolveDisplay(
    ConversationProvider p, {
    required bool forLeftSide,
  }) {
    final isThisSideListening = p.activeSide == (forLeftSide ? true : false);
    final isOtherSideListening = p.activeSide != null && !isThisSideListening;

    if (isThisSideListening) {
      return _PanelDisplay(
        mainText: p.partial.isEmpty ? null : p.partial,
        subText: 'Listening…',
      );
    }
    if (isOtherSideListening) {
      return const _PanelDisplay(subText: 'Listening to the other side…');
    }
    if (p.isTranslating) {
      final pendingFromThis = p.pendingFromLeft == forLeftSide;
      if (pendingFromThis) {
        return _PanelDisplay(
          mainText: p.pendingOriginal,
          subText: 'Translating…',
        );
      }
      return const _PanelDisplay(subText: 'Translating…', showLoader: true);
    }
    if (p.messages.isEmpty) return const _PanelDisplay();
    final latest = p.messages.last;
    final cameFromThisSide = latest.isLeftSpeaker == forLeftSide;
    return _PanelDisplay(
      mainText: cameFromThisSide ? latest.original : latest.translated,
      speakLang: cameFromThisSide ? latest.sourceLang : latest.targetLang,
    );
  }
}

class _PanelDisplay {
  final String? mainText;
  final String? subText;
  final bool showLoader;
  final String? speakLang;
  const _PanelDisplay({
    this.mainText,
    this.subText,
    this.showLoader = false,
    this.speakLang,
  });
}

class _SpeakerPanel extends StatelessWidget {
  final List<Color> gradient;
  final String label;
  final Language language;
  final bool active;
  final bool disabled;
  final _PanelDisplay display;
  final VoidCallback onTapMic;
  final VoidCallback onPickLanguage;

  const _SpeakerPanel({
    required this.gradient,
    required this.label,
    required this.language,
    required this.active,
    required this.disabled,
    required this.display,
    required this.onTapMic,
    required this.onPickLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: context.text.labelLarge?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Material(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onPickLanguage,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            language.flag,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            language.name,
                            style: context.text.labelLarge?.copyWith(
                              color: context.colors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.expand_more_rounded,
                            color: context.colors.onSurface,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(child: _PanelBody(display: display)),
            ),
            const SizedBox(height: 12),
            Center(
              child: _PanelMic(
                active: active,
                disabled: disabled,
                onTap: disabled ? null : onTapMic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelBody extends StatelessWidget {
  final _PanelDisplay display;
  const _PanelBody({required this.display});

  @override
  Widget build(BuildContext context) {
    final hasMain = display.mainText != null && display.mainText!.isNotEmpty;
    final hasSub = display.subText != null && display.subText!.isNotEmpty;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasMain) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                display.mainText!,
                textAlign: TextAlign.center,
                style: context.text.headlineSmall?.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            if (display.speakLang != null) ...[
              const SizedBox(height: 10),
              _PanelSpeakerButton(
                text: display.mainText!,
                lang: display.speakLang!,
              ),
            ],
          ] else if (!hasSub && !display.showLoader)
            Text(
              'Tap the mic to speak',
              textAlign: TextAlign.center,
              style: context.text.titleMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          if (display.showLoader) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: Lottie.asset(
                'assets/lottie/loading_dots.json',
                fit: BoxFit.contain,
              ),
            ),
          ],
          if (hasSub) ...[
            const SizedBox(height: 12),
            Text(
              display.subText!,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PanelMic extends StatelessWidget {
  final bool active;
  final bool disabled;
  final VoidCallback? onTap;
  const _PanelMic({
    required this.active,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final Color bg;
    final Color fg;
    if (disabled) {
      bg = scheme.surfaceContainerHighest.withValues(alpha: 0.6);
      fg = scheme.onSurface.withValues(alpha: 0.35);
    } else if (active) {
      bg = scheme.primary;
      fg = scheme.onPrimary;
    } else {
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurface;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 96 : 84,
      height: active ? 96 : 84,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: disabled
            ? const []
            : [
                BoxShadow(
                  color: (active ? scheme.primary : scheme.shadow).withValues(
                    alpha: active ? 0.35 : 0.12,
                  ),
                  blurRadius: active ? 22 : 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(
            active ? Icons.stop_rounded : Icons.mic_rounded,
            size: 40,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final ConversationProvider provider;
  final bool isActive;
  const _ChatView({required this.provider, required this.isActive});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final ScrollController _scroll = ScrollController();
  int _lastMsgCount = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _autoScroll() {
    if (!_scroll.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    if (p.messages.length != _lastMsgCount ||
        p.partial.isNotEmpty ||
        p.isTranslating) {
      final newCount = p.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lastMsgCount = newCount;
        _autoScroll();
      });
    }

    final isEmpty =
        p.messages.isEmpty && p.activeSide == null && !p.isTranslating;

    return Column(
      children: [
        Expanded(
          child: isEmpty
              ? _ChatEmpty(leftLang: p.leftLang, rightLang: p.rightLang)
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: p.messages.length + (_hasFooter(p) ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i < p.messages.length) {
                      final msg = p.messages[i];
                      return _ChatBubble(message: msg);
                    }
                    return _ChatFooter(provider: p);
                  },
                ),
        ),
        if (p.error != null)
          Container(
            width: double.infinity,
            color: context.colors.errorContainer,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              p.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.onErrorContainer),
            ),
          ),
        Align(
          alignment: Alignment.center,
          child: BannerAdManager(initLoad: widget.isActive),
        ),
        _ChatComposer(provider: p),
      ],
    );
  }

  bool _hasFooter(ConversationProvider p) =>
      p.activeSide != null || p.isTranslating;
}

class _ChatEmpty extends StatelessWidget {
  final String leftLang;
  final String rightLang;
  const _ChatEmpty({required this.leftLang, required this.rightLang});

  @override
  Widget build(BuildContext context) {
    final a = Languages.byCode(leftLang);
    final b = Languages.byCode(rightLang);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: context.colors.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${a.flag} ${a.name}  ↔  ${b.flag} ${b.name}',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Tap a mic below to begin.',
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ConversationMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isLeft = message.isLeftSpeaker;
    final lang = Languages.byCode(message.sourceLang);
    final tgtLang = Languages.byCode(message.targetLang);
    final time = DateFormat.jm().format(message.timestamp);
    final scheme = context.colors;
    final bubbleColor = scheme.primary;
    final fg = scheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isLeft
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                  child: Text(
                    '${lang.flag} ${isLeft ? "Speaker A" : "Speaker B"}',
                    style: context.text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isLeft ? 4 : 18),
                      bottomRight: Radius.circular(isLeft ? 18 : 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: bubbleColor.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        message.original,
                        style: context.text.bodyLarge?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(height: 1, color: fg.withValues(alpha: 0.25)),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tgtLang.flag,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              message.translated,
                              style: context.text.bodyMedium?.copyWith(
                                color: fg.withValues(alpha: 0.92),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    time,
                    style: context.text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelSpeakerButton extends StatelessWidget {
  final String text;
  final String lang;

  const _PanelSpeakerButton({required this.text, required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          try {
            await tts.stop();
          } catch (_) {}
          await tts.speak(
            text,
            lang: lang,
            rate: currentAppSettings.speechRate,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.volume_up_rounded,
                color: scheme.onPrimaryContainer,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Listen',
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatFooter extends StatelessWidget {
  final ConversationProvider provider;
  const _ChatFooter({required this.provider});

  @override
  Widget build(BuildContext context) {
    final p = provider;
    final scheme = context.colors;

    String? title;
    String? body;
    bool showLoader = false;

    if (p.activeSide != null) {
      title = p.activeSide == true
          ? 'Speaker A · Listening…'
          : 'Speaker B · Listening…';
      body = p.partial.isEmpty ? '…' : p.partial;
    } else if (p.isTranslating) {
      title = 'Translating…';
      body = p.pendingOriginal;
      showLoader = p.pendingOriginal == null;
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: p.activeSide == true || p.pendingFromLeft == true
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: context.text.labelSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              if (showLoader)
                SizedBox(
                  height: 28,
                  child: Lottie.asset(
                    'assets/lottie/loading_dots.json',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                )
              else if (body != null && body.isNotEmpty)
                Text(
                  body,
                  style: context.text.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  final ConversationProvider provider;
  const _ChatComposer({required this.provider});

  @override
  Widget build(BuildContext context) {
    final p = provider;
    final scheme = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _ComposerMicButton(
                label: 'Speaker A',
                language: Languages.byCode(p.leftLang),
                active: p.activeSide == true,
                disabled: p.activeSide == false || p.isTranslating,
                onTap: () {
                  if (p.activeSide == true) {
                    p.stopListening();
                  } else if (!p.isBusy) {
                    p.listenLeft();
                  }
                },
                onPickLanguage: () async {
                  final l = await pickLanguage(context, selected: p.leftLang);
                  if (l != null) p.setLeft(l.code);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ComposerMicButton(
                label: 'Speaker B',
                language: Languages.byCode(p.rightLang),
                active: p.activeSide == false,
                disabled: p.activeSide == true || p.isTranslating,
                onTap: () {
                  if (p.activeSide == false) {
                    p.stopListening();
                  } else if (!p.isBusy) {
                    p.listenRight();
                  }
                },
                onPickLanguage: () async {
                  final l = await pickLanguage(context, selected: p.rightLang);
                  if (l != null) p.setRight(l.code);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerMicButton extends StatelessWidget {
  final String label;
  final Language language;
  final bool active;
  final bool disabled;
  final VoidCallback onTap;
  final VoidCallback onPickLanguage;

  const _ComposerMicButton({
    required this.label,
    required this.language,
    required this.active,
    required this.disabled,
    required this.onTap,
    required this.onPickLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final bg = active ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = active ? scheme.onPrimary : scheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: active
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(
                  active ? Icons.stop_rounded : Icons.mic_rounded,
                  color: disabled ? fg.withValues(alpha: 0.4) : fg,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: context.text.labelSmall?.copyWith(
                          color: (disabled ? fg.withValues(alpha: 0.4) : fg)
                              .withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: onPickLanguage,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              language.flag,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                language.name,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodyMedium?.copyWith(
                                  color: disabled
                                      ? fg.withValues(alpha: 0.4)
                                      : fg,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.expand_more_rounded,
                              color: disabled ? fg.withValues(alpha: 0.4) : fg,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RetranslatingBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _RetranslatingBar();

  @override
  Size get preferredSize => const Size.fromHeight(32);

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return SizedBox(
      height: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Lottie.asset(
                      'assets/lottie/loading_dots.json',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Updating translations…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
