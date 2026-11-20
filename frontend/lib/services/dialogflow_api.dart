import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/app_strings.dart';
import '../models/chat_response.dart';

class DialogflowApiService {
  static const String retryLabel = AppStrings.tryAgain;

  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning!';
    } else if (hour >= 12 && hour < 18) {
      return 'Good afternoon!';
    } else {
      return 'Good evening!';
    }
  }

  Future<ChatResponse> sendMessage({
    required String sessionId,
    required String text,
    required String knownUserName,
    bool isSystemTrigger = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'session_id': sessionId, 'text': text}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
          'Server error (${response.statusCode}). Please try again.');
    }

    final data = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map,
    );

    return ChatResponse.fromJson(
      data,
      timeGreeting: getTimeBasedGreeting(),
      isWelcomeTrigger: isSystemTrigger && text.toLowerCase() == 'hi',
      knownUserName: knownUserName,
    );
  }

  Future<void> sendFeedback({
    required String sessionId,
    required String intent,
    required String reply,
    required int rating,
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': sessionId,
          'intent': intent,
          'reply': reply,
          'rating': rating,
        }),
      );
    } catch (_) {}
  }
}