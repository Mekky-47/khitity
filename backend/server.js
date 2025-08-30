const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const path = require('path');
require('dotenv').config();

// Import database configuration
const { sequelize, testConnection, syncDatabase } = require('./config/database');

// Import models
const { User, MoodSession, ChatSession, ChatMessage, StudySession } = require('./models');

// Import routes
const authRoutes = require('./routes/auth');
const moodRoutes = require('./routes/mood');
const chatRoutes = require('./routes/chat');
const studyRoutes = require('./routes/study');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.'
  }
});
app.use('/api/', limiter);

// CORS configuration
app.use(cors({
  origin: [
    'http://localhost:3000',
    'http://localhost:8080',
    'http://localhost:50224', // Flutter web
    'http://127.0.0.1:50224',
    process.env.FRONTEND_URL
  ].filter(Boolean),
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static file serving for uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Health check endpoint
app.get('/api/health', async (req, res) => {
  try {
    const dbStatus = await testConnection();
    res.json({
      status: 'OK',
      timestamp: new Date().toISOString(),
      database: dbStatus ? 'Connected' : 'Disconnected',
      environment: process.env.NODE_ENV || 'development',
      version: '1.0.0'
    });
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/mood', moodRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/study', studyRoutes);

// API documentation endpoint
app.get('/api', (req, res) => {
  res.json({
    message: 'Giyas AI Backend API',
    version: '1.0.0',
    endpoints: {
      auth: {
        'POST /api/auth/register': 'Register new user',
        'POST /api/auth/login': 'Login user',
        'GET /api/auth/profile': 'Get user profile',
        'PUT /api/auth/profile': 'Update user profile',
        'PUT /api/auth/change-password': 'Change password',
        'POST /api/auth/refresh-token': 'Refresh JWT token',
        'POST /api/auth/logout': 'Logout user'
      },
      mood: {
        'POST /api/mood/analyze-text': 'Analyze mood from text',
        'POST /api/mood/analyze-voice': 'Analyze mood from voice',
        'GET /api/mood/history': 'Get mood history',
        'GET /api/mood/:id': 'Get specific mood session',
        'PUT /api/mood/:id': 'Update mood session',
        'DELETE /api/mood/:id': 'Delete mood session',
        'GET /api/mood/analytics/summary': 'Get mood analytics',
        'POST /api/mood/:id/apply-to-plan': 'Apply mood to study plan'
      },
      chat: {
        'GET /api/chat/sessions': 'Get chat sessions',
        'POST /api/chat/sessions': 'Create chat session',
        'GET /api/chat/sessions/:id': 'Get chat session with messages',
        'PUT /api/chat/sessions/:id': 'Update chat session',
        'DELETE /api/chat/sessions/:id': 'Delete chat session',
        'POST /api/chat/send-message': 'Send message to chatbot',
        'GET /api/chat/sessions/:id/messages': 'Get messages for session',
        'PUT /api/chat/sessions/:id/mark-read': 'Mark messages as read',
        'GET /api/chat/unread-count': 'Get unread message count',
        'GET /api/chat/analytics': 'Get chat analytics'
      },
      study: {
        'GET /api/study/sessions': 'Get study sessions',
        'POST /api/study/sessions': 'Create study session',
        'GET /api/study/sessions/:id': 'Get specific study session',
        'PUT /api/study/sessions/:id': 'Update study session',
        'DELETE /api/study/sessions/:id': 'Delete study session',
        'POST /api/study/sessions/:id/start': 'Start study session',
        'POST /api/study/sessions/:id/complete': 'Complete study session',
        'GET /api/study/analytics': 'Get study analytics',
        'GET /api/study/upcoming': 'Get upcoming study sessions'
      }
    },
    authentication: 'All endpoints except /api/health require Bearer token in Authorization header'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  
  if (err.name === 'SequelizeValidationError') {
    return res.status(400).json({
      error: 'Validation error',
      details: err.errors.map(e => ({
        field: e.path,
        message: e.message
      }))
    });
  }
  
  if (err.name === 'SequelizeUniqueConstraintError') {
    return res.status(409).json({
      error: 'Duplicate entry',
      message: 'A record with this information already exists'
    });
  }
  
  if (err.name === 'MulterError') {
    return res.status(400).json({
      error: 'File upload error',
      message: err.message
    });
  }
  
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    message: `The requested endpoint ${req.originalUrl} does not exist`
  });
});

// Database initialization and server startup
async function startServer() {
  try {
    // Test database connection
    console.log('🔌 Testing database connection...');
    const dbConnected = await testConnection();
    
    if (!dbConnected) {
      console.error('❌ Database connection failed. Please check your database configuration.');
      process.exit(1);
    }
    
    // Sync database (create tables)
    console.log('🔄 Syncing database...');
    const dbSynced = await syncDatabase(false); // false = don't force recreate tables
    
    if (!dbSynced) {
      console.error('❌ Database sync failed.');
      process.exit(1);
    }
    
    // Create demo user if in development
    if (process.env.NODE_ENV !== 'production') {
      try {
        const existingUser = await User.findByEmail('student@test.com');
        if (!existingUser) {
          await User.create({
            name: 'Demo Student',
            email: 'student@test.com',
            password: 'password123',
            preferences: {
              language: 'en',
              timezone: 'UTC',
              dailyAvailableMinutes: 480,
              notifications: true
            }
          });
          console.log('✅ Demo user created: student@test.com / password123');
        } else {
          console.log('✅ Demo user already exists');
        }
      } catch (error) {
        console.log('⚠️ Could not create demo user:', error.message);
      }
    }
    
    // Start server
    app.listen(PORT, () => {
      console.log('🚀 Server running on port', PORT);
      console.log('📱 Health check: http://localhost:' + PORT + '/api/health');
      console.log('🔐 Auth endpoints: http://localhost:' + PORT + '/api/auth');
      console.log('😊 Mood endpoints: http://localhost:' + PORT + '/api/mood');
      console.log('💬 Chat endpoints: http://localhost:' + PORT + '/api/chat');
      console.log('📚 Study endpoints: http://localhost:' + PORT + '/api/study');
      console.log('📖 API docs: http://localhost:' + PORT + '/api');
      console.log('🌍 Environment:', process.env.NODE_ENV || 'development');
    });
    
  } catch (error) {
    console.error('❌ Server startup failed:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('🛑 SIGTERM received, shutting down gracefully...');
  try {
    await sequelize.close();
    console.log('✅ Database connection closed.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during shutdown:', error);
    process.exit(1);
  }
});

process.on('SIGINT', async () => {
  console.log('🛑 SIGINT received, shutting down gracefully...');
  try {
    await sequelize.close();
    console.log('✅ Database connection closed.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during shutdown:', error);
    process.exit(1);
  }
});

// Start the server
startServer();
