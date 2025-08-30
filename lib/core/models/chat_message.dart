enum MessageType { user, assistant }

class ChatMessage {
  final String id;
  final String userId;
  final String sessionId;
  final MessageType messageType;
  final String content;
  final Map<String, dynamic>? moodContext;
  final Map<String, dynamic>? studyContext;
  final Map<String, dynamic>? aiResponse;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.messageType,
    required this.content,
    this.moodContext,
    this.studyContext,
    this.aiResponse,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String,
      messageType: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['messageType'],
        orElse: () => MessageType.user,
      ),
      content: json['content'] as String,
      moodContext: json['moodContext'] != null
          ? Map<String, dynamic>.from(json['moodContext'] as Map)
          : null,
      studyContext: json['studyContext'] != null
          ? Map<String, dynamic>.from(json['studyContext'] as Map)
          : null,
      aiResponse: json['aiResponse'] != null
          ? Map<String, dynamic>.from(json['aiResponse'] as Map)
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sessionId': sessionId,
      'messageType': messageType.toString().split('.').last,
      'content': content,
      'moodContext': moodContext,
      'studyContext': studyContext,
      'aiResponse': aiResponse,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? userId,
    String? sessionId,
    MessageType? messageType,
    String? content,
    Map<String, dynamic>? moodContext,
    Map<String, dynamic>? studyContext,
    Map<String, dynamic>? aiResponse,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      moodContext: moodContext ?? this.moodContext,
      studyContext: studyContext ?? this.studyContext,
      aiResponse: aiResponse ?? this.aiResponse,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, messageType: $messageType, content: $content, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ChatSession {
  final String sessionId;
  final String firstMessage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int messageCount;
  final MessageType lastMessageType;

  const ChatSession({
    required this.sessionId,
    required this.firstMessage,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.messageCount,
    required this.lastMessageType,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['sessionId'] as String,
      firstMessage: json['firstMessage'] as String,
      lastMessage: json['lastMessage'] as String,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      messageCount: json['messageCount'] as int,
      lastMessageType: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['lastMessageType'],
        orElse: () => MessageType.user,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'firstMessage': firstMessage,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'messageCount': messageCount,
      'lastMessageType': lastMessageType.toString().split('.').last,
    };
  }
}
