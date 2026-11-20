import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_strings.dart';
import '../drum/drum_tutorial.dart';
import '../models/chat_response.dart';
import '../quiz/quiz_data.dart';
import '../theme/app_theme.dart';
import '../tts/tts_service.dart';
import 'lacquer_widgets.dart';

class TopToolbar extends StatelessWidget {
  final int historyCount;
  final int unlockedBadges;
  final int totalBadges;
  final bool isMuted;
  final SceneMode sceneMode;
  final VoidCallback onOpenTopics;
  final VoidCallback onOpenQuizzes;
  final VoidCallback onOpenHistory;
  final VoidCallback onToggleDrumMode;
  final VoidCallback onToggleMute;
  final VoidCallback onOpenVoiceSettings;

  const TopToolbar({
    super.key,
    required this.historyCount,
    required this.unlockedBadges,
    required this.totalBadges,
    required this.isMuted,
    required this.sceneMode,
    required this.onOpenTopics,
    required this.onOpenQuizzes,
    required this.onOpenHistory,
    required this.onToggleDrumMode,
    required this.onToggleMute,
    required this.onOpenVoiceSettings,
  });

  @override
  Widget build(BuildContext context) {
    final bool inDrumMode = sceneMode != SceneMode.chat;
    final bool isCompact = MediaQuery.of(context).size.width < 640;
    final bool showHistory = historyCount >= 2 || inDrumMode;
    final String quizLabel = 'Quiz ($unlockedBadges/$totalBadges)';

    return Row(
      children: [
        _buildPrimaryDrumButton(inDrumMode: inDrumMode),
        const SizedBox(width: 8),

        if (!isCompact)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: inDrumMode ? 0.36 : 1.0,
            child: IgnorePointer(
              ignoring: inDrumMode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSecondaryTab(
                    iconWidget: const ChineseLineIcon(
                      type: ChineseIconType.scroll,
                      size: 16,
                      color: kAntiqueGold,
                    ),
                    label: AppStrings.topics,
                    onTap: onOpenTopics,
                  ),
                  const SizedBox(width: 8),
                  _buildSecondaryTab(
                    iconWidget: const Icon(
                      Icons.workspace_premium_outlined,
                      size: 16,
                      color: kAntiqueGold,
                    ),
                    label: quizLabel,
                    onTap: onOpenQuizzes,
                  ),
                  if (showHistory) ...[
                    const SizedBox(width: 8),
                    _buildSecondaryTab(
                      iconWidget: const ChineseLineIcon(
                        type: ChineseIconType.chronicle,
                        size: 16,
                        color: kAntiqueGold,
                      ),
                      label: AppStrings.history,
                      onTap: onOpenHistory,
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: inDrumMode ? 0.36 : 1.0,
            child: IgnorePointer(
              ignoring: inDrumMode,
              child: PopupMenuButton<String>(
                tooltip: AppStrings.menuTooltip,
                color: kSurfaceLacquer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: withAlphaColor(kAntiqueGold, 0.6)),
                ),
                onSelected: (value) {
                  if (value == 'topics') onOpenTopics();
                  if (value == 'quizzes') onOpenQuizzes();
                  if (value == 'history') onOpenHistory();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'topics',
                    child: Row(
                      children: [
                        ChineseLineIcon(type: ChineseIconType.scroll, size: 16),
                        SizedBox(width: 10),
                        Text(AppStrings.topics,
                            style: TextStyle(color: kXuanPaper)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'quizzes',
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_outlined,
                            size: 16, color: kAntiqueGold),
                        const SizedBox(width: 10),
                        Text(quizLabel,
                            style: const TextStyle(color: kXuanPaper)),
                      ],
                    ),
                  ),
                  if (historyCount >= 2)
                    const PopupMenuItem(
                      value: 'history',
                      child: Row(
                        children: [
                          ChineseLineIcon(
                              type: ChineseIconType.chronicle, size: 16),
                          SizedBox(width: 10),
                          Text(AppStrings.history,
                              style: TextStyle(color: kXuanPaper)),
                        ],
                      ),
                    ),
                ],
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: withAlphaColor(kSurfaceLacquer, 0.90),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: withAlphaColor(kBronzePatina, 0.85)),
                  ),
                  child: const Icon(Icons.menu_rounded,
                      size: 19, color: kAntiqueGold),
                ),
              ),
            ),
          ),

        const Spacer(),

        Tooltip(
          message: AppStrings.muteTooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onToggleMute,
            onLongPress: onOpenVoiceSettings,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: withAlphaColor(kSurfaceLacquer, 0.88),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: withAlphaColor(kBronzePatina, 0.8),
                  width: 1,
                ),
              ),
              child: ChineseLineIcon(
                type: isMuted
                    ? ChineseIconType.soundMuted
                    : ChineseIconType.sound,
                size: 18,
                color: isMuted ? kTextMuted : kAntiqueGold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: AppStrings.voiceSettingsTooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onOpenVoiceSettings,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: withAlphaColor(kSurfaceLacquer, 0.88),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: withAlphaColor(kBronzePatina, 0.6),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 17,
                color: kTextSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryDrumButton({required bool inDrumMode}) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onToggleDrumMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: inDrumMode
              ? withAlphaColor(kSurfaceLacquer, 0.94)
              : kAntiqueGold,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: kAntiqueGold, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (inDrumMode)
              const Icon(Icons.arrow_back_rounded,
                  size: 16, color: kAntiqueGold)
            else
              const ChineseLineIcon(
                type: ChineseIconType.drum,
                size: 17,
                color: kBgXuanBlack,
              ),
            const SizedBox(width: 8),
            Text(
              inDrumMode ? AppStrings.putAway : AppStrings.drumPractice,
              style: TextStyle(
                color: inDrumMode ? kXuanPaper : kBgXuanBlack,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                fontFamilyFallback: kSansFontFallback,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryTab({
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: withAlphaColor(kSurfaceLacquer, 0.90),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: withAlphaColor(kBronzePatina, 0.85)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: kXuanPaper,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamilyFallback: kSansFontFallback,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showVoiceSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => Consumer(
      builder: (_, ref, __) {
        final ttsState = ref.watch(ttsProvider);
        final ttsNotifier = ref.read(ttsProvider.notifier);

        return AlertDialog(
          backgroundColor: kSurfaceLacquer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: kAntiqueGold, width: 1),
          ),
          title: const Text(
            AppStrings.voiceSettingsTitle,
            style: TextStyle(
              color: kXuanPaper,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamilyFallback: kSerifFontFallback,
            ),
          ),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: kAntiqueGold,
                  title: const Text(
                    AppStrings.autoReadTitle,
                    style: TextStyle(color: kXuanPaper, fontSize: 14),
                  ),
                  subtitle: const Text(
                    AppStrings.autoReadSubtitle,
                    style: TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                  value: ttsState.autoPlay,
                  onChanged: (val) => ttsNotifier.setAutoPlay(val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: kAntiqueGold,
                  title: const Text(
                    AppStrings.muteSpeechTitle,
                    style: TextStyle(color: kXuanPaper, fontSize: 14),
                  ),
                  value: ttsState.isMuted,
                  onChanged: (_) => ttsNotifier.toggleMute(),
                ),
                const SizedBox(height: 10),
                const Text(
                  AppStrings.speechSpeed,
                  style: TextStyle(color: kTextSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: TtsSpeedPreset.values.map((preset) {
                    final selected = ttsState.speed == preset;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selected
                                ? withAlphaColor(kAntiqueGold, 0.22)
                                : kSurfaceElevated,
                            side: BorderSide(
                              color: selected ? kAntiqueGold : kBronzePatina,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () => ttsNotifier.setSpeed(preset),
                          child: Text(
                            preset.label,
                            style: TextStyle(
                              color: selected ? kXuanPaper : kTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                AppStrings.done,
                style: TextStyle(color: kAntiqueGold),
              ),
            ),
          ],
        );
      },
    ),
  );
}

void showHistoryBottomSheet(BuildContext context, List<ChatTurnRecord> history) {
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
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 16, 12),
                child: Row(
                  children: [
                    const ChineseLineIcon(
                        type: ChineseIconType.chronicle, size: 18),
                    const SizedBox(width: 10),
                    const Text(
                      AppStrings.historyTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kXuanPaper,
                        fontFamilyFallback: kSerifFontFallback,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: AppStrings.close,
                      icon: const Icon(Icons.close_rounded,
                          color: kTextSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Divider(color: withAlphaColor(kAntiqueGold, 0.3), height: 1),
              Expanded(
                child: history.isEmpty
                    ? const Center(
                        child: Text(
                          AppStrings.noMessagesYet,
                          style: TextStyle(color: kTextMuted),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        itemBuilder: (_, index) {
                          final item = history[index];
                          return Align(
                            alignment: item.isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(14),
                              constraints: const BoxConstraints(maxWidth: 560),
                              decoration: BoxDecoration(
                                color: item.isUser
                                    ? withAlphaColor(kAntiqueGold, 0.14)
                                    : kSurfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: item.isUser
                                      ? withAlphaColor(kAntiqueGold, 0.55)
                                      : withAlphaColor(kBronzePatina, 0.45),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.isUser
                                        ? AppStrings.userLabel
                                        : AppStrings.guideName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: item.isUser
                                          ? kAntiqueGold
                                          : kXuanPaper,
                                      fontFamilyFallback: kSansFontFallback,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.text,
                                    style: const TextStyle(
                                      color: kXuanPaper,
                                      fontSize: 15,
                                      height: 1.6,
                                      fontFamilyFallback: kSerifFontFallback,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}

void showTopicsBottomSheet(
  BuildContext context, {
  required ValueChanged<String> onSelectQuery,
  required ValueChanged<String> onStartTopicQuiz,
}) {
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
        initialChildSize: 0.74,
        maxChildSize: 0.9,
        minChildSize: 0.45,
        builder: (_, scrollController) {
          return Consumer(
            builder: (_, ref, __) {
              final quizProgress = ref.watch(quizProvider);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 16, 12),
                    child: Row(
                      children: [
                        const ChineseLineIcon(
                            type: ChineseIconType.scroll, size: 18),
                        const SizedBox(width: 10),
                        const Text(
                          AppStrings.exploreTopicsTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kXuanPaper,
                            fontFamilyFallback: kSerifFontFallback,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: AppStrings.close,
                          icon: const Icon(Icons.close_rounded,
                              color: kTextSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: withAlphaColor(kAntiqueGold, 0.3), height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: kAllJianGuTopics.map((cat) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kSurfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: withAlphaColor(kBronzePatina, 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                cat.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: kAntiqueGold,
                                  fontFamilyFallback: kSerifFontFallback,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...cat.questions.map((q) {
                                final unlocked =
                                    quizProgress.isBadgeUnlocked(q.id);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            onSelectQuery(q.query);
                                          },
                                          child: Container(
                                            constraints: const BoxConstraints(
                                                minHeight: 44),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: kSurfaceLacquer,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              border: Border.all(
                                                color: withAlphaColor(
                                                    kAntiqueGold, 0.4),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    q.label,
                                                    style: const TextStyle(
                                                      color: kXuanPaper,
                                                      fontSize: 14,
                                                      fontFamilyFallback:
                                                          kSerifFontFallback,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.chevron_right_rounded,
                                                  size: 18,
                                                  color: kAntiqueGold,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Tooltip(
                                        message: unlocked
                                            ? 'Seal earned — retake 3-question quiz'
                                            : 'Take 3-question quiz',
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            onStartTopicQuiz(q.id);
                                          },
                                          child: Container(
                                            height: 44,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: unlocked
                                                  ? withAlphaColor(
                                                      kBronzePatina, 0.25)
                                                  : kSurfaceLacquer,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              border: Border.all(
                                                color: unlocked
                                                    ? kAntiqueGold
                                                    : withAlphaColor(
                                                        kBronzePatina, 0.75),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  unlocked
                                                      ? Icons
                                                          .verified_outlined
                                                      : Icons.quiz_outlined,
                                                  size: 15,
                                                  color: unlocked
                                                      ? kAntiqueGold
                                                      : kTextSecondary,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  unlocked ? 'Seal' : 'Quiz',
                                                  style: TextStyle(
                                                    color: unlocked
                                                        ? kAntiqueGold
                                                        : kXuanPaper,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamilyFallback:
                                                        kSansFontFallback,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}