jiangu_interactive_bot/
├── backend/                                  # Python FastAPI + Dialogflow ES 中转与知识库服务
│   ├── main.py                               # /chat 与 /feedback 路由、11 主题英文知识库、按会话隔离真实用户名、返回 suggest_practice 标记
│   ├── service-account-key.json              # Google Cloud Dialogflow 私钥（切勿上传至公开仓库）
│   ├── feedback_log.jsonl                    # 自动生成的用户点赞/点踩反馈日志
│   └── requirements.txt                      # Python 依赖（fastapi, uvicorn, google-cloud-dialogflow, pydantic）
│
└── frontend/                                 # Flutter 跨平台客户端（Web / 桌面 / 移动端）
    ├── pubspec.yaml                          # 依赖配置（http, flutter_riverpod, flutter_tts, flutter_soloud）与资源声明
    ├── generate_jiangu_samples.py            # 建鼓声学物理建模脚本（生成 4 个 16-bit PCM 无压缩 WAV）
    │
    ├── web/
    │   └── index.html                        # <html lang="en">、英文 SEO 标题与描述、纯英文字体（Cormorant Garamond + Inter）
    │
    ├── assets/
    │   ├── images/                           # 透明底立绘（idle / explaining / speaking_open / thinking / bowing）与建鼓主图（jiangu_drum）
    │   └── audio/                            # 建鼓声学采样（drum_heavy.wav / drum_light.wav / drum_rim.wav / gong_retreat.wav）
    │
    └── lib/
        ├── main.dart                         # 应用入口：挂载全局 ProviderScope、AppTheme，并注册 /topics/<id> 深链接路由
        │
        ├── theme/
        │   └── app_theme.dart                # 礼乐青铜五色体系（玄黑/朱砂/古金/青铜绿/宣纸米白）与纯英文衬线/无衬线字体栈
        │
        ├── core/                             # 全局基础常量与跨平台工具
        │   ├── app_strings.dart              # 全站唯一英文文案中心（按钮、教学引导、错误提示、拼音+英文释义，零汉字）
        │   ├── external_link_opener.dart     # 条件编译导出接口（打开站外引用链接）
        │   ├── external_link_opener_web.dart # Web 端实现：调用 window.open(..., '_blank', 'noopener,noreferrer')
        │   ├── external_link_opener_stub.dart# 非 Web 平台条件编译占位
        │   └── audio_manager.dart            # [P4 预留] 全局背景古乐 BGM 管理
        │
        ├── models/
        │   └── chat_response.dart            # 数据模型与清洗层：ChatResponse、SourceCitation（校验并丢弃空标签）、11 主题索引 kTopicById、文本规范化（修复 $1 / Zhonghe Shaoyue / Jian Gu）
        │
        ├── services/
        │   └── dialogflow_api.dart           # FastAPI REST 通信层（携带 knownUserName 上下文与时段问候）
        │
        ├── character/                        # 导游角色状态机与安全区舞台渲染
        │   ├── character_state.dart          # Activity（5态）与 Pose（6态）状态定义
        │   ├── character_provider.dart       # Riverpod 状态机（240ms 口型开合定时器、思考/讲解/引导击鼓切换、戳一戳反应）
        │   └── character_stage.dart          # AssetManifest 扫描预缓存、呼吸微浮、微眨眼与底部 ShaderMask 渐隐遮罩
        │
        ├── tts/                              # 英文语音朗读与口型联动
        │   ├── text_sanitizer.dart           # 专有名词自然拼读转换（Jian Gu -> Jyen Goo, Zhonghe Shaoyue -> Johng-huh Shau-yweh）
        │   └── tts_service.dart              # flutter_tts 封装、语速档位（0.85x/1.0x/1.2x）、Web 端超时兜底与口型同步
        │
        ├── drum/                             # 同场景嵌入式建鼓互动与教学模块
        │   ├── drum_audio_service.dart       # 双轨低延迟音频服务（左右鼓槌立体声交替 pan: ±0.14、±3% 音高微抖动、长按滚奏）
        │   ├── drum_web_audio_web.dart       # Chrome Web 原生 Web Audio API（AudioContext + StereoPannerNode）WAV 解码引擎
        │   ├── drum_web_audio_stub.dart      # 非 Web 平台占位（自动回退至 flutter_soloud）
        │   ├── drum_ripple_painter.dart      # CustomPainter 金色/铜绿声波扩散与 Dong / Thump / Da / Clang 上飘字
        │   ├── drum_sticks.dart              # DrumSticks 双控制器 + 带雕木青铜鼓槌架的 DrumstickWithRackView（贴近鼓身 1.28x 宽度）
        │   ├── drum_tutorial.dart            # Onboarding（askName/ready）、SceneMode 与 5 阶段教学状态机（intro -> center -> rim -> roll -> rhythm -> free）
        │   └── drum_stage_panel.dart         # 左鼓右人响应式舞台、焦点脉冲聚光灯、三栏对齐头部、满宽引导台词与三等分可点击区域按钮
        │
        ├── screens/
        │   ├── vn_chat_screen.dart           # 主舞台：上部人物安全区 + 下部 <=40vh 聊天面板、单会话限次 Practice 链接、成绩写回对话
        │   └── topic_detail_screen.dart      # 站内 Reference 详情页（/topics/<id>），支持 "<- Back to chat" 恢复原对话滚动状态
        │
        ├── widgets/
        │   ├── museum_background.dart        # 博物馆展厅虚化底图（含径向压暗暗角与程序化青铜回纹保底）
        │   ├── lacquer_widgets.dart          # 4px 回纹漆面框 LacquerPanel、JG 朱红印章 SealNameplate、计数小印章 CountSealBadge、自绘线稿图标与卷轴展开过渡
        │   ├── dialogue_box.dart             # <=40vh 漆面对话框：局部刷新打字机、完整换行 ReferenceTag（>3 条折叠）、横向追问 chips 与底线输入框
        │   └── chat_modals.dart              # 极简顶栏（前置 Drum Practice/Put Away、Topics、History、窄屏折叠菜单）与历史/话题/语音弹窗
        │
        └── quiz/                             # [P4 预留] 11 主题随堂测验与青铜印章徽章
            ├── quiz_data.dart
            └── quiz_modal.dart