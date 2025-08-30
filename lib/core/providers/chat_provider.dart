import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giyas_ai/core/models/chat_message.dart';
import 'package:giyas_ai/core/services/chat_service.dart';

class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  ChatNotifier() : super(const AsyncValue.data([]));

  String? _currentSessionId;
  List<ChatMessage> get messages => state.value ?? [];
  String? get currentSessionId => _currentSessionId;

  // Start a new chat session
  Future<void> startNewSession() async {
    try {
      state = const AsyncValue.loading();
      final result = await ChatService.startNewSession();

      if (result.isSuccess) {
        _currentSessionId = result.sessionId;
        if (result.welcomeMessage != null) {
          state = AsyncValue.data([result.welcomeMessage!]);
        } else {
          state = const AsyncValue.data([]);
        }
      } else {
        state = AsyncValue.error(
            result.message ?? 'Failed to start session', StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Send a message to the chatbot
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    try {
      // Add user message immediately
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user', // Will be replaced by backend
        sessionId: _currentSessionId ?? 'temp_session',
        messageType: MessageType.user,
        content: content,
        timestamp: DateTime.now(),
      );

      final currentMessages = List<ChatMessage>.from(messages);
      currentMessages.add(userMessage);
      state = AsyncValue.data(currentMessages);

      // Send to backend
      final result = await ChatService.sendMessage(
        content: content,
        sessionId: _currentSessionId,
      );

      if (result.isSuccess) {
        _currentSessionId = result.sessionId;

        // Update messages with backend response
        final updatedMessages = List<ChatMessage>.from(currentMessages);

        // Replace temporary user message with real one
        if (result.userMessage != null) {
          final userIndex =
              updatedMessages.indexWhere((msg) => msg.id == userMessage.id);
          if (userIndex != -1) {
            updatedMessages[userIndex] = result.userMessage!;
          }
        }

        // Add assistant message
        if (result.assistantMessage != null) {
          updatedMessages.add(result.assistantMessage!);
        }

        state = AsyncValue.data(updatedMessages);
      } else {
        // Remove user message on failure
        final updatedMessages = List<ChatMessage>.from(currentMessages);
        updatedMessages.removeLast();
        state = AsyncValue.data(updatedMessages);

        // Show error state
        state = AsyncValue.error(
            result.message ?? 'Failed to send message', StackTrace.current);
      }
    } catch (e) {
      // Remove user message on error
      final currentMessages = List<ChatMessage>.from(messages);
      if (currentMessages.isNotEmpty &&
          currentMessages.last.messageType == MessageType.user) {
        currentMessages.removeLast();
        state = AsyncValue.data(currentMessages);
      }

      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Load chat history for a session
  Future<void> loadChatHistory(String sessionId) async {
    try {
      state = const AsyncValue.loading();
      _currentSessionId = sessionId;

      final result = await ChatService.getChatHistory(sessionId: sessionId);

      if (result.isSuccess && result.messages != null) {
        state = AsyncValue.data(result.messages!);
      } else {
        state = AsyncValue.error(
            result.message ?? 'Failed to load chat history',
            StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Load chat sessions list
  Future<List<ChatSession>> loadChatSessions() async {
    try {
      final result = await ChatService.getChatSessions();

      if (result.isSuccess && result.sessions != null) {
        return result.sessions!;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String sessionId) async {
    try {
      await ChatService.markAsRead(sessionId);

      // Update local state to mark messages as read
      final updatedMessages = messages.map((msg) {
        if (msg.sessionId == sessionId &&
            msg.messageType == MessageType.assistant) {
          return msg.copyWith(isRead: true);
        }
        return msg;
      }).toList();

      state = AsyncValue.data(updatedMessages);
    } catch (e) {
      // Silently fail for read marking
      // Log error for debugging
    }
  }

  // Clear current chat
  void clearChat() {
    state = const AsyncValue.data([]);
    _currentSessionId = null;
  }

  // Get unread message count
  int get unreadCount {
    return messages
        .where((msg) => msg.messageType == MessageType.assistant && !msg.isRead)
        .length;
  }

  // Check if current session has messages
  bool get hasMessages => messages.isNotEmpty;
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessage>>>(
  (ref) => ChatNotifier(),
);

final chatNotifierProvider = Provider<ChatNotifier>((ref) {
  return ref.read(chatProvider.notifier);
});

final unreadMessageCountProvider = Provider<int>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.value
          ?.where(
              (msg) => msg.messageType == MessageType.assistant && !msg.isRead)
          .length ??
      0;
});
