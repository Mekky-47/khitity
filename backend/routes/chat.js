const express = require('express');
const { body, validationResult } = require('express-validator');
const { ChatSession, ChatMessage } = require('../models');
const { auth } = require('../middleware/auth');
const { generateChatResponse } = require('../services/aiService');

const router = express.Router();

// Validation middleware
const validateMessage = [
  body('content').trim().isLength({ min: 1, max: 2000 }).withMessage('Message must be 1-2000 characters'),
  body('sessionId').optional().isUUID().withMessage('Invalid session ID')
];

// Basic chat endpoint information
router.get('/', (req, res) => {
  res.json({
    message: 'Chat API',
    description: 'AI-powered chat sessions and messaging',
    endpoints: {
      'GET /sessions': 'Get user chat sessions (requires auth)',
      'POST /sessions': 'Create new chat session (requires auth)',
      'GET /sessions/:id': 'Get chat session with messages (requires auth)',
      'POST /sessions/:id/messages': 'Send message in session (requires auth)',
      'PUT /sessions/:id': 'Update chat session (requires auth)',
      'DELETE /sessions/:id': 'Delete chat session (requires auth)',
      'GET /sessions/:id/messages': 'Get session messages (requires auth)'
    },
    authentication: 'All endpoints require authentication'
  });
});

// Get user's chat sessions
router.get('/sessions', auth, async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const { count, rows: sessions } = await ChatSession.findAndCountAll({
      where: { userId: req.user.id },
      order: [['lastMessageAt', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset),
      include: [{
        model: ChatMessage,
        as: 'messages',
        limit: 1,
        order: [['createdAt', 'DESC']]
      }]
    });

    res.json({
      sessions: sessions.map(session => ({
        ...session.getPublicData(),
        lastMessage: session.messages?.[0]?.getPublicData()
      })),
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(count / limit),
        totalItems: count,
        itemsPerPage: parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Chat sessions fetch error:', error);
    res.status(500).json({ 
      error: 'Internal server error fetching chat sessions' 
    });
  }
});

// Create new chat session
router.post('/sessions', auth, [
  body('title').optional().trim().isLength({ min: 1, max: 255 }).withMessage('Title must be 1-255 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array() 
      });
    }

    const { title = 'New Chat Session' } = req.body;

    const session = await ChatSession.create({
      userId: req.user.id,
      title,
      isActive: true,
      lastMessageAt: new Date()
    });

    res.status(201).json({
      message: 'Chat session created successfully',
      session: session.getPublicData()
    });

  } catch (error) {
    console.error('Chat session creation error:', error);
    res.status(500).json({ 
      error: 'Internal server error creating chat session' 
    });
  }
});

// Get chat session with messages
router.get('/sessions/:sessionId', auth, async (req, res) => {
  try {
    const session = await ChatSession.findOne({
      where: {
        id: req.params.sessionId,
        userId: req.user.id
      },
      include: [{
        model: ChatMessage,
        as: 'messages',
        order: [['createdAt', 'ASC']]
      }]
    });

    if (!session) {
      return res.status(404).json({ 
        error: 'Chat session not found' 
      });
    }

    res.json({
      session: {
        ...session.getPublicData(),
        messages: session.messages.map(message => message.getPublicData())
      }
    });

  } catch (error) {
    console.error('Chat session fetch error:', error);
    res.status(500).json({ 
      error: 'Internal server error fetching chat session' 
    });
  }
});

// Update chat session
router.put('/sessions/:sessionId', auth, [
  body('title').optional().trim().isLength({ min: 1, max: 255 }).withMessage('Title must be 1-255 characters'),
  body('isActive').optional().isBoolean().withMessage('isActive must be a boolean')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array() 
      });
    }

    const session = await ChatSession.findOne({
      where: {
        id: req.params.sessionId,
        userId: req.user.id
      }
    });

    if (!session) {
      return res.status(404).json({ 
        error: 'Chat session not found' 
      });
    }

    const { title, isActive } = req.body;
    const updateData = {};

    if (title !== undefined) updateData.title = title;
    if (isActive !== undefined) updateData.isActive = isActive;

    await session.update(updateData);

    res.json({
      message: 'Chat session updated successfully',
      session: session.getPublicData()
    });

  } catch (error) {
    console.error('Chat session update error:', error);
    res.status(500).json({ 
      error: 'Internal server error updating chat session' 
    });
  }
});

// Delete chat session
router.delete('/sessions/:sessionId', auth, async (req, res) => {
  try {
    const session = await ChatSession.findOne({
      where: {
        id: req.params.sessionId,
        userId: req.user.id
      }
    });

    if (!session) {
      return res.status(404).json({ 
        error: 'Chat session not found' 
      });
    }

    await session.destroy();

    res.json({
      message: 'Chat session deleted successfully'
    });

  } catch (error) {
    console.error('Chat session delete error:', error);
    res.status(500).json({ 
      error: 'Internal server error deleting chat session' 
    });
  }
});

// Send message to chatbot
router.post('/send-message', auth, validateMessage, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array() 
      });
    }

    const { content, sessionId, moodContext, studyContext } = req.body;

    let session;
    
    if (sessionId) {
      // Use existing session
      session = await ChatSession.findOne({
        where: {
          id: sessionId,
          userId: req.user.id
        }
      });

      if (!session) {
        return res.status(404).json({ 
          error: 'Chat session not found' 
        });
      }
    } else {
      // Create new session
      session = await ChatSession.create({
        userId: req.user.id,
        title: 'New Chat Session',
        isActive: true,
        lastMessageAt: new Date()
      });
    }

    // Save user message
    const userMessage = await ChatMessage.create({
      sessionId: session.id,
      userId: req.user.id,
      messageType: 'user',
      content,
      moodContext,
      studyContext
    });

    // Get conversation context
    const previousMessages = await ChatMessage.findAll({
      where: { sessionId: session.id },
      order: [['createdAt', 'ASC']],
      limit: 10
    });

    const context = previousMessages.map(msg => ({
      role: msg.messageType === 'user' ? 'user' : 'assistant',
      content: msg.content
    }));

    // Generate AI response
    const aiResponse = await generateChatResponse(content, context, {
      moodContext,
      studyContext,
      userId: req.user.id
    });

    // Save AI response
    const assistantMessage = await ChatMessage.create({
      sessionId: session.id,
      userId: req.user.id,
      messageType: 'assistant',
      content: aiResponse.content,
      aiResponse: aiResponse.metadata || {},
      moodContext,
      studyContext
    });

    // Update session
    await session.update({
      lastMessageAt: new Date(),
      messageCount: session.messageCount + 2,
      context: {
        ...session.context,
        lastMoodContext: moodContext,
        lastStudyContext: studyContext
      }
    });

    res.json({
      message: 'Message sent successfully',
      session: session.getPublicData(),
      userMessage: userMessage.getPublicData(),
      assistantMessage: assistantMessage.getPublicData()
    });

  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ 
      error: 'Internal server error sending message' 
    });
  }
});

// Get messages for a session
router.get('/sessions/:sessionId/messages', auth, async (req, res) => {
  try {
    const { page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;

    const session = await ChatSession.findOne({
      where: {
        id: req.params.sessionId,
        userId: req.user.id
      }
    });

    if (!session) {
      return res.status(404).json({ 
        error: 'Chat session not found' 
      });
    }

    const { count, rows: messages } = await ChatMessage.findAndCountAll({
      where: { sessionId: session.id },
      order: [['createdAt', 'ASC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.json({
      messages: messages.map(message => message.getPublicData()),
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(count / limit),
        totalItems: count,
        itemsPerPage: parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Messages fetch error:', error);
    res.status(500).json({ 
      error: 'Internal server error fetching messages' 
    });
  }
});

// Mark messages as read
router.put('/sessions/:sessionId/mark-read', auth, async (req, res) => {
  try {
    const session = await ChatSession.findOne({
      where: {
        id: req.params.sessionId,
        userId: req.user.id
      }
    });

    if (!session) {
      return res.status(404).json({ 
        error: 'Chat session not found' 
      });
    }

    await ChatMessage.update(
      { isRead: true },
      {
        where: {
          sessionId: session.id,
          userId: req.user.id,
          messageType: 'assistant',
          isRead: false
        }
      }
    );

    res.json({
      message: 'Messages marked as read'
    });

  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ 
      error: 'Internal server error marking messages as read' 
    });
  }
});

// Get unread message count
router.get('/unread-count', auth, async (req, res) => {
  try {
    const count = await ChatMessage.count({
      where: {
        userId: req.user.id,
        messageType: 'assistant',
        isRead: false
      }
    });

    res.json({
      unreadCount: count
    });

  } catch (error) {
    console.error('Unread count error:', error);
    res.status(500).json({ 
      error: 'Internal server error fetching unread count' 
    });
  }
});

// Get chat analytics
router.get('/analytics', auth, async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(days));

    const sessions = await ChatSession.findAll({
      where: {
        userId: req.user.id,
        createdAt: {
          [require('sequelize').Op.gte]: startDate
        }
      },
      include: [{
        model: ChatMessage,
        as: 'messages'
      }]
    });

    const totalSessions = sessions.length;
    const totalMessages = sessions.reduce((sum, session) => sum + session.messages.length, 0);
    const averageMessagesPerSession = totalSessions > 0 ? totalMessages / totalSessions : 0;

    const activeSessions = sessions.filter(session => session.isActive).length;

    res.json({
      analytics: {
        totalSessions,
        totalMessages,
        averageMessagesPerSession,
        activeSessions,
        sessionsInPeriod: totalSessions
      }
    });

  } catch (error) {
    console.error('Chat analytics error:', error);
    res.status(500).json({ 
      error: 'Internal server error fetching chat analytics' 
    });
  }
});

module.exports = router;
