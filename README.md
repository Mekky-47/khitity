# 🎓 Giyas.AI - AI-Powered Study Planner

A comprehensive Flutter application with a Node.js backend that provides intelligent study planning, mood analysis, and AI-powered study assistance.

## ✨ Features

### 🧠 **AI-Powered Features**
- **Voice Mood Analysis**: Record your voice to get personalized study recommendations
- **AI Chatbot**: Intelligent study assistant with context-aware conversations
- **Mood-Based Planning**: Study schedules adapted to your emotional state
- **Personalized Recommendations**: AI-driven study tips and time management

### 🔐 **User Authentication**
- **Secure Login/Registration**: Email and password authentication
- **JWT Token Management**: Secure session handling
- **User Profiles**: Personalized settings and preferences
- **Data Privacy**: User-specific data isolation

### 📱 **Mobile App Features**
- **Daily Study Planning**: AI-optimized daily schedules
- **Weekly Planner**: Long-term study organization
- **Voice Recording**: Built-in audio capture for mood analysis
- **Real-time Chat**: Interactive AI study assistant
- **Multi-language Support**: English and Arabic localization
- **Modern UI**: Material Design 3 with beautiful animations

### 🗄️ **Backend Features**
- **PostgreSQL Database**: Robust data storage with relationships
- **RESTful API**: Comprehensive endpoints for all features
- **File Upload**: Audio file handling for voice analysis
- **Security**: Rate limiting, input validation, and CORS protection
- **Analytics**: Study session tracking and mood history

## 🏗️ Architecture

### **Frontend (Flutter)**
```
lib/
├── core/
│   ├── models/          # Data models
│   ├── providers/       # Riverpod state management
│   └── services/        # API services
├── features/
│   ├── auth/           # Authentication screens
│   ├── chat/           # AI chatbot interface
│   ├── mood_analysis/  # Voice/text mood analysis
│   ├── daily_plan/     # Daily study planning
│   ├── weekly_planner/ # Weekly schedule management
│   └── settings/       # User preferences
└── l10n/               # Localization files
```

### **Backend (Node.js/Express)**
```
backend/
├── config/             # Database configuration
├── models/             # Sequelize models
├── routes/             # API endpoints
├── services/           # Business logic
├── middleware/         # Authentication & validation
└── scripts/            # Database migration & seeding
```

## 🚀 Quick Start

### **Prerequisites**
- Flutter SDK (3.0.0+)
- Node.js (18+)
- PostgreSQL database
- Google Gemini API key

### **1. Backend Setup**

```bash
cd backend

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Set up database
npm run db:migrate
npm run db:seed

# Start the server
npm start
```

### **2. Flutter App Setup**

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

### **3. Environment Configuration**

Create `.env` file in the backend directory:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=giyas_ai_db
DB_USER=postgres
DB_PASSWORD=your_password

# JWT Secret
JWT_SECRET=your_jwt_secret_key

# Google Gemini API
GEMINI_API_KEY=your_gemini_api_key

# File Upload
MAX_FILE_SIZE=10485760
UPLOAD_PATH=uploads/audio
```

## 📱 App Features

### **Authentication**
- Secure login and registration
- JWT token-based authentication
- User profile management
- Password change functionality

### **Voice Mood Analysis**
- Record voice messages about your mood
- AI-powered mood detection
- Personalized study recommendations
- Text-based mood analysis (fallback)

### **AI Chatbot**
- Context-aware conversations
- Study-related Q&A
- Mood-adaptive responses
- Conversation history
- Session management

### **Study Planning**
- AI-optimized daily schedules
- Weekly planning interface
- Subject management
- Task prioritization
- Progress tracking

### **Settings & Preferences**
- Language selection (English/Arabic)
- Study preferences
- Notification settings
- Profile customization

## 🔧 API Endpoints

### **Authentication**
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/profile` - Update profile
- `PUT /api/auth/change-password` - Change password

### **Mood Analysis**
- `POST /api/mood/analyze-voice` - Voice mood analysis
- `POST /api/mood/analyze-text` - Text mood analysis
- `GET /api/mood/history` - Mood history
- `GET /api/mood/analytics` - Mood analytics

### **Chat**
- `POST /api/chat/send` - Send message
- `GET /api/chat/session/:id` - Get chat history
- `GET /api/chat/sessions` - Get all sessions
- `POST /api/chat/session` - Start new session

## 🛠️ Development

### **Adding New Features**

1. **Backend**: Add models, routes, and services
2. **Frontend**: Create UI screens and providers
3. **Integration**: Connect frontend to backend APIs
4. **Testing**: Test functionality and error handling

### **Database Schema**

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  preferences JSONB,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Mood sessions table
CREATE TABLE mood_sessions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  mood_type VARCHAR(50) NOT NULL,
  ai_analysis JSONB,
  recommended_study_hours DECIMAL(3,1),
  confidence DECIMAL(3,2),
  created_at TIMESTAMP
);

-- Chat messages table
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  session_id UUID NOT NULL,
  message_type ENUM('user', 'assistant'),
  content TEXT NOT NULL,
  ai_response JSONB,
  created_at TIMESTAMP
);
```

## 🚀 Deployment

### **Backend Deployment (Railway/Render)**

1. Connect your GitHub repository
2. Set environment variables
3. Deploy automatically on push

### **Flutter App Deployment**

1. Build for production:
   ```bash
   flutter build apk --release
   flutter build ios --release
   ```

2. Deploy to app stores or distribute APK

## 🔒 Security Features

- JWT token authentication
- Password hashing with bcrypt
- Input validation and sanitization
- Rate limiting
- CORS protection
- Secure file upload handling

## 📊 Analytics & Monitoring

- Study session tracking
- Mood pattern analysis
- Chat conversation analytics
- User engagement metrics
- Performance monitoring

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the API endpoints

## 🎯 Roadmap

- [ ] Speech-to-text integration
- [ ] Study group features
- [ ] Advanced analytics dashboard
- [ ] Mobile push notifications
- [ ] Offline mode support
- [ ] Integration with calendar apps
- [ ] Study material recommendations
- [ ] Progress visualization

---

**Built with ❤️ using Flutter, Node.js, and Google Gemini AI**
