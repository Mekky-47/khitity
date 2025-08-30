const { DataTypes } = require('sequelize');
const bcrypt = require('bcryptjs');
const { sequelize } = require('../config/database');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING(100),
    allowNull: false,
    validate: {
      len: [2, 100]
    }
  },
  email: {
    type: DataTypes.STRING(255),
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true
    }
  },
  password: {
    type: DataTypes.STRING(255),
    allowNull: false,
    validate: {
      len: [6, 255]
    }
  },
  preferences: {
    type: DataTypes.JSONB,
    defaultValue: {
      language: 'en',
      timezone: 'UTC',
      dailyAvailableMinutes: 480,
      notifications: true
    }
  },
  lastLogin: {
    type: DataTypes.DATE,
    allowNull: true
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  emailVerified: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  verificationToken: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  resetPasswordToken: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  resetPasswordExpires: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  tableName: 'users',
  timestamps: true,
  underscored: true,
  hooks: {
    beforeCreate: async (user) => {
      if (user.password) {
        user.password = await bcrypt.hash(user.password, 12);
      }
    },
    beforeUpdate: async (user) => {
      if (user.changed('password')) {
        user.password = await bcrypt.hash(user.password, 12);
      }
    }
  }
});

// Instance methods
User.prototype.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

User.prototype.getPublicProfile = function() {
  return {
    id: this.id,
    name: this.name,
    email: this.email,
    preferences: this.preferences,
    lastLogin: this.lastLogin,
    isActive: this.isActive,
    emailVerified: this.emailVerified,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

// Class methods
User.findByEmail = function(email) {
  return this.findOne({ where: { email: email.toLowerCase() } });
};

User.createUser = async function(userData) {
  const user = await this.create(userData);
  return user.getPublicProfile();
};

module.exports = User;
