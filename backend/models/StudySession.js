const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const StudySession = sequelize.define('StudySession', {
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
  moodSessionId: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'mood_sessions',
      key: 'id'
    }
  },
  subject: {
    type: DataTypes.STRING(100),
    allowNull: false
  },
  plannedHours: {
    type: DataTypes.DECIMAL(3, 1),
    allowNull: false,
    validate: {
      min: 0.5,
      max: 12.0
    }
  },
  actualHours: {
    type: DataTypes.DECIMAL(3, 1),
    allowNull: true,
    validate: {
      min: 0.0,
      max: 12.0
    }
  },
  startTime: {
    type: DataTypes.DATE,
    allowNull: false
  },
  endTime: {
    type: DataTypes.DATE,
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM('planned', 'in_progress', 'completed', 'cancelled'),
    defaultValue: 'planned'
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  productivity: {
    type: DataTypes.INTEGER,
    allowNull: true,
    validate: {
      min: 1,
      max: 10
    }
  },
  difficulty: {
    type: DataTypes.INTEGER,
    allowNull: true,
    validate: {
      min: 1,
      max: 10
    }
  },
  topics: {
    type: DataTypes.JSONB,
    allowNull: true,
    defaultValue: []
  }
}, {
  tableName: 'study_sessions',
  timestamps: true,
  underscored: true,
  indexes: [
    {
      fields: ['user_id']
    },
    {
      fields: ['start_time']
    },
    {
      fields: ['status']
    },
    {
      fields: ['subject']
    }
  ]
});

// Instance methods
StudySession.prototype.getPublicData = function() {
  return {
    id: this.id,
    moodSessionId: this.moodSessionId,
    subject: this.subject,
    plannedHours: this.plannedHours,
    actualHours: this.actualHours,
    startTime: this.startTime,
    endTime: this.endTime,
    status: this.status,
    notes: this.notes,
    productivity: this.productivity,
    difficulty: this.difficulty,
    topics: this.topics,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

// Class methods
StudySession.findByUser = function(userId, options = {}) {
  const defaultOptions = {
    where: { userId },
    order: [['startTime', 'DESC']],
    limit: 50
  };
  
  return this.findAll({
    ...defaultOptions,
    ...options
  });
};

StudySession.getUserStats = async function(userId, days = 30) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);

  const sessions = await this.findAll({
    where: {
      userId,
      startTime: {
        [sequelize.Op.gte]: startDate
      },
      status: 'completed'
    },
    order: [['startTime', 'ASC']]
  });

  const totalSessions = sessions.length;
  const totalPlannedHours = sessions.reduce((sum, session) => sum + parseFloat(session.plannedHours), 0);
  const totalActualHours = sessions.reduce((sum, session) => sum + (parseFloat(session.actualHours) || 0), 0);
  const averageProductivity = totalSessions > 0 
    ? sessions.reduce((sum, session) => sum + (session.productivity || 5), 0) / totalSessions 
    : 0;
  const averageDifficulty = totalSessions > 0
    ? sessions.reduce((sum, session) => sum + (session.difficulty || 5), 0) / totalSessions
    : 0;

  const subjectStats = {};
  sessions.forEach(session => {
    if (!subjectStats[session.subject]) {
      subjectStats[session.subject] = {
        count: 0,
        totalHours: 0,
        averageProductivity: 0
      };
    }
    subjectStats[session.subject].count++;
    subjectStats[session.subject].totalHours += parseFloat(session.actualHours) || 0;
  });

  // Calculate average productivity per subject
  Object.keys(subjectStats).forEach(subject => {
    const subjectSessions = sessions.filter(s => s.subject === subject);
    subjectStats[subject].averageProductivity = subjectSessions.length > 0
      ? subjectSessions.reduce((sum, session) => sum + (session.productivity || 5), 0) / subjectSessions.length
      : 0;
  });

  return {
    totalSessions,
    totalPlannedHours,
    totalActualHours,
    averageProductivity,
    averageDifficulty,
    subjectStats,
    sessions: sessions.map(session => session.getPublicData())
  };
};

module.exports = StudySession;
