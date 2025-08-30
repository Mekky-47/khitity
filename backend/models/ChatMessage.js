const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const ChatMessage = sequelize.define('ChatMessage', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  sessionId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'chat_sessions',
      key: 'id'
    }
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  messageType: {
    type: DataTypes.ENUM('user', 'assistant'),
    allowNull: false
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  moodContext: {
    type: DataTypes.JSONB,
    allowNull: true
  },
  studyContext: {
    type: DataTypes.JSONB,
    allowNull: true
  },
  aiResponse: {
    type: DataTypes.JSONB,
    allowNull: true
  },
  isRead: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  metadata: {
    type: DataTypes.JSONB,
    allowNull: true,
    defaultValue: {}
  }
}, {
  tableName: 'chat_messages',
  timestamps: true,
  underscored: true,
  indexes: [
    {
      fields: ['session_id']
    },
    {
      fields: ['user_id']
    },
    {
      fields: ['message_type']
    },
    {
      fields: ['created_at']
    },
    {
      fields: ['is_read']
    }
  ]
});

// Instance methods
ChatMessage.prototype.getPublicData = function() {
  return {
    id: this.id,
    sessionId: this.sessionId,
    messageType: this.messageType,
    content: this.content,
    moodContext: this.moodContext,
    studyContext: this.studyContext,
    aiResponse: this.aiResponse,
    isRead: this.isRead,
    metadata: this.metadata,
    timestamp: this.createdAt,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

// Class methods
ChatMessage.findBySession = function(sessionId, options = {}) {
  const defaultOptions = {
    where: { sessionId },
    order: [['createdAt', 'ASC']],
    limit: 100
  };
  
  return this.findAll({
    ...defaultOptions,
    ...options
  });
};

ChatMessage.findByUser = function(userId, options = {}) {
  const defaultOptions = {
    where: { userId },
    order: [['createdAt', 'DESC']],
    limit: 50
  };
  
  return this.findAll({
    ...defaultOptions,
    ...options
  });
};

ChatMessage.getUnreadCount = function(userId) {
  return this.count({
    where: {
      userId,
      messageType: 'assistant',
      isRead: false
    }
  });
};

ChatMessage.markAsRead = function(sessionId, userId) {
  return this.update(
    { isRead: true },
    {
      where: {
        sessionId,
        userId,
        messageType: 'assistant',
        isRead: false
      }
    }
  );
};

module.exports = ChatMessage;
