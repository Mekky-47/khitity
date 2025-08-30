const jwt = require('jsonwebtoken');
const { User } = require('../models');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-for-testing';

// Middleware to authenticate user
const auth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        error: 'Authentication required',
        message: 'No token provided'
      });
    }

    const token = authHeader.substring(7);
    
    // Verify token
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // Find user
    const user = await User.findByPk(decoded.userId);
    
    if (!user || !user.isActive) {
      return res.status(401).json({ 
        error: 'Authentication failed',
        message: 'User not found or inactive'
      });
    }

    // Add user to request object
    req.user = user;
    next();
    
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ 
        error: 'Invalid token',
        message: 'Token is malformed or invalid'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ 
        error: 'Token expired',
        message: 'Please login again'
      });
    }
    
    console.error('Auth middleware error:', error);
    res.status(500).json({ 
      error: 'Authentication error',
      message: 'Internal server error'
    });
  }
};

// Optional authentication middleware (doesn't fail if no token)
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      req.user = null;
      return next();
    }

    const token = authHeader.substring(7);
    
    // Verify token
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // Find user
    const user = await User.findByPk(decoded.userId);
    
    if (user && user.isActive) {
      req.user = user;
    } else {
      req.user = null;
    }
    
    next();
    
  } catch (error) {
    // Don't fail on token errors, just set user to null
    req.user = null;
    next();
  }
};

// Middleware to check if user has specific role (for future use)
const requireRole = (role) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ 
        error: 'Authentication required',
        message: 'No user found'
      });
    }

    // For now, all users have the same role
    // In the future, you can add role-based access control
    next();
  };
};

// Middleware to check if user owns the resource
const requireOwnership = (model, paramName = 'id') => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json({ 
          error: 'Authentication required',
          message: 'No user found'
        });
      }

      const resourceId = req.params[paramName];
      const resource = await model.findByPk(resourceId);
      
      if (!resource) {
        return res.status(404).json({ 
          error: 'Resource not found',
          message: 'The requested resource does not exist'
        });
      }

      if (resource.userId !== req.user.id) {
        return res.status(403).json({ 
          error: 'Access denied',
          message: 'You do not have permission to access this resource'
        });
      }

      req.resource = resource;
      next();
      
    } catch (error) {
      console.error('Ownership check error:', error);
      res.status(500).json({ 
        error: 'Authorization error',
        message: 'Internal server error'
      });
    }
  };
};

module.exports = {
  auth,
  optionalAuth,
  requireRole,
  requireOwnership
};
