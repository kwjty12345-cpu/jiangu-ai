class AppStrings {
  const AppStrings._();

  static const String appTitle = 'Jian Gu Interactive Guide';
  static const String sealMonogram = 'JG';
  static const String guideName = 'Court Music Master';
  static const String guideSubtitle = 'Your Jian Gu Guide';
  static const String userLabel = 'You';

  // Top Toolbar
  static const String topics = 'Topics';
  static const String history = 'History';
  static const String drumPractice = 'Drum Practice';
  static const String putAway = 'Put Away';
  static const String menuTooltip = 'More options';
  static const String muteTooltip = 'Tap to mute, long press for voice settings';
  static const String voiceSettingsTooltip = 'Voice settings';

  // Separated Sections: Suggested Questions vs Details vs References
  static const String suggestedQuestionsTitle = 'SUGGESTED QUESTIONS';
  static const String detailsBadge = 'Details';
  static const String referencesHeader = 'REFERENCES';
  static const String refTypeTopic = 'Topic';
  static const String refTypeArtifact = 'Artifact';
  static const String refTypeExternal = 'Source';

  // Inline Practice Link & Topic Detail
  static const String inlinePracticeLink = 'Try it in Drum Practice \u2192';
  static const String backToChat = '\u2190 Back to chat';
  static const String askGuideAboutTopic = 'Ask the Guide About This Topic';
  static const String dismissTooltip = 'Dismiss';
  static const String showLess = 'Show less \u25B4';
  static String sourcesToggle(int count) => 'Show all ($count) \u25BE';

  // Dialogue Box
  static const String listen = 'Listen';
  static const String stop = 'Stop';
  static const String restartTooltip = 'Restart conversation';
  static const String tapToSkip = 'Tap card to skip';
  static const String loadingArchives = 'Consulting the ritual archives...';
  static const String inputHintName = 'Enter your name first...';
  static const String inputHintReady = 'Ask about the Jian Gu...';
  static const String sendTooltip = 'Send message';
  static const String tryAgain = 'Try again';

  // Modals & Toasts
  static const String exploreTopicsTitle = 'Explore Topics';
  static const String historyTitle = 'Conversation History';
  static const String noMessagesYet = 'No messages yet.';
  static const String voiceSettingsTitle = 'Voice Settings';
  static const String autoReadTitle = 'Auto-Read Replies';
  static const String autoReadSubtitle = 'Read aloud automatically on each reply';
  static const String muteSpeechTitle = 'Mute All Speech';
  static const String speechSpeed = 'Speech Speed';
  static const String done = 'Done';
  static const String close = 'Close';
  static const String feedbackPositiveToast = 'Thanks! Glad this answer was helpful.';
  static const String feedbackNegativeToast = 'Feedback noted. We will refine this answer.';

  // Network Errors
  static const String errorTimeout =
      'The server took too long to respond. Please try again.';
  static const String errorConnection =
      'Connection error. Please check your backend server.';

  // Character Poke Reactions
  static const List<String> pokeReactions = [
    'Careful with the imperial tassels—they took hours to arrange!',
    'A Court Music Master must keep proper posture in the ritual hall.',
    'Curious about the coiled bronze dragons? Ask me anything about the Jian Gu.',
    'Ready to hear the standing drum? Click Drum Practice at the top anytime.',
  ];

  // Drum Practice UI
  static const String start = 'Start';
  static const String retry = 'Retry';
  static const String skip = 'Skip';
  static const String replayTutorialTooltip = 'Replay tutorial';
  static const String skipTutorialTooltip = 'Skip to free play';
  static const String hearPattern = 'Hear Pattern';
  static const String listening = 'Listening...';
  static const String legendCenter = 'Center [F/J]';
  static const String legendRim = 'Rim [D/K]';
  static const String legendHold = 'Hold Roll';
  static const String beatCenter = 'Dong · Center';
  static const String beatRim = 'Da · Rim';

  // Gesture Hints
  static const String hintCenterMobile = 'Tap inside the golden center ring';
  static const String hintCenterDesktop = 'Click golden center or press [F] / [J]';
  static const String hintRimMobile = 'Tap along the bronze-green rim';
  static const String hintRimDesktop = 'Click outer green rim or press [D] / [K]';
  static const String hintRoll = 'Press and hold continuously for 2 seconds';

  // Drum Tutorial Steps
  static const String stepIntroTitle = 'Introduction';
  static const String stepCenterTitle = 'Step 1 · Strike the Center';
  static const String stepRimTitle = 'Step 2 · Strike the Rim';
  static const String stepRollTitle = 'Step 3 · Continuous Roll';
  static const String stepRhythmTitle = 'Step 4 · Court Cadence';
  static const String stepFreeTitle = 'Free Play';

  static String openingIntro(String guest) {
    final addr = guest.isNotEmpty ? ', $guest' : '';
    return 'Step up to the Jian Gu (the ancient Chinese standing drum)$addr. '
        'Learn three core strokes—center, rim, and roll—then follow a classic four-beat cadence.';
  }

  static String openingFree(String guest) {
    final addr = guest.isNotEmpty ? ', $guest' : '';
    return 'Welcome back to the Jian Gu$addr. Your hands are steady—play freely at your own pace.';
  }

  static const String stepCenterGuide =
      'Strike the thick cowhide center for a deep, commanding tone. Tap inside the golden ring 3 times.';

  static const String stepRimGuide =
      'Strike the lacquered wooden rim for a crisp, bright note. Tap the outer green ring 3 times.';

  static const String stepRollGuide =
      'Press and hold the drum center for 2 seconds. Both sticks will alternate in a continuous roll.';

  static const String stepRhythmGuide =
      'Follow my court cadence: Dong, Dong, Da, Dong (Center, Center, Rim, Center). Listen first or begin anytime.';

  static String stepFreeGuide(String guest) {
    final addr = guest.isNotEmpty ? ', $guest' : '';
    return 'Well done$addr. Your strokes are steady—play freely, or click Put Away to return to our conversation.';
  }

  static String practiceLog(int strikes, int maxCombo) =>
      'Drum Practice completed: $strikes hit${strikes == 1 ? '' : 's'} (longest streak: $maxCombo).';

  static String practicePraiseHigh(String guest, int strikes, int maxCombo) {
    final addr = guest.isNotEmpty ? ', $guest' : '';
    return 'Commanding rhythm$addr! You landed $strikes strikes with a streak of $maxCombo. '
        'In Zhonghe Shaoyue (imperial court ritual music) and battlefield signaling alike, '
        'such steady power carried across the entire assembly. What shall we explore next?';
  }

  static String practicePraiseStandard(String guest, int strikes, int maxCombo) {
    final addr = guest.isNotEmpty ? ', $guest' : '';
    return 'Well played$addr! You completed $strikes strikes with a best streak of $maxCombo. '
        'Whenever you wish to return to the standing drum, select Drum Practice at the top.';
  }
}