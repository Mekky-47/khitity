const { sequelize } = require('../config/database');
const { User, MoodSession, ChatMessage } = require('../models');

async function migrate() {
  try {
    console.log('🔄 Starting database migration...');
    
    // Test connection
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    
    // Sync all models
    console.log('🔄 Syncing database models...');
    await sequelize.sync({ force: true }); // WARNING: This will drop existing tables
    
    console.log('✅ Database models synchronized successfully');
    console.log('📊 Created tables:');
    console.log('   - users');
    console.log('   - mood_sessions');
    console.log('   - chat_messages');
    
    console.log('\n🎉 Migration completed successfully!');
    console.log('💡 You can now start the server with: npm start');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

// Run migration if called directly
if (require.main === module) {
  migrate();
}

module.exports = { migrate };
