import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../character/character_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/lacquer_widgets.dart';
import 'quiz_data.dart';

/// Opens the 11-topic Quiz & Bronze Badge Hub
void showQuizHubModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kSurfaceLacquer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        maxChildSize: 0.92,
        minChildSize: 0.50,
        builder: (_, scrollController) {
          return _QuizHubSheetContent(
            scrollController: scrollController,
            onLaunchQuiz: (topicId) {
              Navigator.pop(ctx);
              showTopicQuizModal(context, topicId: topicId);
            },
          );
        },
      );
    },
  );
}

/// Opens a 3-question interactive quiz dialog for a specific topicId
Future<bool?> showTopicQuizModal(
  BuildContext context, {
  required String topicId,
}) {
  final quiz = kTopicQuizById[topicId];
  if (quiz == null) return Future.value(null);

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: _TopicQuizRunnerDialog(quiz: quiz),
      ),
    ),
  );
}

class _QuizHubSheetContent extends ConsumerWidget {
  final ScrollController scrollController;
  final ValueChanged<String> onLaunchQuiz;

  const _QuizHubSheetContent({
    required this.scrollController,
    required this.onLaunchQuiz,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(quizProvider);
    final double ratio = progress.totalCount == 0
        ? 0.0
        : progress.unlockedCount / progress.totalCount;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium_outlined,
                  size: 20, color: kAntiqueGold),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jian Gu Mastery Quizzes',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: kXuanPaper,
                        fontFamilyFallback: kSerifFontFallback,
                      ),
                    ),
                    Text(
                      '11 Topics · 3 Questions Each · Score 2/3 to Earn Bronze Seal',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: kTextSecondary,
                        fontFamilyFallback: kSansFontFallback,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded, color: kTextSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Overall bronze seal collection progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kSurfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: withAlphaColor(kAntiqueGold, 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Bronze Seals Collected: ${progress.unlockedCount} / ${progress.totalCount}',
                      style: const TextStyle(
                        color: kXuanPaper,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: kSansFontFallback,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${progress.totalCorrectBest} / ${progress.totalQuestions} Correct',
                      style: const TextStyle(
                        color: kAntiqueGold,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: kSansFontFallback,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: withAlphaColor(kTextMuted, 0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(kAntiqueGold),
                  ),
                ),
              ],
            ),
          ),
        ),

        Divider(color: withAlphaColor(kAntiqueGold, 0.3), height: 1),

        // 11 Topic Quiz cards
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: kAllTopicQuizzes.length,
            itemBuilder: (_, idx) {
              final quiz = kAllTopicQuizzes[idx];
              final best = progress.bestScoreFor(quiz.topicId);
              final unlocked = progress.isBadgeUnlocked(quiz.topicId);
              final perfect = progress.isPerfect(quiz.topicId);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: kSurfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: unlocked
                        ? withAlphaColor(kAntiqueGold, 0.72)
                        : withAlphaColor(kBronzePatina, 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    _BronzeSealEmblem(
                      monogram: quiz.badgeMonogram,
                      unlocked: unlocked,
                      perfect: perfect,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz.topicTitle,
                            style: const TextStyle(
                              color: kXuanPaper,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              fontFamilyFallback: kSerifFontFallback,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                unlocked
                                    ? '${quiz.badgeTitle} · Best $best/3'
                                    : (best > 0
                                        ? 'Best $best/3 · Need 2/3 to unlock'
                                        : '${quiz.categoryTitle} · 3 Questions'),
                                style: TextStyle(
                                  color: unlocked
                                      ? kAntiqueGold
                                      : kTextSecondary,
                                  fontSize: 12,
                                  fontFamilyFallback: kSansFontFallback,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => onLaunchQuiz(quiz.topicId),
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: unlocked
                              ? Colors.transparent
                              : kAntiqueGold,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: kAntiqueGold,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          unlocked ? 'Retake' : 'Start',
                          style: TextStyle(
                            color: unlocked ? kAntiqueGold : kBgXuanBlack,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            fontFamilyFallback: kSansFontFallback,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopicQuizRunnerDialog extends ConsumerStatefulWidget {
  final TopicQuiz quiz;

  const _TopicQuizRunnerDialog({required this.quiz});

  @override
  ConsumerState<_TopicQuizRunnerDialog> createState() =>
      _TopicQuizRunnerDialogState();
}

class _TopicQuizRunnerDialogState
    extends ConsumerState<_TopicQuizRunnerDialog> {
  int _currentIndex = 0;
  int? _selectedOption;
  int _score = 0;
  bool _finished = false;
  bool _newlyUnlocked = false;

  QuizQuestion get _question => widget.quiz.questions[_currentIndex];

  void _selectOption(int index) {
    if (_selectedOption != null) return;
    setState(() {
      _selectedOption = index;
      if (index == _question.correctIndex) {
        _score++;
      }
    });
  }

  void _advance() {
    if (_currentIndex + 1 < widget.quiz.questions.length) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
      });
    } else {
      final unlockedNow = ref.read(quizProvider.notifier).recordResult(
            topicId: widget.quiz.topicId,
            score: _score,
          );
      if (_score >= QuizProgressState.passThreshold) {
        // Trigger brief celebratory bow on the main guide sprite
        ref
            .read(characterProvider.notifier)
            .stopSpeaking(mood: 'happy', intent: 'Get_User_Name');
      }
      setState(() {
        _finished = true;
        _newlyUnlocked = unlockedNow;
      });
    }
  }

  void _retryQuiz() {
    setState(() {
      _currentIndex = 0;
      _selectedOption = null;
      _score = 0;
      _finished = false;
      _newlyUnlocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LacquerPanel(
      padding: const EdgeInsets.all(20),
      child: _finished ? _buildResultView() : _buildQuestionView(),
    );
  }

  Widget _buildQuestionView() {
    final bool answered = _selectedOption != null;
    final bool isCorrect = answered && _selectedOption == _question.correctIndex;
    const letters = ['A', 'B', 'C', 'D'];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Topic name + Question step + Close
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.quiz.topicTitle.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kAntiqueGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        fontFamilyFallback: kSansFontFallback,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Question ${_currentIndex + 1} of ${widget.quiz.questions.length}',
                          style: const TextStyle(
                            color: kTextSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            fontFamilyFallback: kSansFontFallback,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(widget.quiz.questions.length,
                              (i) {
                            final active = i == _currentIndex;
                            final passed = i < _currentIndex;
                            return Container(
                              margin: const EdgeInsets.only(right: 5),
                              width: active ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: passed
                                    ? kBronzePatina
                                    : (active
                                        ? kAntiqueGold
                                        : withAlphaColor(kTextMuted, 0.35)),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close quiz',
                icon: const Icon(Icons.close_rounded,
                    size: 19, color: kTextMuted),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Question text
          Text(
            _question.prompt,
            style: const TextStyle(
              color: kXuanPaper,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.5,
              fontFamilyFallback: kSerifFontFallback,
            ),
          ),

          const SizedBox(height: 16),

          // 4 Options
          for (int i = 0; i < _question.options.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildOptionTile(
              letter: letters[i],
              label: _question.options[i],
              index: i,
              answered: answered,
            ),
          ],

          // Explanation feedback after selection
          if (answered) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect
                    ? withAlphaColor(kBronzePatina, 0.22)
                    : withAlphaColor(kCinnabar, 0.18),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCorrect ? kBronzePatina : kCinnabar,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isCorrect
                        ? Icons.check_circle_outline_rounded
                        : Icons.info_outline_rounded,
                    size: 18,
                    color: isCorrect ? kAntiqueGold : kCinnabar,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCorrect ? 'Correct!' : 'Not quite right',
                          style: TextStyle(
                            color: isCorrect ? kAntiqueGold : kXuanPaper,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamilyFallback: kSansFontFallback,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _question.explanation,
                          style: const TextStyle(
                            color: kXuanPaper,
                            fontSize: 13.5,
                            height: 1.5,
                            fontFamilyFallback: kSerifFontFallback,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: kAntiqueGold,
                  foregroundColor: kBgXuanBlack,
                  minimumSize: const Size(120, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: _advance,
                child: Text(
                  _currentIndex + 1 < widget.quiz.questions.length
                      ? 'Next Question'
                      : 'View Results',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    fontFamilyFallback: kSansFontFallback,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String letter,
    required String label,
    required int index,
    required bool answered,
  }) {
    final bool isSelected = _selectedOption == index;
    final bool isCorrectOption = index == _question.correctIndex;

    Color bg = kSurfaceElevated;
    Color border = withAlphaColor(kAntiqueGold, 0.35);
    Color badgeBg = withAlphaColor(kAntiqueGold, 0.14);
    Color badgeText = kAntiqueGold;

    if (answered) {
      if (isCorrectOption) {
        bg = withAlphaColor(kBronzePatina, 0.28);
        border = kBronzePatina;
        badgeBg = kBronzePatina;
        badgeText = kXuanPaper;
      } else if (isSelected) {
        bg = withAlphaColor(kCinnabar, 0.24);
        border = kCinnabar;
        badgeBg = kCinnabar;
        badgeText = kXuanPaper;
      } else {
        bg = withAlphaColor(kSurfaceElevated, 0.55);
        border = withAlphaColor(kTextMuted, 0.2);
      }
    }

    return MouseRegion(
      cursor: answered ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: answered ? null : () => _selectOption(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    color: badgeText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamilyFallback: kSansFontFallback,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: (answered && !isCorrectOption && !isSelected)
                        ? kTextMuted
                        : kXuanPaper,
                    fontSize: 14,
                    height: 1.35,
                    fontFamilyFallback: kSansFontFallback,
                  ),
                ),
              ),
              if (answered && isCorrectOption)
                const Icon(Icons.check_rounded, size: 18, color: kAntiqueGold)
              else if (answered && isSelected && !isCorrectOption)
                const Icon(Icons.close_rounded, size: 18, color: kCinnabar),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final bool passed = _score >= QuizProgressState.passThreshold;
    final bool perfect = _score == widget.quiz.questions.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        _BronzeSealEmblem(
          monogram: widget.quiz.badgeMonogram,
          unlocked: passed,
          perfect: perfect,
          size: 72,
        ),
        const SizedBox(height: 14),
        Text(
          perfect
              ? 'Perfect Mastery!'
              : (passed ? 'Bronze Seal Earned!' : 'Keep Exploring'),
          style: const TextStyle(
            color: kXuanPaper,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamilyFallback: kSerifFontFallback,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Score: $_score / ${widget.quiz.questions.length}',
          style: const TextStyle(
            color: kAntiqueGold,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamilyFallback: kSansFontFallback,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          passed
              ? (_newlyUnlocked
                  ? 'You unlocked the "${widget.quiz.badgeTitle}" bronze seal for ${widget.quiz.topicTitle}.'
                  : 'Your "${widget.quiz.badgeTitle}" bronze seal stands gleaming in your collection.')
              : 'Score at least 2/3 to unlock the "${widget.quiz.badgeTitle}" bronze seal. Review the topic and try once more!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 14.5,
            height: 1.55,
            fontFamilyFallback: kSerifFontFallback,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: kTextSecondary,
                side: BorderSide(color: withAlphaColor(kBronzePatina, 0.85)),
                minimumSize: const Size(100, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: _retryQuiz,
              child: const Text('Try Again'),
            ),
            const SizedBox(width: 12),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: kAntiqueGold,
                foregroundColor: kBgXuanBlack,
                minimumSize: const Size(120, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () => Navigator.pop(context, passed),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Square bronze/cinnabar seal emblem rendered purely in code (zero extra image assets)
class _BronzeSealEmblem extends StatelessWidget {
  final String monogram;
  final bool unlocked;
  final bool perfect;
  final double size;

  const _BronzeSealEmblem({
    required this.monogram,
    required this.unlocked,
    required this.perfect,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final Color fillColor = unlocked
        ? (perfect ? kCinnabar : withAlphaColor(kBronzePatina, 0.88))
        : withAlphaColor(kBgXuanBlack, 0.85);
    final Color frameColor = unlocked
        ? (perfect ? kAntiqueGold : withAlphaColor(kXuanPaper, 0.72))
        : withAlphaColor(kTextMuted, 0.35);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: unlocked ? kAntiqueGold : withAlphaColor(kTextMuted, 0.35),
          width: perfect ? 1.6 : 1.0,
        ),
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: frameColor, width: 0.9),
          borderRadius: BorderRadius.circular(2),
        ),
        child: unlocked
            ? Text(
                monogram,
                style: TextStyle(
                  color: kXuanPaper,
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  fontFamilyFallback: kSerifFontFallback,
                ),
              )
            : Icon(
                Icons.lock_outline_rounded,
                size: size * 0.38,
                color: withAlphaColor(kTextMuted, 0.65),
              ),
      ),
    );
  }
}