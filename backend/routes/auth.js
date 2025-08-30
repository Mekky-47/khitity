const express = require('express');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { User } = require('../models');
const { auth } = require('../middleware/auth');

const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-for-testing';

// Validation middleware
const validateRegistration = [
  body('name').trim().isLength({ min: 2, max: 100 }).withMessage('Name must be 2-100 characters'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
];

const validateLogin = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').notEmpty().withMessage('Password required')
];

// Helper function to generate JWT token
const generateToken = (userId) => {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '7d' });
};

// Basic auth endpoint information
router.get('/', (req, res) => {
  res.json({
    message: 'Authentication API',
    description: 'User registration, login, and authentication management',
    endpoints: {
      'POST /register': 'Register new user',
      'POST /login': 'Login user',
      'GET /profile': 'Get user profile (requires auth)',
      'PUT /profile': 'Update user profile (requires auth)',
      'POST /verify-email': 'Verify email address',
      'POST /forgot-password': 'Request password reset',
      'POST /reset-password': 'Reset password with token',
      'POST /logout': 'Logout user (requires auth)'
    },
    authentication: 'Some endpoints require authentication'
  });
});

// Register endpoint
router.post('/register', validateRegistration, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array() 
      });
    }

    const { name, email, password } = req.body;

    // Check if user already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(409).json({ 
        error: 'User with this email already exists' 
      });
    }

    // Create new user
    const user = await User.create({
      name,
      email,
      password
    });

    // Generate JWT token
    const token = generateToken(user.id);

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: user.getPublicProfile()
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ 
      error: 'Internal server error during registration' 
    });
  }
});

// Login endpoint
router.post('/login', validateLogin, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array() 
      });
    }

    const { email, password } = req.body;

    // Find user by email
    const user = await User.findByEmail(email);
    if (!user || !user.isActive) {
      return res.status(401).json({ 
        error: 'Invalid email or password' 
      });
    }

    // Check password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({ 
        error: 'Invalid email or password' 
      });
    }

    // Update last login
    await user.update({ lastLogin: new Date() });

    // Generate JWT token
    const token = generateToken(user.id);

    res.json({
      message: 'Login successful',
      token,
      user: user.getPublicProfile()
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      error: 'Internal server error during login' 
    });
  }
});

// Get user profile
router.get('/profile', auth, async (req, res) => {
  try {
    res.json({
      user: req.user.getPublicProfile()
    });
  } catch (error) {
    console.error('Profile fetch error:', error);
    res.status(500).json({ 
      error: 'Internal server error fetching profile' 
    });
  }
});

// Update user profile
router.put('/profile', auth, [
  body('name').optional().trim().isLength({ min: 2, max: 100 }).withMessage('Name must be 2-100 characters'),
  body('preferences').optional().isObject().withMessage('Preferences must be an object')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array() 
      });
    }

    const { name, preferences } = req.body;
    const updateData = {};

    if (name) updateData.name = name;
    if (preferences) updateData.preferences = { ...req.user.preferences, ...preferences };

    await req.user.update(updateData);

    res.json({
      message: 'Profile updated successfully',
      user: req.user.getPublicProfile()
    });

  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({ 
      error: 'Internal server error updating profile' 
    });
  }
});

// Change password
router.put('/change-password', auth, [
  body('currentPassword').notEmpty().withMessage('Current password required'),
  body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array() 
      });
    }

    const { currentPassword, newPassword } = req.body;

    // Verify current password
    const isCurrentPasswordValid = await req.user.comparePassword(currentPassword);
    if (!isCurrentPasswordValid) {
      return res.status(400).json({ 
        error: 'Current password is incorrect' 
      });
    }

    // Update password
    await req.user.update({ password: newPassword });

    res.json({
      message: 'Password changed successfully'
    });

  } catch (error) {
    console.error('Password change error:', error);
    res.status(500).json({ 
      error: 'Internal server error changing password' 
    });
  }
});

// Refresh token
router.post('/refresh-token', auth, async (req, res) => {
  try {
    // Generate new token
    const token = generateToken(req.user.id);

    res.json({
      message: 'Token refreshed successfully',
      token,
      user: req.user.getPublicProfile()
    });

  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(500).json({ 
      error: 'Internal server error refreshing token' 
    });
  }
});

// Logout (client-side token removal, but we can track it)
router.post('/logout', auth, async (req, res) => {
  try {
    // In a more advanced setup, you might want to blacklist the token
    // For now, we'll just return success
    res.json({
      message: 'Logged out successfully'
    });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ 
      error: 'Internal server error during logout' 
    });
  }
});

module.exports = router;
