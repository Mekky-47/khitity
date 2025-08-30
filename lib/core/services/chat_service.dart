import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:giyas_ai/core/models/chat_message.dart';
import 'package:giyas_ai/core/services/auth_service.dart';

class ChatService {
  static const String _baseUrl = 'http://localhost:3000/api';

  // Send a message to the chatbot
  static Future<ChatResult> sendMessage({
    required String content,
    String? sessionId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return ChatResult.failure(message: 'No authentication token');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
          if (sessionId != null) 'sessionId': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userMessage = ChatMessage.fromJson(data['userMessage']);
        final assistantMessage = ChatMessage.fromJson(data['assistantMessage']);
        final aiResponse = data['aiResponse'] as Map<String, dynamic>;

        return ChatResult.success(
          userMessage: userMessage,
          assistantMessage: assistantMessage,
          sessionId: data['sessionId'] as String,
          aiResponse: aiResponse,
        );
      } else {
        final error = jsonDecode(response.body);
        return ChatResult.failure(
            message: error['error'] ?? 'Failed to send message');
      }
    } catch (e) {
      return ChatResult.failure(message: 'Network error: $e');
    }
  }

  // Get chat history for a session
  static Future<ChatResult> getChatHistory({
    required String sessionId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return ChatResult.failure(message: 'No authentication token');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/session/$sessionId?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = (data['messages'] as List)
            .map((msg) => ChatMessage.fromJson(msg))
            .toList();
        final pagination = data['pagination'] as Map<String, dynamic>;

        return ChatResult.success(
          messages: messages,
          pagination: pagination,
        );
      } else {
        final error = jsonDecode(response.body);
        return ChatResult.failure(
            message: error['error'] ?? 'Failed to get chat history');
      }
    } catch (e) {
      return ChatResult.failure(message: 'Network error: $e');
    }
  }

  // Get all chat sessions for user
  static Future<ChatResult> getChatSessions({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return ChatResult.failure(message: 'No authentication token');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/sessions?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = (data['sessions'] as List)
            .map((session) => ChatSession.fromJson(session))
            .toList();
        final pagination = data['pagination'] as Map<String, dynamic>;

        return ChatResult.success(
          sessions: sessions,
          pagination: pagination,
        );
      } else {
        final error = jsonDecode(response.body);
        return ChatResult.failure(
            message: error['error'] ?? 'Failed to get chat sessions');
      }
    } catch (e) {
      return ChatResult.failure(message: 'Network error: $e');
    }
  }

  // Start a new chat session
  static Future<ChatResult> startNewSession() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return ChatResult.failure(message: 'No authentication token');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/session'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final welcomeMessage = ChatMessage.fromJson(data['welcomeMessage']);
        final sessionId = data['sessionId'] as String;

        return ChatResult.success(
          welcomeMessage: welcomeMessage,
          sessionId: sessionId,
        );
      } else {
        final error = jsonDecode(response.body);
        return ChatResult.failure(
            message: error['error'] ?? 'Failed to start new session');
      }
    } catch (e) {
      return ChatResult.failure(message: 'Network error: $e');
    }
  }

  // Mark messages as read
  static Future<ChatResult> markAsRead(String sessionId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return ChatResult.failure(message: 'No authentication token');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/chat/read/$sessionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return ChatResult.success(message: 'Messages marked as read');
      } else {
        final error = jsonDecode(response.body);
        return ChatResult.failure(
            message: error['error'] ?? 'Failed to mark messages as read');
      }
    } catch (e) {
      return ChatResult.failure(message: 'Network error: $e');
    }
  }

  // Get chat analytics
  static Future<ChatResult> getChatAnalytics({int days = 30}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return ChatResult.failure(message: 'No authentication token');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/analytics?days=$days'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analytics = data['analytics'] as Map<String, dynamic>;

        return ChatResult.success(analytics: analytics);
      } else {
        final error = jsonDecode(response.body);
        return ChatResult.failure(
            message: error['error'] ?? 'Failed to get chat analytics');
      }
    } catch (e) {
      return ChatResult.failure(message: 'Network error: $e');
    }
  }
}

class ChatResult {
  final bool isSuccess;
  final List<ChatMessage>? messages;
  final List<ChatSession>? sessions;
  final ChatMessage? userMessage;
  final ChatMessage? assistantMessage;
  final ChatMessage? welcomeMessage;
  final String? sessionId;
  final Map<String, dynamic>? pagination;
  final Map<String, dynamic>? analytics;
  final Map<String, dynamic>? aiResponse;
  final String? message;

  const ChatResult._({
    required this.isSuccess,
    this.messages,
    this.sessions,
    this.userMessage,
    this.assistantMessage,
    this.welcomeMessage,
    this.sessionId,
    this.pagination,
    this.analytics,
    this.aiResponse,
    this.message,
  });

  factory ChatResult.success({
    List<ChatMessage>? messages,
    List<ChatSession>? sessions,
    ChatMessage? userMessage,
    ChatMessage? assistantMessage,
    ChatMessage? welcomeMessage,
    String? sessionId,
    Map<String, dynamic>? pagination,
    Map<String, dynamic>? analytics,
    Map<String, dynamic>? aiResponse,
    String? message,
  }) {
    return ChatResult._(
      isSuccess: true,
      messages: messages,
      sessions: sessions,
      userMessage: userMessage,
      assistantMessage: assistantMessage,
      welcomeMessage: welcomeMessage,
      sessionId: sessionId,
      pagination: pagination,
      analytics: analytics,
      aiResponse: aiResponse,
      message: message,
    );
  }

  factory ChatResult.failure({String? message}) {
    return ChatResult._(
      isSuccess: false,
      message: message,
    );
  }
}
