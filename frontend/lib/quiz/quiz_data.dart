import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class QuizQuestion {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

@immutable
class TopicQuiz {
  final String topicId;
  final String topicTitle;
  final String categoryTitle;
  final String badgeTitle;
  final String badgeMonogram;
  final List<QuizQuestion> questions;

  const TopicQuiz({
    required this.topicId,
    required this.topicTitle,
    required this.categoryTitle,
    required this.badgeTitle,
    required this.badgeMonogram,
    required this.questions,
  });
}

@immutable
class QuizProgressState {
  /// Best score (0..3) recorded per topicId
  final Map<String, int> bestScores;

  const QuizProgressState({this.bestScores = const {}});

  static const int passThreshold = 2;

  int bestScoreFor(String topicId) => bestScores[topicId] ?? 0;

  bool isBadgeUnlocked(String topicId) =>
      bestScoreFor(topicId) >= passThreshold;

  bool isPerfect(String topicId) => bestScoreFor(topicId) >= 3;

  int get unlockedCount => kAllTopicQuizzes
      .where((q) => isBadgeUnlocked(q.topicId))
      .length;

  int get totalCount => kAllTopicQuizzes.length;

  int get totalCorrectBest => bestScores.values.fold(0, (a, b) => a + b);

  int get totalQuestions => kAllTopicQuizzes.length * 3;

  QuizProgressState copyWith({Map<String, int>? bestScores}) {
    return QuizProgressState(bestScores: bestScores ?? this.bestScores);
  }
}

class QuizProgressNotifier extends Notifier<QuizProgressState> {
  @override
  QuizProgressState build() => const QuizProgressState();

  /// Records a completed topic quiz. Returns true if this run newly unlocked a badge.
  bool recordResult({required String topicId, required int score}) {
    final prevScore = state.bestScoreFor(topicId);
    final wasUnlocked = prevScore >= QuizProgressState.passThreshold;
    final nextBest = score > prevScore ? score : prevScore;

    final updated = Map<String, int>.from(state.bestScores);
    updated[topicId] = nextBest;
    state = state.copyWith(bestScores: updated);

    return !wasUnlocked && nextBest >= QuizProgressState.passThreshold;
  }

  void resetAll() {
    state = const QuizProgressState();
  }
}

final quizProvider =
    NotifierProvider<QuizProgressNotifier, QuizProgressState>(
  QuizProgressNotifier.new,
);

/// 11 Topics x 3 Questions = 33 historically curated questions
const List<TopicQuiz> kAllTopicQuizzes = [
  // 1. Origins of the Jian Gu
  TopicQuiz(
    topicId: 'origins',
    topicTitle: 'Origins of the Jian Gu',
    categoryTitle: 'History & Artifacts',
    badgeTitle: 'Ancient Lineage',
    badgeMonogram: 'OR',
    questions: [
      QuizQuestion(
        prompt:
            'Which early Chinese dynasties do the origins of the Jian Gu trace back to?',
        options: [
          'Shang and Zhou dynasties',
          'Song and Yuan dynasties',
          'Ming and Qing dynasties',
          'Sui and Tang dynasties',
        ],
        correctIndex: 0,
        explanation:
            'The Jian Gu dates back to the Shang and Zhou dynasties and remained a ceremonial centerpiece for over two millennia.',
      ),
      QuizQuestion(
        prompt:
            'What core structural feature distinguishes the Jian Gu from suspended frame drums?',
        options: [
          'It is played flat on the ground',
          'A single vertical pillar pierces straight through the drum body',
          'It hangs by silk cords from a crossbar',
          'It is shaped like an hourglass held under the arm',
        ],
        correctIndex: 1,
        explanation:
            'A vertical shaft pierces the drum shell and anchors into the pedestal, letting the instrument stand upright on its own.',
      ),
      QuizQuestion(
        prompt: 'What does the traditional name "Jian Gu" literally describe?',
        options: [
          'Bronze bell drum',
          'Cloud-patterned drum',
          'Erected or standing drum',
          'Chariot war drum',
        ],
        correctIndex: 2,
        explanation:
            '"Jian" means erected or established upright, referring directly to the standing pillar mounting of the drum.',
      ),
    ],
  ),

  // 2. Zeng Hou Yi Bronze Dragon Base
  TopicQuiz(
    topicId: 'zeng-hou-yi-base',
    topicTitle: 'Zeng Hou Yi Bronze Dragon Base',
    categoryTitle: 'History & Artifacts',
    badgeTitle: 'Dragon Founder',
    badgeMonogram: 'ZY',
    questions: [
      QuizQuestion(
        prompt:
            'Around which date was the tomb of Marquis Yi of Zeng in Hubei sealed?',
        options: [
          '221 BCE',
          '433 BCE',
          '100 CE',
          '618 CE',
        ],
        correctIndex: 1,
        explanation:
            'Excavated in Suizhou, Hubei, the tomb of Marquis Yi of Zeng dates to roughly 433 BCE during the early Warring States period.',
      ),
      QuizQuestion(
        prompt:
            'How many intertwined dragons form the famous openwork bronze Jian Gu base?',
        options: [
          'Four dragons',
          'Eight dragons',
          'Sixteen dragons',
          'Thirty-two dragons',
        ],
        correctIndex: 2,
        explanation:
            'Eight pairs—sixteen intertwined bronze dragons in total—coil together to anchor the ceremonial standing drum.',
      ),
      QuizQuestion(
        prompt:
            'Which iconic musical artifact was unearthed alongside this Jian Gu base?',
        options: [
          'The Bianzhong bronze chime bells',
          'A Tang Dynasty Pipa lute',
          'A Ming porcelain flute',
          'Terracotta soldiers',
        ],
        correctIndex: 0,
        explanation:
            'The Jian Gu base stood beside the monumental Bianzhong chime bells inside the central ritual chamber of the tomb.',
      ),
    ],
  ),

  // 3. Four Structural Highlights Overview
  TopicQuiz(
    topicId: 'structure-overview',
    topicTitle: 'Four Structural Highlights Overview',
    categoryTitle: 'Structure & Craftsmanship',
    badgeTitle: 'Master Architect',
    badgeMonogram: 'ST',
    questions: [
      QuizQuestion(
        prompt:
            'Which four structural parts compose a complete ceremonial Jian Gu?',
        options: [
          'Soundboard, strings, pegs, and bridge',
          'Feather canopy, central pillar, drum body, and sculpted base',
          'Crossbar, hanging ropes, mallet rack, and gong',
          'Resonator tube, reed, mouthpiece, and bell',
        ],
        correctIndex: 1,
        explanation:
            'From top to bottom, the ceremonial Jian Gu unites the Yu Bao canopy, Guan Zhu pillar, cowhide drum body, and pedestal.',
      ),
      QuizQuestion(
        prompt:
            'What material is traditionally stretched over both faces of the Jian Gu?',
        options: [
          'Woven silk canvas',
          'Hammered sheet bronze',
          'Thick cowhide',
          'Carved bamboo strips',
        ],
        correctIndex: 2,
        explanation:
            'Taut, thick cowhide drumheads generate the deep, far-carrying resonance characteristic of the Jian Gu.',
      ),
      QuizQuestion(
        prompt:
            'How does striking the center of the Jian Gu contrast with striking its rim?',
        options: [
          'Center gives a deep boom; wooden rim gives a crisp bright click',
          'Both zones produce the exact same pitch',
          'Center produces a metallic ring; rim produces silence',
          'Rim is lower in pitch than the center',
        ],
        correctIndex: 0,
        explanation:
            'Drummers combine the commanding low boom of the cowhide center with the sharp, articulate click of the lacquered wood rim.',
      ),
    ],
  ),

  // 4. Central Pillar (Guan Zhu)
  TopicQuiz(
    topicId: 'central-pillar',
    topicTitle: 'Central Pillar (Guan Zhu)',
    categoryTitle: 'Structure & Craftsmanship',
    badgeTitle: 'Pillar Keeper',
    badgeMonogram: 'GZ',
    questions: [
      QuizQuestion(
        prompt:
            'What is the traditional name for the vertical shaft supporting the Jian Gu?',
        options: [
          'Yu Bao',
          'Guan Zhu',
          'Ba Yin',
          'Pan Gu',
        ],
        correctIndex: 1,
        explanation:
            'Guan Zhu literally means "penetrating pillar," describing how the wooden column runs vertically through the drum body.',
      ),
      QuizQuestion(
        prompt: 'How is the Guan Zhu fitted to the Jian Gu drum shell?',
        options: [
          'Tied lightly to the outside edge with hemp rope',
          'Piercing vertically straight through the drum body into the base',
          'Attached only to the top rim as a decorative handle',
          'Resting horizontally beneath the drum like a cradle',
        ],
        correctIndex: 1,
        explanation:
            'The pillar passes vertically through the wooden shell, locking into the pedestal below and raising the canopy above.',
      ),
      QuizQuestion(
        prompt:
            'What practical advantage did the central pillar give ancient drummers?',
        options: [
          'It allowed the drum to float on water',
          'It eliminated side frames so drummers could strike freely from either side',
          'It automatically tuned the cowhide pitch',
          'It doubled the number of drumheads to four',
        ],
        correctIndex: 1,
        explanation:
            'Without an enclosing outer rack, players could strike unobstructed during dances, temple rites, or chariot marches.',
      ),
    ],
  ),

  // 5. Feather Canopy (Yu Bao)
  TopicQuiz(
    topicId: 'feather-canopy',
    topicTitle: 'Feather Canopy (Yu Bao)',
    categoryTitle: 'Structure & Craftsmanship',
    badgeTitle: 'Canopy Herald',
    badgeMonogram: 'YB',
    questions: [
      QuizQuestion(
        prompt:
            'Where is the Yu Bao (feather canopy) mounted on a ceremonial Jian Gu?',
        options: [
          'Wrapped around the bronze pedestal',
          'Crowning the very top of the central pillar',
          'Tucked inside the hollow drum shell',
          'Fastened to the drumsticks',
        ],
        correctIndex: 1,
        explanation:
            'The Yu Bao sits at the summit of the Guan Zhu pillar, giving the ceremonial drum its unmistakable silhouette.',
      ),
      QuizQuestion(
        prompt:
            'Which decorative elements traditionally adorned the Yu Bao canopy?',
        options: [
          'Iron chains and armor plates',
          'Plumage, silk tassels, and auspicious motifs',
          'Plain unpainted hemp cloth',
          'Clay bells filled with pebbles',
        ],
        correctIndex: 1,
        explanation:
            'Feathers, silk tassels, and royal motifs transformed the drum into a visual emblem of state ritual dignity.',
      ),
      QuizQuestion(
        prompt:
            'What did the towering feather canopy signify in imperial court orchestras?',
        options: [
          'That the drum was reserved only for private practice',
          'Royal state authority and harmony between heaven and earth',
          'The geographic region where the wood was harvested',
          'The speed of the musical piece',
        ],
        correctIndex: 1,
        explanation:
            'Visually elevated above other instruments, the Yu Bao marked the Jian Gu as a solemn symbol of sovereign ritual order.',
      ),
    ],
  ),

  // 6. Lost-Wax Bronze Casting
  TopicQuiz(
    topicId: 'lost-wax-casting',
    topicTitle: 'Lost-Wax Bronze Casting',
    categoryTitle: 'Structure & Craftsmanship',
    badgeTitle: 'Bronze Alchemist',
    badgeMonogram: 'LW',
    questions: [
      QuizQuestion(
        prompt:
            'What material did artisans sculpt first when crafting the Zeng Hou Yi base via lost-wax casting?',
        options: [
          'Solid granite',
          'Beeswax',
          'Wrought iron',
          'Porcelain glaze',
        ],
        correctIndex: 1,
        explanation:
            'Founders carved the intricate coiled dragon lattice in beeswax before coating it in fine clay slurry.',
      ),
      QuizQuestion(
        prompt:
            'What happens to the wax model before molten bronze is poured into the mold?',
        options: [
          'It stays inside permanently as a core',
          'It is heated and melted out to leave a hollow cavity',
          'It is dissolved in cold river water',
          'It is hammered flat into a bronze sheet',
        ],
        correctIndex: 1,
        explanation:
            'Melting away the wax leaves an exact negative cavity inside the baked clay mold ready for molten bronze.',
      ),
      QuizQuestion(
        prompt:
            'Why was lost-wax casting crucial for the Marquis Yi dragon drum stand?',
        options: [
          'It made the bronze lighter than wood',
          'It enabled complex 3D undercut dragon coils impossible with piece-molds alone',
          'It required no heat or furnace',
          'It prevented the bronze from ever developing patina',
        ],
        correctIndex: 1,
        explanation:
            'Interlocking, undercut openwork coils could not be cleanly separated from rigid multi-piece clay molds without lost-wax casting.',
      ),
    ],
  ),

  // 7. Ming & Qing Court Rituals (Zhonghe Shaoyue)
  TopicQuiz(
    topicId: 'court-rituals',
    topicTitle: 'Ming & Qing Court Rituals (Zhonghe Shaoyue)',
    categoryTitle: 'Musicology & Court Rituals',
    badgeTitle: 'Ritual Maestro',
    badgeMonogram: 'ZS',
    questions: [
      QuizQuestion(
        prompt:
            'In which Ming and Qing imperial ritual orchestra did the Jian Gu serve as rhythmic anchor?',
        options: [
          'Zhonghe Shaoyue',
          'Kunqu Opera',
          'Silk and Bamboo chamber music',
          'Guqin solo school',
        ],
        correctIndex: 0,
        explanation:
            'Zhonghe Shaoyue was the grand state ceremonial music performed at imperial sacrifices and court assemblies.',
      ),
      QuizQuestion(
        prompt:
            'How did the Jian Gu traditionally open Qing Dynasty Confucian temple rites?',
        options: [
          'With a single soft rim tap',
          'With three ceremonial drum rolls',
          'By remaining silent until the finale',
          'With a solo flute melody',
        ],
        correctIndex: 1,
        explanation:
            'Three solemn rolls on the Jian Gu opened Confucian temple ceremonies and signaled the assembly to stand in reverence.',
      ),
      QuizQuestion(
        prompt:
            'What title did classical treatises bestow upon the Jian Gu within large court ensembles?',
        options: [
          'The whisper of the strings',
          'The regulator of ensemble tempo',
          'The echo of the mountains',
          'The solo voice of the wind',
        ],
        correctIndex: 1,
        explanation:
            'While bells opened and chime stones closed the movement, the Jian Gu regulated tempo and unified the entire ensemble.',
      ),
    ],
  ),

  // 8. The "Eight Tones" (Ba Yin) System
  TopicQuiz(
    topicId: 'eight-tones',
    topicTitle: 'The "Eight Tones" (Ba Yin) System',
    categoryTitle: 'Musicology & Court Rituals',
    badgeTitle: 'Ba Yin Scholar',
    badgeMonogram: 'BY',
    questions: [
      QuizQuestion(
        prompt:
            'How does the classical Chinese Ba Yin (Eight Tones) system classify instruments?',
        options: [
          'By the dynasty in which they were invented',
          'By their primary vibrating material',
          'By the height of the performer',
          'By musical key signature',
        ],
        correctIndex: 1,
        explanation:
            'Ba Yin groups instruments by vibrating substance: metal, stone, silk, bamboo, gourd, clay, leather, and wood.',
      ),
      QuizQuestion(
        prompt: 'Which Ba Yin category does the Jian Gu belong to?',
        options: [
          'Jin (metal)',
          'Si (silk)',
          'Ge (leather / hide)',
          'Tu (clay)',
        ],
        correctIndex: 2,
        explanation:
            'Because its voice comes from stretched cowhide drumheads, the Jian Gu belongs to the Ge (leather) category.',
      ),
      QuizQuestion(
        prompt:
            'What musical role did leather drums play alongside melodic instruments in Ba Yin ensembles?',
        options: [
          'Playing high-pitched vocal harmonies',
          'Providing foundational pulse and dynamic contrast',
          'Tuning the bronze chime bells before performance',
          'Replacing bamboo flutes in outdoor venues',
        ],
        correctIndex: 1,
        explanation:
            'Leather drums anchored the rhythmic pulse and added commanding weight to balance bells, stones, strings, and winds.',
      ),
    ],
  ),

  // 9. Ancient Battlefield Signaling
  TopicQuiz(
    topicId: 'battlefield-signaling',
    topicTitle: 'Ancient Battlefield Signaling',
    categoryTitle: 'Military & Performing Arts',
    badgeTitle: 'Vanguard Drummer',
    badgeMonogram: 'AW',
    questions: [
      QuizQuestion(
        prompt:
            'Which classic military treatise explains how drums and gongs unified ten thousand soldiers?',
        options: [
          'The Art of War',
          'The Classic of Tea',
          'Records of the Grand Historian',
          'Compendium of Materia Medica',
        ],
        correctIndex: 0,
        explanation:
            'The Art of War notes that because voices cannot carry across a battlefield, commanders rely on drums and gongs to unify action.',
      ),
      QuizQuestion(
        prompt:
            'In ancient Chinese warfare, what command did the thunderous beating of war drums signal?',
        options: [
          'Set up night camp',
          'Advance forward and rally morale',
          'Surrender weapons',
          'Hold silence in ambush',
        ],
        correctIndex: 1,
        explanation:
            'A steady, powerful drumbeat commanded troops to charge forward while lifting battlefield morale.',
      ),
      QuizQuestion(
        prompt:
            'Which instrument paired with the war drum to signal an orderly retreat?',
        options: [
          'Silk zither',
          'Jade flute',
          'Bronze gong',
          'Clay ocarina',
        ],
        correctIndex: 2,
        explanation:
            'The classic military maxim paired "advance at the drum" with "retreat at the bronze gong."',
      ),
    ],
  ),

  // 10. Han Dynasty Acrobatic Drum Dance
  TopicQuiz(
    topicId: 'han-drum-dance',
    topicTitle: 'Han Dynasty Acrobatic Drum Dance',
    categoryTitle: 'Military & Performing Arts',
    badgeTitle: 'Banquet Performer',
    badgeMonogram: 'HD',
    questions: [
      QuizQuestion(
        prompt:
            'Which archaeological artifacts most vividly preserve Han Dynasty Jian Gu dances?',
        options: [
          'Oil paintings on canvas',
          'Carved Han stone reliefs',
          'Printed woodblock newspapers',
          'Glass mosaic windows',
        ],
        correctIndex: 1,
        explanation:
            'Han tomb stone reliefs capture dancers leaping, spinning, and drumming energetically around tall standing Jian Gu.',
      ),
      QuizQuestion(
        prompt:
            'Which celebrated Han choreography was often performed alongside the Jian Gu?',
        options: [
          'Pan Gu (plate-and-drum dance)',
          'Ballet en pointe',
          'Courtly waltz',
          'Noh masked drama',
        ],
        correctIndex: 0,
        explanation:
            'Dancers balanced and stepped across upturned plates and small drums around the towering Jian Gu in Pan Gu performances.',
      ),
      QuizQuestion(
        prompt:
            'What cultural shift do Han Dynasty drum dance reliefs reveal about the Jian Gu?',
        options: [
          'It was banned from all public gatherings',
          'It expanded from solemn temple rites into joyful banquet entertainment',
          'It shrank into a pocket-sized hand drum',
          'It was played exclusively without percussion sticks',
        ],
        correctIndex: 1,
        explanation:
            'During the Han era, the Jian Gu bridged sacred ritual music and exuberant aristocratic banquet artistry.',
      ),
    ],
  ),

  // 11. Tang Dynasty Dunhuang Cave 156 Murals
  TopicQuiz(
    topicId: 'dunhuang-murals',
    topicTitle: 'Tang Dynasty Dunhuang Cave 156 Murals',
    categoryTitle: 'Military & Performing Arts',
    badgeTitle: 'Silk Road Chronicler',
    badgeMonogram: 'DH',
    questions: [
      QuizQuestion(
        prompt:
            'Which Dunhuang Mogao cave contains famous Tang Dynasty murals depicting the Jian Gu?',
        options: [
          'Cave 17',
          'Cave 156',
          'Cave 285',
          'Cave 428',
        ],
        correctIndex: 1,
        explanation:
            'Mogao Cave 156 preserves sweeping Tang murals depicting military processions and celestial musicians playing standing drums.',
      ),
      QuizQuestion(
        prompt:
            'In what context are standing drums portrayed inside the Cave 156 murals?',
        options: [
          'Underwater temple ruins',
          'Grand military processions and celestial orchestras',
          'Quiet scholar studies',
          'Farming harvest markets',
        ],
        correctIndex: 1,
        explanation:
            'The murals show richly painted standing drums carried on portable wooden stands during triumphal marches and heavenly ensembles.',
      ),
      QuizQuestion(
        prompt:
            'What historical value do the Tang Dunhuang murals offer music historians?',
        options: [
          'Audio recordings of Tang drummers',
          'Vivid visual evidence of drum lacquer colors, silhouettes, and Silk Road ensembles',
          'Exact bronze smelting temperature charts',
          'Blueprints for Ming porcelain kilns',
        ],
        correctIndex: 1,
        explanation:
            'Because ancient wooden drums rarely survive intact, these murals document authentic Tang drum proportions, pigments, and ensemble setups.',
      ),
    ],
  ),
];

final Map<String, TopicQuiz> kTopicQuizById = {
  for (final quiz in kAllTopicQuizzes) quiz.topicId: quiz,
};