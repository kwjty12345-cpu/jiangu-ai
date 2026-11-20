import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../models/chat_response.dart';
import '../theme/app_theme.dart';
import 'lacquer_widgets.dart';

class DialogueBox extends StatefulWidget {
  final ValueListenable<String> displayedTextListenable;
  final ValueListenable<bool> isTypingListenable;
  final ValueListenable<bool> hasShownSkipHintListenable;
  final double maxPanelHeight;
  final bool isLoading;
  final bool hasError;
  final bool isReadyPhase;
  final bool isSpeakingTts;
  final bool canReplayTts;
  final bool showPracticeLink;
  final List<SourceCitation> sources;
  final int currentRating;
  final TextEditingController textController;
  final ScrollController scrollController;
  final VoidCallback onSkipTypewriter;
  final VoidCallback onReset;
  final VoidCallback onToggleSpeak;
  final VoidCallback onOpenDrumPractice;
  final VoidCallback onDismissPracticeLink;
  final ValueChanged<String> onSend;
  final ValueChanged<int> onRate;
  final ValueChanged<SourceCitation> onSourceTap;

  const DialogueBox({
    super.key,
    required this.displayedTextListenable,
    required this.isTypingListenable,
    required this.hasShownSkipHintListenable,
    required this.maxPanelHeight,
    required this.isLoading,
    required this.hasError,
    required this.isReadyPhase,
    required this.isSpeakingTts,
    required this.canReplayTts,
    required this.showPracticeLink,
    required this.sources,
    required this.currentRating,
    required this.textController,
    required this.scrollController,
    required this.onSkipTypewriter,
    required this.onReset,
    required this.onToggleSpeak,
    required this.onOpenDrumPractice,
    required this.onDismissPracticeLink,
    required this.onSend,
    required this.onRate,
    required this.onSourceTap,
  });

  @override
  State<DialogueBox> createState() => _DialogueBoxState();
}

class _DialogueBoxState extends State<DialogueBox> {
  bool _showFeedbackBar = false;
  bool _sourcesExpanded = false;

  @override
  void didUpdateWidget(covariant DialogueBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sources != widget.sources) {
      _sourcesExpanded = false;
    }
  }

  /// Archival "REFERENCES" block clearly separated from the reply text
  Widget _buildReferencesSection() {
    if (widget.sources.isEmpty) return const SizedBox.shrink();

    final bool hasOverflow = widget.sources.length > 3;
    final List<SourceCitation> visibleSources =
        (!hasOverflow || _sourcesExpanded)
            ? widget.sources
            : widget.sources.take(3).toList();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: withAlphaColor(kTextMuted, 0.22),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 12,
                color: kTextMuted,
              ),
              const SizedBox(width: 6),
              const Text(
                AppStrings.referencesHeader,
                style: TextStyle(
                  color: kTextMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontFamilyFallback: kSansFontFallback,
                ),
              ),
              if (hasOverflow) ...[
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(3),
                  onTap: () =>
                      setState(() => _sourcesExpanded = !_sourcesExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _sourcesExpanded
                          ? AppStrings.showLess
                          : AppStrings.sourcesToggle(widget.sources.length),
                      style: const TextStyle(
                        color: kAntiqueGold,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: kSansFontFallback,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: visibleSources
                .map((src) => _ReferenceTag(
                      source: src,
                      onTap: () => widget.onSourceTap(src),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _showFeedbackBar = true),
      onExit: (_) => setState(() => _showFeedbackBar = false),
      child: GestureDetector(
        onTap: widget.onSkipTypewriter,
        onLongPress: () => setState(() => _showFeedbackBar = !_showFeedbackBar),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxPanelHeight),
          child: LacquerPanel(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SealNameplate(),
                    const Spacer(),
                    ValueListenableBuilder<bool>(
                      valueListenable: widget.isTypingListenable,
                      builder: (_, isTyping, __) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: widget.hasShownSkipHintListenable,
                          builder: (_, hasShown, __) {
                            if (isTyping && !hasShown) {
                              return const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Text(
                                  AppStrings.tapToSkip,
                                  style: TextStyle(
                                    color: kTextMuted,
                                    fontSize: 12,
                                    fontFamilyFallback: kSansFontFallback,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                    if (widget.canReplayTts && !widget.isLoading)
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: widget.onToggleSpeak,
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: widget.isSpeakingTts
                                ? withAlphaColor(kBronzePatina, 0.28)
                                : Colors.transparent,
                            border: Border.all(
                              color: widget.isSpeakingTts
                                  ? kAntiqueGold
                                  : withAlphaColor(kBronzePatina, 0.7),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ChineseLineIcon(
                                type: widget.isSpeakingTts
                                    ? ChineseIconType.soundMuted
                                    : ChineseIconType.sound,
                                size: 15,
                                color: widget.isSpeakingTts
                                    ? kAntiqueGold
                                    : kXuanPaper,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.isSpeakingTts
                                    ? AppStrings.stop
                                    : AppStrings.listen,
                                style: const TextStyle(
                                  color: kXuanPaper,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamilyFallback: kSansFontFallback,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: AppStrings.restartTooltip,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: widget.onReset,
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: kTextMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 2. Scrollable reply body + References footer
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    controller: widget.scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    color: kAntiqueGold,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  AppStrings.loadingArchives,
                                  style: TextStyle(
                                    color: kTextSecondary,
                                    fontSize: 15.5,
                                    fontFamilyFallback: kSerifFontFallback,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ValueListenableBuilder<String>(
                            valueListenable: widget.displayedTextListenable,
                            builder: (_, displayedText, __) {
                              return Text(
                                displayedText,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: widget.hasError
                                      ? const Color(0xFFD98A7C)
                                      : kXuanPaper,
                                  fontSize: 17,
                                  height: 1.65,
                                  fontFamilyFallback: kSerifFontFallback,
                                ),
                              );
                            },
                          ),

                        ValueListenableBuilder<bool>(
                          valueListenable: widget.isTypingListenable,
                          builder: (_, isTyping, __) {
                            return ValueListenableBuilder<String>(
                              valueListenable: widget.displayedTextListenable,
                              builder: (_, displayedText, __) {
                                if (widget.isLoading ||
                                    isTyping ||
                                    displayedText.isEmpty ||
                                    widget.hasError) {
                                  return const SizedBox.shrink();
                                }

                                final bool revealFeedback = _showFeedbackBar ||
                                    widget.currentRating != 0;

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Archival References
                                    _buildReferencesSection(),

                                    // Compact Drum Practice link + subtle thumbs
                                    if (widget.showPracticeLink ||
                                        revealFeedback) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (widget.showPracticeLink)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                  onTap:
                                                      widget.onOpenDrumPractice,
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 3,
                                                            horizontal: 2),
                                                    child: Text(
                                                      AppStrings
                                                          .inlinePracticeLink,
                                                      style: TextStyle(
                                                        color: kAntiqueGold,
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamilyFallback:
                                                            kSansFontFallback,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Tooltip(
                                                  message:
                                                      AppStrings.dismissTooltip,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                    onTap: widget
                                                        .onDismissPracticeLink,
                                                    child: const Padding(
                                                      padding:
                                                          EdgeInsets.all(3),
                                                      child: Icon(
                                                        Icons.close_rounded,
                                                        size: 13,
                                                        color: kTextMuted,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          const Spacer(),
                                          AnimatedOpacity(
                                            duration: const Duration(
                                                milliseconds: 180),
                                            opacity: revealFeedback ? 1.0 : 0.0,
                                            child: IgnorePointer(
                                              ignoring: !revealFeedback,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  InkWell(
                                                    onTap: () =>
                                                        widget.onRate(1),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      child: Icon(
                                                        widget.currentRating ==
                                                                1
                                                            ? Icons
                                                                .thumb_up_rounded
                                                            : Icons
                                                                .thumb_up_outlined,
                                                        size: 14,
                                                        color: widget
                                                                    .currentRating ==
                                                                1
                                                            ? kAntiqueGold
                                                            : kTextMuted,
                                                      ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () =>
                                                        widget.onRate(-1),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5),
                                                      child: Icon(
                                                        widget.currentRating ==
                                                                -1
                                                            ? Icons
                                                                .thumb_down_rounded
                                                            : Icons
                                                                .thumb_down_outlined,
                                                        size: 14,
                                                        color: widget
                                                                    .currentRating ==
                                                                -1
                                                            ? kAntiqueGold
                                                            : kTextMuted,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 3. Input bar
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: withAlphaColor(kAntiqueGold, 0.72),
                        width: 1.1,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.textController,
                          enabled: !widget.isLoading,
                          style: const TextStyle(
                            color: kXuanPaper,
                            fontSize: 14.5,
                            fontFamilyFallback: kSansFontFallback,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.isReadyPhase
                                ? AppStrings.inputHintReady
                                : AppStrings.inputHintName,
                            hintStyle: const TextStyle(
                              color: kTextMuted,
                              fontSize: 14,
                              fontFamilyFallback: kSansFontFallback,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onSubmitted: widget.onSend,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: AppStrings.sendTooltip,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: widget.isLoading
                              ? null
                              : () => widget.onSend(widget.textController.text),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: widget.isLoading
                                  ? withAlphaColor(kTextMuted, 0.4)
                                  : kAntiqueGold,
                            ),
                          ),
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

class _ReferenceTag extends StatefulWidget {
  final SourceCitation source;
  final VoidCallback onTap;

  const _ReferenceTag({required this.source, required this.onTap});

  @override
  State<_ReferenceTag> createState() => _ReferenceTagState();
}

class _ReferenceTagState extends State<_ReferenceTag> {
  bool _hovered = false;
  bool _focused = false;

  IconData _iconForType(ReferenceType type) {
    switch (type) {
      case ReferenceType.topic:
        return Icons.article_outlined;
      case ReferenceType.artifact:
        return Icons.account_balance_outlined;
      case ReferenceType.external:
        return Icons.open_in_new_rounded;
    }
  }

  String _typeLabel(ReferenceType type) {
    switch (type) {
      case ReferenceType.topic:
        return AppStrings.refTypeTopic;
      case ReferenceType.artifact:
        return AppStrings.refTypeArtifact;
      case ReferenceType.external:
        return AppStrings.refTypeExternal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool active = _hovered || _focused;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onFocusChange: (f) => setState(() => _focused = f),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: active
                ? withAlphaColor(kAntiqueGold, 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: Border(
              bottom: BorderSide(
                color: active
                    ? kAntiqueGold
                    : withAlphaColor(kTextMuted, 0.45),
                width: _focused ? 1.4 : 0.9,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _iconForType(widget.source.type),
                size: 13,
                color: active ? kAntiqueGold : kTextMuted,
              ),
              const SizedBox(width: 5),
              Text(
                '${_typeLabel(widget.source.type)}:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: active ? kAntiqueGold : kTextMuted,
                  fontFamilyFallback: kSansFontFallback,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.source.title,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 12,
                    color: active ? kXuanPaper : kTextSecondary,
                    height: 1.35,
                    fontFamilyFallback: kSansFontFallback,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}