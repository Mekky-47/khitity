const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const MoodSession = sequelize.define('MoodSession', {
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
  moodType: {
    type: DataTypes.STRING(50),
    allowNull: false,
    validate: {
      isIn: [['happy', 'excited', 'tired', 'stressed', 'bored', 'anxious', 'focused', 'relaxed', 'neutral', 'sad', 'angry']]
    }
  },
  moodDescription: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  voiceFileUrl: {
    type: DataTypes.STRING(500),
    allowNull: true
  },
  aiAnalysis: {
    type: DataTypes.JSONB,
    allowNull: false
  },
  recommendedStudyHours: {
    type: DataTypes.DECIMAL(3, 1),
    allowNull: false,
    validate: {
      min: 0.5,
      max: 12.0
    }
  },
  confidence: {
    type: DataTypes.DECIMAL(3, 2),
    allowNull: false,
    validate: {
      min: 0.0,
      max: 1.0
    }
  },
  studyTips: {
    type: DataTypes.JSONB,
    allowNull: false,
    defaultValue: []
  },
  appliedToPlan: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  sessionDate: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  tableName: 'mood_sessions',
  timestamps: true,
  underscored: true,
  indexes: [
    {
      fields: ['user_id']
    },
    {
      fields: ['session_date']
    },
    {
      fields: ['mood_type']
    }
  ]
});

// Instance methods
MoodSession.prototype.getPublicData = function() {
  return {
    id: this.id,
    moodType: this.moodType,
    moodDescription: this.moodDescription,
    voiceFileUrl: this.voiceFileUrl,
    aiAnalysis: this.aiAnalysis,
    recommendedStudyHours: this.recommendedStudyHours,
    confidence: this.confidence,
    studyTips: this.studyTips,
    appliedToPlan: this.appliedToPlan,
    sessionDate: this.sessionDate,
    notes: this.notes,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

// Class methods
MoodSession.findByUser = function(userId, options = {}) {
  const defaultOptions = {
    where: { userId },
    order: [['sessionDate', 'DESC']],
    limit: 50
  };
  
  return this.findAll({
    ...defaultOptions,
    ...options
  });
};

MoodSession.getUserAnalytics = async function(userId, days = 30) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);

  const sessions = await this.findAll({
    where: {
      userId,
      sessionDate: {
        [sequelize.Op.gte]: startDate
      }
    },
    order: [['sessionDate', 'ASC']]
  });

  // Calculate analytics
  const totalSessions = sessions.length;
  const averageConfidence = totalSessions > 0 
    ? sessions.reduce((sum, session) => sum + parseFloat(session.confidence), 0) / totalSessions 
    : 0;
  
  const averageStudyHours = totalSessions > 0
    ? sessions.reduce((sum, session) => sum + parseFloat(session.recommendedStudyHours), 0) / totalSessions
    : 0;

  const moodDistribution = {};
  sessions.forEach(session => {
    moodDistribution[session.moodType] = (moodDistribution[session.moodType] || 0) + 1;
  });

  const appliedToPlanCount = sessions.filter(session => session.appliedToPlan).length;

  return {
    totalSessions,
    averageConfidence,
    averageStudyHours,
    moodDistribution,
    appliedToPlanCount,
    appliedToPlanPercentage: totalSessions > 0 ? (appliedToPlanCount / totalSessions) * 100 : 0,
    sessions: sessions.map(session => session.getPublicData())
  };
};

module.exports = MoodSession;
