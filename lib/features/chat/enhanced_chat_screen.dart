import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giyas_ai/core/models/chat_message.dart';
import 'package:giyas_ai/core/models/user.dart';
import 'package:giyas_ai/core/providers/chat_provider.dart';
import 'package:giyas_ai/core/providers/auth_provider.dart';

class EnhancedChatScreen extends ConsumerStatefulWidget {
  const EnhancedChatScreen({super.key});

  @override
  ConsumerState<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends ConsumerState<EnhancedChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNewSession();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startNewSession() async {
    await ref.read(chatProvider.notifier).startNewSession();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    await ref.read(chatProvider.notifier).sendMessage(message);

    setState(() {
      _isTyping = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giyas.AI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Study Assistant',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewSession,
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: chatState.when(
              data: (messages) => messages.isEmpty
                  ? _buildWelcomeMessage(user)
                  : _buildMessagesList(messages),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _startNewSession,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Typing Indicator
          if (_isTyping) _buildTypingIndicator(),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage(User? user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Icon(
                Icons.psychology,
                size: 64,
                color: Colors.blue[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hello${user?.name != null ? ', ${user!.name}' : ''}! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'I\'m Giyas.AI, your personal study assistant. I can help you with:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildFeatureChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChips() {
    final features = [
      {'icon': Icons.schedule, 'text': 'Study Planning'},
      {'icon': Icons.psychology, 'text': 'Mood Analysis'},
      {'icon': Icons.lightbulb, 'text': 'Study Tips'},
      {'icon': Icons.quiz, 'text': 'Exam Prep'},
      {'icon': Icons.timer, 'text': 'Time Management'},
      {'icon': Icons.book, 'text': 'Subject Help'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.map((feature) {
        return ActionChip(
          avatar: Icon(
            feature['icon'] as IconData,
            size: 16,
            color: Colors.blue,
          ),
          label: Text(
            feature['text'] as String,
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: Colors.blue[50],
          side: BorderSide(color: Colors.blue[200]!),
          onPressed: () {
            _messageController.text = 'Help me with ${feature['text']}';
            _sendMessage();
          },
        );
      }).toList(),
    );
  }

  Widget _buildMessagesList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.messageType == MessageType.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.psychology,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey[100],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: Icon(
              Icons.psychology,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                _buildTypingDot(1),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.grey[600]?.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
