const express = require('express');
const { body, validationResult } = require('express-validator');
const { StudySession, MoodSession } = require('../models');
const { auth } = require('../middleware/auth');

const router = express.Router();

// Validation middleware
const validateStudySession = [
  body('subject').trim().isLength({ min: 1, max: 100 }).withMessage('Subject must be 1-100 characters'),
  body('plannedHours').isFloat({ min: 0.5, max: 12.0 }).withMessage('Planned hours must be 0.5-12.0'),
  body('startTime').isISO8601().withMessage('Valid start time required'),
  body('notes').optional().trim().isLength({ max: 1000 }).withMessage('Notes must be 0-1000 characters')
];

// Basic study endpoint information
router.get('/', (req, res) => {
  res.json({
    message: 'Study Planning API',
    description: 'Study session management and planning',
    endpoints: {
      'GET /sessions': 'Get user study sessions (requires auth)',
      'POST /sessions': 'Create new study session (requires auth)',
      'GET /sessions/:id': 'Get study session details (requires auth)',
      'PUT /sessions/:id': 'Update study session (requires auth)',
      'DELETE /sessions/:id': 'Delete study session (requires auth)',
      'POST /sessions/:id/start': 'Start study session (requires auth)',
      'POST /sessions/:id/pause': 'Pause study session (requires auth)',
      'POST /sessions/:id/complete': 'Complete study session (requires auth)',
      'GET /analytics': 'Get study analytics (requires auth)'
    },
    authentication: 'All endpoints require authentication'
  });
});

// Get user's study sessions
router.get('/sessions', auth, async (req, res) => {
  try {
    const { page = 1, limit = 20, status, subject } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = { userId: req.user.id };
    
    if (status) {
      whereClause.status = status;
    }
    
    if (subject) {
      whereClause.subject = {
        [require('sequelize').Op.iLike]: `%${subject}%`
      };
    }

    const { count, rows: sessions } = await StudySession.findAndCountAll({
      where: whereClause,
      order: [['startTime', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset),
      include: [{
        model: MoodSession,
        as: 'moodSession',
        attributes: ['moodType', 'recommendedStudyHours']
      }]
    });

    res.json({
      sessions: sessions.map(session => ({
        ...session.getPublicData(),
        moodSession: session.moodSession?.getPublicData()
      })),
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(count / limit),
        totalItems: count,
        itemsPerPage: parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Study sessions fetch error:', error);
    res.status(500).json({ 
      error: 'Internal server error fetching study sessions' 
    });
  }
});

// Create new study session
router.post('/sessions', auth, validateStudySession, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array() 
      });
    }

    const { subject, plannedHours, startTime, endTime, notes, moodSessionId, topics } = req.body;

    const session = await StudySession.create({
      userId: req.user.id,
      moodSessionId,
      subject,
      plannedHours,
      startTime: new Date(startTime),
      endTime: endTime ? new Date(endTime) : null,
      status: 'planned',
      notes,
      topics: topics || []
    });

    res.status(201).json({
      message: 'Study session created successfully',
      session: session.getPublicData()
    });

  } catch (error) {
    console.error('Study session creation error:', error);
    res.status(500).json({ 
      error: 'Internal server error creating study session' 
    });
  }
});

// Get specific study session
router.get('/sessions/:id', auth, async (req, res) => {
  try {
    const session = await StudySession.findOne({
      where: {
        id: req.params.id,
        userId: req.user.id
      },
      include: [{
        model: MoodSession,
        as: 'moodSession'
      }]
    });

    if (!session) {
      return res.status(404).json({ 
        error: 'Study session not found' 
      });
    }

    res.json({
      session: {
        ...session.getPublicData(),
        moodSession: session.moodSession?.getPublicData()
      }
    });

  } catch (error) {
    console.error('Study session fetch error:', error);
    res.status(500).json({ 
      error: 'Internal server error fetching study session' 
    });
  }
});

// Update study session
router.put('/sessions/:id', auth, [
  body('subject').optional().trim().isLength({ min: 1, max: 100 }).withMessage('Subject must be 1-100 characters'),
  body('plannedHours').optional().isFloat({ min: 0.5, max: 12.0 }).withMessage('Planned hours must be 0.5-12.0'),
  body('actualHours').optional().isFloat({ min: 0.0, max: 12.0 }).withMessage('Actual hours must be 0.0-12.0'),
  body('startTime').optional().isISO8601().withMessage('Valid start time required'),
  body('endTime').optional().isISO8601().withMessage('Valid end time required'),
  body('status').optional().isIn(['planned', 'in_progress', 'completed', 'cancelled']).withMessage('Invalid status'),
  body('notes').optional().trim().isLength({ max: 1000 }).withMessage('Notes must be 0-1000 characters'),
  body('productivity').optional().isInt({ min: 1, max: 10 }).withMessage('Productivity must be 1-10'),
  body('difficulty').optional().isInt({ min: 1, max: 10 }).withMessage('Difficulty must be 1-10'),
  body('topics').optional().isArray().withMessage('Topics must be an array')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array() 
      });
    }

    const session = await StudySession.findOne({
      where: {
        id: req.params.id,
        userId: req.user.id
      }
    });

    if (!session) {
      return res.status(404).json({ 
        error: 'Study session not found' 
      });
    }

    const updateData = {};
    const allowedFields = [
      'subject', 'plannedHours', 'actualHours', 'startTime', 'endTime', 
      'status', 'notes', 'productivity', 'difficulty', 'topics'
    ];

    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        if (field === 'startTime' || field === 'endTime') {
          updateData[field] = new Date(req.body[field]);
        } else {
          updateData[field] = req.body[field];
        }
      }
    });

    await session.update(updateData);

    res.json({
      message: 'Study session updated successfully',
      session: session.getPublicData()
    });

  } catch (error) {
    console.error('Study session update error:', error);
    res.status(500).json({ 
      error: 'Internal server error updating study session' 
    });
  }
});

// Delete study session
router.delete('/sessions/:id', auth, async (req, res) => {
  try {
    const session = await StudySession.findOne({
      where: {
        id: req.params.id,
        userId: req.user.id
      }
    });

    if (!session) {
      return res.status(404).json({ 
        error: 'Study session not found' 
      });
    }

    await session.destroy();

    res.json({
      message: 'Study session deleted successfully'
    });

  } catch (error) {
    console.error('Study session delete error:', error);
    res.status(500).json({ 
      error: 'Internal server error deleting study session' 
    });
  }
});

// Start study session
router.post('/sessions/:id/start', auth, async (req, res) => {
  try {
    const session = await StudySession.findOne({
      where: {
        id: req.params.id,
        userId: req.user.id,
        status: 'planned'
      }
    });

    if (!session) {
      return res.status(404).json({ 
        error: 'Study session not found or cannot be started' 
      });
    }

    await session.update({
      status: 'in_progress',
      startTime: new Date()
    });

    res.json({
      message: 'Study session started successfully',
      session: session.getPublicData()
    });

  } catch (error) {
    console.error('Start study session error:', error);
    res.status(500).json({ 
      error: 'Internal server error starting study session' 
    });
  }
});

// Complete study session
router.post('/sessions/:id/complete', auth, [
  body('actualHours').isFloat({ min: 0.0, max: 12.0 }).withMessage('Actual hours must be 0.0-12.0'),
  body('productivity').optional().isInt({ min: 1, max: 10 }).withMessage('Productivity must be 1-10'),
  body('difficulty').optional().isInt({ min: 1, max: 10 }).withMessage('Difficulty must be 1-10'),
  body('notes').optional().trim().isLength({ max: 1000 }).withMessage('Notes must be 0-1000 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array() 
      });
    }

    const session = await StudySession.findOne({
      where: {
        id: req.params.id,
        userId: req.user.id,
        status: 'in_progress'
      }
    });

    if (!session) {
      return res.status(404).json({ 
        error: 'Study session not found or cannot be completed' 
      });
    }

    const { actualHours, productivity, difficulty, notes } = req.body;

    await session.update({
      status: 'completed',
      endTime: new Date(),
      actualHours,
      productivity,
      difficulty,
      notes: notes || session.notes
    });

    res.json({
      message: 'Study session completed successfully',
      session: session.getPublicData()
    });

  } catch (error) {
    console.error('Complete study session error:', error);
    res.status(500).json({ 
      error: 'Internal server error completing study session' 
    });
  }
});

// Get study analytics
router.get('/analytics', auth, async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const analytics = await StudySession.getUserStats(req.user.id, parseInt(days));

    res.json({
      analytics
    });

  } catch (error) {
    console.error('Study analytics error:', error);
    res.status(500).json({ 
      error: 'Internal server error fetching study analytics' 
    });
  }
});

// Get upcoming study sessions
router.get('/upcoming', auth, async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    const sessions = await StudySession.findAll({
      where: {
        userId: req.user.id,
        status: 'planned',
        startTime: {
          [require('sequelize').Op.gte]: new Date()
        }
      },
      order: [['startTime', 'ASC']],
      limit: parseInt(limit),
      include: [{
        model: MoodSession,
        as: 'moodSession',
        attributes: ['moodType', 'recommendedStudyHours']
      }]
    });

    res.json({
      sessions: sessions.map(session => ({
        ...session.getPublicData(),
        moodSession: session.moodSession?.getPublicData()
      }))
    });

  } catch (error) {
    console.error('Upcoming sessions fetch error:', error);
    res.status(500).json({ 
      error: 'Internal server error fetching upcoming sessions' 
    });
  }
});

module.exports = router;
