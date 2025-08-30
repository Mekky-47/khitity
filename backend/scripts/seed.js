const { sequelize } = require('../config/database');
const { User, MoodSession, ChatMessage } = require('../models');
const bcrypt = require('bcryptjs');

async function seed() {
  try {
    console.log('🌱 Starting database seeding...');
    
    // Test connection
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    
    // Create sample users
    console.log('👥 Creating sample users...');
    
    const hashedPassword = await bcrypt.hash('password123', 10);
    
    const users = await User.bulkCreate([
      {
        name: 'Test Student',
        email: 'student@test.com',
        password: hashedPassword,
        preferences: {
          language: 'en',
          timezone: 'UTC',
          dailyAvailableMinutes: 120,
          notifications: true
        }
      },
      {
        name: 'Demo User',
        email: 'demo@test.com',
        password: hashedPassword,
        preferences: {
          language: 'ar',
          timezone: 'Asia/Riyadh',
          dailyAvailableMinutes: 90,
          notifications: false
        }
      }
    ]);
    
    console.log(`✅ Created ${users.length} users`);
    
    // Create sample mood sessions
    console.log('😊 Creating sample mood sessions...');
    
    const moodSessions = await MoodSession.bulkCreate([
      {
        userId: users[0].id,
        moodType: 'happy',
        moodDescription: 'Feeling great and motivated to study!',
        aiAnalysis: {
          moodType: 'happy',
          confidence: 0.85,
          recommendedStudyHours: 4.0,
          explanation: 'Your positive mood suggests high energy and focus.',
          studyTips: [
            'Take advantage of your energy',
            'Tackle challenging subjects first',
            'Include short breaks every hour'
          ]
        },
        recommendedStudyHours: 4.0,
        confidence: 0.85,
        studyTips: [
          'Take advantage of your energy',
          'Tackle challenging subjects first',
          'Include short breaks every hour'
        ]
      },
      {
        userId: users[0].id,
        moodType: 'tired',
        moodDescription: 'A bit tired but still want to study',
        aiAnalysis: {
          moodType: 'tired',
          confidence: 0.72,
          recommendedStudyHours: 2.0,
          explanation: 'Your current state suggests you need shorter, focused sessions.',
          studyTips: [
            'Keep sessions short and focused',
            'Take frequent breaks',
            'Start with easier subjects'
          ]
        },
        recommendedStudyHours: 2.0,
        confidence: 0.72,
        studyTips: [
          'Keep sessions short and focused',
          'Take frequent breaks',
          'Start with easier subjects'
        ]
      }
    ]);
    
    console.log(`✅ Created ${moodSessions.length} mood sessions`);
    
    // Create sample chat messages
    console.log('💬 Creating sample chat messages...');
    
    const chatMessages = await ChatMessage.bulkCreate([
      {
        userId: users[0].id,
        sessionId: 'sample-session-1',
        messageType: 'user',
        content: 'How can I improve my study habits?',
        timestamp: new Date(Date.now() - 3600000) // 1 hour ago
      },
      {
        userId: users[0].id,
        sessionId: 'sample-session-1',
        messageType: 'assistant',
        content: 'Great question! Based on your recent mood analysis, I recommend starting with shorter, focused study sessions. Try the Pomodoro technique: 25 minutes of focused study followed by a 5-minute break.',
        moodContext: {
          moodType: 'tired',
          confidence: 0.72
        },
        timestamp: new Date(Date.now() - 3500000) // 58 minutes ago
      },
      {
        userId: users[0].id,
        sessionId: 'sample-session-1',
        messageType: 'user',
        content: 'That sounds helpful! What subjects should I focus on first?',
        timestamp: new Date(Date.now() - 3000000) // 50 minutes ago
      },
      {
        userId: users[0].id,
        sessionId: 'sample-session-1',
        messageType: 'assistant',
        content: 'Since you\'re feeling a bit tired, I suggest starting with subjects you find easier or more enjoyable. This will help you build momentum and confidence. Once you\'re in a good rhythm, you can tackle more challenging topics.',
        moodContext: {
          moodType: 'tired',
          confidence: 0.72
        },
        timestamp: new Date(Date.now() - 2900000) // 48 minutes ago
      }
    ]);
    
    console.log(`✅ Created ${chatMessages.length} chat messages`);
    
    console.log('\n🎉 Database seeding completed successfully!');
    console.log('\n📋 Sample Data Created:');
    console.log('   - Users: student@test.com / password123');
    console.log('   - Users: demo@test.com / password123');
    console.log('   - Mood sessions with AI analysis');
    console.log('   - Chat conversations with context');
    
    console.log('\n💡 You can now test the API with these credentials');
    
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

// Run seeding if called directly
if (require.main === module) {
  seed();
}

module.exports = { seed };
