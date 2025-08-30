const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { body, validationResult } = require('express-validator');
const { MoodSession, StudySession } = require('../models');
const { auth } = require('../middleware/auth');
const { analyzeVoiceMood, analyzeTextMood } = require('../services/aiService');

const router = express.Router();

// Ensure upload directory exists
const uploadDir = path.join(__dirname, '../uploads/voice');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configure multer for voice file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, `voice-${req.user.id}-${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024 // 10MB default
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /wav|mp3|m4a|aac|ogg/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only audio files are allowed'));
    }
  }
});

// Validation middleware
const validateMoodAnalysis = [
  body('moodDescription').trim().isLength({ min: 10, max: 1000 }).withMessage('Mood description must be 10-1000 characters')
];

// Basic mood endpoint information
router.get('/', (req, res) => {
  res.json({
    message: 'Mood Analysis API',
    description: 'AI-powered mood analysis and study planning',
    endpoints: {
      'POST /analyze-text': 'Analyze mood from text description',
      'POST /analyze-voice': 'Analyze mood from voice recording',
      'GET /history': 'Get user mood history',
      'GET /:id': 'Get specific mood session',
      'PUT /:id': 'Update mood session',
      'DELETE /:id': 'Delete mood session',
      'GET /analytics/summary': 'Get mood analytics summary',
      'POST /:id/apply-to-plan': 'Apply mood insights to study plan'
    },
    authentication: 'All endpoints require authentication'
  });
});

// Analyze mood from text
router.post('/analyze-text', auth, validateMoodAnalysis, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array() 
      });
    }

    const { moodDescription } = req.body;

    // Analyze mood using AI
    const analysis = await analyzeTextMood(moodDescription);

    // Create mood session
    const moodSession = await MoodSession.create({
      userId: req.user.id,
      moodType: analysis.mood,
      moodDescription,
      aiAnalysis: analysis,
      recommendedStudyHours: analysis.recommendedHours,
      confidence: analysis.confidence,
      studyTips: analysis.studyTips || []
    });

    res.json({
      message: 'Mood analysis completed',
      moodSession: moodSession.getPublicData()
    });

  } catch (error) {
    console.error('Text mood analysis error:', error);
    res.status(500).json({ 
      error: 'Internal server error during mood analysis' 
    });
  }
});

// Analyze mood from voice
router.post('/analyze-voice', auth, upload.single('audio'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ 
        error: 'No audio file provided' 
      });
    }

    const voiceFileUrl = `/uploads/voice/${req.file.filename}`;

    // Analyze voice using AI
    const analysis = await analyzeVoiceMood(req.file.path);

    // Create mood session
    const moodSession = await MoodSession.create({
      userId: req.user.id,
      moodType: analysis.mood,
      moodDescription: analysis.description || 'Voice-based mood analysis',
      voiceFileUrl,
      aiAnalysis: analysis,
      recommendedStudyHours: analysis.recommendedHours,
      confidence: analysis.confidence,
      studyTips: analysis.studyTips || []
    });

    res.json({
      message: 'Voice mood analysis completed',
      moodSession: moodSession.getPublicData()
    });

  } catch (error) {
    console.error('Voice mood analysis error:', error);
    
    // Clean up uploaded file if analysis failed
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    
    res.status(500).json({ 
      error: 'Internal server error during voice mood analysis' 
    });
  }
});

// Get user's mood history
router.get('/history', auth, async (req, res) => {
  try {
    const { page = 1, limit = 20, days } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = { userId: req.user.id };
    
    if (days) {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - parseInt(days));
      whereClause.sessionDate = {
        [require('sequelize').Op.gte]: startDate
      };
    }

    const { count, rows: moodSessions } = await MoodSession.findAndCountAll({
      where: whereClause,
      order: [['sessionDate', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.json({
      moodSessions: moodSessions.map(session => session.getPublicData()),
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(count / limit),
        totalItems: count,
        itemsPerPage: parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Mood history fetch error:', error);
    res.status(500).json({ 
      error: 'Internal server error fetching mood history' 
    });
  }
});

// Get specific mood session
router.get('/:id', auth, async (req, res) => {
  try {
    const moodSession = await MoodSession.findOne({
      where: {
        id: req.params.id,
        userId: req.user.id
      }
    });

    if (!moodSession) {
      return res.status(404).json({ 
        error: 'Mood session not found' 
      });
    }

    res.json({
      moodSession: moodSession.getPublicData()
    });

  } catch (error) {
    console.error('Mood session fetch error:', error);
    res.status(500).json({ 
      error: 'Internal server error fetching mood session' 
    });
  }
});

// Update mood session
router.put('/:id', auth, async (req, res) => {
  try {
    const moodSession = await MoodSession.findOne({
      where: {
        id: req.params.id,
        userId: req.user.id
      }
    });

    if (!moodSession) {
      return res.status(404).json({ 
        error: 'Mood session not found' 
      });
    }

    const { notes, appliedToPlan } = req.body;
    const updateData = {};

    if (notes !== undefined) updateData.notes = notes;
    if (appliedToPlan !== undefined) updateData.appliedToPlan = appliedToPlan;

    await moodSession.update(updateData);

    res.json({
      message: 'Mood session updated successfully',
      moodSession: moodSession.getPublicData()
    });

  } catch (error) {
    console.error('Mood session update error:', error);
    res.status(500).json({ 
      error: 'Internal server error updating mood session' 
    });
  }
});

// Delete mood session
router.delete('/:id', auth, async (req, res) => {
  try {
    const moodSession = await MoodSession.findOne({
      where: {
        id: req.params.id,
        userId: req.user.id
      }
    });

    if (!moodSession) {
      return res.status(404).json({ 
        error: 'Mood session not found' 
      });
    }

    // Delete associated voice file if exists
    if (moodSession.voiceFileUrl) {
      const filePath = path.join(__dirname, '..', moodSession.voiceFileUrl);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    }

    await moodSession.destroy();

    res.json({
      message: 'Mood session deleted successfully'
    });

  } catch (error) {
    console.error('Mood session delete error:', error);
    res.status(500).json({ 
      error: 'Internal server error deleting mood session' 
    });
  }
});

// Get mood analytics
router.get('/analytics/summary', auth, async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const analytics = await MoodSession.getUserAnalytics(req.user.id, parseInt(days));

    res.json({
      analytics
    });

  } catch (error) {
    console.error('Mood analytics error:', error);
    res.status(500).json({ 
      error: 'Internal server error fetching mood analytics' 
    });
  }
});

// Apply mood to study plan
router.post('/:id/apply-to-plan', auth, [
  body('subject').trim().isLength({ min: 1, max: 100 }).withMessage('Subject is required'),
  body('startTime').isISO8601().withMessage('Valid start time required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array() 
      });
    }

    const moodSession = await MoodSession.findOne({
      where: {
        id: req.params.id,
        userId: req.user.id
      }
    });

    if (!moodSession) {
      return res.status(404).json({ 
        error: 'Mood session not found' 
      });
    }

    const { subject, startTime, notes } = req.body;

    // Create study session based on mood analysis
    const studySession = await StudySession.create({
      userId: req.user.id,
      moodSessionId: moodSession.id,
      subject,
      plannedHours: moodSession.recommendedStudyHours,
      startTime: new Date(startTime),
      status: 'planned',
      notes: notes || `Study session based on ${moodSession.moodType} mood`
    });

    // Mark mood session as applied to plan
    await moodSession.update({ appliedToPlan: true });

    res.json({
      message: 'Mood applied to study plan successfully',
      studySession: studySession.getPublicData(),
      moodSession: moodSession.getPublicData()
    });

  } catch (error) {
    console.error('Apply mood to plan error:', error);
    res.status(500).json({ 
      error: 'Internal server error applying mood to plan' 
    });
  }
});

module.exports = router;
