const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const ChatSession = sequelize.define('ChatSession', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  title: {
    type: DataTypes.STRING(255),
    allowNull: false,
    defaultValue: 'New Chat Session'
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  lastMessageAt: {
    type: DataTypes.DATE,
    allowNull: true
  },
  messageCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  context: {
    type: DataTypes.JSONB,
    allowNull: true,
    defaultValue: {}
  }
}, {
  tableName: 'chat_sessions',
  timestamps: true,
  underscored: true,
  indexes: [
    {
      fields: ['user_id']
    },
    {
      fields: ['last_message_at']
    },
    {
      fields: ['is_active']
    }
  ]
});

// Instance methods
ChatSession.prototype.getPublicData = function() {
  return {
    id: this.id,
    title: this.title,
    isActive: this.isActive,
    lastMessageAt: this.lastMessageAt,
    messageCount: this.messageCount,
    context: this.context,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

// Class methods
ChatSession.findByUser = function(userId, options = {}) {
  const defaultOptions = {
    where: { userId },
    order: [['lastMessageAt', 'DESC']],
    limit: 50
  };
  
  return this.findAll({
    ...defaultOptions,
    ...options
  });
};

ChatSession.createForUser = async function(userId, title = 'New Chat Session') {
  return await this.create({
    userId,
    title,
    isActive: true,
    lastMessageAt: new Date()
  });
};

module.exports = ChatSession;
