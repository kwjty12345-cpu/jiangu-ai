import 'package:flutter/material.dart';

String normalizeEnglishMuseumText(
  String raw, {
  String knownUserName = '',
}) {
  var text = raw;

  text = text.replaceAll(r'$1', '');
  text = text.replaceAll(
    RegExp(r'\bZhonghe\s+Shaole\b', caseSensitive: false),
    'Zhonghe Shaoyue',
  );
  text = text.replaceAll(
    RegExp(r'\bShaole\b', caseSensitive: false),
    'Shaoyue',
  );
  text = text.replaceAll(RegExp(r'\bJianGu\b'), 'Jian Gu');
  text = text.replaceAll(RegExp(r'\bJiangu\b'), 'Jian Gu');

  text = text.replaceAll(RegExp(r'\uFF08[^\uFF09]*\uFF09'), '');
  text = text.replaceAll(RegExp(r'\([^)]*[\u4e00-\u9fff]+[^)]*\)'), '');
  text = text.replaceAll(
    RegExp(r'[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef]+'),
    ' ',
  );

  text = text
      .replaceAll(RegExp(r'\(\s*\)'), '')
      .replaceAll(RegExp(r'["\u201C\u201D]\s*["\u201C\u201D]'), '')
      .replaceAll(RegExp(r"'\s*'"), '')
      .replaceAll(RegExp(r'\s*[\u2014\u2013-]{2,}\s*'), ' ');

  if (knownUserName.trim().isEmpty) {
    text = text.replaceAllMapped(
      RegExp(r',\s*Jackson([.!?])', caseSensitive: false),
      (m) => m[1]!,
    );
  }

  text = text
      .replaceAllMapped(RegExp(r'\s+([.,!?;:])'), (m) => m[1]!)
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  return text;
}

enum ReferenceType {
  topic,
  artifact,
  external,
}

class SourceCitation {
  final ReferenceType type;
  final String title;
  final String? topicId;
  final String? url;
  final String snippet;

  const SourceCitation({
    required this.type,
    required this.title,
    this.topicId,
    this.url,
    this.snippet = '',
  });

  bool get isInternal => topicId != null && topicId!.isNotEmpty;
  bool get isExternal => !isInternal && url != null && url!.isNotEmpty;

  static SourceCitation? tryFromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? '').toString().toLowerCase().trim();
    final rawTitle = (json['title'] ?? '').toString().trim();
    final rawTopicId =
        (json['topic_id'] ?? json['topicId'] ?? '').toString().trim();
    final rawUrl = (json['url'] ?? '').toString().trim();
    final rawSnippet = (json['snippet'] ?? json['ref'] ?? '').toString().trim();

    String cleanTitle = normalizeEnglishMuseumText(rawTitle);
    if (cleanTitle.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').isEmpty) {
      cleanTitle = '';
    }

    if (cleanTitle.isEmpty ||
        cleanTitle.toLowerCase() == 'ctext' ||
        cleanTitle.toLowerCase() == 'historical reference') {
      cleanTitle =
          _recoverEnglishTitleFromMetadata(rawUrl, rawTopicId, rawSnippet);
    }

    String? validTopicId;
    if (rawTopicId.isNotEmpty && kTopicById.containsKey(rawTopicId)) {
      validTopicId = rawTopicId;
    }

    final String? validUrl =
        (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))
            ? rawUrl
            : null;

    if (cleanTitle.isEmpty) return null;
    if (validTopicId == null && validUrl == null) return null;

    ReferenceType resolvedType;
    if (rawType == 'artifact') {
      resolvedType = ReferenceType.artifact;
    } else if (rawType == 'topic' || validTopicId != null) {
      resolvedType = ReferenceType.topic;
    } else {
      resolvedType = ReferenceType.external;
    }

    return SourceCitation(
      type: resolvedType,
      title: cleanTitle,
      topicId: validTopicId,
      url: validUrl,
      snippet: normalizeEnglishMuseumText(rawSnippet),
    );
  }

  static String _recoverEnglishTitleFromMetadata(
    String url,
    String topicId,
    String snippet,
  ) {
    if (topicId.isNotEmpty && kTopicById.containsKey(topicId)) {
      return kTopicById[topicId]!.label;
    }
    final lower = '$url $snippet'.toLowerCase();
    if (lower.contains('ctext.org')) {
      return 'The Art of War: Military Maneuvers (Chinese Text Project)';
    }
    if (lower.contains('ihchina.cn')) {
      return 'Zhonghe Shaoyue — National Intangible Cultural Heritage';
    }
    if (lower.contains('xinhuanet') || lower.contains('news.cn')) {
      return 'Imperial Grand Orchestra Exhibition (Xinhua)';
    }
    if (lower.contains('thepaper.cn')) {
      return 'Ancient Battlefield Drum & Gong Signaling';
    }
    if (lower.contains('hbww') || lower.contains('hubei') || lower.contains('zeng')) {
      return 'Marquis Yi of Zeng Bronze Drum Base (Hubei Museum)';
    }
    if (lower.contains('dunhuang') || lower.contains('dha.ac.cn')) {
      return 'Dunhuang Mogao Cave 156 Musical Murals';
    }
    if (lower.contains('dpm.org.cn') || lower.contains('palace')) {
      return 'Palace Museum Court Ritual Instruments';
    }
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && uri.host.isNotEmpty) {
        return 'Reference Archive (${uri.host.replaceFirst('www.', '')})';
      }
    }
    return '';
  }
}

class TopicItem {
  final String id;
  final String label;
  final String query;
  final String summary;
  final List<String> highlights;
  final String followUpChip;

  const TopicItem({
    required this.id,
    required this.label,
    required this.query,
    required this.summary,
    required this.highlights,
    required this.followUpChip,
  });
}

class TopicCategory {
  final String title;
  final IconData icon;
  final List<TopicItem> questions;

  const TopicCategory({
    required this.title,
    required this.icon,
    required this.questions,
  });
}

const List<TopicCategory> kAllJianGuTopics = [
  TopicCategory(
    title: 'History & Artifacts',
    icon: Icons.account_balance_rounded,
    questions: [
      TopicItem(
        id: 'origins',
        label: 'Origins of the Jian Gu',
        query: 'What is the history and origin of the Jian Gu?',
        summary:
            'The Jian Gu (the ancient Chinese standing drum) dates back to the Shang and Zhou dynasties and evolved into a centerpiece of imperial court music, ritual ceremonies, and military signaling.',
        highlights: [
          'Distinguished from suspended drums by a single vertical wooden pillar piercing the drum body.',
          'Featured prominently in Warring States, Han, Tang, Ming, and Qing musical ensembles.',
          'Symbolized solemn authority in both sacred temples and royal processions.',
        ],
        followUpChip: 'How did it evolve?',
      ),
      TopicItem(
        id: 'zeng-hou-yi-base',
        label: 'Zeng Hou Yi Bronze Dragon Base',
        query: 'What is the Zeng Hou Yi Jian Gu base famous for?',
        summary:
            'Unearthed from the 433 BCE tomb of Marquis Yi of Zeng in Hubei, this intricate bronze stand is celebrated as a masterpiece of Warring States metallurgy.',
        highlights: [
          'Composed of sixteen intertwined dragons sculpted in openwork bronze.',
          'Supported a massive lacquered standing drum beside the famous Bianzhong chime bells.',
          'Demonstrates extraordinary control of complex lost-wax bronze casting.',
        ],
        followUpChip: 'How was it cast?',
      ),
    ],
  ),
  TopicCategory(
    title: 'Structure & Craftsmanship',
    icon: Icons.architecture_rounded,
    questions: [
      TopicItem(
        id: 'structure-overview',
        label: 'Four Structural Highlights Overview',
        query: 'Give me an overview of the whole Jian Gu structure.',
        summary:
            'A complete ceremonial Jian Gu combines four iconic structural parts: the ornate canopy, the central pillar, the lacquered cowhide drum body, and the sculptural stand.',
        highlights: [
          'Yu Bao (feather canopy) crowning the summit.',
          'Guan Zhu (central pillar) piercing vertically through the drum shell.',
          'Double-headed cowhide drum body lacquered in cinnabar red and gold.',
          'Sculpted bronze or carved wooden pedestal anchoring the instrument.',
        ],
        followUpChip: 'Explore each part',
      ),
      TopicItem(
        id: 'central-pillar',
        label: 'Central Pillar (Guan Zhu)',
        query: 'What is the function of the central pillar (Guan Zhu)?',
        summary:
            'The Guan Zhu (central penetrating pillar) runs straight through the wooden drum frame, anchoring the drum upright into the pedestal below and supporting the canopy above.',
        highlights: [
          'Eliminates the need for an external hanging frame.',
          'Allows drummers to strike freely from either side during parades or dances.',
          'Gives the Jian Gu its literal name: "erected" or "standing" drum.',
        ],
        followUpChip: 'Why pierce the drum?',
      ),
      TopicItem(
        id: 'feather-canopy',
        label: 'Feather Canopy (Yu Bao)',
        query:
            'What is the cultural significance of the feather canopy (Yu Bao) on top?',
        summary:
            'Crowning the top of the central pillar, the Yu Bao (feather canopy) and perched decorative ornaments marked the drum as a royal instrument of state ritual.',
        highlights: [
          'Adorned with silk tassels, plumage, and auspicious motifs.',
          'Visually elevated the drum above other instruments in court orchestras.',
          'Signified harmony between heaven, earth, and sovereign order.',
        ],
        followUpChip: 'See ritual symbolism',
      ),
      TopicItem(
        id: 'lost-wax-casting',
        label: 'Lost-Wax Bronze Casting',
        query: 'How was this base made using lost-wax casting?',
        summary:
            'Artisans sculpted the dragon lattice in beeswax, encased it in fine clay slurry, melted out the wax, and poured molten bronze into the negative cavity.',
        highlights: [
          'Enabled three-dimensional undercut coils impossible with piece-molds alone.',
          'Paired with bronze soldering to join intricate dragon segments seamlessly.',
          'Preserves razor-sharp geometric patterns after more than 2,400 years.',
        ],
        followUpChip: 'Compare casting methods',
      ),
    ],
  ),
  TopicCategory(
    title: 'Musicology & Court Rituals',
    icon: Icons.music_note_rounded,
    questions: [
      TopicItem(
        id: 'court-rituals',
        label: 'Ming & Qing Court Rituals (Zhonghe Shaoyue)',
        query: 'How was the Jian Gu used in peaceful court rituals?',
        summary:
            'Within Zhonghe Shaoyue (imperial court ritual music of the Ming and Qing dynasties), the Jian Gu served as the rhythmic anchor that opened ceremonies and unified large ensembles.',
        highlights: [
          'Three ceremonial drum rolls on the Jian Gu traditionally opened Confucian temple rites.',
          'Paired with Bianzhong (bronze bells) and Bianqing (chime stones) to mark musical phrases.',
          'Known in classical treatises as the regulator of ensemble tempo.',
        ],
        followUpChip: 'Hear the three rolls',
      ),
      TopicItem(
        id: 'eight-tones',
        label: 'The "Eight Tones" (Ba Yin) System',
        query: 'Where does the Jian Gu fit in the "Eight Tones" system?',
        summary:
            'In the traditional Chinese Ba Yin (Eight Tones) acoustic classification, the Jian Gu belongs to the Ge (leather/hide) category alongside other skin-headed percussion.',
        highlights: [
          'Ba Yin groups instruments by primary vibrating material: silk, bamboo, wood, stone, metal, clay, gourd, and leather.',
          'Leather drums provide foundational pulse and dynamic contrast for court orchestras.',
        ],
        followUpChip: 'List all Eight Tones',
      ),
    ],
  ),
  TopicCategory(
    title: 'Military & Performing Arts',
    icon: Icons.military_tech_rounded,
    questions: [
      TopicItem(
        id: 'battlefield-signaling',
        label: 'Ancient Battlefield Signaling',
        query: 'How was the Jian Gu used in ancient military tactics?',
        summary:
            'Mounted on command chariots or field stands, war drums like the Jian Gu carried acoustic commands across vast formations where spoken orders could not be heard.',
        highlights: [
          'The Art of War explains that drums and gongs unified the ears and eyes of ten thousand soldiers.',
          'Steady drumbeats signaled troops to advance and lifted morale; bronze gongs signaled retreat.',
        ],
        followUpChip: 'How did gongs signal?',
      ),
      TopicItem(
        id: 'han-drum-dance',
        label: 'Han Dynasty Acrobatic Drum Dance',
        query: 'Tell me about the Jian Gu in Han Dynasty dances.',
        summary:
            'Han Dynasty stone reliefs vividly portray dancers and acrobats leaping, spinning, and playing drums around tall standing Jian Gu drums at banquets.',
        highlights: [
          'Often combined with Pan Gu (plate-and-drum) dance choreography.',
          'Showcases the Jian Gu shifting from solemn temple ritual into joyous banquet entertainment.',
        ],
        followUpChip: 'See Han stone reliefs',
      ),
      TopicItem(
        id: 'dunhuang-murals',
        label: 'Tang Dynasty Dunhuang Cave 156 Murals',
        query: 'How is the Jian Gu depicted in Dunhuang murals?',
        summary:
            'Tang Dynasty murals in Mogao Cave 156 depict military processions and celestial orchestras featuring brightly painted standing drums carried and played in motion.',
        highlights: [
          'Illustrates the vibrant Silk Road exchange of percussion and ensemble performance.',
          'Shows richly decorated drum shells mounted on portable wooden frames.',
        ],
        followUpChip: 'Explore Tang orchestras',
      ),
    ],
  ),
];

final Map<String, TopicItem> kTopicById = {
  for (final cat in kAllJianGuTopics)
    for (final item in cat.questions) item.id: item,
};

String specificDetailChipForIntent(String intent, String reply) {
  final lower = '$intent $reply'.toLowerCase();
  if (lower.contains('shaoyue') || lower.contains('ritual') || lower.contains('court')) {
    return 'More on court rites';
  }
  if (lower.contains('military') || lower.contains('battlefield') || lower.contains('art of war')) {
    return 'More on war signals';
  }
  if (lower.contains('lost-wax') || lower.contains('casting')) {
    return 'More on bronze casting';
  }
  if (lower.contains('zeng') || lower.contains('dragon')) {
    return 'More on dragon base';
  }
  if (lower.contains('pillar') || lower.contains('guan zhu')) {
    return 'More on the pillar';
  }
  if (lower.contains('canopy') || lower.contains('yu bao') || lower.contains('yubao')) {
    return 'More on the canopy';
  }
  if (lower.contains('eight tones') || lower.contains('ba yin')) {
    return 'More on Ba Yin';
  }
  if (lower.contains('han') || lower.contains('dance')) {
    return 'More on Han dance';
  }
  if (lower.contains('dunhuang') || lower.contains('mural')) {
    return 'More on Dunhuang art';
  }
  if (lower.contains('origin') || lower.contains('history')) {
    return 'More on its origins';
  }
  return 'Read full explanation';
}

TopicItem? matchTopicForIntent(String intent, String reply) {
  final lower = '$intent $reply'.toLowerCase();
  if (lower.contains('shaoyue') || lower.contains('ritual') || lower.contains('court')) {
    return kTopicById['court-rituals'];
  }
  if (lower.contains('military') || lower.contains('battlefield') || lower.contains('art of war')) {
    return kTopicById['battlefield-signaling'];
  }
  if (lower.contains('lost-wax') || lower.contains('casting')) {
    return kTopicById['lost-wax-casting'];
  }
  if (lower.contains('zeng') || lower.contains('dragon')) {
    return kTopicById['zeng-hou-yi-base'];
  }
  if (lower.contains('pillar') || lower.contains('guan zhu')) {
    return kTopicById['central-pillar'];
  }
  if (lower.contains('canopy') || lower.contains('yu bao') || lower.contains('yubao')) {
    return kTopicById['feather-canopy'];
  }
  if (lower.contains('eight tones') || lower.contains('ba yin')) {
    return kTopicById['eight-tones'];
  }
  if (lower.contains('han') || lower.contains('dance')) {
    return kTopicById['han-drum-dance'];
  }
  if (lower.contains('dunhuang') || lower.contains('mural')) {
    return kTopicById['dunhuang-murals'];
  }
  if (lower.contains('structure') || lower.contains('overview')) {
    return kTopicById['structure-overview'];
  }
  if (lower.contains('origin') || lower.contains('history')) {
    return kTopicById['origins'];
  }
  return null;
}

class ChatResponse {
  final String reply;
  final String detail;
  final String detailChipLabel;
  final List<String> suggestions;
  final List<SourceCitation> sources;
  final String mood;
  final String intent;
  final bool suggestPractice;

  const ChatResponse({
    required this.reply,
    required this.detail,
    required this.detailChipLabel,
    required this.suggestions,
    required this.sources,
    required this.mood,
    required this.intent,
    required this.suggestPractice,
  });

  factory ChatResponse.fromJson(
    Map<String, dynamic> json, {
    required String timeGreeting,
    required bool isWelcomeTrigger,
    required String knownUserName,
  }) {
    final intentName = (json['intent'] ?? '').toString().trim();
    var primaryReply = normalizeEnglishMuseumText(
      (json['reply'] ?? '...').toString(),
      knownUserName: knownUserName,
    );
    var detailText = normalizeEnglishMuseumText(
      (json['detail'] ?? '').toString(),
      knownUserName: knownUserName,
    );

    if (intentName == 'Default Welcome Intent' || isWelcomeTrigger) {
      if (primaryReply.startsWith('Welcome!')) {
        primaryReply = primaryReply.replaceFirst('Welcome!', timeGreeting);
      } else if (!primaryReply.toLowerCase().startsWith('good ')) {
        primaryReply = '$timeGreeting $primaryReply';
      }
      if (!primaryReply.toLowerCase().contains('drum practice')) {
        primaryReply =
            '$primaryReply You can also try Drum Practice at the top anytime.';
      }
    }

    if (detailText.isEmpty && primaryReply.length > 260) {
      final splitIdx = primaryReply.indexOf('. ', 120);
      if (splitIdx != -1 && splitIdx + 2 < primaryReply.length) {
        detailText = primaryReply.substring(splitIdx + 2).trim();
        primaryReply = primaryReply.substring(0, splitIdx + 1).trim();
      }
    }

    final detailChip = specificDetailChipForIntent(intentName, primaryReply);

    // Keep default follow-up questions strictly separate from the Details expander
    final followUps = <String>[];
    if (json['suggestions'] is List) {
      for (final item in (json['suggestions'] as List)) {
        final s = normalizeEnglishMuseumText(
          item.toString(),
          knownUserName: knownUserName,
        );
        if (s.isNotEmpty && s.toLowerCase() != 'tell me more') {
          followUps.add(s);
        }
      }
    }
    followUps.sort((a, b) => a.length.compareTo(b.length));
    final cleanSuggestions = followUps.take(3).toList();

    final parsedSources = <SourceCitation>[];
    final seenTitles = <String>{};

    final matchedTopic = matchTopicForIntent(intentName, primaryReply);
    if (matchedTopic != null) {
      parsedSources.add(
        SourceCitation(
          type: ReferenceType.topic,
          title: matchedTopic.label,
          topicId: matchedTopic.id,
          snippet: matchedTopic.summary,
        ),
      );
      seenTitles.add(matchedTopic.label.toLowerCase());
    }

    if (json['sources'] is List) {
      for (final item in (json['sources'] as List)) {
        if (item is Map) {
          final parsed = SourceCitation.tryFromJson(
            Map<String, dynamic>.from(item),
          );
          if (parsed != null &&
              !seenTitles.contains(parsed.title.toLowerCase())) {
            parsedSources.add(parsed);
            seenTitles.add(parsed.title.toLowerCase());
          }
        }
      }
    }

    final bool suggestPractice = json['suggest_practice'] == true;

    return ChatResponse(
      reply: primaryReply,
      detail: detailText,
      detailChipLabel: detailChip,
      suggestions: cleanSuggestions,
      sources: parsedSources,
      mood: (json['mood'] ?? 'explaining').toString(),
      intent: intentName,
      suggestPractice: suggestPractice,
    );
  }
}

class ChatTurnRecord {
  final bool isUser;
  final String text;
  final String intent;
  final List<SourceCitation> sources;
  final DateTime timestamp;
  int rating;

  ChatTurnRecord({
    required this.isUser,
    required this.text,
    this.intent = '',
    this.sources = const [],
    DateTime? timestamp,
    this.rating = 0,
  }) : timestamp = timestamp ?? DateTime.now();
}