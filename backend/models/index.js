const User = require('./User');
const MoodSession = require('./MoodSession');
const ChatSession = require('./ChatSession');
const ChatMessage = require('./ChatMessage');
const StudySession = require('./StudySession');

// Define associations
User.hasMany(MoodSession, {
  foreignKey: 'userId',
  as: 'moodSessions',
  onDelete: 'CASCADE'
});

MoodSession.belongsTo(User, {
  foreignKey: 'userId',
  as: 'user'
});

User.hasMany(ChatSession, {
  foreignKey: 'userId',
  as: 'chatSessions',
  onDelete: 'CASCADE'
});

ChatSession.belongsTo(User, {
  foreignKey: 'userId',
  as: 'user'
});

ChatSession.hasMany(ChatMessage, {
  foreignKey: 'sessionId',
  as: 'messages',
  onDelete: 'CASCADE'
});

ChatMessage.belongsTo(ChatSession, {
  foreignKey: 'sessionId',
  as: 'session'
});

User.hasMany(ChatMessage, {
  foreignKey: 'userId',
  as: 'chatMessages',
  onDelete: 'CASCADE'
});

ChatMessage.belongsTo(User, {
  foreignKey: 'userId',
  as: 'user'
});

User.hasMany(StudySession, {
  foreignKey: 'userId',
  as: 'studySessions',
  onDelete: 'CASCADE'
});

StudySession.belongsTo(User, {
  foreignKey: 'userId',
  as: 'user'
});

MoodSession.hasMany(StudySession, {
  foreignKey: 'moodSessionId',
  as: 'studySessions'
});

StudySession.belongsTo(MoodSession, {
  foreignKey: 'moodSessionId',
  as: 'moodSession'
});

module.exports = {
  User,
  MoodSession,
  ChatSession,
  ChatMessage,
  StudySession
};
