import 'package:flutter/foundation.dart';

/// 角色核心行为状态（避免多个交互事件动画冲突）
enum CharacterActivity {
  idle,      // 待机
  thinking,  // 思考（加载回复 / 疑惑）
  speaking,  // 说话（打字机 / TTS 朗读中）
  drumming,  // 击鼓
  poked,     // 被戳反应
}

/// 角色立绘姿态与情绪
enum CharacterPose {
  idle,         // guide_idle.png
  explaining,   // guide_explaining.png（闭嘴讲解）
  speakingOpen, // guide_speaking_open.png（张嘴说话）
  thinking,     // guide_thinking.png（托腮思考）
  drumming,     // guide_drumming.png（执槌击鼓）
  bowing,       // guide_bowing.png（作揖微笑）
}

@immutable
class CharacterState {
  final CharacterActivity activity;
  final CharacterPose pose;
  final bool isMouthOpen;
  final String? reactionBubble;
  final int pokeCount;

  const CharacterState({
    this.activity = CharacterActivity.idle,
    this.pose = CharacterPose.idle,
    this.isMouthOpen = false,
    this.reactionBubble,
    this.pokeCount = 0,
  });

  /// 根据当前活动状态与口型计算实际渲染的立绘文件前缀
  String get currentAssetBaseName {
    if (activity == CharacterActivity.speaking) {
      return isMouthOpen ? 'guide_speaking_open' : 'guide_explaining';
    }
    switch (pose) {
      case CharacterPose.explaining:
        return 'guide_explaining';
      case CharacterPose.speakingOpen:
        return 'guide_speaking_open';
      case CharacterPose.thinking:
        return 'guide_thinking';
      case CharacterPose.drumming:
        return 'guide_drumming';
      case CharacterPose.bowing:
        return 'guide_bowing';
      case CharacterPose.idle:
        return 'guide_idle';
    }
  }

  CharacterState copyWith({
    CharacterActivity? activity,
    CharacterPose? pose,
    bool? isMouthOpen,
    String? reactionBubble,
    bool clearBubble = false,
    int? pokeCount,
  }) {
    return CharacterState(
      activity: activity ?? this.activity,
      pose: pose ?? this.pose,
      isMouthOpen: isMouthOpen ?? this.isMouthOpen,
      reactionBubble:
          clearBubble ? null : (reactionBubble ?? this.reactionBubble),
      pokeCount: pokeCount ?? this.pokeCount,
    );
  }
}