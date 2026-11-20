import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_strings.dart';
import 'models/chat_response.dart';
import 'screens/topic_detail_screen.dart';
import 'screens/vn_chat_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: JianGuGameApp(),
    ),
  );
}

class JianGuGameApp extends StatelessWidget {
  const JianGuGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const VisualNovelScreen(),
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        if (name.startsWith('/topics/')) {
          final topicId = name.substring('/topics/'.length);
          final topic = kTopicById[topicId];
          if (topic != null) {
            return MaterialPageRoute<String>(
              settings: settings,
              builder: (_) => TopicDetailScreen(topic: topic),
            );
          }
        }
        return null;
      },
    );
  }
}