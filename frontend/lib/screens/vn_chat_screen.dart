import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../character/character_provider.dart';
import '../character/character_stage.dart';
import '../core/app_strings.dart';
import '../core/external_link_opener.dart';
import '../drum/drum_audio_service.dart';
import '../drum/drum_stage_panel.dart';
import '../drum/drum_tutorial.dart';
import '../models/chat_response.dart';
import '../services/dialogflow_api.dart';
import '../theme/app_theme.dart';
import '../tts/tts_service.dart';
import '../widgets/chat_modals.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/museum_background.dart';
import '../quiz/quiz_data.dart';
import '../quiz/quiz_modal.dart';

class VisualNovelScreen extends ConsumerStatefulWidget {
  const VisualNovelScreen({super.key});

  @override
  ConsumerState<VisualNovelScreen> createState() => _VisualNovelScreenState();
}

class _VisualNovelScreenState extends ConsumerState<VisualNovelScreen> {
  final DialogflowApiService _apiService = DialogflowApiService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _dialogueScrollController = ScrollController();

  final ValueNotifier<String> _displayedTextNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _isTypingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasShownSkipHintNotifier =
      ValueNotifier<bool>(false);

  late String _sessionId;
  final List<ChatTurnRecord> _history = [];

  bool _hasShownPracticeLinkInSession = false;
  bool _practiceLinkDismissed = false;
  bool _showPracticeLinkOnCurrentReply = false;

  String _fullText = '';
  String _pendingDetail = '';
  String _pendingDetailChipLabel = '';
  List<SourceCitation> _currentSources = [];
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _characterMood = 'idle';
  String _lastMessage = 'Hi';
  String _lastIntent = '';
  int _requestId = 0;

  Timer? _typewriterTimer;

  static String _newSessionId() =>
      'user_${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _sessionId = _newSessionId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendMessage('Hi', isSystemTrigger: true);
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _displayedTextNotifier.dispose();
    _isTypingNotifier.dispose();
    _hasShownSkipHintNotifier.dispose();
    _textController.dispose();
    _dialogueScrollController.dispose();
    super.dispose();
  }

  void _scrollDialogueToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dialogueScrollController.hasClients) {
        _dialogueScrollController.jumpTo(
          _dialogueScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  String _extractName(String raw) {
    final cleaned = raw
        .replaceFirst(
          RegExp(r"^(my name is|i am|i'm|call me|it's)\s+", caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'[.!?,]+$'), '')
        .trim();
    return cleaned.isNotEmpty ? cleaned : raw.trim();
  }

  Future<void> _enterDrumMode({bool forceTutorial = false}) async {
    _typewriterTimer?.cancel();
    _isTypingNotifier.value = false;
    await ref.read(ttsProvider.notifier).stop(resetCharacter: false);

    setState(() {
      _showPracticeLinkOnCurrentReply = false;
    });

    ref
        .read(drumTutorialProvider.notifier)
        .prepareSession(forceTutorial: forceTutorial);

    final bool willRunTutorial =
        ref.read(drumTutorialProvider).step != DrumStep.free;

    ref.read(sceneModeProvider.notifier).state =
        willRunTutorial ? SceneMode.drumTutorial : SceneMode.drum;

    ref.read(characterProvider.notifier).setGuidingDrum();
  }

  void _exitDrumMode() {
    final tutState = ref.read(drumTutorialProvider);
    ref.read(sceneModeProvider.notifier).state = SceneMode.chat;

    final int strikes = tutState.sessionStrikes;
    final int maxCombo = tutState.maxCombo;
    final String realName = ref.read(userNameProvider).trim();

    if (strikes > 0) {
      final String summaryLog = AppStrings.practiceLog(strikes, maxCombo);
      final String guidePraise = strikes >= 20
          ? AppStrings.practicePraiseHigh(realName, strikes, maxCombo)
          : AppStrings.practicePraiseStandard(realName, strikes, maxCombo);

      setState(() {
        _showPracticeLinkOnCurrentReply = false;
        _history.add(ChatTurnRecord(isUser: true, text: summaryLog));
        _history.add(ChatTurnRecord(
          isUser: false,
          text: guidePraise,
          intent: 'Drum_Practice_Summary',
        ));
        _characterMood = 'happy';
        _lastIntent = 'Get_User_Name';
      });

      _presentReply(guidePraise, enableTts: true);
    } else {
      ref.read(characterProvider.notifier).returnToIdle();
    }
  }

  void _resetConversation() {
    _requestId++;
    _typewriterTimer?.cancel();
    _isTypingNotifier.value = false;
    _displayedTextNotifier.value = '';
    ref.read(sceneModeProvider.notifier).state = SceneMode.chat;
    ref.read(onboardingProvider.notifier).state = Onboarding.askName;
    ref.read(userNameProvider.notifier).state = '';
    ref.read(ttsProvider.notifier).stop(resetCharacter: false);
    ref.read(characterProvider.notifier).returnToIdle();
    setState(() {
      _sessionId = _newSessionId();
      _history.clear();
      _hasShownPracticeLinkInSession = false;
      _practiceLinkDismissed = false;
      _showPracticeLinkOnCurrentReply = false;
      _isLoading = false;
      _hasError = false;
      _showSuggestions = false;
      _suggestions = [];
      _currentSources = [];
      _pendingDetail = '';
      _pendingDetailChipLabel = '';
      _fullText = '';
      _characterMood = 'idle';
      _lastIntent = '';
    });
    _sendMessage('Hi', isSystemTrigger: true);
  }

  void _handleExpandDetail() {
    if (_pendingDetail.isEmpty || _isLoading) return;
    final detailText = _pendingDetail;
    final detailLabel = _pendingDetailChipLabel;
    setState(() {
      _pendingDetail = '';
      _pendingDetailChipLabel = '';
      _showSuggestions = false;
      _showPracticeLinkOnCurrentReply = false;
      _history.add(ChatTurnRecord(isUser: true, text: detailLabel));
      _history.add(ChatTurnRecord(
        isUser: false,
        text: detailText,
        intent: _lastIntent,
        sources: _currentSources,
      ));
    });
    _presentReply(detailText);
  }

  Future<void> _sendMessage(String text, {bool isSystemTrigger = false}) async {
    final msg = text.trim();
    if (msg.isEmpty || _isLoading) return;

    final myRequestId = ++_requestId;
    _typewriterTimer?.cancel();
    _isTypingNotifier.value = false;
    await ref.read(ttsProvider.notifier).stop(resetCharacter: false);

    final bool wasAskingName =
        !isSystemTrigger && ref.read(onboardingProvider) == Onboarding.askName;
    if (wasAskingName) {
      ref.read(userNameProvider.notifier).state = _extractName(msg);
      ref.read(onboardingProvider.notifier).state = Onboarding.ready;
    }

    ref.read(characterProvider.notifier).setThinking();

    setState(() {
      _isLoading = true;
      _hasError = false;
      _showSuggestions = false;
      _showPracticeLinkOnCurrentReply = false;
      _suggestions = [];
      _currentSources = [];
      _pendingDetail = '';
      _pendingDetailChipLabel = '';
      _lastMessage = msg;
      if (!isSystemTrigger) {
        _textController.clear();
        _history.add(ChatTurnRecord(isUser: true, text: msg));
      }
    });

    try {
      final res = await _apiService.sendMessage(
        sessionId: _sessionId,
        text: msg,
        knownUserName: ref.read(userNameProvider),
        isSystemTrigger: isSystemTrigger,
      );

      if (!mounted || myRequestId != _requestId) return;

      final bool isReady = ref.read(onboardingProvider) == Onboarding.ready;

      bool shouldShowPracticeLink = false;
      if (isReady &&
          res.suggestPractice &&
          !_hasShownPracticeLinkInSession &&
          !_practiceLinkDismissed) {
        shouldShowPracticeLink = true;
        _hasShownPracticeLinkInSession = true;
      }

      setState(() {
        _isLoading = false;
        _characterMood = res.mood;
        _lastIntent = res.intent;
        _pendingDetail = res.detail;
        _pendingDetailChipLabel = res.detailChipLabel;
        _currentSources = res.sources;
        _showPracticeLinkOnCurrentReply = shouldShowPracticeLink;
        _suggestions = isReady ? res.suggestions : [];
        _history.add(ChatTurnRecord(
          isUser: false,
          text: res.reply,
          intent: res.intent,
          sources: res.sources,
        ));
      });

      _presentReply(res.reply);
    } on TimeoutException {
      if (mounted && myRequestId == _requestId) {
        _showError(AppStrings.errorTimeout);
      }
    } catch (_) {
      if (mounted && myRequestId == _requestId) {
        _showError(AppStrings.errorConnection);
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _hasError = true;
      _characterMood = 'confused';
      _suggestions = [DialogflowApiService.retryLabel];
      _currentSources = [];
      _pendingDetail = '';
      _pendingDetailChipLabel = '';
      _showPracticeLinkOnCurrentReply = false;
    });
    _presentReply(message, enableTts: false);
  }

  void _presentReply(String targetText, {bool enableTts = true}) {
    final ttsState = ref.read(ttsProvider);
    final bool shouldSpeak =
        enableTts && ttsState.autoPlay && !ttsState.isMuted;

    if (shouldSpeak) {
      ref.read(ttsProvider.notifier).speak(
            targetText,
            mood: _characterMood,
            intent: _lastIntent,
          );
    }

    _startTypewriterEffect(targetText, drivenByTts: shouldSpeak);
  }

  void _onSuggestionTap(String suggestion) {
    if (suggestion == DialogflowApiService.retryLabel) {
      _sendMessage(_lastMessage, isSystemTrigger: true);
    } else {
      _sendMessage(suggestion);
    }
  }

  Future<void> _handleReferenceTap(SourceCitation src) async {
    if (src.isInternal && src.topicId != null) {
      await ref.read(ttsProvider.notifier).stop();
      if (!mounted) return;
      final selectedQuery = await Navigator.of(context).pushNamed(
        '/topics/${src.topicId}',
      );
      if (mounted && selectedQuery is String && selectedQuery.isNotEmpty) {
        _sendMessage(selectedQuery);
      }
      return;
    }

    if (src.isExternal && src.url != null) {
      await openExternalUrl(src.url!);
    }
  }

  void _startTypewriterEffect(String targetText, {required bool drivenByTts}) {
    _typewriterTimer?.cancel();
    _fullText = targetText;
    final charNotifier = ref.read(characterProvider.notifier);

    _displayedTextNotifier.value = '';
    _isTypingNotifier.value = true;
    if (!drivenByTts) {
      charNotifier.startSpeaking(mood: _characterMood, intent: _lastIntent);
    }

    final chars = targetText.runes.map(String.fromCharCode).toList();
    final buffer = StringBuffer();
    int charIndex = 0;

    _typewriterTimer =
        Timer.periodic(const Duration(milliseconds: 22), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (charIndex < chars.length) {
        buffer.write(chars[charIndex]);
        charIndex++;
        _displayedTextNotifier.value = buffer.toString();
        _scrollDialogueToBottom();
      } else {
        timer.cancel();
        _isTypingNotifier.value = false;
        _hasShownSkipHintNotifier.value = true;
        if (!ref.read(ttsProvider).isSpeaking) {
          charNotifier.stopSpeaking(mood: _characterMood, intent: _lastIntent);
        }
        if (_suggestions.isNotEmpty || _pendingDetail.isNotEmpty) {
          setState(() => _showSuggestions = true);
        }
        _scrollDialogueToBottom();
      }
    });
  }

  void _skipTypewriter() {
    if (_isTypingNotifier.value) {
      _typewriterTimer?.cancel();
      _isTypingNotifier.value = false;
      _hasShownSkipHintNotifier.value = true;
      _displayedTextNotifier.value = _fullText;
      if (!ref.read(ttsProvider).isSpeaking) {
        ref
            .read(characterProvider.notifier)
            .stopSpeaking(mood: _characterMood, intent: _lastIntent);
      }
      if (_suggestions.isNotEmpty || _pendingDetail.isNotEmpty) {
        setState(() => _showSuggestions = true);
      }
      _scrollDialogueToBottom();
    }
  }

  void _handleToggleSpeak() {
    final ttsState = ref.read(ttsProvider);
    final ttsNotifier = ref.read(ttsProvider.notifier);
    if (ttsState.isSpeaking) {
      ttsNotifier.stop();
    } else if (_fullText.isNotEmpty) {
      ttsNotifier.speak(
        _fullText,
        mood: _characterMood,
        intent: _lastIntent,
        force: true,
      );
    }
  }

  Future<void> _rateCurrentResponse(int rating) async {
    final botTurns = _history.where((t) => !t.isUser).toList();
    if (botTurns.isEmpty) return;
    final latestBot = botTurns.last;
    if (latestBot.rating == rating) return;

    setState(() => latestBot.rating = rating);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: kSurfaceElevated,
        content: Text(
          rating > 0
              ? AppStrings.feedbackPositiveToast
              : AppStrings.feedbackNegativeToast,
          style: const TextStyle(color: kXuanPaper),
        ),
      ),
    );

    await _apiService.sendFeedback(
      sessionId: _sessionId,
      intent: latestBot.intent,
      reply: latestBot.text,
      rating: rating,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 640;
    final ttsState = ref.watch(ttsProvider);
    final drumAudio = ref.watch(drumAudioProvider);
    final onboarding = ref.watch(onboardingProvider);
    final sceneMode = ref.watch(sceneModeProvider);
    final quizProgress = ref.watch(quizProvider); 

    final bool inDrumMode = sceneMode != SceneMode.chat;
    final bool isReadyPhase = onboarding == Onboarding.ready;
    final latestBotTurn = _history.where((t) => !t.isUser).lastOrNull;
    final currentRating = latestBotTurn?.rating ?? 0;

    final double maxChatPanelHeight = (size.height * 0.40).clamp(230.0, 350.0);
    final bool showRightGuideInDrum = inDrumMode && isWide;
    final bool hasDetailButton =
        _pendingDetail.isNotEmpty && _pendingDetailChipLabel.isNotEmpty;
    final bool showQuestionPanel =
        !inDrumMode &&
        (isReadyPhase || _hasError) &&
        _showSuggestions &&
        (hasDetailButton || _suggestions.isNotEmpty) &&
        !_isLoading;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Museum blurred bronze background
          const Positioned.fill(child: MuseumBackground()),

          // 1.5 Shared exhibition stone horizon in drum mode
          AnimatedPositioned(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: inDrumMode ? 195 : -120,
            height: 76,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 360),
                opacity: inDrumMode ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        withAlphaColor(kBgXuanBlack, 0.82),
                        kBgXuanBlack,
                      ],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: withAlphaColor(kAntiqueGold, 0.22),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Right-side character stage during wide Drum Practice
          if (showRightGuideInDrum)
            Positioned.fill(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 28, bottom: 200),
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: CharacterStage(
                          maxHeight: (size.height * 0.44).clamp(260.0, 400.0),
                          softBottomFade: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 3. Foreground Layout
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TopToolbar(
                        historyCount: _history.length,
                        unlockedBadges: quizProgress.unlockedCount,
                        totalBadges: quizProgress.totalCount,
                        isMuted: inDrumMode ? drumAudio.isMuted : ttsState.isMuted,
                        sceneMode: sceneMode,
                        onOpenTopics: () {
                          ref.read(ttsProvider.notifier).stop();
                          showTopicsBottomSheet(
                            context,
                            onSelectQuery: (query) => _sendMessage(query),
                            onStartTopicQuiz: (topicId) {
                              showTopicQuizModal(context, topicId: topicId);
                            },
                          );
                        },
                        onOpenQuizzes: () {
                          ref.read(ttsProvider.notifier).stop();
                          showQuizHubModal(context);
                        },
                        onOpenHistory: () {
                          ref.read(ttsProvider.notifier).stop();
                          showHistoryBottomSheet(context, _history);
                        },
                        onToggleDrumMode: () {
                          if (inDrumMode) {
                            _exitDrumMode();
                          } else {
                            _enterDrumMode();
                          }
                        },
                        onToggleMute: () {
                          if (inDrumMode) {
                            ref.read(drumAudioProvider.notifier).toggleMute();
                          } else {
                            ref.read(ttsProvider.notifier).toggleMute();
                          }
                        },
                        onOpenVoiceSettings: () => showVoiceSettingsDialog(context),
                      ),

                      if (!inDrumMode) ...[
                        // Upper stage: Character + Right-aligned Suggested Questions (with Details pinned at top)
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final bool canSideBySide =
                                  constraints.maxWidth >= 660;

                              if (canSideBySide) {
                                final double panelWidth =
                                    (constraints.maxWidth * 0.31)
                                        .clamp(220.0, 264.0);
                                final Alignment charAlign = (showQuestionPanel &&
                                        constraints.maxWidth < 800)
                                    ? const Alignment(-0.32, 1.0)
                                    : Alignment.bottomCenter;

                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: AnimatedAlign(
                                        duration:
                                            const Duration(milliseconds: 280),
                                        curve: Curves.easeOutCubic,
                                        alignment: charAlign,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: CharacterStage(
                                            maxHeight:
                                                constraints.maxHeight * 0.94,
                                            softBottomFade: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 10,
                                      child: _SuggestedQuestionsDock(
                                        visible: showQuestionPanel,
                                        width: panelWidth,
                                        detailLabel: hasDetailButton
                                            ? _pendingDetailChipLabel
                                            : null,
                                        onExpandDetail: _handleExpandDetail,
                                        questions: _suggestions,
                                        onSelect: _onSuggestionTap,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              // Narrow / mobile width
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (_, charBox) {
                                        return Align(
                                          alignment: Alignment.bottomCenter,
                                          child: CharacterStage(
                                            maxHeight:
                                                charBox.maxHeight * 0.95,
                                            softBottomFade: true,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (showQuestionPanel)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 6, bottom: 8),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: _SuggestedQuestionsDock(
                                          visible: true,
                                          width: constraints.maxWidth
                                              .clamp(220.0, 340.0),
                                          detailLabel: hasDetailButton
                                              ? _pendingDetailChipLabel
                                              : null,
                                          onExpandDetail: _handleExpandDetail,
                                          questions: _suggestions,
                                          onSelect: _onSuggestionTap,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        DialogueBox(
                          displayedTextListenable: _displayedTextNotifier,
                          isTypingListenable: _isTypingNotifier,
                          hasShownSkipHintListenable: _hasShownSkipHintNotifier,
                          maxPanelHeight: maxChatPanelHeight,
                          isLoading: _isLoading,
                          hasError: _hasError,
                          isReadyPhase: isReadyPhase,
                          isSpeakingTts: ttsState.isSpeaking,
                          canReplayTts:
                              _fullText.isNotEmpty && !ttsState.isMuted,
                          showPracticeLink: _showPracticeLinkOnCurrentReply,
                          sources: _currentSources,
                          currentRating: currentRating,
                          textController: _textController,
                          scrollController: _dialogueScrollController,
                          onSkipTypewriter: _skipTypewriter,
                          onReset: _resetConversation,
                          onToggleSpeak: _handleToggleSpeak,
                          onOpenDrumPractice: () {
                            setState(() {
                              _showPracticeLinkOnCurrentReply = false;
                            });
                            _enterDrumMode();
                          },
                          onDismissPracticeLink: () {
                            setState(() {
                              _practiceLinkDismissed = true;
                              _showPracticeLinkOnCurrentReply = false;
                            });
                          },
                          onSend: (val) => _sendMessage(val),
                          onRate: _rateCurrentResponse,
                          onSourceTap: _handleReferenceTap,
                        ),
                      ] else ...[
                        const Spacer(),
                        const DrumStagePanel(key: ValueKey('drum_stage')),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Right-aligned stack above the dialogue box: Details pinned at top, followed by Suggested Questions
class _SuggestedQuestionsDock extends StatelessWidget {
  final bool visible;
  final double width;
  final String? detailLabel;
  final VoidCallback onExpandDetail;
  final List<String> questions;
  final ValueChanged<String> onSelect;

  const _SuggestedQuestionsDock({
    required this.visible,
    required this.width,
    required this.detailLabel,
    required this.onExpandDetail,
    required this.questions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDetail = detailLabel != null && detailLabel!.isNotEmpty;
    final items = questions.take(3).toList();
    final bool hasAny = hasDetail || items.isNotEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: (visible && hasAny)
          ? SizedBox(
              key: ValueKey('${detailLabel ?? ''}|${items.join('|')}'),
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6, right: 2),
                    child: Text(
                      AppStrings.suggestedQuestionsTitle,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: kAntiqueGold,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontFamilyFallback: kSansFontFallback,
                      ),
                    ),
                  ),
                  if (hasDetail) ...[
                    _DetailDockItem(
                      label: detailLabel!,
                      onTap: onExpandDetail,
                    ),
                    if (items.isNotEmpty) const SizedBox(height: 6),
                  ],
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 6),
                    _QuestionDockItem(
                      label: items[i],
                      onTap: () => onSelect(items[i]),
                    ),
                  ],
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Pinned top item for expanding the current answer's full details (patina-green accent)
class _DetailDockItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _DetailDockItem({required this.label, required this.onTap});

  @override
  State<_DetailDockItem> createState() => _DetailDockItemState();
}

class _DetailDockItemState extends State<_DetailDockItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered
            ? withAlphaColor(kBronzePatina, 0.36)
            : withAlphaColor(kBronzePatina, 0.24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: _hovered
                ? kAntiqueGold
                : withAlphaColor(kBronzePatina, 0.9),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                const Icon(
                  Icons.unfold_more_rounded,
                  size: 15,
                  color: kAntiqueGold,
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: withAlphaColor(kBronzePatina, 0.65),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    AppStrings.detailsBadge,
                    style: TextStyle(
                      color: kXuanPaper,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      fontFamilyFallback: kSansFontFallback,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kXuanPaper,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      fontFamilyFallback: kSansFontFallback,
                    ),
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

class _QuestionDockItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _QuestionDockItem({required this.label, required this.onTap});

  @override
  State<_QuestionDockItem> createState() => _QuestionDockItemState();
}

class _QuestionDockItemState extends State<_QuestionDockItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered
            ? withAlphaColor(kSurfaceElevated, 0.96)
            : withAlphaColor(kSurfaceLacquer, 0.90),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: _hovered
                ? kAntiqueGold
                : withAlphaColor(kAntiqueGold, 0.55),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kXuanPaper,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      fontFamilyFallback: kSansFontFallback,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: _hovered
                      ? kAntiqueGold
                      : withAlphaColor(kAntiqueGold, 0.75),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}