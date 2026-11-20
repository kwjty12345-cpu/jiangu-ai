class TtsTextSanitizer {
  static final Map<RegExp, String> _phoneticMap = {
    RegExp(r'\bJian\s*Gu\b', caseSensitive: false): 'Jyen Goo',
    RegExp(r'\bZeng\s*Hou\s*Yi\b', caseSensitive: false): 'Dzuhng Hoh Yee',
    RegExp(r'\bZhonghe\s*Shao(?:le|yue)\b', caseSensitive: false):
        'Johng-huh Shau-yweh',
    RegExp(r'\bGuan\s*Zhu\b', caseSensitive: false): 'Gwahn Joo',
    RegExp(r'\bYu\s*Bao\b', caseSensitive: false): 'Yoo Bau',
    RegExp(r'\bYubao\b', caseSensitive: false): 'Yoo Bau',
    RegExp(r'\bBa\s*Yin\b', caseSensitive: false): 'Bah Yin',
    RegExp(r'\bDunhuang\b', caseSensitive: false): 'Doon-hwahng',
  };

  static String sanitizeForEnglishTts(String rawText) {
    if (rawText.trim().isEmpty) return '';

    var text = rawText;

    // Remove parenthetical CJK notes and any leftover CJK ranges
    text = text.replaceAll(RegExp(r'\uFF08[^\uFF09]*\uFF09'), '');
    text = text.replaceAll(RegExp(r'\([^)]*[\u4e00-\u9fff]+[^)]*\)'), '');
    text = text.replaceAll(
      RegExp(r'[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef]+'),
      ' ',
    );

    _phoneticMap.forEach((pattern, phonetic) {
      text = text.replaceAll(pattern, phonetic);
    });

    text = text
        .replaceAll(RegExp(r'\s+([.,!?;:])'), '')
        .replaceAllMapped(RegExp(r'\s+([.,!?;:])'), (m) => m[1]!)
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    return text;
  }
}