import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../models/chat_response.dart';
import '../theme/app_theme.dart';
import '../widgets/lacquer_widgets.dart';
import '../quiz/quiz_modal.dart';
import '../widgets/museum_background.dart';

class TopicDetailScreen extends StatelessWidget {
  final TopicItem topic;

  const TopicDetailScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: MuseumBackground()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top navigation bar with "<- Back to chat"
                      Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              height: 40,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: withAlphaColor(kSurfaceLacquer, 0.94),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: kAntiqueGold,
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                AppStrings.backToChat,
                                style: TextStyle(
                                  color: kXuanPaper,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  fontFamilyFallback: kSansFontFallback,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '/topics/${topic.id}',
                            style: const TextStyle(
                              color: kTextMuted,
                              fontSize: 12,
                              fontFamilyFallback: kSansFontFallback,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Main topic detail lacquer card
                      Expanded(
                        child: SingleChildScrollView(
                          child: LacquerPanel(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.article_outlined,
                                      size: 18,
                                      color: kAntiqueGold,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'TOPIC ARCHIVE',
                                      style: TextStyle(
                                        color: withAlphaColor(
                                            kAntiqueGold, 0.9),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.4,
                                        fontFamilyFallback: kSansFontFallback,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  topic.label,
                                  style: const TextStyle(
                                    color: kXuanPaper,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                    fontFamilyFallback: kSerifFontFallback,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  topic.summary,
                                  style: const TextStyle(
                                    color: kXuanPaper,
                                    fontSize: 17,
                                    height: 1.7,
                                    fontFamilyFallback: kSerifFontFallback,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Divider(
                                  color: withAlphaColor(kAntiqueGold, 0.3),
                                  height: 1,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Key Highlights',
                                  style: TextStyle(
                                    color: kAntiqueGold,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamilyFallback: kSansFontFallback,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...topic.highlights.map(
                                  (bullet) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: SizedBox(
                                            width: 6,
                                            height: 6,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: kAntiqueGold,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            bullet,
                                            style: const TextStyle(
                                              color: kTextSecondary,
                                              fontSize: 15.5,
                                              height: 1.6,
                                              fontFamilyFallback:
                                                  kSerifFontFallback,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Wrap(
                                    alignment: WrapAlignment.end,
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: kAntiqueGold,
                                          side: const BorderSide(
                                              color: kAntiqueGold),
                                          minimumSize: const Size(0, 40),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        onPressed: () => showTopicQuizModal(
                                          context,
                                          topicId: topic.id,
                                        ),
                                        icon: const Icon(
                                            Icons.workspace_premium_outlined,
                                            size: 16),
                                        label: const Text(
                                          'Take 3-Question Quiz',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            fontFamilyFallback:
                                                kSansFontFallback,
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          backgroundColor: kAntiqueGold,
                                          foregroundColor: kBgXuanBlack,
                                          minimumSize: const Size(0, 40),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        onPressed: () => Navigator.of(context)
                                            .pop<String>(topic.query),
                                        icon: const Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 16),
                                        label: const Text(
                                          AppStrings.askGuideAboutTopic,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            fontFamilyFallback:
                                                kSansFontFallback,
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