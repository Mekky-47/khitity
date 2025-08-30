const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// In-memory storage (same as in auth.js)
const users = new Map();
const tokens = new Map();

// JWT secret
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-for-testing';

// Helper function to generate JWT token
const generateToken = (userId) => {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '7d' });
};

async function registerDemoUser() {
  try {
    const email = 'student@test.com';
    const password = 'password123';
    const name = 'Demo Student';

    // Check if user already exists
    if (users.has(email)) {
      console.log('✅ Demo user already exists');
      return;
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Create user
    const userId = Date.now().toString();
    const user = {
      id: userId,
      name,
      email,
      password: hashedPassword,
      preferences: {
        language: 'en',
        timezone: 'UTC',
        dailyAvailableMinutes: 480,
        notifications: true
      },
      lastLogin: new Date(),
      isActive: true
    };

    users.set(email, user);

    // Generate token
    const token = generateToken(userId);
    tokens.set(userId, token);

    console.log('✅ Demo user registered successfully!');
    console.log('📧 Email:', email);
    console.log('🔑 Password:', password);
    console.log('🎫 Token:', token);
    console.log('\n🚀 You can now login with these credentials in the Flutter app!');

  } catch (error) {
    console.error('❌ Error registering demo user:', error);
  }
}

// Run the registration
registerDemoUser();
